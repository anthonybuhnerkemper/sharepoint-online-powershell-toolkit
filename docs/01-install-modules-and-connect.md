# 01 - Install the modules and connect

This toolkit uses two modules:

| Module | Used for |
|---|---|
| `Microsoft.Online.SharePoint.PowerShell` | Tenant-wide admin: site inventory, storage, sharing settings, lock state |
| `PnP.PowerShell` (2.x / 3.x) | Site-level work: permissions, lists, provisioning |

## 1. Install
```powershell
# PowerShell 7.4+
Install-Module PnP.PowerShell -Scope CurrentUser
Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
```
On PowerShell 7 the SPO module is loaded with Windows PowerShell compatibility on some builds. If `Connect-SPOService` fails with an assembly error, run:
```powershell
Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell
```

## 2. Connect interactively
```powershell
. ./scripts/Connect/Connect-M365Admin.ps1
Connect-M365Admin -Service SharePoint -Interactive -SharePointAdminUrl https://contoso-admin.sharepoint.com
Connect-M365Admin -Service PnP -Interactive -SharePointAdminUrl https://contoso-admin.sharepoint.com `
    -ClientId 00000000-0000-0000-0000-000000000000
```

## 3. Connect with a certificate (app-only)
```powershell
$env:M365_TENANT_ID       = '00000000-0000-0000-0000-000000000000'
$env:M365_CLIENT_ID       = '00000000-0000-0000-0000-000000000000'
$env:M365_CERT_THUMBPRINT = '<thumbprint>'
$env:M365_ORGANIZATION    = 'contoso.onmicrosoft.com'
$env:M365_SPO_ADMIN_URL   = 'https://contoso-admin.sharepoint.com'
Connect-M365Admin -Service SharePoint, PnP
```

## 4. Verify
```powershell
Get-SPOTenant | Select-Object SharingCapability, StorageQuota
Get-PnPTenantSite | Select-Object -First 5 Url, Title
```
