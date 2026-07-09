Import-Module "$PSScriptRoot\..\src\PkgSync.psm1" -Force

Describe 'Test-PkgSyncLinkIsStale' {
    It 'returns true when the target path does not exist' {
        Test-PkgSyncLinkIsStale -Target 'TestDrive:\nowhere\ghost.exe' | Should -BeTrue
    }

    It 'returns false when the target path exists' {
        $target = Join-Path $TestDrive 'real.exe'
        Set-Content -Path $target -Value 'stub'
        Test-PkgSyncLinkIsStale -Target $target | Should -BeFalse
    }
}

Describe 'Test-PkgSyncConflict' {
    It 'returns false when targets are identical' {
        Test-PkgSyncConflict -ExistingTarget 'C:\a\foo.exe' -CandidateTarget 'C:\a\foo.exe' | Should -BeFalse
    }

    It 'returns false when targets differ only by case' {
        Test-PkgSyncConflict -ExistingTarget 'C:\a\foo.exe' -CandidateTarget 'C:\A\FOO.EXE' | Should -BeFalse
    }

    It 'returns true when targets point to different files' {
        Test-PkgSyncConflict -ExistingTarget 'C:\a\foo.exe' -CandidateTarget 'C:\b\foo.exe' | Should -BeTrue
    }
}
