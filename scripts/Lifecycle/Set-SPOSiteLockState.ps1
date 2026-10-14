#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Sets the lock state (Unlock, ReadOnly, NoAccess) on one or more sites, for example to archive
    inactive sites after owner review.
.DESCRIPTION
    Requires Connect-SPOService (SharePoint Administrator). Accepts URLs directly or a CSV with a
    Url column (such as the output of Get-SPOInactiveSites.ps1). Supports -WhatIf and -Confirm and
    writes a change log CSV.
.PARAMETER Url
    One or more site URLs.
.PARAMETER CsvPath
    CSV file with a Url column.
.PARAMETER LockState
    Unlock, ReadOnly or NoAccess. Default ReadOnly.
.PARAMETER OutputFolder
    Folder for the change log. Defaults to ./output.
.EXAMPLE
    ./Set-SPOSiteLockState.ps1 -CsvPath ./output/SPOInactiveSites-20260101-0900.csv -LockState ReadOnly -WhatIf
.EXAMPLE
    ./Set-SPOSiteLockState.ps1 -Url https://contoso.sharepoint.com/sites/OldProject -LockState Unlock
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Url')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Url')][string[]]$Url,
    [Parameter(Mandatory, ParameterSetName = 'Csv')][string]$CsvPath,
    [ValidateSet('Unlock', 'ReadOnly', 'NoAccess')][string]$LockState = 'ReadOnly',
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$targets = if ($PSCmdlet.ParameterSetName -eq 'Csv') { (Import-Csv $CsvPath).Url } else { $Url }

$log = foreach ($u in $targets) {
    $site = Get-SPOSite -Identity $u
    $result = 'Skipped'
    if ($site.LockState -eq $LockState) { $result = 'AlreadySet' }
    elseif ($PSCmdlet.ShouldProcess($u, "Set LockState $($site.LockState) -> $LockState")) {
        try { Set-SPOSite -Identity $u -LockState $LockState; $result = 'Changed' }
        catch { $result = "Failed: $($_.Exception.Message)" }
    }
    [pscustomobject]@{ Url = $u; Previous = $site.LockState; Target = $LockState; Result = $result; Time = Get-Date }
}
$file = Join-Path $OutputFolder "SPOLockStateChanges-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$log | Export-Csv -Path $file -NoTypeInformation
Write-Information "Processed $(@($log).Count) site(s) -> $file" -InformationAction Continue
