#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Audits external sharing: each site's sharing level and the guest accounts present on it.
.DESCRIPTION
    Requires Connect-SPOService (SharePoint Administrator). For every site whose
    SharingCapability is not Disabled, lists users whose login contains #ext# or who are
    flagged as guests. Produces two CSVs: a site summary and a guest detail file. Read-only.
    Large tenants: use -SiteUrl to scope the guest scan.
.PARAMETER SiteUrl
    Optional list of site URLs to audit. Defaults to all non-OneDrive sites.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SPOExternalSharingAudit.ps1
.EXAMPLE
    ./Get-SPOExternalSharingAudit.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Projects
#>
[CmdletBinding()]
param(
    [string[]]$SiteUrl,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$tenant = Get-SPOTenant
$sites = if ($SiteUrl) { $SiteUrl | ForEach-Object { Get-SPOSite -Identity $_ } } else { Get-SPOSite -Limit All }

$summary = [System.Collections.Generic.List[object]]::new()
$guests = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($s in $sites) {
    $i++
    Write-Progress -Activity 'External sharing audit' -Status $s.Url -PercentComplete (100 * $i / @($sites).Count)
    $siteGuests = @()
    if ($s.SharingCapability -ne 'Disabled') {
        try {
            $siteGuests = @(Get-SPOUser -Site $s.Url -Limit All | Where-Object { $_.LoginName -like '*#ext#*' -or $_.UserType -eq 'Guest' })
        }
        catch { Write-Warning "Could not read users for $($s.Url): $($_.Exception.Message)" }
    }
    foreach ($g in $siteGuests) {
        $guests.Add([pscustomobject]@{ SiteUrl = $s.Url; DisplayName = $g.DisplayName; LoginName = $g.LoginName })
    }
    $summary.Add([pscustomobject]@{
        Url                       = $s.Url
        Title                     = $s.Title
        SharingCapability         = $s.SharingCapability
        MoreRestrictiveThanTenant = ($s.SharingCapability -ne $tenant.SharingCapability)
        SharingDomainRestriction  = $s.SharingDomainRestrictionMode
        DefaultSharingLinkType    = $s.DefaultSharingLinkType
        GuestCount                = $siteGuests.Count
    })
}
Write-Progress -Activity 'External sharing audit' -Completed

$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$summary | Export-Csv (Join-Path $OutputFolder "SPOSharingSummary-$stamp.csv") -NoTypeInformation
$guests | Export-Csv (Join-Path $OutputFolder "SPOSiteGuests-$stamp.csv") -NoTypeInformation
Write-Information "Tenant sharing: $($tenant.SharingCapability). Sites: $($summary.Count), guest entries: $($guests.Count). CSVs in $OutputFolder" -InformationAction Continue
