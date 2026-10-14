#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Applies the sharing baseline from config/sharing-baseline.json to the tenant.
.DESCRIPTION
    Requires Connect-SPOService (SharePoint Administrator). Only settings that differ from the
    baseline are changed, one Set-SPOTenant call per setting so each can be confirmed or skipped.
    Supports -WhatIf and -Confirm. A CSV change log is written.
.PARAMETER BaselinePath
    Path to the baseline JSON. Defaults to ../../config/sharing-baseline.json.
.PARAMETER OutputFolder
    Folder for the change log CSV. Defaults to ./output.
.EXAMPLE
    ./Set-SPOSharingBaseline.ps1 -WhatIf
.EXAMPLE
    ./Set-SPOSharingBaseline.ps1 -Confirm
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$BaselinePath = (Join-Path $PSScriptRoot '../../config/sharing-baseline.json'),
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$baseline = Get-Content -Raw -Path $BaselinePath | ConvertFrom-Json -AsHashtable
$tenant = Get-SPOTenant
$log = foreach ($key in $baseline.Keys | Sort-Object) {
    $current = "$($tenant.$key)"
    $target = $baseline[$key]
    if ($current -eq "$target") { continue }
    $result = 'Skipped'
    if ($PSCmdlet.ShouldProcess("SharePoint tenant setting $key", "Change '$current' -> '$target'")) {
        $splat = @{ $key = $target }
        Set-SPOTenant @splat
        $result = 'Changed'
    }
    [pscustomobject]@{ Setting = $key; Previous = $current; Target = "$target"; Result = $result; Time = Get-Date }
}
$file = Join-Path $OutputFolder "SPOSharingBaselineChanges-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$log | Export-Csv -Path $file -NoTypeInformation
Write-Information "Settings differing from baseline: $(@($log).Count) -> $file" -InformationAction Continue
