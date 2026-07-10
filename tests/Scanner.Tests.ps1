# tests/Scanner.Tests.ps1
Import-Module "$PSScriptRoot\..\src\PkgSync.psm1" -Force

Describe 'Get-PkgSyncSourceExecutables' {
    It 'returns an empty array when the source path does not exist' {
        $result = Get-PkgSyncSourceExecutables -Path 'TestDrive:\does-not-exist' -SourceName 'cargo'
        @($result).Count | Should -Be 0
    }

    It 'finds .exe, .cmd, and .bat files, stripping their extension for Name' {
        $dir = Join-Path $TestDrive 'bin1'
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content -Path (Join-Path $dir 'foo.exe') -Value 'stub'
        Set-Content -Path (Join-Path $dir 'bar.cmd') -Value 'stub'
        Set-Content -Path (Join-Path $dir 'baz.bat') -Value 'stub'
        Set-Content -Path (Join-Path $dir 'ignoreme.txt') -Value 'stub'

        $result = @(Get-PkgSyncSourceExecutables -Path $dir -SourceName 'cargo')

        $result.Count | Should -Be 3
        ($result | Where-Object Name -eq 'foo').Source | Should -Be 'cargo'
        ($result | Where-Object Name -eq 'bar').Target | Should -Be (Join-Path $dir 'bar.cmd')
    }

    It 'includes extensionless files with a shebang line' {
        $dir = Join-Path $TestDrive 'bin2'
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content -Path (Join-Path $dir 'shebanged') -Value "#!/usr/bin/env python`nprint('hi')"
        Set-Content -Path (Join-Path $dir 'plaintext') -Value 'just a readme, no shebang'

        $result = @(Get-PkgSyncSourceExecutables -Path $dir -SourceName 'pipx')

        $result.Count | Should -Be 1
        $result[0].Name | Should -Be 'shebanged'
    }

    It 'dedupes multiple shims for the same tool, preferring .cmd over .ps1 and extensionless' {
        $dir = Join-Path $TestDrive 'npmstyle'
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content -Path (Join-Path $dir 'foo') -Value "#!/bin/sh`necho hi"
        Set-Content -Path (Join-Path $dir 'foo.cmd') -Value 'stub'
        Set-Content -Path (Join-Path $dir 'foo.ps1') -Value 'stub'

        $result = @(Get-PkgSyncSourceExecutables -Path $dir -SourceName 'npm')

        $result.Count | Should -Be 1
        $result[0].Name | Should -Be 'foo'
        $result[0].Target | Should -Be (Join-Path $dir 'foo.cmd')
    }

    It 'dedupes case-insensitively, preferring .exe over .cmd' {
        $dir = Join-Path $TestDrive 'mixedcase'
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content -Path (Join-Path $dir 'Foo.exe') -Value 'stub'
        Set-Content -Path (Join-Path $dir 'foo.cmd') -Value 'stub'

        $result = @(Get-PkgSyncSourceExecutables -Path $dir -SourceName 'cargo')

        $result.Count | Should -Be 1
        $result[0].Target | Should -Be (Join-Path $dir 'Foo.exe')
    }
}
