# 05 - Site permissions reporting

`Get-PnPSitePermissionReport.ps1` answers "who can get into this site?"

```powershell
./scripts/Permissions/Get-PnPSitePermissionReport.ps1 -SiteUrl https://contoso.sharepoint.com/sites/Finance -Interactive
```

It reports three layers:
1. **SharePoint groups** (Owners, Members, Visitors and custom groups) with each member and the group's permission levels.
2. **Direct permissions** granted to users or Entra groups on the site itself.
3. **Lists and libraries with unique permissions** (broken inheritance), with each role assignment.

Tips:
- For group-connected sites, membership of the Microsoft 365 group shows up as a claim (`c:0o.c|federateddirectoryclaimprovider|...`). Expand it with `Get-MgGroupMember` from the Graph SDK.
- `Everyone except external users` entries are a common oversharing finding.
- Item-level unique permissions are not enumerated (slow on large libraries); use the site's "Sharing" report in the admin center for those.
