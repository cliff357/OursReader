# OursReader — GSD Roadmap

Last updated: 2026-09-16

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

Exit criteria:

- Project purpose and uncertainty are documented.
- Existing major feature families are inventoried.
- Next phase can be chosen without relying on memory or README history alone.

### 0.2 Reproducible build baseline — IN PROGRESS

Goal: prove what a fresh developer checkout needs in order to build and run.

Audit deliverable:

- `.planning/BUILD_BASELINE.md`

Audit completed:

- Xcode targets, schemes, deployment targets, SPM dependencies, capabilities, bundle IDs, and signing assumptions reviewed.
- Firebase, CloudKit, App Group, Push, Sign in with Apple, App Check, Watch, Fastlane, and Xcode Cloud assumptions recorded.
- Simulator-only vs physical-device validation requirements classified.
- Build/setup items classified as PASS / FAIL / BLOCKED / NOT REQUIRED.

Repository-controlled blockers found:

- Main ArchiveAction uses Debug instead of Release.
- Fastlane `prod` builds Debug for App Store export and hard-codes a personal TestFlight account.
- Project/workspace `xcuserdata` is tracked.
- Debug/Release entitlement intent is not properly separated; Release currently carries development APNs entitlement.
- App Check has no documented Debug/simulator provider path.
- Apple development team is hard-coded in target settings.
- Firebase environment/configuration strategy is implicit rather than parameterized/documented.
- Project-level deployment target still contains 16.4 while supported product targets use iOS 17.

#### 0.2a Fix repository-controlled build/release blockers — NEXT

Tasks:

- Change the main archive configuration to Release.
- Change Fastlane production build to Release and parameterize account assumptions.
- Remove tracked Xcode user data and expand `.gitignore` for `xcuserdata`/user metadata.
- Normalize deployment-target policy.
- Define Debug vs Release entitlement behavior.
- Establish and document a Firebase App Check debug/simulator path.
- Make signing/team assumptions explicit rather than relying on one personal team silently.
- Document Firebase environment strategy.

#### 0.2b Clean build verification — PENDING

Tasks:

- Resolve packages from a clean checkout.
- Compile the shared `OursReader` scheme on a clean Mac/Xcode environment.
- Launch a supported simulator using the documented App Check development path.
- Record any compile/runtime blockers.

#### 0.2c Hardware/account verification — PENDING / BLOCKED

Validate when hardware/account access is available:

- APNs + FCM
- App Attest
- CloudKit
- Sign in with Apple
- App Group provisioning
- Multipeer on two devices
- iPhone ↔ Apple Watch
- TestFlight / Xcode Cloud

Exit criteria:

- A developer can follow one documented setup path from clone to build.
- Known blockers are explicit rather than implicit.
- No required setup depends on undocumented personal machine state.
- Release archive uses Release configuration.
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

Run **Phase 0.2a — Fix repository-controlled build/release blockers**.
