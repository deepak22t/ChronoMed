# Product Requirements Document (PRD)
## Project Name: ChronoMed
**Document Version:** 1.1.0  
**Status:** Approved for Development  
**Target Platform:** Mobile-first Flutter (iOS, Android, Windows Desktop) & Web Demo

---

## Phase 0: Development Status (Updated 2026-09-22)

| Phase | Scope | Status |
|---|---|---|
| **Phase 1 — Core CSP Engine** | Pure Dart constraint solver, clinical rules, drug registry | ✅ **COMPLETE** |
| **Phase 2 — Flutter Mobile App** | UI, notifications, OCR, local persistence | 🔄 In Progress |
| **Phase 3 — V2 Ecosystem** | Caregiver relay, cloud features, wearables | 📋 Planned |

> [!NOTE]
> **Phase 1 verification:** All 4 unit tests in `clinical_rules_test.dart` and all 4 tests in `drug_registry_test.dart` are **PASSING**. The CSP solver converges in a measured **7 ms** on desktop hardware. The clinical knowledge base covers 50 FDA drug profiles with full pharmacokinetic rules (`clinical_data/data/top_50_drugs.json`).

---

## 1. Executive Summary
**ChronoMed** is a clinical-grade, constraint-satisfaction medication and nutrition choreographer. Unlike traditional medication reminder apps that operate as simple static alarm clocks, ChronoMed models polypharmacy as a mathematical constraint satisfaction problem (CSP). It synchronizes multi-drug regimens with real-world patient lifestyles (meals, beverages, circadian rhythm, delayed awakenings) to maximize drug bioavailability, prevent dangerous chelation/interaction events, and eliminate patient cognitive overload.

---

## 2. Core Problem & Market Reality
### 2.1 The Problem
- **Polypharmacy Complexity:** Over 40% of older adults take 5 or more prescription drugs daily.
- **Critical Bioavailability Loss:** Taking drugs like Levothyroxine or Ciprofloxacin within 4 hours of calcium, iron, or magnesium reduces absorption by up to 80%, causing silent treatment failure.
- **The "Alarm Fatigue" Failure Mode:** Existing reminder apps (Apple Health, Medisafe) send uncoordinated static alarms. When a user wakes up 2 hours late or reschedules breakfast, existing apps cannot recompute downstream dependent doses, leading patients to either skip doses or ingest conflicting medications simultaneously.
- **Caregiver Blindspot:** Family caregivers have zero visibility into whether elderly relatives actually consumed their morning doses or just dismissed a phone notification.

### 2.2 Target Personas
1. **The Multi-Chronic Patient ("Sarah", 54):** Manages hypothyroidism, osteopenia, diabetes, and GERD. Struggles daily to space thyroid medication, calcium, coffee, and meals.
2. **The Stressed Family Caregiver ("Raj", 32):** Manages medications for an aging parent living independently. Needs passive verification that critical cardiac/BP drugs were taken without calling 5 times a day.
3. **The Neurodivergent / Brain-Fog Patient ("Alex", 28):** Experiences executive dysfunction (ADHD/Lupus/Long-COVID) and needs zero-friction, proactive reminders rather than complex app navigation.

---

## 3. Goals & Success Metrics
### 3.1 Primary Goals
- **Zero Accidental Chelation:** Eliminate co-administration of conflicting multivalent cations and target medications.
- **Dynamic Recalibration in <100ms:** Recalculate full-day timelines instantly when routine shifts occur.
- **Proactive Delivery:** Ensure >90% notification engagement without requiring the user to manually open the app.

### 3.2 Key Performance Indicators (KPIs)
- **Adherence Rate:** Increase user on-time medication compliance from ~50% baseline to >85%.
- **Recalibration Usage:** Measure percentage of successful schedule recoveries after missed/delayed doses.
- **Zero Clinical Collisions:** 100% adherence to hard FDA contraindication guidelines in all generated timelines.

---

## 4. User Journeys
### Journey 1: Initial Setup (Onboarding)
1. User enters typical daily anchors: Wake time (e.g., 07:00 AM), Breakfast (08:30 AM), Lunch (01:00 PM), Dinner (07:30 PM), Sleep (11:00 PM).
2. User adds medications via camera label scan (OCR) or search.
3. System fetches standardized RxCUI and pharmacokinetic rules (e.g., empty stomach, food requirement, chelation spacing).
4. System computes and displays the baseline **Optimal Daily Choreography**.

### Journey 2: The Delayed Morning ("I Overslept")
1. User wakes up at 09:30 AM instead of 07:00 AM.
2. User taps single lockscreen button: *"Just Woke Up"* or marks morning pill taken at 09:35 AM.
3. Engine runs localized forward-shift:
   - Recalculates safe Breakfast window (10:35 AM+).
   - Shifts afternoon Calcium/Iron to maintain mandatory 4-hour spacing.
   - Emits revised notification timeline.

