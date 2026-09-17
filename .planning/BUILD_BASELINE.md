# OursReader — Reproducible Build Baseline

Last updated: 2026-09-17
Branch: `development`
Phase: **0.2 — Reproducible build baseline**
Status: **IN PROGRESS — repository fixes complete; clean Xcode verification next**

## Purpose

This document records what a fresh checkout needs before OursReader can be treated as reproducibly buildable. Existing code/configuration is not counted as proven unless the relevant path can be repeated on a clean environment.

Status values:

- **PASS** — repository evidence is sufficient for this baseline item.
- **FAIL** — repository contains a concrete configuration problem that should be fixed.
- **BLOCKED** — Apple/Firebase account access, hardware, or an actual Xcode build is required.
- **NOT REQUIRED** — not required for the current baseline or intentionally deferred.

## Baseline checklist

| Area | Status | Finding / action |
| --- | --- | --- |
| Repository development path | PASS | `development` is the working branch used by this GSD baseline. |
| Main shared scheme | PASS | `OursReader.xcscheme` is committed and includes build/test/run/profile/archive actions. |
| Unit/UI test targets in scheme | PASS | `OursReaderTests` and `OursReaderUITests` are wired into TestAction. Test quality is a later issue. |
| Shared widget schemes | PASS | `SendMissExtension` and `SImplySendMissExtension` schemes are committed. |
| Dedicated shared Watch scheme | NOT REQUIRED | Watch target is embedded in the iPhone app. A separate shared Watch scheme can be added later if Phase 1 keeps Watch in v1. |
| Swift Package resolution | PASS | `Package.resolved` is committed with pinned revisions/versions. |
| iOS app deployment target | PASS | Main product target explicitly uses iOS 17.0. |
| Widget deployment target | PASS | Widget targets explicitly use iOS 17.0. |
| Watch deployment target | PASS | Watch target explicitly uses watchOS 10.6. |
| Project-level iOS 16.4 value | NOT REQUIRED | Product targets explicitly override with iOS 17.0, so the older project-level value is not a build blocker. Normalize later during project cleanup if desired. |
| Main bundle identifier | PASS | `com.cliffchan.manwareader`. |
| Watch bundle identifier | PASS | `com.cliffchan.manwareader.watchkitapp`, matching the Watch Firebase plist. |
| Widget bundle identifiers | PASS | `com.cliffchan.manwareader.SendMiss` and `com.cliffchan.manwareader.SImplySendMiss`. |
| Signing style | PASS | Targets use automatic signing. |
| Development team configuration | PASS | The committed Team ID is treated as project ownership metadata. Developers doing signed/device builds must be members of that Apple Developer team; this prerequisite is documented in `ENVIRONMENT_SETUP.md`. |
| Main app entitlements | PASS | Push, Sign in with Apple, App Attest, CloudKit, App Group, and keychain groups are declared. |
| Watch entitlements | PASS | Watch target declares the shared App Group and keychain group. |
| Debug vs Release entitlement separation | PASS | Debug uses development APNs/App Attest environment; Release uses production APNs/App Attest environment. |
| APNs production configuration | PASS | Release entitlement now contains `aps-environment = production`. |
| App Check provider ordering | PASS | App Check provider factory is set before Firebase configuration. |
| App Check Debug/simulator path | PASS | Debug builds use `AppCheckDebugProviderFactory`; setup/token registration is documented in `ENVIRONMENT_SETUP.md`. |
| App Check debug-token acceptance | BLOCKED | A generated token must still be registered/verified in Firebase Console. |
| Firebase iOS config present | PASS | iOS `GoogleService-Info.plist` is committed for Firebase project `our-reader`. |
| Firebase Watch config present | PASS | Watch `GoogleService-Info.plist` is committed and uses the Watch bundle ID. |
| Firebase environment strategy | PASS | Current single-project strategy is now explicit. Future multi-environment work must use explicit build configuration/plist selection. |
| CloudKit container declared | PASS | Main entitlement declares `iCloud.com.cliffchan.manwareader`. |
| CloudKit account/schema availability | BLOCKED | Must be verified in Apple Developer/CloudKit and on device. |
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
| Main archive configuration | PASS | `OursReader.xcscheme` ArchiveAction now uses Release. |
| Fastlane production lane | PASS | `prod` now builds Release for App Store export. |
| Fastlane account portability | PASS | Personal TestFlight username was removed; authentication is supplied by local/CI Fastlane credentials or API key. |
| Xcode Cloud post-clone preflight | PASS | Script now validates required repository-controlled Firebase/entitlement/package files and fails early when missing. |
| Xcode Cloud signed run | BLOCKED | Requires Xcode Cloud/App Store Connect signing configuration and an actual run. |
| Tracked Xcode user data | PASS | Tracked project/workspace `xcuserdata` files were removed and `.gitignore` now ignores all `xcuserdata` plus common local Xcode state. |
| Fresh clean Xcode build | BLOCKED | Requires Mac/Xcode execution. |
| Fresh simulator launch | BLOCKED | Requires Xcode plus registering the generated App Check debug token in Firebase. |
| Physical-device launch | BLOCKED | Requires signing team, capabilities, provisioning, and Apple/Firebase services. |

