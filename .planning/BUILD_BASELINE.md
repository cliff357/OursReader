# OursReader — Reproducible Build Baseline

Last updated: 2026-09-16
Branch: `development`
Phase: **0.2 — Reproducible build baseline**
Status: **IN PROGRESS — audit complete, blockers remain**

## Purpose

This document records what a fresh checkout needs before OursReader can be treated as reproducibly buildable. Existing code/configuration is not counted as proven unless the relevant path can be repeated on a clean environment.

Status values:

- **PASS** — repository evidence is sufficient for this baseline item.
- **FAIL** — repository contains a concrete configuration problem that should be fixed.
- **BLOCKED** — repository evidence is insufficient; Apple/Firebase account access, hardware, or an actual Xcode build is required.
- **NOT REQUIRED** — not required for the current baseline or is pending v1 scope.

## Baseline checklist

| Area | Status | Finding / action |
| --- | --- | --- |
| Repository default development path | PASS | `development` is the working branch used by this GSD baseline. |
| Main shared scheme | PASS | `OursReader.xcscheme` is committed and includes build/test/run/profile/archive actions. |
| Unit/UI test targets in scheme | PASS | `OursReaderTests` and `OursReaderUITests` are included in TestAction. Test quality is a later issue. |
| Shared widget schemes | PASS | `SendMissExtension` and `SImplySendMissExtension` schemes are committed. |
| Dedicated shared Watch scheme | BLOCKED | Watch target exists and is embedded in the iPhone app, but there is no separate shared Watch scheme in the committed shared schemes. Decide whether one is needed after v1 scope. |
| Swift Package resolution | PASS | `Package.resolved` is committed with pinned revisions/versions, including Firebase iOS SDK 10.27.0 and Google Sign-In 7.1.0. |
| iOS app deployment target | PASS | Main target is iOS 17.0. |
| Widget deployment target | PASS | Widget targets are iOS 17.0. |
| Watch deployment target | PASS | Watch target is watchOS 10.6. |
| Project deployment target consistency | FAIL | Project-level iOS deployment target still contains 16.4 while product targets use 17.0. Normalize intentionally. |
| Main bundle identifier | PASS | `com.cliffchan.manwareader`. |
| Watch bundle identifier | PASS | `com.cliffchan.manwareader.watchkitapp`, matching the Watch Firebase plist. |
| Widget bundle identifiers | PASS | `com.cliffchan.manwareader.SendMiss` and `com.cliffchan.manwareader.SImplySendMiss`. |
| Signing style | PASS | Targets use automatic signing. |
| Development team portability | FAIL | Team ID is hard-coded throughout project settings. Fresh developers outside that team cannot use the project unchanged for signed/device builds. |
| Main app entitlements | PASS | Push, Sign in with Apple, App Attest, CloudKit, App Group, and keychain groups are declared. |
| Watch entitlements | PASS | Watch target declares the shared App Group and keychain group. |
| Debug vs Release entitlements separation | FAIL | Main Debug and Release entitlement files are effectively identical. Both use APNs `development` and App Attest `production`; environment intent is not separated. |
| APNs production configuration | FAIL | Release entitlement currently contains `aps-environment = development`. Release/archive intent must be corrected/verified. |
| App Attest debug/simulator path | FAIL | App runtime always selects App Attest/DeviceCheck; Debug provider exists only as commented code. Fresh simulator development therefore has no documented App Check debug path. |
| Firebase iOS config present | PASS | `OursReader/GoogleService-Info.plist` is committed for Firebase project `our-reader`. |
| Firebase Watch config present | PASS | Watch `GoogleService-Info.plist` is committed and uses the Watch bundle ID. |
| Firebase environment portability | FAIL | Firebase client configuration is tied directly to the current project and there is no documented dev/staging/prod configuration strategy. |
| CloudKit container declared | PASS | Main entitlement declares `iCloud.com.cliffchan.manwareader`. |
| CloudKit account/schema availability | BLOCKED | Must be verified in the Apple Developer/CloudKit environment and on device. |
| App Group declared | PASS | Main app and Watch use `group.com.cliffchan.manreader.shared`. |
| App Group provisioning | BLOCKED | Requires Apple Developer capability/provisioning verification. |
| Sign in with Apple capability | PASS | Main app entitlement is present. |
| Sign in with Apple provider setup | BLOCKED | Requires Apple Developer/Firebase provider verification. |
| Push registration code | PASS | App registers for remote notifications and passes APNs token to Firebase Messaging. |
| APNs/FCM delivery | BLOCKED | Requires Firebase/APNs credentials and a physical device. |
| Multipeer local-network plist entries | PASS | Bonjour services and local-network usage description are present. |
| Multipeer two-device behavior | BLOCKED | Requires two physical devices. |
| Watch Connectivity code | PASS | iPhone app activates WCSession and responds to Watch requests. |
| Watch end-to-end pairing/data | BLOCKED | Requires paired iPhone/Watch hardware. |
| Main archive configuration | FAIL | `OursReader.xcscheme` ArchiveAction uses `Debug` instead of `Release`. |
| Fastlane production lane | FAIL | `prod` explicitly builds `Debug` while exporting `app-store`. |
| Fastlane account portability | FAIL | TestFlight username is hard-coded to a personal account. |
| Xcode Cloud setup script | FAIL | `ci_post_clone.sh` only disables package-plugin fingerprint validation; it does not document/provision required Firebase/signing/environment setup. |
| Tracked Xcode user data | FAIL | Project and workspace contain committed `xcuserdata`; `.gitignore` only ignores `.xcuserstate`/one path and does not prevent all user metadata from being tracked. |
| Fresh clean Xcode build | BLOCKED | This audit environment cannot run Xcode/macOS builds. Must be executed on a clean Mac/Xcode environment. |
| Fresh simulator launch | BLOCKED | Requires Xcode plus an explicit App Check debug/simulator strategy. |
| Physical-device launch | BLOCKED | Requires signing team, registered capabilities, provisioning, and Apple/Firebase services. |