### Journey 3: Proactive Caregiver Safety Net
1. User receives full-screen alarm at 08:30 AM for Blood Pressure medication.
2. No response logged by 09:15 AM (45-minute grace threshold).
3. System triggers automated secondary alert to designated caregiver via SMS/WhatsApp: *"Papa has not confirmed morning BP dose."*

---

## 5. Functional Requirements (FR)

### Module A: Routine & Habit Profiler
- **FR-A1:** User can define weekday and weekend routines (Wake, Breakfast, Lunch, Dinner, Bedtime).
- **FR-A2:** User can log beverage habits (Coffee/Tea timing, Alcohol consumption).
- **FR-A3:** User can adjust meal times dynamically for a specific day without altering default profile.

### Module B: Medication & Clinical Knowledge Ingestion
- **FR-B1:** Medication lookup supporting brand names, generics, and National Drug Codes (NDC).
- **FR-B2:** Automated categorization of clinical constraints:
  - `REQUIRES_EMPTY_STOMACH` (Fasting buffer: $\ge 60$m before food OR $\ge 120$m after food).
  - `REQUIRES_FOOD` (Prandial buffer: $0$ to $30$m post-meal).
  - `SEPARATION_REQUIRED` (Bilateral minimum time gap between drug pairs, e.g., 240m).
  - `CIRCADIAN_PREFERENCE` (Morning 06:00–10:00, Evening 18:00–21:00, Bedtime 21:00–23:30).
  - `FOOD_INTERACTION_FLAG` (e.g., Avoid Grapefruit, Avoid High-Potassium substitutes).

### Module C: Constraint Satisfaction Engine
- **FR-C1:** Deterministic mathematical solver generating minute-level schedules.
- **FR-C2:** Support for Hard Constraints (non-negotiable safety rules) and Soft Constraints (user lifestyle preferences).
- **FR-C3:** Unresolvable Conflict Detection: If medication count/spacing exceeds waking hours, system **must not** guess. It must emit an explicit clinical alert explaining the exact bottleneck.

### Module D: Proactive Notification & Escalation
- **FR-D1:** Android Full-Screen Intent / iOS Critical Alerts for high-priority medications.
- **FR-D2:** Actionable notification triggers: `[Taken Now]`, `[Snooze 15m]`, `[Eating Now]`.
- **FR-D3:** Automated WhatsApp/SMS webhook integration for zero-app-interaction logging.
- **FR-D4:** Caregiver escalation trigger after configurable timeout (default: 45 minutes).

### Module E: Visual & Printable Choreography
- **FR-E1:** Color-coded daily timeline displaying "Safe Eating Windows" vs "Fasting / Pill Windows".
- **FR-E2:** One-click generation of high-contrast printable PDF schedule ("Fridge Sheet") for elderly patients.

---

## 6. Non-Functional Requirements (NFR)
- **NFR-1 (Zero Hallucination):** No generative AI / LLM shall ever participate in calculating dose timing or determining drug-drug interactions. All scheduling must be 100% deterministic code.
- **NFR-2 (Performance):** Timeline calculation must execute in $<100$ milliseconds on mobile hardware. The current Phase 1 CSP solver benchmarks at **7 ms** on desktop.
- **NFR-3 (Offline-First):** All core scheduling and alarm logic must function with zero active internet connection.
- **NFR-4 (Privacy & Security):** The current web demo (`core_engine/bin/serve_web.dart`) persists user data to a local `user_store.json` file for development purposes only. Production Flutter builds (Phase 3) will store all health data in an encrypted SQLite database via **SQLCipher** (AES-256), with keys stored in the platform Keychain/Keystore. Zero transmission of patient-identifiable clinical data to third-party tracking services.
- **NFR-5 (Accessibility):** WCAG 2.1 AA compliance, minimum 48×48dp touch targets, high-contrast support, screen-reader friendly.

---

## 7. Release Scope

| Feature Area | Phase 1 — ✅ COMPLETE | Phase 2 — 🔄 In Progress | Phase 3 — 📋 Planned |
|---|---|---|---|
| **Solver** | Top 50 chronic medications (CSP engine, 4/4 tests passing, 7 ms) | Full FDA/RxNorm library integration | Multi-day cycle drugs (weekly/monthly) |
| **Routine Engine** | 3 Meals + Wake/Sleep anchors | Dynamic snack/coffee buffers | Wearable circadian tracking |
| **App Shell** | Pure Dart HTTP web demo (`serve_web.dart`, port 8080) | Flutter mobile app (iOS & Android) | Windows Desktop + Web PWA |
| **Alerts** | — | Local mobile notifications | WhatsApp Bot + Caregiver SMS relay |
| **Scanning** | — | Prescription bottle OCR (Google ML Kit) | Tablet Computer Vision verifier |
| **Persistence** | `user_store.json` (dev/demo only) | Drift ORM + SQLCipher (Phase 3 mobile) | Multi-device sync (opt-in, end-to-end encrypted) |
| **Reporting** | — | In-app visual timeline | Printable PDF Fridge Chart; Clinical Export for Doctor visits |
