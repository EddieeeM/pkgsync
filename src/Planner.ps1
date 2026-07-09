function Test-PkgSyncLinkIsStale {
    param(
        [Parameter(Mandatory)][string]$Target
    )
    return -not (Test-Path -LiteralPath $Target)
}

function Test-PkgSyncConflict {
    param(
        [Parameter(Mandatory)][string]$ExistingTarget,
        [Parameter(Mandatory)][string]$CandidateTarget
    )
    return $ExistingTarget.TrimEnd('\') -ine $CandidateTarget.TrimEnd('\')
}