## Required clone-to-build setup path

Until the FAIL items are fixed, use this as the minimum setup contract:

1. Clone the repository and checkout `development`.
2. Open `OursReader.xcodeproj` with an Xcode version that supports iOS 17 and watchOS 10.6.
3. Allow Swift Package Manager to resolve the committed `Package.resolved` pins.
4. Confirm the main scheme `OursReader` is selected.
5. Use an Apple Developer team that owns or can reproduce these capabilities/bundle IDs, or replace bundle IDs/team/capabilities with a development-specific configuration.
6. Confirm Firebase configuration for the iOS and Watch targets.
7. Confirm CloudKit container, App Group, Sign in with Apple, Push Notifications, App Attest, and keychain access are enabled for the chosen identifiers.
8. For simulator development, define a supported Firebase App Check debug path before treating runtime Firebase flows as valid.
9. For device validation, use physical hardware for APNs/App Attest/Multipeer/iCloud/Watch tests.
10. Do not use the current production Fastlane lane or Debug archive as release evidence until the release configuration failures below are corrected.

## Phase 0.2 blockers to fix next

These are repository-controlled and should be corrected before Phase 0.2 can close:

1. Change the main ArchiveAction from Debug to Release.
2. Change Fastlane `prod` to build Release and remove/parameterize the personal TestFlight username.
3. Decide and document Debug vs Release entitlement behavior, especially APNs and App Check.
4. Add a documented App Check debug/simulator strategy.
5. Remove tracked project/workspace `xcuserdata` and broaden `.gitignore` to ignore Xcode user metadata.
6. Normalize the project-level deployment target with the supported product target policy.
7. Document or parameterize Apple development team/signing assumptions.
8. Document Firebase environment strategy rather than relying implicitly on the committed client plists.
9. Perform a clean Xcode build after the repository-controlled fixes.

## Hardware/account validation after repository fixes

The following should remain BLOCKED until tested with the relevant services/hardware:

- APNs + FCM delivery
- App Attest enforcement
- CloudKit container/schema
- Sign in with Apple provider setup
- App Group provisioning
- Multipeer exchange on two devices
- iPhone ↔ Apple Watch connectivity
- TestFlight upload / Xcode Cloud run

## Exit criteria for Phase 0.2

Phase 0.2 is COMPLETE only when:

- repository-controlled FAIL items above are fixed or deliberately documented as accepted constraints;
- a clean Mac can resolve packages and compile the `OursReader` scheme using documented setup;
- Debug/simulator Firebase behavior has a documented App Check path;
- release archive uses Release configuration;
- remaining Apple/Firebase/hardware checks are explicitly marked BLOCKED rather than assumed to work.

## `/gsd-next`

> **Phase 0.2a — Fix repository-controlled build/release blockers**
>
> Clean tracked Xcode user data, normalize release/archive configuration, make signing/Firebase assumptions explicit, and establish a Debug App Check path before running a clean Xcode build.
