# ReLoop - AI-Powered Waste Decision Assistant

## Complete End-User Documentation & Project Overview

> **Version**: `0.1.6+99`
> **Status**: `In Development`
> **Scope**: Flutter app for policy-aware household disposal assistance
> **Last Updated**: 2026-08-03

## Project Overview

**ReLoop** helps users move from disposal questions to correct action with policy-aware guidance:

1. identify the item,
2. prepare it for disposal,
3. match it to the correct stream,
4. use local timing and destination guidance.

### Mission
Improve household disposal outcomes through accurate item understanding, transparent confidence handling, and location-specific operational guidance.

### Focused Product Value
- **Policy-aware guidance**: combine classification with municipal and society-level policy checks
- **Safety-first uncertainty handling**: preserve risk controls under low confidence
- **Completion orientation**: surface what the user should do next, not only what the item is

## Current Status

- Policy + confidence behavior is implemented and tested in the current branch.
- Offline queueing, queue cleanup, and temporary image handling workflows are implemented.
- Collection/timetable completion is a primary design priority and remains iterative.
- The app is not positioned as production-ready in this document; outcomes are explicitly scoped to implementation state and verified tests.

## Architecture

- Framework: Flutter / Dart
- Local data: Hive and app-local persistence
- Backend: Firebase (Auth, Firestore, Cloud Storage where enabled)
- AI stack: OpenAI model routing with fallback paths and validation gates
- Mapping: `flutter_map` with OpenStreetMap integration

## Core Workflow

1. Input: camera, gallery, barcode, or text
2. AI classification + model confidence
3. Local policy evaluation + provenance
4. Disposal action guidance (what to do, where to take it, when to do it)
5. User correction loop + optional feedback

## Core Features

### 1. AI-Assisted Waste Identification
- Multi-mode input support (capture, upload, text)
- Multi-tier fallback chain for model failure
- Confidence labels and uncertainty behavior tied to safety expectations

### 2. Policy and Authority-Aware Guidance
- City/society/local policy layers represented with provenance metadata
- Safe handling for edge and regulated categories
- Structured routing between operational instructions and compliance-oriented constraints

### 3. Education and Household Knowledge
- Structured educational content to support category understanding and correct disposal habits

### 4. Family and Shared Access
- Household-level support for shared use contexts

### 5. Offline and Retry Reliability
- Queueing for deferred uploads and operations
- Expiry and cleanup pathways for staged local artifacts

## Waste Streams and Decision Taxonomy

Current app behavior uses a policy-aware household stream framing where practical:

- Wet waste
- Dry waste
- Sanitary waste
- Special-care waste
- Unknown/mixed/needs clarification

Subflows (e.g. batteries, medicines, e-waste, domestic hazardous items, sharps) are represented where policy data is available and are surfaced in the guidance pathway with higher safety defaults.

## User Guidance Positioning

The result flow is ordered for action:

1. What is this item?
2. What preparation is required?
3. Which local stream applies?
4. Can routine collection accept it?
5. What date/time/location is next?

Where confidence is insufficient for risky disposal, the app uses conservative, non-mixing guidance and escalation prompts instead of weakening controls.

## Data, Compliance and Security Notes

- Offline queue images use OS-sandbox-protected temporary files. Hive stores only a file reference, SHA-256 content hash, byte length, and queue metadata; cleanup and expiry paths remove the temporary file.
- Sensitive decisions and policy provenance are logged in structured app/analytics flows where enabled.
- Runtime access and secret handling remain environment-driven; no hardcoded credentials.
- Security posture and policy proofs are documented in the repository security docs and tests.

## Metrics and Evidence Stance

Evidence labels used in this project documentation:

- **Measured**: directly observed in repo evidence/tests
- **Target**: implementation intent and acceptance criteria
- **Hypothesis**: planned but not yet validated

### Technical
- Policy-compliance and local-rule behavior: **Target** currently, moving toward full measured cadence
- Offline reliability and queue recovery: **Target** under ongoing verification
- AI latency and cost behavior: **Hypothesis** without one unified release benchmark payload in this document

### Product
- Retention, engagement, and conversion values in this file are **not user-retained metrics claims** unless sourced from a signed test report.

## Safety and Correctness Priorities

- Confidence asymmetry is preserved for high-risk classes (don’t demote safeguards under uncertainty).
- Authority hierarchy remains a priority for legal/safety constraints.
- User corrections are treated as learning evidence, not immediate ground truth.
- Facility/service claims are shown with source/freshness status when available.

## Environment Setup

### Prerequisites
- Flutter SDK
- Dart SDK
- Firebase CLI
- Android Studio / Xcode
- Git

### Local Setup

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

### Required Variables
- `OPENAI_API_KEY`
- `GOOGLE_DRIVE_CLIENT_ID` (where relevant)
- `FIREBASE_PROJECT_ID`

### Build

```bash
flutter run
flutter build apk --release
flutter build ios --release
flutter test
```

## Testing and Quality

- Unit tests (core business logic)
- Widget tests (UI contracts)
- Firestore rule tests (security boundaries)
- Accessibility and lint checks

Quality is treated as evidence-gated, not marketing-gated.

## Documentation Links

- `docs/reference/api_documentation/`
- `docs/security/`
- `docs/technical/architecture/`
- `docs/review/`
- `docs/reference/troubleshooting/`

## Contributing

1. Open an issue from the repository template
2. Link required tests for changed behavior
3. Keep policy and evidence claims explicit (measured/target/hypothesis)
4. Update relevant security and release notes

## Last Notes

ReLoop’s current value is strongest when framed as a **policy-aware disposal action assistant**:
identify, prepare, route, schedule, and complete disposal correctly.
The next milestones are evidence-backed schedule/pickup completion workflows and stronger municipal/RWA operator integration.
