# OursReader

OursReader is a SwiftUI app for reading self-imported ebooks and staying connected with friends through quick push notifications. The repository also contains a companion watchOS app, widget / Live Activity experiments, and Python tools that convert PDFs or web books into OursReader's JSON format.

> Project status: active prototype. The main reading, account, friend, push-notification, and watch connectivity flows are present, but some UI and release automation still need consolidation and broader testing.

## What is in the project

### iOS app

- Email, Google, and Apple authentication through Firebase Auth
- Firebase App Check backed by App Attest / DeviceCheck
- Friend discovery and nearby profile exchange with Multipeer Connectivity
- Configurable one-tap push notifications backed by Firebase
- Ebook library with JSON file import and iCloud Drive scanning
- CloudKit storage with chunking for large book content
- Local ebook cache, download state, reading progress, bookmarks, and font settings
- Side-menu navigation for dashboard, friends, and settings
- Localized strings and bundled Work Sans fonts

### watchOS companion

- Receives the signed-in Firebase token from the iPhone through Watch Connectivity
- Loads push settings and friend tokens
- Sends quick notifications from Apple Watch

### Extensions and supporting tools

- `SendMiss`: widget / Live Activity extension
- `SImplySendMiss`: additional widget experiment
- `scripts/pdf_to_ebook_converter.py`: converts a local or remote PDF into importable JSON
- `script/universal_book_scraper.py`: scrapes chapter-based web books into importable JSON with retry and resume support
- `public/`: Firebase Hosting content, currently used for web-facing static pages such as terms and conditions
- `fastlane/` and `ci_scripts/`: early TestFlight and Xcode Cloud automation

## Technology

- Swift 5, SwiftUI
- iOS 17+
- watchOS 10.6+
- Firebase Authentication, Firestore / Realtime Database, Messaging, and App Check
- CloudKit and iCloud Documents
- WatchConnectivity and MultipeerConnectivity
- Swift Package Manager
- Python 3 for book-conversion utilities

The pinned Swift package versions are recorded in `OursReader.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Repository structure

```text
OursReader/                   Main iOS application
  Helpers/                   Firebase, CloudKit, cache, security, and services
  Model/                     App and ebook data models
  Router/                    Navigation routing
  View/                      SwiftUI screens and reusable views
  ViewModels/                Authentication and import state
readerWatchOS Watch App/     watchOS companion app
SendMiss/                    Widget and Live Activity extension
SImplySendMiss/              Secondary widget extension
OursReaderTests/             Unit-test target
OursReaderUITests/           UI-test target
scripts/                     PDF conversion utility
script/                      Web-book scraper
public/                      Firebase Hosting site
fastlane/                    TestFlight automation
```

## Getting started

### Requirements

- macOS with a version of Xcode that supports iOS 17 and watchOS 10.6
- An Apple Developer account for CloudKit, App Attest, push notifications, widgets, and device testing
- A Firebase project configured for the iOS and watchOS bundle identifiers
- Python 3 if you want to use the conversion tools

### App setup

1. Clone the repository:

   ```bash
   git clone https://github.com/cliff357/OursReader.git
   cd OursReader
   ```

2. Open `OursReader.xcodeproj` in Xcode. Swift Package Manager should resolve the pinned dependencies automatically.

3. Supply Firebase configuration files for the app targets:

   - `OursReader/GoogleService-Info.plist`
   - `readerWatchOS Watch App/GoogleService-Info.plist`

4. Select your own development team and review the bundle identifiers, signing, App Groups, iCloud / CloudKit, push notification, Sign in with Apple, and App Attest capabilities for every target.

5. Configure the corresponding Firebase Authentication providers, database rules, Cloud Messaging, and App Check enforcement. The backend resources and security rules are not fully defined in this repository.

6. Select the `OursReader` scheme and run it on an iOS 17+ simulator or device. Hardware is required to verify the complete App Attest, APNs, nearby-device, iCloud, and Apple Watch flows.

Never commit private keys, service-account JSON, signing certificates, or production secrets. Firebase client plist files contain project identifiers rather than server credentials, but use configuration files belonging to your own Firebase project for development.

## Ebook JSON format

The importer expects a JSON array. Each item follows the `EbookData` model and contains book metadata plus an array of page strings. A minimal example is:

```json
[
  {
    "id": "example-book",
    "title": "Example Book",
    "author": "Example Author",
    "instruction": "A short description",
    "coverImage": "",
    "pages": ["Page one", "Page two"],
    "totalPages": 2,
    "currentPage": 0,
    "bookmarkedPages": []
  }
]
```

Check the `EbookData` declaration in `OursReader/Helpers/BookImportManager.swift` before producing data programmatically; it is the source of truth for the current import schema.

### PDF converter

Install its dependencies in a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install pymupdf requests
python3 scripts/pdf_to_ebook_converter.py
```

The converter prompts for either a local PDF path or a PDF URL. Only process material you have permission to download and reproduce.

### Web-book scraper

```bash
python3 -m pip install requests beautifulsoup4
python3 script/universal_book_scraper.py
```

Website layouts vary, so selectors may require adjustment. Respect copyright, robots policies, and site terms.

## Testing and delivery

- Unit and UI test targets exist but currently contain only starter coverage.
- Xcode Cloud post-clone setup is in `ci_scripts/ci_post_clone.sh`.
- The Fastlane `prod` lane builds the `OursReader` scheme and uploads to TestFlight; its signing, build configuration, and account settings should be reviewed before use.
- Firebase Hosting is configured by `firebase.json` to deploy the `public/` directory.

## Known gaps

- No backend functions, Firestore rules, or deployment guide are included in the repository.
- Automated tests do not yet cover authentication, book imports, CloudKit chunking, notification delivery, or watch connectivity.
- Some dashboard areas are feature-gated or marked “Coming Soon”.
- There are two similarly named `BookImportManager` implementations that should be consolidated.
- Logging still includes development `print` statements and should be normalized before production release.
- Release automation uses project-specific account and signing assumptions.
- User-specific Xcode workspace data is currently tracked and should be removed from version control in a cleanup change.

## GSD improvement roadmap

The repository does not currently contain a GSD workspace or planning files. A practical Get Shit Done sequence would be:

1. **Define the product:** decide whether OursReader's primary promise is personal reading, friend-to-friend notifications, or a deliberate combination of both.
2. **Create a reproducible baseline:** document Firebase / CloudKit setup, remove machine-specific files, make a clean build pass, and record known failures.
3. **Stabilize core reading:** consolidate import logic; test JSON import, caching, chunking, progress, bookmarks, and offline behavior.
4. **Stabilize communication:** define the friend and push data model, add security-rule tests, and verify token lifecycle and account deletion.
5. **Finish companion surfaces:** settle the widget targets and validate iPhone-to-Watch authentication and push actions end to end.
6. **Production hardening:** structured logging, accessibility, localization review, privacy disclosures, error recovery, test coverage, CI, and TestFlight release checks.

Each phase should have a written goal, a small set of verifiable requirements, implementation tasks, and a completion check. Keep feature work out of a phase until its baseline checks pass.

## GitHub

Repository: [github.com/cliff357/OursReader](https://github.com/cliff357/OursReader)

The default remote currently points to the `development` branch.

## License

No license file is currently included. Until a license is added, the source remains all rights reserved by default.
