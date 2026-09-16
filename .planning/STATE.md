# OursReader — GSD State

Last updated: 2026-09-16
Branch: `development`

## Current position

- Current phase: **Phase 0 — Bootstrap and Baseline**
- Current sub-phase: **0.1 GSD bootstrap + current-state inventory**
- Status: **COMPLETE**
- Next sub-phase: **0.2 Reproducible build baseline**

## Baseline snapshot

The repository already contains substantial implementation across reading, communication, Watch, widget, and release-support areas, but much of it has not been revalidated recently as one coherent product baseline.

### Verified from repository scan

| Area | Evidence seen | State |
| --- | --- | --- |
| Main SwiftUI app | Login, signup, main view, home, dashboard, friends, settings, book views | Implemented / needs verification |
| Dashboard | Push / Widget / Ebook paged surfaces | Implemented |
| Ebook UI | Add, import, detail, reader views | Implemented / needs verification |
| Ebook state | Progress, bookmarks, font settings | Implemented / needs verification |
| Storage | Book cache + CloudKit manager | Implemented / needs verification |
| Friend flow | Add friend, list, Multipeer discovery view model | Implemented / needs verification |
| Push flow | Notification manager + push setting UI + Firebase Functions dependency | Implemented / needs verification |
| Firebase App Check | App Attest / DeviceCheck provider logic | Implemented / needs verification |
| Apple Watch | Separate app with Connectivity, Firebase, services, models, views | Implemented / needs verification |
| Widget | `SendMiss` widget + App Intent + Live Activity files | Experimental |
| Secondary widget | `SImplySendMiss` target | Experimental |
| Tests | XCTest target mostly default starter template | Missing meaningful coverage |
| Release support | Fastlane + Xcode Cloud scripts | Needs verification |
| Book conversion | PDF converter + web scraper | Supporting tooling |

## Important observations

1. **Code maturity is uneven.** Some individual files are substantial, especially the ebook import / reader / CloudKit paths, but file size is not completion evidence.
2. **Testing is the clearest baseline gap.** The unit-test target currently contains starter/template tests rather than meaningful assertions.
3. **Hardware-dependent flows are unproven in this baseline.** APNs, App Attest, Multipeer, iCloud, and Apple Watch require device validation.
4. **Backend completeness is uncertain from this repo alone.** The client references Firebase services / Functions, but backend resources and security configuration are not fully represented here.
5. **Companion scope is unresolved.** Watch, Widget, Live Activity, and the second widget target exist, but v1 ownership must be decided deliberately.
6. **Release automation exists but must be treated as unverified** until signing/account assumptions are audited.

## Phase history

### 2026-09-16 — Phase 0.1 COMPLETE

Completed:

- Scanned repository root and major application modules.
- Confirmed real implementation exists for reading, friend, push, Watch, widget, and release-support areas.
- Confirmed automated tests currently provide essentially no meaningful functional coverage.
- Created the GSD planning workspace:
  - `.planning/PROJECT.md`
  - `.planning/ROADMAP.md`
  - `.planning/STATE.md`
- Classified major areas as implemented, needs verification, experimental, or missing.

Decisions intentionally deferred:

- Final v1 product promise.
- Whether Watch / Widget / Live Activity are required for v1.
- Whether `SImplySendMiss` should be merged, retained, or removed.
- Exact minimum ebook import surface.

## Next action — Phase 0.2

Create a **reproducible build baseline**.

The next pass should audit:

- Xcode targets and schemes
- deployment targets
- Swift Package dependencies
- bundle identifiers
- signing / team assumptions
- entitlements and capabilities
- Firebase plist / environment assumptions
- CloudKit containers
- App Groups
- Push Notifications
- Sign in with Apple
- App Check
- Watch pairing requirements
- tracked user-specific Xcode data
- Fastlane / Xcode Cloud assumptions

### Phase 0.2 output

Produce a setup / verification checklist where every item is one of:

- PASS
- FAIL
- BLOCKED — requires device / account / backend
- NOT REQUIRED for current v1 scope

Do not start feature implementation until this baseline has been recorded.

## `/gsd-next`

Return:

> **Phase 0.2 — Reproducible build baseline**
>
> Audit the Xcode/Firebase/Apple configuration and create a clone-to-build checklist before changing product behavior.
