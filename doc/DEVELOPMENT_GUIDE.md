# Developer Setup & Implementation Guide
## Project Name: ChronoMed
**Document Version:** 2.1.0  
**Target Audience:** Core Developers & Mobile Systems Engineers

> [!NOTE]
> This document reflects the **actual repository layout** as of Phase 3 completion. The root is `project1/` (not `chronomed/`). There is no `cloud_relay/` folder — it is planned for Phase 5.

---

## 1. Project Directory Structure

```
project1/                                   ← Git repository root
│
├── doc/                                    # Comprehensive Project Documentation
│   ├── README.md                           # Master Documentation Hub
│   ├── PRD.md                              # Product Requirements Document
│   ├── HLD.md                              # High-Level Architecture & System Topology
│   ├── LLD.md                              # Low-Level Design & Data Models
│   ├── TECH_STACK.md                       # Technology Stack & Rationales
│   ├── ADR.md                              # Architecture Decision Records
│   ├── API_AND_EVENTS.md                   # API Contracts, Event Schemas & Error Codes
│   ├── SECURITY_AND_COMPLIANCE.md          # HIPAA/GDPR, Threat Modeling & Key Management
│   ├── RULES_AND_GUARDRAILS.md             # Clinical Guardrails & Production Standards
│   └── DEVELOPMENT_GUIDE.md               # This Implementation Guide
│
├── core_engine/                            # Pure Dart scheduling package (no Flutter dependency)
│   ├── lib/
│   │   └── src/
│   │       ├── models/                     # Immutable Dart domain models
│   │       │   ├── meal.dart               # MealAnchor, MealType enum
│   │       │   ├── medication.dart         # Medication
│   │       │   ├── pharmacokinetic_rule.dart # PharmacokineticRule, DrugSeparationConstraint
│   │       │   ├── routine.dart            # Routine
│   │       │   └── schedule_result.dart    # DailyScheduleResult (sealed), ScheduledDose, DoseStatus
│   │       ├── constants/
│   │       │   └── clinical_buffers.dart   # Clinical buffer constants (FDA citations)
│   │       ├── csp_solver.dart             # Core Backtracking Constraint Solver (~7 ms)
│   │       ├── dynamic_recalibrator.dart   # Shift & late-dose forward re-solver
│   │       └── interval_math.dart          # Minute-of-day interval algebra
│   ├── bin/
│   │   ├── serve_web.dart                  # Development REST server + Clinical Studio UI
│   │   └── run_simulation.dart             # CLI simulation runner
│   ├── data/
│   │   └── user_store.json                 # Current JSON disk persistence (Phases 1–3)
│   └── test/
│       └── clinical_rules_test.dart        # Verification of FDA spacing rules
│
├── clinical_data/                          # Drug knowledge base (separate Dart package)
│   ├── data/
│   │   └── top_50_drugs.json               # Pharmacokinetic metadata for top 50 drugs
│   └── lib/
│       └── src/
│           └── drug_registry.dart          # DrugRegistry — lookup & search API
│
├── app/                                    # Flutter mobile app (Phase 4 — In Progress)
│   ├── lib/
│   │   ├── main.dart                       # App entrypoint
│   │   ├── core/                           # Platform bridges (DB, alarms, theme)
│   │   └── features/                       # Feature-first UI modules
│   └── pubspec.yaml
│
└── README.md
```

> [!NOTE]
> **`cloud_relay/` does not exist yet.** The caregiver escalation microservice is planned for Phase 5.

---

## 2. How to Run

### Web Demo Server (Clinical Studio UI)

Starts the development server. The full Clinical Studio browser UI is served at `http://localhost:8080`. The REST API described in `API_AND_EVENTS.md` is available on the same port.

```powershell
cd core_engine
dart run bin/serve_web.dart
# → Listening on http://localhost:8080
```

### CLI Simulation

Runs a headless schedule simulation and prints the result to stdout. Useful for verifying the solver output without a browser.

```powershell
cd core_engine
dart run bin/run_simulation.dart
```

### Run All Tests

```powershell
cd core_engine
dart test
```

---

## 3. Core Implementation Phases

### Phase 1: Pure Dart Mathematical Core (`core_engine`) — ✅ COMPLETE

**Deliverable:** A zero-dependency Dart package that compiles directly to native AOT machine code.

1. **Domain Models & Constants (`lib/src/models/`):**
   - Immutable pure-Dart classes: `Routine`, `MealAnchor`, `Medication`, `PharmacokineticRule`, `DrugSeparationConstraint`, `ScheduledDose`.
   - Exported clinical constants in `constants/clinical_buffers.dart` (FDA-cited minimum separations, fasting buffers, etc.).

