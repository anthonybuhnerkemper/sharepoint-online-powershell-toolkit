#Requires -Version 7.4
#Requires -Modules PnP.PowerShell
<#
.SYNOPSIS
    Provisions communication or team sites in bulk from a CSV file.
.DESCRIPTION
    Requires an existing Connect-PnPOnline session to the admin site (see Connect-M365Admin -Service PnP).
    CSV columns: Type (CommunicationSite|TeamSite), Title, Alias (team sites) or Url (communication
    sites), Owner, Description. Existing URLs are skipped. Supports -WhatIf and -Confirm.
.PARAMETER CsvPath
    Path to the input CSV. See config/new-sites.sample.csv.
.PARAMETER OutputFolder
    Folder for the result CSV. Defaults to ./output.
.EXAMPLE
    ./New-PnPSiteFromCsv.ps1 -CsvPath ./config/new-sites.sample.csv -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [string]$OutputFolder = (Join-Path (Get-Location) 'output')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

$log = foreach ($row in Import-Csv $CsvPath) {
    $target = if ($row.Type -eq 'TeamSite') { "team site alias $($row.Alias)" } else { $row.Url }
    $result = 'Skipped'
    $siteUrl = $null
    if ($row.Type -eq 'CommunicationSite' -and (Get-PnPTenantSite -Identity $row.Url -ErrorAction SilentlyContinue)) {
        $result = 'AlreadyExists'
    }
    elseif ($PSCmdlet.ShouldProcess($target, "Create $($row.Type) '$($row.Title)'")) {
        try {
            if ($row.Type -eq 'TeamSite') {
                $siteUrl = New-PnPSite -Type TeamSite -Title $row.Title -Alias $row.Alias -Owners $row.Owner -Description $row.Description -Wait
            }
            else {
                $siteUrl = New-PnPSite -Type CommunicationSite -Title $row.Title -Url $row.Url -Owner $row.Owner -Description $row.Description -Wait
            }
            $result = 'Created'
        }
        catch { $result = "Failed: $($_.Exception.Message)" }
    }
    [pscustomobject]@{ Type = $row.Type; Title = $row.Title; Target = $target; SiteUrl = $siteUrl; Result = $result }
}
$file = Join-Path $OutputFolder "NewSites-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
$log | Export-Csv -Path $file -NoTypeInformation
Write-Information "Rows processed: $(@($log).Count) -> $file" -InformationAction Continue
