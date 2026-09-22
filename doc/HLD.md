# High-Level Architecture (HLD) & System Topology
## Project Name: ChronoMed
**Document Version:** 2.0.0
**Status:** Approved for Engineering Implementation
**Last Updated:** 2026-09-22

---

## 0. Current Implementation Status

> **This section reflects the actual, measured state of the codebase as of document revision date.**

```
+---------------------------------------------------------------------+
|                 CHRONOMED BUILD STATUS DASHBOARD                    |
+---------------------------------------------------------------------+
|  ✅  BUILT      Core Engine (CSP Solver, Recalibrator, Interval Math)|
|  ✅  BUILT      Drug Registry (50 FDA Drugs, sub-1ms lookup)         |
|  ✅  BUILT      Web Demo Server (Dart HTTP, Clinical Studio UI)       |
|  🔄  IN PROGRESS  Flutter Mobile App (skeleton exists)               |
|  📋  PLANNED    SQLCipher Encrypted Persistence (Drift ORM)          |
|  📋  PLANNED    Cloud Relay / WhatsApp / Caregiver Escalation        |
+---------------------------------------------------------------------+
```

| Package / Component | Status | Location | Notes |
|---|---|---|---|
| `core_engine` | ✅ **COMPLETE** | `core_engine/` | Pure Dart 3.5, zero ext. deps. 4/4 tests passing. CSP Solver: **7ms measured**. |
| `clinical_data` | ✅ **COMPLETE** | `clinical_data/` | 50 FDA drug profiles, `DrugRegistry` class, sub-1ms lookup. 4/4 tests passing. |
| Web Demo Server | ✅ **COMPLETE** | `core_engine/bin/serve_web.dart` | Full-stack Dart HTTP server on port 8080. Serves Clinical Studio UI + REST APIs. |
| Flutter Mobile App | 🔄 **IN PROGRESS** | `app/` | Flutter 3.24 skeleton. Riverpod, Drift ORM, and SQLCipher integration pending. |
| SQLCipher Persistence | 📋 **PLANNED** | `app/` | Drift ORM + SQLCipher (AES-256). Replaces current JSON file persistence. |
| Cloud Relay | 📋 **PLANNED** | External microservice | Stateless FastAPI or Node.js. WhatsApp Cloud API + Twilio SMS + Upstash QStash. |

---

## 1. 10,000-Foot Executive System Architecture

ChronoMed is designed as an **Edge-First, Privacy-Preserving, Event-Driven Platform**.

The core clinical intelligence and mathematical solver reside **100% on the user's physical device**, written in **Pure Dart 3.5**, compiled to native ARM64 machine code via Dart's AOT compiler. The cloud infrastructure exists solely as a stateless communication relay for asynchronous external channels (WhatsApp, Caregiver SMS, and optional encrypted backup).

