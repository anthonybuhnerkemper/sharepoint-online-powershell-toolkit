# 04 - External sharing audit and sharing baseline

## 1. Audit sites and guests
```powershell
./scripts/Sharing/Get-SPOExternalSharingAudit.ps1
```
Output:
- `SPOSharingSummary-*.csv` with each site's `SharingCapability` and guest count.
- `SPOSiteGuests-*.csv` with each guest on each site.

Sharing levels from most to least permissive: `ExternalUserAndGuestSharing` (Anyone links), `ExternalUserSharingOnly` (new and existing guests), `ExistingExternalUserSharingOnly`, `Disabled`. A site can never be more permissive than the tenant.

## 2. Compare the tenant with the baseline
Edit `config/sharing-baseline.json` to match your policy, then:
```powershell
./scripts/Sharing/Get-SPOTenantSharingSettings.ps1
```

## 3. Apply the baseline (preview first)
```powershell
./scripts/Sharing/Set-SPOSharingBaseline.ps1 -WhatIf
./scripts/Sharing/Set-SPOSharingBaseline.ps1 -Confirm
```
Each differing setting is changed with its own `Set-SPOTenant` call so you can approve them one at a time. A change log CSV is written.