2. **Interval Algebra (`lib/src/interval_math.dart`):**
   - Pure functions operating strictly in integer minute-of-day space ($0 \le t \le 1439$):
     - `bool isWithinFastingWindow(int minute, List<MealAnchor> meals)`
     - `bool satisfiesSeparationDistance(int tA, int tB, int requiredGap)`

3. **CSP Solver (`lib/src/csp_solver.dart`):**
   - Discretizes waking hours into 15-minute intervals (≤ 96 slots).
   - Orders variables using Minimum Remaining Values (MRV) heuristic.
   - Recursive backtracking search with forward-checking domain pruning.
   - **Measured: ~7 ms for a standard 5–10 medication regimen.**

4. **Dynamic Recalibrator (`lib/src/dynamic_recalibrator.dart`):**
   - Handles the *"I overslept / took it late"* scenario.
   - Locks historical doses as immutable constraints; solves for minimum perturbation of remaining doses.

---

### Phase 2: Drug Knowledge Base (`clinical_data`) — ✅ COMPLETE

**Deliverable:** A standalone Dart package providing an offline drug registry.

1. **`data/top_50_drugs.json`:** Pharmacokinetic metadata for the 50 most commonly prescribed medications — food requirements, circadian preferences, and separation constraints.
2. **`lib/src/drug_registry.dart`:** `DrugRegistry` class exposing lookup and fuzzy search over the JSON dataset.

---

### Phase 3: Web Demo Server (`core_engine/bin/serve_web.dart`) — ✅ COMPLETE

**Deliverable:** A single-command development server delivering the Clinical Studio UI and REST API.

1. Serves the full browser-based **Clinical Studio** HTML application at `GET /`.
2. Exposes the 8 REST endpoints documented in `API_AND_EVENTS.md § 2`.
3. Persists state to `core_engine/data/user_store.json` (plain JSON on disk).

---

### Phase 4: Flutter Mobile App + SQLCipher (`app/`) — 🔄 IN PROGRESS

**Deliverable:** A production-grade mobile application with encrypted local storage.

1. **Drift ORM Tables (`app/lib/core/database/`):**
   - Define `UserRoutines`, `UserMeals`, `UserMedications`, `ScheduledDoses`, `CaregiverContacts`.
   - Column names match the planned schema in `LLD.md § 6`.
2. **SQLCipher Integration:**
   - Link `sqlcipher_flutter_libs` to encrypt the database file with AES-256.
   - Encryption key retrieved from `flutter_secure_storage` (Android Keystore / iOS Keychain).
3. **Reactive Streams:**
   - Expose `Stream<List<ScheduledDose>> watchTodayDoses()` to automatically re-render the timeline when a dose status changes.
4. **24-Hour Living Timeline (`app/lib/features/timeline/`):**
   - `CustomPainter`-based canvas timeline rendered via Flutter's Impeller engine.
   - 🟢 Green Bands: Safe food/beverage windows.
   - 🟠 Orange Indicators: Medication scheduled targets.
   - 🔴 Red Bands: Fasting / no-snack windows.
5. **Proactive Alarms:**
   - Android `AlarmManager` full-screen intent for lockscreen alerts.
   - iOS Critical Alerts for do-not-disturb bypass.

---

### Phase 5: Cloud Relay + Caregiver Escalation — 📋 PLANNED

**Deliverable:** A stateless microservice for asynchronous caregiver notifications.

1. The 45-minute safety watcher registers a delayed job (Upstash QStash) when a critical dose is due.
2. If the patient confirms locally within 45 minutes → cancel the job.
3. If 45 minutes elapse → QStash fires webhook → Meta WhatsApp Cloud API messages the caregiver.
4. Caregiver inbound replies (e.g., "Handled") processed via `POST /v1/webhooks/whatsapp/inbound`.

See `API_AND_EVENTS.md § 3` for the full planned endpoint specification.

---

## 4. Developer Verification Checklist (Definition of Done)

Before opening any Pull Request (PR):

- [ ] **No Generative AI in Core:** Zero LLM calls in `core_engine/` scheduling logic. The CSP solver must remain purely deterministic.
- [ ] **Deterministic Unit Tests:** 100% pass rate on all clinical rule test suites (`dart test`).
- [ ] **No Magic Numbers:** All time intervals reference exported clinical constants in `constants/clinical_buffers.dart` with FDA citations.
- [ ] **Performance Pass:** CSP Solver executes in ≤ 15 ms for a 10-drug regimen (current measured baseline is ~7 ms).
- [ ] **Strict Sound Null Safety:** Zero `dynamic` or untyped structures in Dart. All fields match exact names from `lib/src/models/`.
- [ ] **Offline Verification:** Server starts, loads `user_store.json`, and returns a valid schedule via `GET /api/state` with no external network calls.