```
+=============================================================================+
|                       EDGE LAYER (USER'S DEVICE)                            |
|                                                                             |
|   +---------------------------------------------------------------------+   |
|   |                        PRESENTATION LAYER                           |   |
|   |   - Interactive Daily Living Timeline UI (Flutter)                  |   |
|   |   - Lockscreen Full-Screen Intent Alarm Overlay                     |   |
|   |   - Prescription Camera Scanner (Google ML Kit OCR)                 |   |
|   +-----------------------------------+---------------------------------+   |
|                                       |                                     |
|   +-----------------------------------v---------------------------------+   |
|   |          CORE DETERMINISTIC ENGINE — Pure Dart 3.5 AOT Native       |   |
|   |   - Constraint Satisfaction Solver   (csp_solver.dart)              |   |
|   |     Package: core_engine  |  Measured latency: 7ms                 |   |
|   |   - Dynamic Recalibrator / Forward-Shift Solver                     |   |
|   |     (dynamic_recalibrator.dart)                                     |   |
|   |   - Local Interval Algebra Math  (interval_math.dart)               |   |
|   |     Domain: 0–1439 minute-of-day discrete space                     |   |
|   |   - Drug Knowledge Base  (clinical_data / top_50_drugs.json)        |   |
|   |     50 FDA Profiles  |  DrugRegistry class  |  sub-1ms lookup      |   |
|   +-----------------------------------+---------------------------------+   |
|                                       |                                     |
|   +-----------------------------------v---------------------------------+   |
|   |                     LOCAL DATA & HARDWARE LAYER                     |   |
|   |   [Current]  JSON file persistence  (data/user_store.json)          |   |
|   |   [Planned]  Encrypted SQLite via Drift ORM + SQLCipher (AES-256)  |   |
|   |   [Planned]  Native AlarmManager / iOS AlarmKit                     |   |
|   +-----------------------------------+---------------------------------+   |
|                                                                             |
|   +---------------------------------------------------------------------+   |
|   |              WEB DEMO SERVER (Dev / Demo Only)                      |   |
|   |   core_engine/bin/serve_web.dart  — pure Dart HTTP on port 8080    |   |
|   |   Serves: Dark-theme 3-panel Clinical Studio UI (HTML/CSS/JS)       |   |
|   |   REST APIs: /api/state, /api/dose/toggle, /api/medication/add,    |   |
|   |              /api/medication/delete, /api/routine/update,           |   |
|   |              /api/search, /api/sim/overslept, /api/sim/reset       |   |
|   |   Persistence: data/user_store.json  (JSON file, disk)             |   |
|   +---------------------------------------------------------------------+   |
+===========================================|=================================+
                                            | (HTTPS / TLS 1.3 — Stateless,
                                            |  PLANNED — not yet deployed)
                                            v
+=============================================================================+
|                  CLOUD & RELAY LAYER (OPTIONAL — PLANNED)                   |
|                                                                             |
|   +---------------------------------------------------------------------+   |
|   |             API GATEWAY & NOTIFICATION RELAY (Stateless)            |   |
|   |   - FastAPI (Python) or Node.js Micro-Gateway                       |   |
|   |   - Scheduled Delayed Job Queue (Upstash QStash)                    |   |
|   +-------------------+-----------------------------+-------------------+   |
|                       |                             |                       |
|                       v                             v                       |
|     +----------------------------+   +----------------------------+         |
|     |     CAREGIVER GATEWAY      |   |   PHARMACOLOGY DATA SYNC   |         |
|     |  - Twilio (SMS Fallback)   |   |  - NIH RxNorm REST API     |         |
|     |  - Meta WhatsApp Business  |   |  - DailyMed / OpenFDA      |         |
|     |    Cloud API               |   |    Monthly Update Worker   |         |
|     +----------------------------+   +----------------------------+         |
+=============================================================================+
```

> **⚠️ Important:** The Cloud & Relay Layer is **architecturally planned but not yet implemented**. All current functionality runs fully on-device. The web demo server (`serve_web.dart`) provides a browser-based development interface to the same core Dart engine.

---

## 2. Core Architectural Principles

### 2.1 The "Airplane Mode" Guarantee
If a user loses all network connectivity (airplane mode, rural travel, basement clinic, or power outage):
* The daily timeline still displays.
* Alarms and reminders still fire with 100% precision.
* The "I woke up late" recalibration solver executes in **7ms** (measured; design target: <30ms).
* Doses can be logged and stored locally.

**This is guaranteed by design:** the Core Engine is Pure Dart AOT native, with zero network dependencies. The `DrugRegistry` runs entirely from an on-device JSON file.

### 2.2 Zero-Knowledge Health Privacy
* No clinical data (drug names, dosages, disease indications) is stored in unencrypted plain text in the cloud.
* All computation runs in-process on the user's device (current: in-memory + JSON file; planned: AES-256 SQLCipher).
* If cloud backup is enabled (planned), the database is encrypted client-side using a key derived from the user's master password before leaving the device.

### 2.3 Technology Stack Purity
The ChronoMed core engine is **Pure Dart 3.5** — no TypeScript, no WebAssembly, no Python in the solving path. Dart compiles to native ARM64 machine code via AOT compilation, delivering sub-10ms solver latency directly on mobile CPUs without a JavaScript bridge or interpreter.

---

## 3. End-to-End System Data Flows

