# Architecture Decision Records (ADRs)
## Project Name: ChronoMed
**Status:** Living Document  
**Standard:** Michael Nygard ADR Format

This document logs all consequential architectural and design decisions made for ChronoMed, capturing the context, consequences, and trade-offs of each choice.

---

## ADR-001: Discretization of Daily Timeline into 15-Minute Intervals

### Status
Accepted

### Context
Medication scheduling can mathematically be modeled in either continuous time ($t \in \mathbb{R}$, second-by-second) or discrete intervals ($t \in \mathbb{N}$). Continuous nonlinear optimization (e.g., via Mixed-Integer Linear Programming) produces high CPU overhead, floating-point rounding hazards, and non-deterministic runtimes on low-power mobile devices. Furthermore, human medication adherence in real life operates on 15-to-30-minute windows (no patient takes a pill at exactly 08:14:27 AM).

### Decision
Discretize the 24-hour day (1440 minutes) into 96 discrete 15-minute time steps:
$$D = \{ 0, 15, 30, 45, \dots, 1425 \}$$

This is implemented in `core_engine/lib/src/interval_math.dart`. All scheduling domain values (`scheduledMinute`, `actualTakenMinute`) stored in `ScheduledDose` are integer minute-of-day values aligned to this grid.

### Consequences
* **Positive:** Reduces the variable domain from $1440$ to $\le 96$ slots.
* **Positive:** Bounded search tree allows recursive backtracking with forward checking. Measured convergence: **7 ms** on desktop hardware (10 medications, 3 meals, 16-hour waking day).
* **Positive:** Clean alignment with real-world human meal and waking habits.
* **Negative:** Loss of sub-15-minute granularity (acceptable, as clinical pharmacology spacing operates on 30m, 60m, 120m, and 240m thresholds — all declared as named constants in `core_engine/lib/src/constants/clinical_buffers.dart`).

---

## ADR-002: Client-Side Pure Dart Engine & Flutter Architecture Over Cloud Python / OR-Tools

### Status
Accepted

### Context
Constraint satisfaction algorithms are traditionally implemented in Python using libraries such as Google OR-Tools or Z3. However, routing scheduling requests to a remote Python backend requires an active internet connection, introduces network latency (200–800ms), compromises patient privacy, and incurs server compute costs. Bundling a Python runtime into a mobile app (Chaquopy/Pyodide) adds 40 MB+ to bundle size and causes a 2-second boot delay.

Between Flutter and React Native, ChronoMed requires high-fidelity custom canvas rendering for the 24-hour Living Timeline and native background alarm execution from deep OS sleep (Android Doze Mode, iOS background tasks). React Native's JavaScript bridge introduces non-deterministic latency for real-time schedule recalculation — unacceptable for a clinical safety tool.

### Decision
Implement ChronoMed as a **Flutter** client (iOS, Android, Windows Desktop) with the Constraint Satisfaction Problem solver written in **Pure Dart 3.5** (`core_engine/`), compiling directly to native ARM64 machine code via Dart AOT. The `core_engine` package has **no Flutter dependency** — it is a pure Dart library that can be tested, benchmarked, and served independently.

Rejected alternatives:
- **Cloud Python + OR-Tools backend:** Requires internet, exposes PHI, adds latency.
- **React Native + JavaScript solver:** Non-deterministic bridge latency; weaker native alarm integration.
- **Embedded Python runtime (Chaquopy/Pyodide):** 40 MB+ bundle bloat; 2-second cold start.

### Consequences
* **Positive:** Ahead-of-Time (AOT) Dart compilation runs the CSP solver in **7 ms** (measured) on current hardware, well under the 100 ms NFR-2 budget.
* **Positive:** Flutter's Impeller engine renders custom timeline canvas graphics at 120 FPS without UI bridge overhead.
* **Positive:** Native Android `AlarmManager.setExactAndAllowWhileIdle()` and iOS `BGTaskScheduler` wake the device from OS sleep without waiting for a JavaScript or Python runtime.
* **Positive:** 100% offline availability; zero health data leaves the local device.
* **Positive:** The pure Dart `core_engine` package can be unit-tested in isolation (4/4 tests passing in `clinical_rules_test.dart`) and served as a web demo via the built-in Dart HTTP server (`core_engine/bin/serve_web.dart`).
* **Negative:** Cannot directly reuse solver code in a Node.js ecosystem without compiling via `dart2js` or running the Dart runtime server-side.

---

## ADR-003: SQLite with SQLCipher & Drift ORM Over NoSQL or Key-Value Stores

### Status
Accepted (Planned for Phase 3 Flutter Mobile Build)

