function Get-PkgSyncSourceExecutables {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$SourceName
    )

    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    $extensions = @('.exe', '.cmd', '.bat', '.ps1')
    $results = @()

    Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | ForEach-Object {
        $ext = $_.Extension.ToLowerInvariant()
        $isMatch = $extensions -contains $ext

        if (-not $isMatch -and [string]::IsNullOrEmpty($ext)) {
            $firstLine = Get-Content -LiteralPath $_.FullName -TotalCount 1 -ErrorAction SilentlyContinue
            if ($firstLine -and $firstLine.StartsWith('#!')) { $isMatch = $true }
        }

        if ($isMatch) {
            $results += [pscustomobject]@{
                Name   = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                Target = $_.FullName
                Source = $SourceName
            }
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
                Target   = $_.Target[0]
                LinkPath = $_.FullName
            }
        }
}
