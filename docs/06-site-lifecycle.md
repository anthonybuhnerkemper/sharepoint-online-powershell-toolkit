# 06 - Site lifecycle: provision, review, archive

## 1. Provision from CSV
```powershell
./scripts/Lifecycle/New-PnPSiteFromCsv.ps1 -CsvPath ./config/new-sites.sample.csv -WhatIf
./scripts/Lifecycle/New-PnPSiteFromCsv.ps1 -CsvPath ./config/new-sites.sample.csv
```

## 2. Find inactive sites
```powershell
./scripts/Lifecycle/Get-SPOInactiveSites.ps1 -DaysInactive 365
```
Send the list to the owners. For group-connected sites, prefer the Microsoft 365 group expiration policy.

## 3. Archive by locking
```powershell
./scripts/Lifecycle/Set-SPOSiteLockState.ps1 -CsvPath ./output/SPOInactiveSites-<stamp>.csv -LockState ReadOnly -WhatIf
./scripts/Lifecycle/Set-SPOSiteLockState.ps1 -CsvPath ./output/SPOInactiveSites-<stamp>.csv -LockState ReadOnly
```
`ReadOnly` keeps content visible; `NoAccess` blocks it (users are redirected to the tenant's `NoAccessRedirectUrl` if set). `Unlock` reverses either.

## 4. Delete (manual, deliberate)
Deletion is intentionally not scripted here. After the retention period, use `Remove-SPOSite` and remember deleted sites stay in the recycle bin for 93 days (`Get-SPODeletedSite`).
