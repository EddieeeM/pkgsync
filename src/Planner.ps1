function Test-PkgSyncLinkIsStale {
    param(
        [Parameter(Mandatory)][string]$Target
    )
    return -not (Test-Path -LiteralPath $Target)
}

function Test-PkgSyncConflict {
    param(
        [Parameter(Mandatory)][string]$ExistingTarget,
        [Parameter(Mandatory)][string]$CandidateTarget
    )
    return $ExistingTarget.TrimEnd('\') -ine $CandidateTarget.TrimEnd('\')
}

function Get-PkgSyncPlan {
    param(
        [Parameter(Mandatory)][array]$SourceExecutables,
        [Parameter(Mandatory=$false)][array]$ExistingLinks = @()
    )

    $existingByName = @{}
    foreach ($link in $ExistingLinks) {
        $existingByName[$link.Name.ToLowerInvariant()] = $link
    }

    $toRemove = @()
    $staleNames = @{}
    foreach ($link in $ExistingLinks) {
        if (Test-PkgSyncLinkIsStale -Target $link.Target) {
            $toRemove += $link
            $staleNames[$link.Name.ToLowerInvariant()] = $true
        }
    }

    $toCreate = @()
    $conflicts = @()
    $unchanged = @()
    $claimed = @{}

    foreach ($exe in $SourceExecutables) {
        $key = $exe.Name.ToLowerInvariant()
        $existing = $existingByName[$key]
        $existingIsLive = $existing -and -not $staleNames.ContainsKey($key)

        if ($existingIsLive) {
            if (Test-PkgSyncConflict -ExistingTarget $existing.Target -CandidateTarget $exe.Target) {
                $conflicts += [pscustomobject]@{
                    Name            = $exe.Name
                    ExistingTarget  = $existing.Target
                    CandidateTarget = $exe.Target
                    CandidateSource = $exe.Source
                }
            } else {
                $unchanged += [pscustomobject]@{ Name = $exe.Name; Target = $exe.Target; Source = $exe.Source }
            }
            continue
        }

        if ($claimed.ContainsKey($key)) {
            $winner = $claimed[$key]
            if (Test-PkgSyncConflict -ExistingTarget $winner.Target -CandidateTarget $exe.Target) {
                $conflicts += [pscustomobject]@{
                    Name            = $exe.Name
                    ExistingTarget  = $winner.Target
                    CandidateTarget = $exe.Target
                    CandidateSource = $exe.Source
                }
            }
            continue
        }

        $claimed[$key] = $exe
        $toCreate += [pscustomobject]@{ Name = $exe.Name; Target = $exe.Target; Source = $exe.Source }
    }

    [pscustomobject]@{
        ToCreate  = $toCreate
        Conflicts = $conflicts
        ToRemove  = $toRemove
        Unchanged = $unchanged
    }
}
