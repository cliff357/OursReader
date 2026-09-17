# OursReader — GSD State

Last updated: 2026-09-17
Branch: `development`

## Current position

- Current phase: **Phase 0 — Bootstrap and Baseline**
- Current sub-phase: **0.2 Reproducible build baseline**
- Status: **IN PROGRESS — 0.2a repository fixes complete**
- Next sub-phase: **0.2b Clean build verification**

## Baseline snapshot

The repository-controlled build/release blockers found during the Phase 0.2 audit have now been corrected or deliberately documented as accepted project constraints. The remaining evidence needed to close Phase 0.2 requires a clean Mac/Xcode build plus account/hardware checks.

### Current build-baseline summary

| Area | State |
| --- | --- |
| Shared main scheme | PASS |
| Unit/UI test targets wired into scheme | PASS |
| Pinned Swift Package dependencies | PASS |
| Main iOS target = iOS 17 | PASS |
| Watch target = watchOS 10.6 | PASS |
| Main/Watch bundle IDs match Firebase configs | PASS |
| Main capabilities declared | PASS |
| Debug/Release entitlement separation | PASS |
| Release APNs entitlement | PASS — production |
| App Check Debug/simulator code path | PASS — debug provider configured |
| Main ArchiveAction configuration | PASS — Release |
| Fastlane production configuration | PASS — Release, no personal Apple ID hard-code |
| Xcode Cloud repository preflight | PASS |
| Tracked Xcode user data | PASS — removed/ignored |
| Apple team/signing assumption | PASS — documented project-team requirement |
| Firebase environment strategy | PASS — documented single-project model |
| CloudKit/App Group/Sign in with Apple provisioning | BLOCKED — account/device verification |
| APNs/FCM delivery | BLOCKED — Firebase/APNs/device verification |
| App Check debug-token acceptance | BLOCKED — Firebase Console registration + runtime verification |
| Multipeer | BLOCKED — two-device verification |
| Watch end-to-end | BLOCKED — paired hardware verification |
| Clean Xcode build | BLOCKED — requires Mac/Xcode execution |

## Phase 0.2a fixes completed

1. Changed the main scheme ArchiveAction from Debug to Release.
2. Changed Fastlane `prod` from Debug to Release.
3. Removed hard-coded personal TestFlight username from Fastlane.
4. Split Debug/Release entitlement intent:
   - Debug: development APNs / development App Attest environment.
   - Release: production APNs / production App Attest environment.
5. Debug iOS and Watch builds now use `AppCheckDebugProviderFactory`.
6. App Check provider configuration now happens before Firebase initialization.
7. Removed tracked Xcode project/workspace `xcuserdata` files.
8. Expanded `.gitignore` for `xcuserdata`, Xcode user state, DerivedData/build output, and macOS metadata.
9. Expanded Xcode Cloud post-clone preflight to validate required repository-controlled configuration files.
10. Added `.planning/ENVIRONMENT_SETUP.md` documenting Apple signing, Firebase project strategy, App Check debug-token handling, and fresh-clone requirements.

### Deliberate decisions

- The committed Apple Development Team ID is retained. For a production app with fixed bundle IDs/capabilities, the Team ID is treated as project ownership metadata rather than a secret. Signed/device builds require membership in that team.
- The old project-level iOS 16.4 setting is not currently a build blocker because all supported product targets explicitly override it with iOS 17. It can be normalized later during project-file cleanup without blocking 0.2b.
- OursReader currently has one explicit Firebase project (`our-reader`). A future dev/staging/prod split is a separate architecture decision rather than a prerequisite for this baseline.

## Phase history

### 2026-09-16 — Phase 0.1 COMPLETE

Completed:

- Scanned repository root and major application modules.
- Confirmed real implementation exists for reading, friend, push, Watch, widget, and release-support areas.
- Confirmed automated tests currently provide essentially no meaningful functional coverage.
- Created the GSD planning workspace.

### 2026-09-16 — Phase 0.2 AUDIT COMPLETE

Completed:

- Audited schemes, targets, deployment targets, SPM, signing, entitlements, Firebase, CloudKit, App Groups, Push, Sign in with Apple, App Check, Watch, Fastlane, Xcode Cloud, and tracked Xcode metadata.
- Created `.planning/BUILD_BASELINE.md` with PASS / FAIL / BLOCKED classification.

### 2026-09-17 — Phase 0.2a COMPLETE

Completed all repository-controlled fixes described above.

Not completed yet:

- Clean Xcode build from a fresh checkout.
- Simulator Firebase verification with a registered App Check debug token.
- Hardware/account dependent flows.

## Next action — Phase 0.2b

Run clean build verification on a Mac/Xcode environment:

1. Fresh checkout `development`.
2. Resolve committed Swift Package pins.
3. Build the shared `OursReader` scheme.
4. Run unit/UI test targets once.
5. Launch a supported simulator.
6. Register the generated App Check debug token in Firebase Console.
7. Verify at least one Firebase-backed app path.
8. Record any remaining compile/runtime blockers.

After 0.2b, proceed to **0.2c Hardware/account verification** or close Phase 0.2 with hardware-only checks explicitly BLOCKED.

## `/gsd-next`

Return:

> **Phase 0.2b — Clean build verification**
>
> Run the cleaned repository through a fresh Xcode build and simulator launch, register the Debug App Check token, and record any remaining compile/runtime blockers.
