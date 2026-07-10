function Resolve-PkgSyncSourcePaths {
    $sources = @()

    $winget = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    if (Test-Path -LiteralPath $winget) { $sources += [pscustomobject]@{ Name = 'winget'; Path = $winget } }

    $chocoRoot = $env:ChocolateyInstall
    if (-not $chocoRoot) { $chocoRoot = 'C:\ProgramData\chocolatey' }
    $chocoBin = Join-Path $chocoRoot 'bin'
    if (Test-Path -LiteralPath $chocoBin) { $sources += [pscustomobject]@{ Name = 'chocolatey'; Path = $chocoBin } }

    $scoopShims = Join-Path $env:USERPROFILE 'scoop\shims'
    if (Test-Path -LiteralPath $scoopShims) { $sources += [pscustomobject]@{ Name = 'scoop'; Path = $scoopShims } }

    $npmBin = Join-Path $env:APPDATA 'npm'
    if (Test-Path -LiteralPath $npmBin) { $sources += [pscustomobject]@{ Name = 'npm'; Path = $npmBin } }

    $pnpmBin = Join-Path $env:LOCALAPPDATA 'pnpm'
    if (Test-Path -LiteralPath $pnpmBin) { $sources += [pscustomobject]@{ Name = 'pnpm'; Path = $pnpmBin } }

    $localBin = Join-Path $env:USERPROFILE '.local\bin'
    if (Test-Path -LiteralPath $localBin) {
        $sources += [pscustomobject]@{ Name = 'pipx'; Path = $localBin }
        $sources += [pscustomobject]@{ Name = 'uv'; Path = $localBin }
    }

    $cargoBin = Join-Path $env:USERPROFILE '.cargo\bin'
    if (Test-Path -LiteralPath $cargoBin) { $sources += [pscustomobject]@{ Name = 'cargo'; Path = $cargoBin } }

    if (Get-Command gem -ErrorAction SilentlyContinue) {
        try {
            $gemDir = (& gem environment gemdir 2>$null)
            if ($gemDir) {
                $gemBin = Join-Path (Split-Path -Parent $gemDir) 'bin'
                if (Test-Path -LiteralPath $gemBin) { $sources += [pscustomobject]@{ Name = 'gem'; Path = $gemBin } }
            }
        } catch {
            # gem present but query failed; treat as not installed for this run
        }
    }

    $goBin = $env:GOBIN
    if (-not $goBin) {
        $goPath = $env:GOPATH
        if (-not $goPath) { $goPath = Join-Path $env:USERPROFILE 'go' }
        $goBin = Join-Path $goPath 'bin'
    }
    if (Test-Path -LiteralPath $goBin) { $sources += [pscustomobject]@{ Name = 'go'; Path = $goBin } }

    return $sources
}
