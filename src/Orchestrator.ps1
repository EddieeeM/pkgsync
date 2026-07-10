function Test-PkgSyncIsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Invoke-PkgSync {
    param(
        [string]$TargetDirectory = (Join-Path $env:USERPROFILE 'bin')
    )

    $sources = Resolve-PkgSyncSourcePaths

    $sourceExecutables = @()
    foreach ($source in $sources) {
        $sourceExecutables += Get-PkgSyncSourceExecutables -Path $source.Path -SourceName $source.Name
    }

    $existingLinks = Get-PkgSyncExistingLinks -Path $TargetDirectory
    $plan = Get-PkgSyncPlan -SourceExecutables $sourceExecutables -ExistingLinks $existingLinks

    Invoke-PkgSyncPlan -Plan $plan -TargetDirectory $TargetDirectory
    $pathAdded = Set-PkgSyncEnsurePath -Directory $TargetDirectory

    foreach ($conflict in $plan.Conflicts) {
        Write-Warning "Skipped '$($conflict.Name)' from $($conflict.CandidateSource): already linked to $($conflict.ExistingTarget)"
    }

    [pscustomobject]@{
        Added     = $plan.ToCreate.Count
        Conflicts = $plan.Conflicts.Count
        Removed   = $plan.ToRemove.Count
        PathAdded = $pathAdded
    }
}