### Context
Polypharmacy data is inherently relational: a patient has Daily Routines, Meals, and Medications. Each `Medication` record (see `core_engine/lib/src/models/medication.dart`) has multiple `PharmacokineticRule` entries and `DrugSeparationConstraint` pairs. Doses belong to a specific generated `DailyScheduleResult` and maintain a historical Dose Log.

Key-value stores (e.g., SharedPreferences, Hive) do not provide ACID guarantees or cascading relational lookups. Unencrypted SQLite databases violate HIPAA/GDPR standards for storing Protected Health Information (PHI) at rest.

**Current state (Phase 1 / Phase 2 web demo):** User and schedule data is persisted to a local `user_store.json` file by the development HTTP server (`core_engine/bin/serve_web.dart`). This is intentional for the demo/development phase only and is **not suitable for production**.

### Decision
Standardize the production Flutter mobile app on SQLite embedded with **SQLCipher** (AES-256 database-level encryption), accessed via the compile-time verified **Drift ORM** for Dart. The migration from `user_store.json` to the encrypted Drift database will be completed as part of the Phase 3 mobile persistence milestone.

### Consequences
* **Positive:** Relational integrity with foreign key enforcement and cascading deletes.
* **Positive:** Compile-time SQL query validation: syntax errors and broken schema migrations are caught by the Dart compiler before build, not at runtime.
* **Positive:** Reactive database streams (`Stream<List<Dose>>`) keep the UI timeline live without manual polling.
* **Positive:** Hardware-backed encryption key stored in iOS Keychain or Android Keystore.
* **Negative:** SQLCipher binary adds ~3 MB to the mobile bundle size (acceptable trade-off for clinical-grade security).
* **Current limitation:** The web demo (`serve_web.dart`) uses a plaintext `user_store.json` file. This is a known, intentional development-phase constraint and must be replaced before any production or clinical deployment.

---

## ADR-004: Dual-Tier Alarm Notification Strategy

### Status
Accepted

### Context
Modern mobile operating systems (iOS and Android) aggressively terminate background processes to preserve battery life. Standard Push Notifications (FCM / APNs) are silent by default when the phone is on "Do Not Disturb" (DND) or silent mode, and are frequently dismissed accidentally by elderly users.

### Decision
Implement a tiered notification architecture:
1. **Tier 1 (Flexible Supplements / Vitamins):** Standard OS local notifications.
2. **Tier 2 (Critical Prescriptions — e.g., Insulin, Blood Thinners, Thyroid, Cardiac meds):**
   * **Android:** Native `AlarmManager.setExactAndAllowWhileIdle()` coupled with `USE_FULL_SCREEN_INTENT` to display an incoming-call style interactive modal over the lockscreen.
   * **iOS:** Apple Critical Alerts entitlement with persistent high-volume audio bypassing the physical mute switch.

### Consequences
* **Positive:** Critical medication adherence increases dramatically; alarms cannot be silently ignored or killed by OS battery optimization.
* **Negative:** Requires special Android permissions (`USE_FULL_SCREEN_INTENT`, `SCHEDULE_EXACT_ALARM`) and Apple developer Critical Alert entitlement review for App Store submission.

---

## ADR-005: Stateless Caregiver Escalation Relay via QStash & WhatsApp

### Status
Accepted (Planned — Not Yet Implemented)

### Context
When an elderly patient fails to confirm a critical dose, a caregiver must be notified without requiring the caregiver to install a dedicated app or maintain an open WebSocket connection. Storing patient medical history on a central backend creates severe regulatory and compliance liabilities.

### Decision
Build a stateless cloud relay using **Upstash QStash** (serverless delayed task queue) and the **Meta WhatsApp Cloud API**. When a dose is due, the mobile device schedules a 45-minute delayed webhook containing an ephemeral, cryptographically signed token. If the dose is confirmed locally, the token is invalidated. If 45 minutes elapse without confirmation, the webhook triggers a templated WhatsApp message to the registered caregiver.

The relay server will be implemented in **FastAPI** (Python), acting as a thin, stateless message forwarder only — it stores no patient clinical data.

### Consequences
* **Positive:** Zero patient clinical data is stored in the cloud; the relay handles only opaque signed tokens.
* **Positive:** Caregivers receive notifications on the most widely used messaging app in the world (WhatsApp) with SMS fallback via Twilio.
* **Positive:** Cloud architecture is completely serverless and auto-scaling, costing \$0.00 during initial launch.
* **Negative:** Requires internet connectivity for the caregiver escalation path (the core scheduling engine remains fully offline-capable regardless).
