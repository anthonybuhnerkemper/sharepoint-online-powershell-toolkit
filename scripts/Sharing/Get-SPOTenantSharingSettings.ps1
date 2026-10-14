#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Compares the tenant's SharePoint/OneDrive sharing settings with a baseline JSON file.
.DESCRIPTION
    Requires Connect-SPOService. Reads config/sharing-baseline.json (or -BaselinePath), reads the
    same properties from Get-SPOTenant and exports Setting, Current, Baseline, Compliant to CSV.
    Read-only; use Set-SPOSharingBaseline.ps1 -WhatIf to preview remediation.
.PARAMETER BaselinePath
    Path to the baseline JSON. Defaults to ../../config/sharing-baseline.json.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SPOTenantSharingSettings.ps1
#>
[CmdletBinding()]
param(
    [string]$BaselinePath = (Join-Path $PSScriptRoot '../../config/sharing-baseline.json'),
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$baseline = Get-Content -Raw -Path $BaselinePath | ConvertFrom-Json -AsHashtable
$tenant = Get-SPOTenant
$rows = foreach ($key in $baseline.Keys | Sort-Object) {
    $current = $tenant.$key
    [pscustomobject]@{
        Setting   = $key
        Current   = "$current"
        Baseline  = "$($baseline[$key])"
        Compliant = ("$current" -eq "$($baseline[$key])")
    }
}
$file = Join-Path $OutputFolder "SPOSharingBaseline-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
$rows | Format-Table -AutoSize | Out-String | Write-Information -InformationAction Continue
Write-Information "Non-compliant settings: $(@($rows | Where-Object { -not $_.Compliant }).Count) -> $file" -InformationAction Continue
