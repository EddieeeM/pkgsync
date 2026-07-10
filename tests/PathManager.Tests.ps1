# tests/PathManager.Tests.ps1
Import-Module "$PSScriptRoot\..\src\PkgSync.psm1" -Force

Describe 'Test-PkgSyncPathContainsDirectory' {
    It 'finds an exact match among semicolon-separated entries' {
        Test-PkgSyncPathContainsDirectory -PathValue 'C:\a;C:\b;C:\c' -Directory 'C:\b' | Should -BeTrue
    }

    It 'is case-insensitive and ignores a trailing backslash' {
        Test-PkgSyncPathContainsDirectory -PathValue 'C:\Users\eamon\BIN\' -Directory 'C:\Users\eamon\bin' | Should -BeTrue
    }

    It 'returns false when the directory is not present' {
        Test-PkgSyncPathContainsDirectory -PathValue 'C:\a;C:\b' -Directory 'C:\z' | Should -BeFalse
    }

    It 'returns false for an empty PATH value' {
        Test-PkgSyncPathContainsDirectory -PathValue '' -Directory 'C:\z' | Should -BeFalse
    }
}
