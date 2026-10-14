#Requires -Version 7.4
#Requires -Modules PnP.PowerShell
<#
.SYNOPSIS
    Reports who has access to a site: site groups and members, direct site permissions,
    and lists or libraries with unique (broken) permissions.
.DESCRIPTION
    Connects to the given site with Connect-PnPOnline using the same ClientId/certificate values
    as Connect-M365Admin (environment variables M365_CLIENT_ID, M365_ORGANIZATION,
    M365_CERT_THUMBPRINT) or -Interactive. Read-only.
.PARAMETER SiteUrl
    The site to report on, for example https://contoso.sharepoint.com/sites/Finance.
.PARAMETER Interactive
    Use interactive sign-in instead of certificate auth.
.PARAMETER ClientId
    Entra app registration used by PnP. Defaults to $env:M365_CLIENT_ID.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-PnPSitePermissionReport.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Finance -Interactive
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SiteUrl,
    [switch]$Interactive,
    [string]$ClientId = $env:M365_CLIENT_ID,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
if (-not $ClientId) { throw 'PnP.PowerShell needs -ClientId or M365_CLIENT_ID (your own app registration).' }

if ($Interactive) { Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId }
else { Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Tenant $env:M365_ORGANIZATION -Thumbprint $env:M365_CERT_THUMBPRINT }

$rows = [System.Collections.Generic.List[object]]::new()

# 1. SharePoint groups and their members
foreach ($group in Get-PnPGroup) {
    $roles = (Get-PnPGroupPermissions -Identity $group.Title -ErrorAction SilentlyContinue | Where-Object { -not $_.Hidden }).Name -join '; '
    foreach ($m in Get-PnPGroupMember -Group $group.Title) {
        $rows.Add([pscustomobject]@{
            Scope = 'Site'; Object = $SiteUrl; Principal = $m.Title; LoginName = $m.LoginName
            PrincipalType = $m.PrincipalType; ViaGroup = $group.Title; Permissions = $roles
        })
    }
}

# 2. Direct role assignments on the web
$web = Get-PnPWeb -Includes RoleAssignments
foreach ($ra in $web.RoleAssignments) {
    Get-PnPProperty -ClientObject $ra -Property Member, RoleDefinitionBindings | Out-Null
    if ($ra.Member.PrincipalType -eq 'SharePointGroup') { continue }
    $rows.Add([pscustomobject]@{
        Scope = 'Site'; Object = $SiteUrl; Principal = $ra.Member.Title; LoginName = $ra.Member.LoginName
        PrincipalType = $ra.Member.PrincipalType; ViaGroup = ''; Permissions = ($ra.RoleDefinitionBindings.Name -join '; ')
    })
}

# 3. Lists and libraries with unique permissions
foreach ($list in Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments | Where-Object { -not $_.Hidden -and $_.HasUniqueRoleAssignments }) {
    foreach ($ra in $list.RoleAssignments) {
        Get-PnPProperty -ClientObject $ra -Property Member, RoleDefinitionBindings | Out-Null
        $rows.Add([pscustomobject]@{
            Scope = 'List'; Object = $list.Title; Principal = $ra.Member.Title; LoginName = $ra.Member.LoginName
            PrincipalType = $ra.Member.PrincipalType; ViaGroup = ''; Permissions = ($ra.RoleDefinitionBindings.Name -join '; ')
        })
    }
}

$safeName = ($SiteUrl -replace '^https?://', '' -replace '[^\w\-]', '_')
$file = Join-Path $OutputFolder "SitePermissions-$safeName-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Permission entries: $($rows.Count) -> $file" -InformationAction Continue
