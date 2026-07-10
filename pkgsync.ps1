# pkgsync.ps1
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'src\PkgSync.psm1') -Force

try {
    $result = Invoke-PkgSync
} catch {
    $isPrivilegeError = $false
    $ex = $_.Exception
    while ($ex) {
        if ($ex.HResult -eq 0x80070522 -or $ex.HResult -eq 0x80070005) {
            $isPrivilegeError = $true
            break
        }
        $ex = $ex.InnerException
    }
    if (-not $isPrivilegeError) {
        $isPrivilegeError = $_.Exception.Message -match 'privilege|access is denied'
    }

    if ($isPrivilegeError -and -not (Test-PkgSyncIsElevated)) {
        Write-Host 'Elevation required to create symlinks. Requesting admin rights...'
        Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
        )
        exit
    }
    throw
}

Write-Host "pkgsync: $($result.Added) added, $($result.Conflicts) conflicts skipped, $($result.Removed) removed."
if ($result.PathAdded) {
    Write-Host 'Added your bin directory to the User PATH. Open a new terminal for it to take effect.'
}
