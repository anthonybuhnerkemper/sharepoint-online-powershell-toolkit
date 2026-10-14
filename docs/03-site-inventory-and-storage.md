# 03 - Site inventory and storage reporting

## 1. Full inventory
```powershell
./scripts/Sites/Get-SPOSiteInventory.ps1
./scripts/Sites/Get-SPOSiteInventory.ps1 -Template GROUP#0      # Microsoft 365 group sites only
./scripts/Sites/Get-SPOSiteInventory.ps1 -IncludeOneDrive        # include personal sites
```
Common templates: `GROUP#0` (group-connected team site), `STS#3` (team site without a group), `SITEPAGEPUBLISHING#0` (communication site), `TEAMCHANNEL#1` (private/shared channel site).

## 2. Storage
```powershell
./scripts/Storage/Get-SPOStorageReport.ps1 -WarningPercent 85 -Top 50
```
- `StorageUsedGB` / `StorageQuotaGB` per site and `OverWarning` when the threshold is reached.
- The summary line shows the tenant pool (`Get-SPOTenant`.StorageQuota) against storage used by sites.

## 3. Read the results
1. Open the CSV in Excel and filter `OverWarning = TRUE`.
2. Contact the site owner (the `Owner` column in the inventory) before raising a quota.
3. Large version histories are a common cause; review version limits per library.