```
+-----------------------------------------------------------------------------+
| FLOW A: MEDICATION INGESTION & CLINICAL RULE EXTRACTION                     |
+-----------------------------------------------------------------------------+

[User Scans Label]
        |
        v
 (Google ML Kit — on-device, 100% offline, hardware NPU-accelerated)
        |
        v  Extracts string: "Levothyroxine 50 mcg"
 (Local Dart Rule Matcher — DrugRegistry.lookup())
        |
        +--> Match against clinical_data/top_50_drugs.json  (sub-1ms lookup)
        |
        +--> If missing: Query NIH RxNav API (https://rxnav.nlm.nih.gov)
        |
        v
 [Planned: Store in Drift ORM / SQLCipher]
 [Current: Persist to data/user_store.json via web demo server]
        - Medication Record: ID, Name, Dosage
        - Attached Rules: Empty Stomach (Pre 60m, Post 120m),
          Chelation Matrix (Calcium >= 240m, Iron >= 240m)
```

```
+-----------------------------------------------------------------------------+
| FLOW B: DYNAMIC TIMELINE GENERATION & ALARM SCHEDULING                      |
+-----------------------------------------------------------------------------+

[User Routine Input] (Wake: 07:00, Breakfast: 08:30, Lunch: 13:00, Sleep: 23:00)
        |
        v
[ChronoMed CSP Solver — csp_solver.dart, Pure Dart 3.5, 7ms measured]
        | Discretizes domain into 15-min intervals (96 slots, 0–1439 min-of-day)
        | Applies Hard Clinical Rules (Empty stomach, Chelation separation)
        | Optimizes for lifestyle adherence (Wake time, meal proximity)
        v
[Schedule Output] (07:00: Thyroid, 08:30: Metformin, 15:30: Calcium)
        |
        +--> Render Living Timeline on UI (Green/Orange/Red bands)
        |    [Current: Clinical Studio via serve_web.dart]
        |    [Planned: Flutter CustomPainter / Impeller GPU canvas]
        |
        +--> [Planned] Schedule Native System Alarms
             (Android AlarmManager / iOS AlarmKit)
```

```
+-----------------------------------------------------------------------------+
| FLOW C: THE "I OVERSLEPT" DYNAMIC RECALIBRATION FLOW                        |
+-----------------------------------------------------------------------------+

[User Wakes at 09:30 AM (2.5h late)]
        |
        v  User taps "Just Woke Up" or marks Morning Pill taken at 09:35 AM
           [Current: POST /api/sim/overslept via Clinical Studio web UI]
           [Planned: Flutter UI gesture on mobile app]
[Dynamic Recalibrator — dynamic_recalibrator.dart, Pure Dart 3.5]
        |
        | 1. Lock past events (historical logs immutable)
        | 2. Set T_actual = 09:35 AM as a fixed constraint
        | 3. Detect downstream conflicts:
        |    - Breakfast now blocked until 10:35 AM (Fasting rule)
        |    - Afternoon Calcium must move to 13:35 + 4h = 17:35 PM
        | 4. Run Minimum Perturbation Local Solver (Dart, in-process)
        v
[Updated Schedule Applied]
        |
        +--> Update Live UI Timeline
        +--> [Planned] Re-arm Local Native Alarms with revised timestamps
        +--> Push Delta Toast: "Breakfast safe at 10:35 AM. Calcium moved to 05:35 PM."
```

```
+-----------------------------------------------------------------------------+
| FLOW D: PROACTIVE CAREGIVER SAFETY ESCALATION FLOW   [PLANNED]              |
+-----------------------------------------------------------------------------+

[Alarm Fires at 08:30 AM for Heart/BP Medication]
        |
        v
[Local Dart Background Timer — 45-minute countdown]
        |
        +--> If User taps [TAKEN]: Timer canceled. Log written. Done.
        |
        +--> If 45 Minutes elapse with NO RESPONSE:
                  |
                  v
              [Dispatch Escalation Event — outbound HTTPS]
                  | Payload: { userId, doseId, medName, scheduledTime }
                  v
              [Cloud Notification Relay — FastAPI or Node.js, stateless]
                  |
                  +--> Meta WhatsApp Cloud API -> Sends template message to Caregiver
                  |
                  +--> Fallback: Twilio SMS -> "Papa has not confirmed 08:30 AM BP dose."
```

> **Note on Flow D:** The entire on-device logic (timer, local alarm) is implemented in **Dart**. The cloud relay component (FastAPI/Node.js) is a thin stateless forwarder and holds zero patient data. This component is not yet built.

---

## 4. Subsystem Breakdown

