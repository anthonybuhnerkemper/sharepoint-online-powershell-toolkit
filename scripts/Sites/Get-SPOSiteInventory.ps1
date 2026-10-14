#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Exports an inventory of every SharePoint Online site in the tenant to CSV.
.DESCRIPTION
    Uses Get-SPOSite -Limit All with -Detailed-equivalent properties. Requires Connect-SPOService
    (SharePoint Administrator). OneDrive sites are excluded unless -IncludeOneDrive is set.
    Read-only.
.PARAMETER IncludeOneDrive
    Also include personal (OneDrive) sites.
.PARAMETER Template
    Optional template filter, for example GROUP#0, SITEPAGEPUBLISHING#0, STS#3, TEAMCHANNEL#1.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SPOSiteInventory.ps1
.EXAMPLE
    ./Get-SPOSiteInventory.ps1 -Template GROUP#0
#>
[CmdletBinding()]
param(
    [switch]$IncludeOneDrive,
    [string]$Template,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$getParams = @{ Limit = 'All' }
if ($IncludeOneDrive) { $getParams.IncludePersonalSite = $true }
if ($Template) { $getParams.Template = $Template }
$sites = Get-SPOSite @getParams

$rows = foreach ($s in $sites) {
    [pscustomobject]@{
        Url                     = $s.Url
        Title                   = $s.Title
        Template                = $s.Template
        Owner                   = $s.Owner
        GroupId                 = $s.GroupId
        IsTeamsConnected        = $s.IsTeamsConnected
        IsHubSite               = $s.IsHubSite
        HubSiteId               = $s.HubSiteId
        SensitivityLabel        = $s.SensitivityLabel
        SharingCapability       = $s.SharingCapability
        LockState               = $s.LockState
        StorageUsedMB           = $s.StorageUsageCurrent
        StorageQuotaMB          = $s.StorageQuota
        LastContentModifiedDate = $s.LastContentModifiedDate
    }
}
$file = Join-Path $OutputFolder "SPOSiteInventory-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Sort-Object Url | Export-Csv -Path $file -NoTypeInformation
Write-Information "Sites: $(@($rows).Count) -> $file" -InformationAction Continue
