function Invoke-PkgSyncPlan {
    param(
        [Parameter(Mandatory)][pscustomobject]$Plan,
        [Parameter(Mandatory)][string]$TargetDirectory
    )

    if (-not (Test-Path -LiteralPath $TargetDirectory)) {
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
    }

    foreach ($item in $Plan.ToRemove) {
        Remove-Item -LiteralPath $item.LinkPath -Force -ErrorAction Stop
    }

    foreach ($item in $Plan.ToCreate) {
        $extension = [System.IO.Path]::GetExtension($item.Target)
        $linkPath = Join-Path $TargetDirectory ($item.Name + $extension)
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $item.Target -ErrorAction Stop | Out-Null
    }
}
