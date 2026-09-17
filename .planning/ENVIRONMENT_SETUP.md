# OursReader — Environment Setup

Last updated: 2026-09-17
Branch: `development`

## Purpose

This is the environment contract for a fresh OursReader checkout. Repository configuration should be sufficient to understand what is required locally, while account secrets/tokens stay outside Git.

## Current environment model

OursReader currently uses one committed Firebase client configuration for the `our-reader` Firebase project:

- iOS app: `OursReader/GoogleService-Info.plist`
- Watch app: `readerWatchOS Watch App/GoogleService-Info.plist`

This is intentionally documented as a **single-project setup**, not an implicit dev/staging/prod system. If separate Firebase environments are introduced later, they should use explicit build configurations and separate plist selection rather than silently replacing these files.

## Apple signing

The Xcode project uses automatic signing and the existing OursReader Apple Developer team.

For the original production bundle IDs/capabilities, a developer must have access to that Apple Developer team. The committed Team ID is therefore treated as project ownership metadata rather than a personal secret.

If a developer does not have access to the production team, use temporary development bundle identifiers/capabilities locally instead of changing production identifiers in committed project files.

Required Apple-side capabilities for full device validation include:

- Push Notifications
- Sign in with Apple
- iCloud / CloudKit
- App Groups
- Keychain Sharing
- App Attest
- Watch app pairing/provisioning

## Firebase App Check

### Debug builds

Debug builds use `AppCheckDebugProviderFactory` on iOS and Watch. The provider factory is configured before `FirebaseApp.configure(...)`.

Fresh simulator/device setup:

1. Run the Debug build.
2. Read the Firebase App Check debug token printed in the Xcode console.
3. In Firebase Console, open App Check for the relevant app and register that debug token.
4. Keep the token private. Never commit a debug token to Git.

For CI, store the debug token in the CI provider's secure secret store and expose it only to the test/build process. Do not add the token to this repository.

### Release builds

Release builds use the production attestation provider (`AppAttestProvider`, with DeviceCheck fallback where applicable).

The main app Release entitlement uses:

- APNs environment: `production`
- App Attest environment: `production`

The main app Debug entitlement uses:

- APNs environment: `development`
- App Attest environment: `development`

## Firebase client configuration

The committed Firebase plist files identify the current Firebase project and bundle IDs. They are client configuration, but access to Firebase Console/backend configuration is still required to verify:

- App Check enforcement and registered debug tokens
- Authentication providers
- APNs/FCM credentials
- Firestore / Realtime Database rules
- Functions deployment and App Check enforcement

Do not put server credentials, service-account private keys, App Store Connect API private keys, or App Check debug tokens in the repository.

## CloudKit / App Group

Repository entitlements reference:

- CloudKit container: `iCloud.com.cliffchan.manwareader`
- App Group: `group.com.cliffchan.manreader.shared`

These declarations are committed, but the matching Apple Developer resources and provisioning must be verified with an authorized account and physical devices.

## Fresh clone checklist

1. Checkout `development`.
2. Open `OursReader.xcodeproj` in an Xcode version supporting iOS 17 / watchOS 10.6.
3. Allow Swift Package Manager to resolve the committed `Package.resolved`.
4. Confirm the `OursReader` shared scheme.
5. For simulator Firebase testing, register the generated App Check debug token in Firebase Console.
6. For physical-device testing, use an authorized Apple Developer team and verify required capabilities/profiles.
7. Use Release configuration for Archive/TestFlight builds.
8. Keep local Xcode `xcuserdata`, App Check debug tokens, CI secrets, and personal credentials out of Git.

## Known external verification still required

The repository alone cannot prove these paths:

- clean Xcode compilation on a fresh Mac
- App Check token acceptance by Firebase
- APNs/FCM delivery
- CloudKit schema/container access
- Sign in with Apple provider configuration
- App Group provisioning
- Multipeer exchange across two devices
- iPhone ↔ Apple Watch end-to-end connectivity
- TestFlight upload / Xcode Cloud signing
