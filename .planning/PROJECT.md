# OursReader — Project Definition

Last updated: 2026-09-16

## Purpose

OursReader is an active SwiftUI prototype that combines personal ebook reading with lightweight friend-to-friend communication. The current repository also includes an Apple Watch companion, widgets / Live Activity experiments, Firebase Hosting content, and book-conversion utilities.

This file is the GSD project-level source of truth. Product scope may be narrowed during Phase 1, but implementation work should not silently expand beyond the roadmap.

## Current product hypothesis

A personal reading app where a user can import and read books, stay connected with friends, and trigger simple one-tap messages from iPhone / Apple Watch surfaces.

This is a hypothesis, not yet the final v1 promise. Phase 1 must decide whether v1 is primarily:

1. a reading product,
2. a communication / quick-push product, or
3. a deliberately scoped combination of both.

## Verified repository capabilities

### iOS application

- SwiftUI app with login, signup, main navigation, dashboard, friends, settings, and book screens.
- Dashboard contains Push, Widget, and Ebook surfaces.
- Firebase Authentication integrations include email plus Google / Apple sign-in paths.
- Firebase App Check integration exists with App Attest / DeviceCheck provider logic.
- Friend discovery / exchange code exists using Multipeer Connectivity.
- Push notification UI and a `NotificationManager` backed by Firebase Functions exist.
- Ebook import, detail, reader, local cache, CloudKit storage, progress, bookmark, and font-setting code exists.
- Localized resources and custom fonts are present.

### Apple Watch companion

- Separate watchOS target exists.
- WatchConnectivity is used between iPhone and Apple Watch.
- Watch target includes Firebase, helpers, models, views, view models, and data-service code.
- Current intent is to load push / friend data and trigger quick notifications from the watch.

### Extensions / tooling

- `SendMiss` contains widget, App Intent, and Live Activity code.
- `SImplySendMiss` is a second widget experiment and must be reviewed before production scope is fixed.
- `scripts/pdf_to_ebook_converter.py` converts PDF content into the app's import format.
- `script/universal_book_scraper.py` handles chapter-style web book conversion.
- `fastlane/` and `ci_scripts/` contain early release / Xcode Cloud automation.
- `public/` contains Firebase Hosting content.

## Maturity classification

The repository is an **active prototype**, not a production-ready release baseline.

Use these labels in planning:

- **Implemented** — meaningful production code exists.
- **Needs verification** — code exists but end-to-end behavior has not been revalidated in the current baseline.
- **Experimental** — target / feature exists but is not yet accepted into v1 scope.
- **Missing** — required implementation or verification evidence is absent.

Current classification:

| Area | Status | Notes |
| --- | --- | --- |
| Authentication | Needs verification | Multiple auth paths exist; current clean-device behavior not revalidated. |
| Dashboard navigation | Implemented | Push / Widget / Ebook paging exists. |
| Ebook import | Needs verification | Substantial import code exists; schema and edge cases need baseline tests. |
| Ebook reader | Needs verification | Reading progress, bookmark, and font-setting logic exists. |
| Local cache / CloudKit | Needs verification | Large implementation exists; sync / chunking / offline behavior needs validation. |
| Friend discovery | Needs verification | Multipeer-based implementation exists; two-device flow needs revalidation. |
| Push notification | Needs verification | Firebase Functions client path exists; backend / token lifecycle must be checked. |
| Apple Watch | Needs verification | Companion implementation exists; end-to-end pairing/auth/push flow needs validation. |
| Widget / Live Activity | Experimental | `SendMiss` implementation exists; product role not confirmed. |
| Secondary widget target | Experimental | `SImplySendMiss` must be retained, merged, or removed deliberately. |
| Automated tests | Missing | Test target is effectively starter/template coverage. |
| Release automation | Needs verification | Fastlane / Xcode Cloud material exists but is project-specific and unverified. |

## Technical baseline

- Swift / SwiftUI
- iOS 17+
- watchOS 10.6+
- Firebase Auth, Messaging, Firestore / Realtime Database, Functions, App Check
- CloudKit / iCloud Documents
- WatchConnectivity
- MultipeerConnectivity
- Swift Package Manager
- Python 3 conversion utilities

## Constraints

- Hardware is required for complete App Attest, APNs, Multipeer, iCloud, and Apple Watch validation.
- Backend Firebase resources / rules / functions are not fully represented in this repository.
- Production work must not rely on developer-specific signing or account assumptions.
- New features should not be added until the current phase exit criteria are satisfied.

## v1 scope guardrail

Until Phase 1 is complete:

- Do not add new major feature families.
- Treat Widget / Live Activity and the second widget target as optional / experimental.
- Prioritize reproducibility and verification over feature expansion.
- Preserve existing user-facing functionality while documenting what is actually proven to work.

## Success definition

OursReader is ready to move from prototype to release candidate when:

1. v1 product scope is explicit.
2. A clean checkout can be configured and built repeatably.
3. Core v1 flows have deterministic verification steps and automated tests where practical.
4. Authentication, storage, notification, and account lifecycle behavior are validated.
5. iPhone / Watch / widget surfaces included in v1 work end to end.
6. Logging, accessibility, localization, privacy, recovery, CI, and release checks meet the production-hardening phase criteria.
