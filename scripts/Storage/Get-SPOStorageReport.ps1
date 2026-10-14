#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Reports storage used per site, percent of quota, and the tenant storage total.
.DESCRIPTION
    Requires Connect-SPOService. Sites at or above -WarningPercent of their quota are flagged.
    Tenant-level totals come from Get-SPOTenant (StorageQuota / StorageQuotaAllocated). Read-only.
.PARAMETER WarningPercent
    Flag sites using at least this percentage of their quota. Default 80.
.PARAMETER Top
    Only keep the largest N sites (0 = all). Default 0.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SPOStorageReport.ps1 -WarningPercent 90 -Top 50
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 100)][int]$WarningPercent = 80,
    [ValidateRange(0, 100000)][int]$Top = 0,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$tenant = Get-SPOTenant
$sites = Get-SPOSite -Limit All
$rows = foreach ($s in $sites) {
    $pct = if ($s.StorageQuota -gt 0) { [math]::Round(100 * $s.StorageUsageCurrent / $s.StorageQuota, 1) } else { $null }
    [pscustomobject]@{
        Url            = $s.Url
        Title          = $s.Title
        Template       = $s.Template
        StorageUsedGB  = [math]::Round($s.StorageUsageCurrent / 1024, 2)
        StorageQuotaGB = [math]::Round($s.StorageQuota / 1024, 2)
        PercentUsed    = $pct
        OverWarning    = ($null -ne $pct -and $pct -ge $WarningPercent)
        LastModified   = $s.LastContentModifiedDate
    }
}
$rows = $rows | Sort-Object StorageUsedGB -Descending
if ($Top -gt 0) { $rows = $rows | Select-Object -First $Top }

$file = Join-Path $OutputFolder "SPOStorage-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
$usedGB = [math]::Round(($sites | Measure-Object StorageUsageCurrent -Sum).Sum / 1024, 1)
Write-Information ("Tenant quota: {0:N0} GB  Used by sites: {1:N1} GB  Sites over {2}%: {3} -> {4}" -f `
    ($tenant.StorageQuota / 1024), $usedGB, $WarningPercent, @($rows | Where-Object OverWarning).Count, $file) -InformationAction Continue
