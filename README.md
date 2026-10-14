# SharePoint Online PowerShell Toolkit

A practical toolkit and step-by-step guide for administering **SharePoint Online** with **PowerShell 7**, using current Microsoft modules:

- **PnP.PowerShell** 2.x / 3.x (site-level work)
- **Microsoft.Online.SharePoint.PowerShell** (tenant-level admin)

It covers site inventory, external sharing audits, permissions reports, storage reporting, site lifecycle (provision, review, lock), and a sharing settings baseline. Every script has comment-based help (`Get-Help ./script.ps1 -Full`), reports export to CSV, and every change script supports `-WhatIf` / `-Confirm`. Authentication uses **certificates** (app-only) or **interactive** sign-in via the same `Connect-M365Admin` pattern as [graph-powershell7-admin-toolkit](https://github.com/anthonybuhnerkemper/graph-powershell7-admin-toolkit). No secrets are stored in the repo.

> ⚠️ **Disclaimer:** Test everything in a non-production / developer tenant first. Examples use `contoso.com`, `contoso.sharepoint.com`, and placeholder GUIDs (`00000000-0000-0000-0000-000000000000`). Review each script before running it in your environment.

## Prerequisites

| Requirement | Version / notes |
|---|---|
| PowerShell | 7.4 or later (`pwsh`) |
| PnP.PowerShell | 2.x or 3.x, with your own Entra app registration ([docs/02](docs/02-app-registration-for-pnp.md)) |
| Microsoft.Online.SharePoint.PowerShell | Latest from PSGallery |
| Role | SharePoint Administrator (or site collection admin for site-level reports) |

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
```

## Quick start

```powershell
git clone https://github.com/anthonybuhnerkemper/sharepoint-online-powershell-toolkit.git
cd sharepoint-online-powershell-toolkit

. ./scripts/Connect/Connect-M365Admin.ps1
Connect-M365Admin -Service SharePoint -Interactive -SharePointAdminUrl https://contoso-admin.sharepoint.com

# Reports (CSV files land in ./output)
./scripts/Sites/Get-SPOSiteInventory.ps1
./scripts/Storage/Get-SPOStorageReport.ps1
./scripts/Sharing/Get-SPOExternalSharingAudit.ps1
./scripts/Sharing/Get-SPOTenantSharingSettings.ps1

# Preview a change before applying it
./scripts/Sharing/Set-SPOSharingBaseline.ps1 -WhatIf

. ./scripts/Connect/Disconnect-M365Admin.ps1
Disconnect-M365Admin
```

## Repo map

```text
.github/workflows/pssa.yml  PSScriptAnalyzer CI on push and PR
config/
  sharing-baseline.json     Target tenant sharing settings
  new-sites.sample.csv      Sample input for bulk provisioning
docs/
  01-install-modules-and-connect.md
  02-app-registration-for-pnp.md
  03-site-inventory-and-storage.md
  04-external-sharing-audit-and-baseline.md
  05-permissions-reporting.md
  06-site-lifecycle.md
scripts/
  Connect/      Connect-M365Admin.ps1, Disconnect-M365Admin.ps1
  Sites/        Get-SPOSiteInventory
  Storage/      Get-SPOStorageReport
  Sharing/      Get-SPOExternalSharingAudit, Get-SPOTenantSharingSettings, Set-SPOSharingBaseline
  Permissions/  Get-PnPSitePermissionReport
  Lifecycle/    Get-SPOInactiveSites, Set-SPOSiteLockState, New-PnPSiteFromCsv
```

## Permissions

| Script | Module | Role / permission | Changes? |
|---|---|---|---|
| Get-SPOSiteInventory | SPO | SharePoint Administrator | No |
| Get-SPOStorageReport | SPO | SharePoint Administrator | No |
| Get-SPOExternalSharingAudit | SPO | SharePoint Administrator | No |
| Get-SPOTenantSharingSettings | SPO | SharePoint Administrator | No |
| Set-SPOSharingBaseline | SPO | SharePoint Administrator | Yes (`-WhatIf`) |
| Get-PnPSitePermissionReport | PnP | Site collection admin, or app `Sites.Read.All` | No |
| Get-SPOInactiveSites | SPO | SharePoint Administrator | No |
| Set-SPOSiteLockState | SPO | SharePoint Administrator | Yes (`-WhatIf`) |
| New-PnPSiteFromCsv | PnP | SharePoint Administrator, or app `Sites.FullControl.All` + `Group.ReadWrite.All` | Yes (`-WhatIf`) |

## Related

- [graph-powershell7-admin-toolkit](https://github.com/anthonybuhnerkemper/graph-powershell7-admin-toolkit): Graph, Exchange Online, Purview and Entra ID security reporting
- [onedrive-powershell-toolkit](https://github.com/anthonybuhnerkemper/onedrive-powershell-toolkit): OneDrive inventory, sharing and departed-user access

## License

[MIT](LICENSE) © 2026 Anthony Buhnerkemper