### 4.1 Client Presentation Layer (`app/`)
* **Technology:** **Flutter 3.24+** (Dart 3.5, Impeller Rendering Engine)
* **Status:** 🔄 In Progress — skeleton application exists
* **Responsibilities:**
  * Render the 24-hour vertical Living Timeline gauge via Flutter `CustomPainter`.
  * Native module for Android `USE_FULL_SCREEN_INTENT` (wake screen over lockscreen for high-priority doses).
  * On-device camera feed processing using Google ML Kit (planned OCR integration).
  * State management via **Riverpod** (planned).

### 4.2 Core Domain Engine (`core_engine/`)
* **Technology:** **Pure Dart 3.5 AOT Native** — zero external dependencies except `meta: ^1.11.0`
* **Status:** ✅ Complete — 4/4 tests passing
* **Key files:**
  * `lib/csp_solver.dart` — Constraint Satisfaction solver. Measured latency: **7ms**.
  * `lib/dynamic_recalibrator.dart` — Minimum-perturbation recalibration on routine disruption.
  * `lib/interval_math.dart` — Interval algebra over discrete 0–1439 minute-of-day space.
* **Responsibilities:**
  * Mathematical model: Interval algebra and discrete backtracking search.
  * Validation: Deterministic verification that no FDA contraindication is violated.
  * Conflict Isolation: Identifying the Minimal Unsatisfiable Subset (MUS) when schedules are mathematically infeasible.

### 4.3 Drug Knowledge Base (`clinical_data/`)
* **Technology:** Pure Dart 3.5. Offline JSON data file.
* **Status:** ✅ Complete — 4/4 tests passing
* **Key files:**
  * `data/top_50_drugs.json` — 50 FDA drug profiles with clinical constraint rules.
  * `DrugRegistry` class — sub-millisecond keyed lookup for drug interactions and constraints.
* **Responsibilities:**
  * Provide authoritative clinical rules (empty stomach windows, chelation separation) to the CSP Solver.
  * Serve as the offline fallback when NIH RxNav is unreachable.

### 4.4 Web Demo Server (`core_engine/bin/serve_web.dart`)
* **Technology:** Pure Dart 3.5 HTTP server (using `dart:io` `HttpServer`)
* **Status:** ✅ Complete — serves the Clinical Studio development UI
* **Purpose:** Bridges Phase 2 (core engine complete) and Phase 4 (Flutter app in progress). Allows the full scheduling engine to be exercised via a browser without a mobile device.
* **Responsibilities:**
  * Serve a dark-theme 3-panel Clinical Studio web UI (HTML/CSS/JS) on port 8080.
  * Expose REST APIs consumed by the UI (and testable via `curl` or Postman):
    * `GET  /api/state` — Retrieve full application state
    * `POST /api/dose/toggle` — Mark a dose taken/untaken
    * `POST /api/medication/add` — Add a new medication to the registry
    * `POST /api/medication/delete` — Remove a medication
    * `POST /api/routine/update` — Update wake/meal/sleep routine anchors
    * `GET  /api/search` — Search the drug knowledge base
    * `POST /api/sim/overslept` — Simulate the "I overslept" recalibration scenario
    * `POST /api/sim/reset` — Reset the simulation to default state
  * Persist application state to `data/user_store.json` (JSON file on disk).

### 4.5 Persistence Layer — Current & Planned
| Phase | Technology | Status |
|---|---|---|
| **Current (Demo)** | `data/user_store.json` — plain JSON on disk | ✅ In use via `serve_web.dart` |
| **Planned (Production)** | Drift ORM + SQLCipher (AES-256) | 📋 Planned for Flutter mobile app |

### 4.6 External Communication Gateway (`notification-service`) — Planned
* **Technology:** Lightweight FastAPI (Python) **or** Node.js — stateless serverless function on AWS Lambda / Google Cloud Run
* **Status:** 📋 Planned — not yet implemented
* **Responsibilities:**
  * Receive escalation webhooks from devices (outbound HTTPS from Dart client).
  * Format and dispatch templated WhatsApp and SMS messages to caregivers.
  * Zero persistent storage of patient medical history on the server.
  * Delayed job scheduling via Upstash QStash (45-minute caregiver escalation timer).

---

## 5. Security & Boundary Matrix

