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

Describe 'Get-PkgSyncPlan' {
    It 'creates a link for a brand-new executable' {
        $plan = Get-PkgSyncPlan -SourceExecutables @(
            @{ Name = 'foo'; Target = 'C:\src\foo.exe'; Source = 'cargo' }
        ) -ExistingLinks @()

        $plan.ToCreate.Count | Should -Be 1
        $plan.ToCreate[0].Name | Should -Be 'foo'
        $plan.Conflicts.Count | Should -Be 0
    }

    It 'leaves an existing link unchanged when the target matches' {
        $target = Join-Path $TestDrive 'foo.exe'
        Set-Content -Path $target -Value 'stub'

        $plan = Get-PkgSyncPlan -SourceExecutables @(
            @{ Name = 'foo'; Target = $target; Source = 'cargo' }
        ) -ExistingLinks @(
            @{ Name = 'foo'; Target = $target; LinkPath = 'C:\bin\foo.exe' }
        )

        $plan.Unchanged.Count | Should -Be 1
        $plan.ToCreate.Count | Should -Be 0
    }

    It 'flags a conflict when a live existing link points elsewhere' {
        $existingTarget = Join-Path $TestDrive 'foo.exe'
        Set-Content -Path $existingTarget -Value 'stub'

        $plan = Get-PkgSyncPlan -SourceExecutables @(
            @{ Name = 'foo'; Target = 'C:\src\new-foo.exe'; Source = 'npm' }
        ) -ExistingLinks @(
            @{ Name = 'foo'; Target = $existingTarget; LinkPath = 'C:\bin\foo.exe' }
        )

        $plan.Conflicts.Count | Should -Be 1
        $plan.Conflicts[0].CandidateSource | Should -Be 'npm'
        $plan.ToCreate.Count | Should -Be 0
    }

    It 'flags a conflict between two new candidates claiming the same name' {
        $plan = Get-PkgSyncPlan -SourceExecutables @(
            @{ Name = 'foo'; Target = 'C:\src\cargo-foo.exe'; Source = 'cargo' }
            @{ Name = 'foo'; Target = 'C:\src\npm-foo.exe'; Source = 'npm' }
        ) -ExistingLinks @()

        $plan.ToCreate.Count | Should -Be 1
        $plan.ToCreate[0].Source | Should -Be 'cargo'
        $plan.Conflicts.Count | Should -Be 1
        $plan.Conflicts[0].CandidateSource | Should -Be 'npm'
    }

    It 'marks a dead existing link as stale and frees its name for a new candidate' {
        $liveTarget = Join-Path $TestDrive 'foo.exe'
        Set-Content -Path $liveTarget -Value 'stub'

        $plan = Get-PkgSyncPlan -SourceExecutables @(
            @{ Name = 'foo'; Target = $liveTarget; Source = 'cargo' }
        ) -ExistingLinks @(
            @{ Name = 'foo'; Target = 'TestDrive:\gone\foo.exe'; LinkPath = 'C:\bin\foo.exe' }
        )

        $plan.ToRemove.Count | Should -Be 1
        $plan.ToRemove[0].LinkPath | Should -Be 'C:\bin\foo.exe'
        $plan.ToCreate.Count | Should -Be 1
        $plan.ToCreate[0].Target | Should -Be $liveTarget
    }
}
