#Requires -Version 7.4
#Requires -Modules Microsoft.Online.SharePoint.PowerShell
<#
.SYNOPSIS
    Finds sites with no content changes for a number of days (lifecycle review candidates).
.DESCRIPTION
    Requires Connect-SPOService. Uses LastContentModifiedDate. Group-connected sites are flagged
    so their Microsoft 365 group can be reviewed with the group expiration policy instead.
    Read-only; feed the CSV to Set-SPOSiteLockState.ps1 after owner review.
.PARAMETER DaysInactive
    Days without content changes. Default 180.
.PARAMETER OutputFolder
    Folder for CSV output. Defaults to ./output.
.EXAMPLE
    ./Get-SPOInactiveSites.ps1 -DaysInactive 365
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3650)][int]$DaysInactive = 180,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$cutoff = (Get-Date).AddDays(-$DaysInactive)
$rows = Get-SPOSite -Limit All |
    Where-Object { $_.LastContentModifiedDate -lt $cutoff -and $_.Url -notmatch '/(search|portals/hub)$' } |
    ForEach-Object {
        [pscustomobject]@{
            Url               = $_.Url
            Title             = $_.Title
            Template          = $_.Template
            Owner             = $_.Owner
            GroupConnected    = ($_.GroupId -and $_.GroupId -ne [guid]::Empty)
            LockState         = $_.LockState
            StorageUsedMB     = $_.StorageUsageCurrent
            LastContentChange = $_.LastContentModifiedDate
            DaysInactive      = [int]((Get-Date) - $_.LastContentModifiedDate).TotalDays
        }
    } | Sort-Object DaysInactive -Descending

$file = Join-Path $OutputFolder "SPOInactiveSites-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$rows | Export-Csv -Path $file -NoTypeInformation
Write-Information "Inactive sites (>$DaysInactive days): $(@($rows).Count) -> $file" -InformationAction Continue