| Component | Network Access Required? | PII / Medical Data Exposed? | Encryption Method | Status |
|---|---|---|---|---|
| **Core CSP Solver** (`csp_solver.dart`) | ❌ No (100% Offline) | ❌ In-Memory Only | Ephemeral RAM | ✅ Built |
| **Dynamic Recalibrator** | ❌ No (100% Offline) | ❌ In-Memory Only | Ephemeral RAM | ✅ Built |
| **DrugRegistry** | ❌ No (Offline JSON) | ❌ Static rule data only | N/A | ✅ Built |
| **Demo Persistence** (`user_store.json`) | ❌ No | ✅ Yes (Stored locally, plaintext) | None (dev only) | ✅ Built |
| **Production SQLite DB** (Drift + SQLCipher) | ❌ No | ✅ Yes (Stored locally) | SQLCipher AES-256 | 📋 Planned |
| **Label Scanner (OCR)** | ❌ No (ML Kit on-device) | ❌ Ephemeral Frame | None (In-memory buffer) | 📋 Planned |
| **Notification Relay** | ✅ Yes (Outbound HTTPS) | ⚠️ Minimal (Sanitized Event) | TLS 1.3 In-Transit | 📋 Planned |
| **WhatsApp/SMS Gateway** | ✅ Yes | ⚠️ Caregiver Phone Number only | TLS 1.3 In-Transit | 📋 Planned |

---

## 6. Resilience & Fault Tolerance Strategy

1. **Offline-First by Design:**
   * The `core_engine` package has zero network calls. The entire CSP solving, recalibration, and drug lookup path is 100% offline and executes deterministically in native Dart AOT code.

2. **Dead Battery / Phone Reboot Recovery (Planned):**
   * On device boot (`BOOT_COMPLETED` intent on Android), a startup service queries the local Drift/SQLCipher database and re-registers all pending `AlarmManager` alarms for the remainder of the day.

3. **Server Outage Grace (Planned):**
   * If the cloud notification relay is down, the user's device continues to ring local audio alarms and display lockscreen banners unaffected. Only the secondary caregiver SMS is queued for retry.

4. **Database Corruption Protection (Planned):**
   * SQLite Write-Ahead Logging (`WAL` mode) enabled to prevent corruption during sudden device shutdowns.

5. **Demo Server Statefulness:**
   * The `serve_web.dart` demo server writes `data/user_store.json` atomically after each mutation. On server restart, state is fully restored from this file.

---

## 7. Package Dependency Map

```
core_engine/
  pubspec.yaml:
    dependencies:
      meta: ^1.11.0        # Only external dependency — Dart annotations

clinical_data/
  pubspec.yaml:
    dependencies:
      (zero external dependencies — pure Dart + bundled JSON)

app/ (Flutter)
  pubspec.yaml: (planned)
    dependencies:
      flutter_riverpod: ^2.5+
      drift: ^2.x
      sqlcipher_flutter_libs: ^x.x
      android_alarm_manager_plus: ^x.x
      flutter_local_notifications: ^x.x
      google_mlkit_text_recognition: ^x.x
```

---

## 8. Architectural Decision Records (ADRs)

| # | Decision | Rationale |
|---|---|---|
| ADR-001 | **Pure Dart AOT for core engine** — no TypeScript, no WebAssembly | Native ARM64 compilation delivers measured 7ms solver latency with zero JS bridge overhead. Dart's sealed classes model clinical states exhaustively at compile time. |
| ADR-002 | **Flutter (not React Native)** for mobile | Impeller rendering engine (Vulkan/Metal) enables 120 FPS custom canvas timeline with zero platform bridge. Single codebase, full native performance. |
| ADR-003 | **Edge-First architecture** — cloud relay is optional | HIPAA alignment, offline guarantee, zero cloud compute cost for core scheduling. Cloud only touches sanitized event payloads for caregiver escalation. |
| ADR-004 | **Drift ORM + SQLCipher** for production persistence | Compile-time SQL validation, reactive `Stream<List<Dose>>` for live UI updates, AES-256 encryption at rest for PHI compliance. |
| ADR-005 | **Stateless cloud relay** (FastAPI/Node.js) for caregiver notifications | Relay holds zero patient data. Receives sanitized event payload, dispatches to WhatsApp/Twilio, returns. No database, no session. |
| ADR-006 | **JSON file persistence for demo server** | Minimal-friction development bridge. `serve_web.dart` is not a production component — it demonstrates the core engine to stakeholders while the Flutter app is built. |
