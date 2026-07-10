function Test-PkgSyncPathContainsDirectory {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$PathValue,
        [Parameter(Mandatory)][string]$Directory
    )

    $normalizedTarget = $Directory.TrimEnd('\').ToLowerInvariant()
    $entries = $PathValue -split ';' | Where-Object { $_ -ne '' }

    foreach ($entry in $entries) {
        if ($entry.TrimEnd('\').ToLowerInvariant() -eq $normalizedTarget) { return $true }
    }

    return $false
}

function Send-PkgSyncSettingChangeBroadcast {
    if (-not ([System.Management.Automation.PSTypeName]'PkgSync.NativeMethods').Type) {
        Add-Type -Namespace PkgSync -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    }

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1A
    $result = [UIntPtr]::Zero
    [PkgSync.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null
}

function Set-PkgSyncEnsurePath {
    param(
        [Parameter(Mandatory)][string]$Directory
    )

    $currentPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $currentPath) { $currentPath = '' }

    if (Test-PkgSyncPathContainsDirectory -PathValue $currentPath -Directory $Directory) {
        return $false
    }

    $separator = ''
    if ($currentPath -and -not $currentPath.EndsWith(';')) { $separator = ';' }
    $newPath = "$currentPath$separator$Directory"

    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Send-PkgSyncSettingChangeBroadcast

    return $true
}