## Repository-controlled fixes completed in 0.2a

1. Main ArchiveAction changed from Debug to Release.
2. Fastlane `prod` changed from Debug to Release.
3. Personal TestFlight username removed from Fastlane.
4. Main Debug/Release entitlement environments separated.
5. Debug builds now use Firebase App Check debug provider.
6. App Check provider setup is performed before Firebase configuration on iOS and Watch.
7. Tracked Xcode `xcuserdata` files removed.
8. `.gitignore` expanded to prevent Xcode user metadata/build output returning.
9. Xcode Cloud post-clone script now validates repository-controlled build prerequisites.
10. Apple signing and Firebase single-project assumptions documented in `.planning/ENVIRONMENT_SETUP.md`.

## Fresh clone setup path

1. Clone the repository and checkout `development`.
2. Open `OursReader.xcodeproj` with Xcode supporting iOS 17 and watchOS 10.6.
3. Allow Swift Package Manager to resolve the committed `Package.resolved` pins.
4. Select the shared `OursReader` scheme.
5. For simulator Firebase testing, run Debug, copy the App Check debug token from the Xcode console, and register it in Firebase Console.
6. For signed/device testing, use an account authorized for the OursReader Apple Developer team and verify the declared capabilities.
7. Use physical hardware for APNs/App Attest/Multipeer/iCloud/Watch validation.
8. Use Release configuration for Archive/TestFlight builds.
9. Keep App Check debug tokens, CI credentials, API private keys, and Xcode `xcuserdata` out of Git.

See `.planning/ENVIRONMENT_SETUP.md` for the detailed environment contract.

## Phase 0.2b — next verification

Repository-controlled blockers are no longer the reason Phase 0.2 is open. The next required evidence is a clean Mac/Xcode run:

- resolve packages from a clean checkout;
- build the shared `OursReader` scheme;
- run unit/UI test targets at least once, even though coverage is currently weak;
- launch a supported simulator;
- obtain/register an App Check debug token and verify a Firebase-backed path;
- record compile/runtime blockers if any.

## Hardware/account validation after clean build

Remain BLOCKED until tested with the relevant services/hardware:

- APNs + FCM delivery
- production App Attest enforcement
- CloudKit container/schema
- Sign in with Apple provider setup
- App Group provisioning
- Multipeer exchange on two devices
- iPhone ↔ Apple Watch connectivity
- TestFlight upload / Xcode Cloud signed run

## Exit criteria for Phase 0.2

Phase 0.2 is COMPLETE only when:

- repository-controlled configuration fixes remain clean;
- a clean Mac can resolve packages and compile the `OursReader` scheme using the documented setup;
- Debug/simulator Firebase behavior successfully uses a registered App Check debug token;
- Release archive uses Release configuration;
- remaining Apple/Firebase/hardware checks are explicitly marked BLOCKED rather than assumed to work.

## `/gsd-next`

> **Phase 0.2b — Clean build verification**
>
> Run a clean Xcode build and simulator launch using the documented App Check debug path, then record any remaining compile/runtime blockers.
