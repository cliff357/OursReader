# OursReader — GSD Roadmap

Last updated: 2026-09-17

## Roadmap rules

- Work one phase at a time.
- Each phase must have observable exit criteria.
- Existing code does not count as complete until the relevant flow is verified.
- Do not add unrelated feature work while a baseline / stabilization phase is open.
- Update `STATE.md` whenever a phase or sub-phase changes status.

## Phase 0 — Bootstrap and Baseline

Goal: establish a trustworthy project state before changing product behavior.

### 0.1 GSD bootstrap + current-state inventory — COMPLETE

Deliverables:

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- Initial classification of implemented / needs verification / experimental / missing areas

### 0.2 Reproducible build baseline — IN PROGRESS

Goal: prove what a fresh developer checkout needs in order to build and run.

Deliverables:

- `.planning/BUILD_BASELINE.md`
- `.planning/ENVIRONMENT_SETUP.md`

#### 0.2a Fix repository-controlled build/release blockers — COMPLETE

Completed:

- Main ArchiveAction changed to Release.
- Fastlane `prod` changed to Release.
- Personal TestFlight username removed from Fastlane.
- Debug/Release entitlement environment intent separated.
- Debug iOS/Watch builds now use Firebase App Check debug provider.
- App Check provider setup moved before Firebase initialization.
- Tracked project/workspace `xcuserdata` removed.
- `.gitignore` broadened for Xcode user state/build output.
- Xcode Cloud post-clone preflight now validates repository-controlled prerequisites.
- Apple team/signing assumptions documented.
- Current Firebase single-project strategy documented.

Accepted constraints / deferred cleanup:

- The Apple Development Team ID remains committed as project ownership metadata; signed builds require team membership.
- The project-level iOS 16.4 value remains because supported product targets explicitly override it with iOS 17; normalize later during project-file cleanup.
- Multi-environment Firebase configuration is not required for this baseline; current one-project strategy is explicit.

#### 0.2b Clean build verification — NEXT

Tasks:

- Resolve packages from a clean checkout.
- Compile the shared `OursReader` scheme on a clean Mac/Xcode environment.
- Run unit/UI test targets once.
- Launch a supported simulator.
- Register the generated Firebase App Check debug token.
- Verify at least one Firebase-backed app path.
- Record compile/runtime blockers.

#### 0.2c Hardware/account verification — PENDING / BLOCKED

Validate when hardware/account access is available:

- APNs + FCM
- production App Attest
- CloudKit
- Sign in with Apple
- App Group provisioning
- Multipeer on two devices
- iPhone ↔ Apple Watch
- TestFlight / Xcode Cloud signed run

Exit criteria:

- A developer can follow one documented setup path from clone to build.
- Known blockers are explicit rather than implicit.
- No required setup depends on undocumented personal machine state.
- Release archive uses Release configuration.
- Debug/simulator Firebase has a verified App Check path.
- Remaining hardware/account-only checks are explicitly marked BLOCKED rather than assumed.

## Phase 1 — Product Definition

Goal: decide exactly what OursReader v1 is.

Tasks:

- Choose the primary product promise: reading, quick communication, or a scoped combination.
- Define v1 user journey and non-goals.
- Decide whether Widget, Live Activity, Apple Watch, and `SImplySendMiss` are v1, post-v1, or removed.
- Define the minimum supported book-import path.
- Define the minimum friend / push experience if communication remains in v1.

Exit criteria:

- One-sentence v1 promise exists.
- Included and excluded feature families are explicit.
- Every later roadmap phase can be mapped to the v1 promise.

## Phase 2 — Stable Reading Core

Goal: make the core ebook lifecycle deterministic and testable.

Tasks:

- Confirm current ebook JSON schema and source of truth.
- Validate import from supported sources.
- Validate local cache and download state.
- Validate CloudKit upload / download / chunking behavior.
- Validate reader progress, bookmarks, font settings, and resume behavior.
- Validate offline / reconnect behavior.
- Add focused unit tests for pure reading / import logic.
- Consolidate duplicated or competing reading paths if discovered during audit.

Exit criteria:

- A supported book can be imported, opened, read, closed, reopened, and recovered reliably.
- Core reading state has automated coverage where practical.
- Failure states have defined user-facing behavior.

## Phase 3 — Friend and Push Stability

Goal: make communication data and notification behavior safe and predictable.

Tasks:

- Document friend and push data models.
- Revalidate Multipeer friend exchange on two physical devices.
- Verify Firebase token registration / refresh / deletion lifecycle.
- Verify one-tap push path end to end.
- Review Firebase database / Firestore security expectations.
- Verify account deletion cleans relevant user data / tokens.
- Add tests around deterministic data transformation / state logic.

Exit criteria:

- Two supported devices can establish the intended friend relationship reliably.
- Notification delivery works through the documented backend path.
- Token and account lifecycle behavior is defined and verified.

## Phase 4 — Companion Surfaces

Goal: stabilize only the non-iPhone surfaces accepted into v1.

Tasks:

- Apple Watch: verify iPhone-to-Watch authentication / state transfer.
- Apple Watch: verify data load and notification action end to end.
- Widget: define the accepted widget use case and validate it.
- Live Activity: retain only if it supports the v1 promise.
- Resolve `SendMiss` vs `SImplySendMiss` ownership / duplication.

Exit criteria:

- Every retained companion surface has one documented purpose.
- Included surfaces work end to end on supported hardware.
- Experimental targets not in scope are clearly isolated or removed.

## Phase 5 — Production Hardening

Goal: turn the stabilized v1 scope into a release candidate.

Tasks:

- Replace uncontrolled development `print` logging with structured logging where needed.
- Accessibility audit and fixes.
- Localization review.
- Privacy / permission / account-deletion review.
- Error and recovery behavior audit.
- Expand automated test coverage around highest-risk paths.
- Verify Fastlane / Xcode Cloud configuration.
- Define release checklist and TestFlight acceptance pass.

Exit criteria:

- Release checklist passes.
- Critical v1 flows have repeatable evidence.
- CI / release automation is documented and usable.
- No known release-blocking privacy, security, data-loss, or account-lifecycle issue remains open.

## Deferred ideas

Keep ideas here rather than interrupting an active phase:

- New reading formats beyond the selected v1 import scope
- Additional social / friend features
- Additional widgets or Live Activities
- New Apple Watch experiences beyond the selected v1 action set
- New scraping / publishing automation
- New AI features

## Current next action

Run **Phase 0.2b — Clean build verification**.
