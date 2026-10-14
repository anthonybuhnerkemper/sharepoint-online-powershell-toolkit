# 02 - App registration for PnP.PowerShell and app-only SPO

Since September 2024 the shared "PnP Management Shell" app is gone, so PnP.PowerShell needs **your own** Entra ID app registration.

## 1. Interactive (delegated) app
```powershell
Register-PnPEntraIDAppForInteractiveLogin -ApplicationName 'Contoso PnP Interactive' `
    -Tenant contoso.onmicrosoft.com -SharePointDelegatePermissions AllSites.FullControl
```
Note the Client ID it prints and use it as `-ClientId`.

## 2. App-only (certificate) app
```powershell
Register-PnPEntraIDApp -ApplicationName 'Contoso PnP Automation' -Tenant contoso.onmicrosoft.com `
    -Store CurrentUser -SharePointApplicationPermissions Sites.FullControl.All `
    -GraphApplicationPermissions Group.Read.All
```
This creates a self-signed certificate, uploads the public key, and opens the consent page.

## 3. Least-privilege alternatives
- Reporting only: `Sites.Read.All` (SharePoint) instead of `Sites.FullControl.All`.
- Single-site automation: `Sites.Selected`, then grant the app access to specific sites:
```powershell
Grant-PnPAzureADAppSitePermission -AppId 00000000-0000-0000-0000-000000000000 `
    -DisplayName 'Contoso PnP Automation' -Site https://contoso.sharepoint.com/sites/Finance -Permissions Read
```

## 4. Keep the certificate safe
- Store the PFX outside the repo (`certs/` and `*.pfx` are in `.gitignore`).
- Prefer the Windows certificate store or Azure Key Vault over files.
- Set an expiry reminder; the Entra app shows the certificate end date.
