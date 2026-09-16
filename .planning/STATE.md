# OursReader — GSD State

Last updated: 2026-09-16
Branch: `development`

## Current position

- Current phase: **Phase 0 — Bootstrap and Baseline**
- Current sub-phase: **0.2 Reproducible build baseline**
- Status: **IN PROGRESS — audit complete, repository-controlled blockers remain**
- Next sub-phase: **0.2a Fix repository-controlled build/release blockers**

## Baseline snapshot

The repository contains substantial implementation, but it is not yet a reproducible clone-to-build/release baseline. The Phase 0.2 audit is recorded in `.planning/BUILD_BASELINE.md`.

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
| CloudKit/App Group/Sign in with Apple provisioning | BLOCKED — account/device verification |
| APNs/FCM delivery | BLOCKED — Firebase/APNs/device verification |
| Multipeer | BLOCKED — two-device verification |
| Watch end-to-end | BLOCKED — paired hardware verification |
| Project-level deployment target consistency | FAIL |
| Development-team portability | FAIL |
| Debug/Release entitlement separation | FAIL |
| Release APNs entitlement | FAIL |
| App Check Debug/simulator path | FAIL |
| Main ArchiveAction configuration | FAIL — Debug instead of Release |
| Fastlane production configuration | FAIL — Debug App Store build + personal account |
| Xcode Cloud setup completeness | FAIL |
| Tracked Xcode user data | FAIL |
| Firebase environment strategy | FAIL — implicit/current-project only |
| Clean Xcode build | BLOCKED — requires Mac/Xcode execution |

## Important Phase 0.2 findings

1. `Package.resolved` is committed and pins the dependency graph, including Firebase and Google Sign-In.
2. The main shared scheme includes both unit and UI tests, but ArchiveAction currently uses **Debug**.
3. Fastlane's `prod` lane also explicitly builds **Debug** while exporting for the App Store and hard-codes a personal TestFlight username.
4. Signing uses automatic signing but the Apple Development Team ID is hard-coded across targets.
5. Main Debug and Release entitlement files are effectively identical: APNs is `development` and App Attest is `production` in both.
6. Runtime App Check always selects App Attest/DeviceCheck; the Debug provider is commented out. There is no reproducible simulator App Check path documented.
7. The repository tracks both project and workspace `xcuserdata`, including multiple users. Current `.gitignore` does not prevent all of this metadata from being tracked.
8. Main and Watch Firebase client plists are committed and tied to the `our-reader` Firebase project. No environment-selection strategy is documented.
9. Main app target is iOS 17 and Watch is watchOS 10.6, but project-level configuration still contains iOS 16.4.
10. Hardware/service-dependent behaviors remain intentionally BLOCKED rather than being treated as working without evidence.

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

### 2026-09-16 — Phase 0.2 AUDIT COMPLETE / PHASE IN PROGRESS

Completed:

- Audited shared schemes and test wiring.
- Audited deployment targets and bundle identifiers.
- Audited committed Swift Package pins.
- Audited signing/team assumptions.
- Audited main and Watch entitlements.
- Audited Firebase plist/configuration assumptions.
- Audited App Check setup.
- Audited CloudKit/App Group/Push/Sign in with Apple requirements.
- Audited tracked Xcode user metadata.
- Audited Fastlane and Xcode Cloud support.
- Created `.planning/BUILD_BASELINE.md` with PASS / FAIL / BLOCKED status.

Not completed yet:

- Repository-controlled configuration failures have not been fixed.
- A clean Xcode build has not been executed.
- Hardware/account dependent flows have not been revalidated.

## Next action — Phase 0.2a

Fix repository-controlled baseline blockers before any product feature work:

1. Release archive must use Release configuration.
2. Fastlane production lane must use Release and remove/parameterize personal account assumptions.
3. Remove tracked `xcuserdata` and improve `.gitignore`.
4. Normalize deployment-target policy.
5. Separate/document Debug vs Release entitlement behavior.
6. Establish a Debug/simulator Firebase App Check path.
7. Make Apple team/signing assumptions explicit.
8. Document Firebase environment strategy.

After 0.2a, proceed to **0.2b Clean build verification** on a Mac/Xcode environment.

## `/gsd-next`

Return:

> **Phase 0.2a — Fix repository-controlled build/release blockers**
>
> Clean Xcode user metadata, correct Release/archive/Fastlane configuration, define Debug App Check and entitlement behavior, and make signing/Firebase assumptions explicit before running a clean build.
