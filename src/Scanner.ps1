function Get-PkgSyncSourceExecutables {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$SourceName
    )

    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    $extensionPriority = @{ '.exe' = 0; '.cmd' = 1; '.bat' = 2; '.ps1' = 3; '' = 4 }
    $candidates = @()

    Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $ext = $_.Extension.ToLowerInvariant()
        $isMatch = $extensionPriority.ContainsKey($ext) -and $ext -ne ''

        if (-not $isMatch -and [string]::IsNullOrEmpty($ext)) {
            $firstLine = Get-Content -LiteralPath $_.FullName -TotalCount 1 -ErrorAction SilentlyContinue
            if ($firstLine -and $firstLine.StartsWith('#!')) { $isMatch = $true }
        }

        if ($isMatch) {
            $candidates += [pscustomobject]@{
                Name      = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                Target    = $_.FullName
                Source    = $SourceName
                Extension = $ext
            }
        }
    }

    $results = @()
    $candidates | Group-Object -Property { $_.Name.ToLowerInvariant() } | ForEach-Object {
        $winner = $_.Group | Sort-Object { $extensionPriority[$_.Extension] } | Select-Object -First 1
        $results += [pscustomobject]@{
            Name   = $winner.Name
            Target = $winner.Target
            Source = $winner.Source
        }
    }

    return $results
}

function Get-PkgSyncExistingLinks {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LinkType -eq 'SymbolicLink' } |
        ForEach-Object {
            [pscustomobject]@{
                Name     = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                Target   = @($_.Target)[0]
                LinkPath = $_.FullName
            }
        }
}
