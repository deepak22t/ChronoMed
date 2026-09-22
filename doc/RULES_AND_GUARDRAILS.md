# Engineering Rules, Clinical Guardrails & Production Standards
## Project Name: ChronoMed
**Document Version:** 1.1.0  
**Mandatory Level:** Strict (Enforced in all code reviews, CI/CD pipelines, and AI code generation)

---

## 1. The Core Philosophy: "Reliability Over Cleverness"

ChronoMed is a healthcare utility that directly impacts human physiology. A software bug here does not just cause a visual glitch — it can cause a patient to absorb zero thyroid hormone or suffer severe gastrointestinal bleeding from NSAIDs.

Therefore, this codebase rejects premature optimization, unnecessary architectural complexity, and speculative features. Every line of code must be **transparent, testable, and mathematically verifiable**.

---

## 2. Clinical Guardrail #1: The Zero-Hallucination Mandate

> [!CAUTION]
> **STRICT PROHIBITION:** Under NO circumstances shall a Large Language Model (LLM) or Generative AI be used to determine medication timing, drug-to-drug interactions, or clinical safety constraints.

### Allowed vs. Prohibited AI Usage:
* **PROHIBITED:** Asking an LLM: *"When should Sarah take Levothyroxine and Calcium?"* (LLMs hallucinate, confuse AM/PM, and cannot guarantee mathematical constraint satisfaction).
* **PERMITTED:** Using OCR / Vision models solely to extract raw text from prescription labels (e.g., *"Levothyroxine 50mcg"*). Once extracted, the string is mapped to a verified National Drug Code (NDC) or NIH RxCUI database entry in `clinical_data/lib/src/drug_registry.dart`.
* **MANDATORY:** All interaction checks and daily timeline scheduling **MUST** be performed by pure, deterministic, symbolic code (the Constraint Satisfaction Engine in `core_engine/lib/src/csp_solver.dart`).

---

## 3. Clinical Guardrail #2: Fail-Closed Medical Safety

In web development, systems often "fail soft" (e.g., displaying placeholder data if an API fails). In ChronoMed, the system **MUST FAIL CLOSED**:

1. **Infeasible Schedules:** If a user's medication list and routine cannot satisfy all safety rules (e.g., too many conflicting drugs to fit in a 16-hour waking day), the engine **MUST NOT** compromise or drop a constraint to "make it fit."
2. **Explicit Bottleneck Disclosure:** The engine must return an `InfeasibleConflict` result (see the sealed `DailyScheduleResult` class hierarchy in `core_engine/lib/src/models/schedule_result.dart`) that clearly surfaces:
   - Exactly which two or three drugs are colliding (via `conflictingMedications`).
   - The clinical reason via `clinicalExplanation` (e.g., *"Levothyroxine and Calcium Carbonate require 4 hours separation, but your meal schedule leaves only 2 hours available"*).
   - Clear recommendation to consult the prescribing physician via `actionableAdvice`.
   - The error code `errorCode` (default: `'CHRONO_1001'`).

The `csp_solver.dart` must **never** silently drop a `DrugSeparationConstraint` or `PharmacokineticRule` to manufacture a feasible-looking result. A wrong schedule is far more dangerous than an honest infeasibility report.

---

## 4. Code Architecture & Anti-Bloat Guardrails (KISS / YAGNI)

### 4.1 No Unnecessary Abstractions
- **Avoid "Layer Mania":** Do not create an Interface, an Abstract Base Class, a Factory, a Repository, and a Service just to read a single SQLite row.
- **Direct & Modular:** Keep modules focused. A single `csp_solver.dart` file containing the pure constraint satisfaction algorithm is vastly superior to 10 fragmented files with indirection.
- **Dependency Diet:** Minimize external libraries. Use standard Dart library primitives for date/time math, data structures, and algorithms wherever possible.

### 4.2 Absolute Time Normalization (Minute-of-Day Standard)
- **Zero Timezone Headaches:** The core scheduling engine **never** deals with dates, timezones, or UTC conversions.
- All times within the domain engine are represented as an integer:
  $$\text{minuteOfDay} \in [0, 1439] \quad (\text{where } 0 = 00:00, \quad 420 = 07:00\text{ AM}, \quad 1439 = 23:59)$$
- This is reflected directly in the `ScheduledDose` model field `scheduledMinute` (type `int`) and the nullable `actualTakenMinute` (type `int?`).
- Conversion to localized display strings (e.g., `"08:30 AM"`) is exclusively an **Adapter / UI** concern and is handled by the `formattedTime` getter on `ScheduledDose`.

### 4.3 Pure Functions for Mathematical Core
- The solver entry point in `csp_solver.dart` must be **100% pure**:
  - Given the same inputs (`Routine`, `List<Medication>`, `List<PharmacokineticRule>`), it must return the exact same `DailyScheduleResult` every single time.
  - Zero side effects: no database queries, no network calls, no disk reads inside the solver loop.
  - Memory-safe: no dynamic memory leaks or recursive stack overflow. Discretization ensures the search space is finite and bounded (≤96 slots per 24-hour day).

### 4.4 Zero Magic Numbers
Every medical interval or clinical constant in the code must be declared as a named constant with its clinical rationale. All such constants live in `core_engine/lib/src/constants/clinical_buffers.dart`.

```dart
// BAD:
if (timeB - timeA < 240) return false;

// GOOD:
/// Minimum mandatory separation between polyvalent cations (Ca²⁺, Fe²⁺, Mg²⁺)
/// and target medications (Levothyroxine, Fluoroquinolones) to prevent insoluble
/// chelation complexes forming in the GI tract.
///
/// Clinical Reference: FDA Levothyroxine Package Insert / DailyMed.
const int minCationChelationSeparationMinutes = 240;

/// Standard gastric emptying duration. Doses requiring an empty stomach
/// must be taken >= 60 min before a meal or >= 120 min after a meal.
///
/// Clinical Reference: FDA Guidance for Industry — Food-Effect Studies.
const int emptyStomachPreMealBufferMinutes  = 60;
const int emptyStomachPostMealBufferMinutes = 120;
const int prandialFoodBufferMinutes         = 30;
```

> [!IMPORTANT]
> The field name on `DrugSeparationConstraint` is `minimumSeparationMinutes` (not `minSeparation`, `separationMinutes`, or any other variant). Always use the exact field names defined in the model classes. Refer to `core_engine/lib/src/models/` for the canonical source of truth.

---

## 5. Defensive Testing & Quality Requirements

### 5.1 Unit Tests for Every Clinical Rule
Every clinical constraint must have explicit, isolated unit tests. Current passing tests in `core_engine/test/clinical_rules_test.dart` (4/4 ✅):
- `test_empty_stomach_dose_never_overlaps_meal()`
- `test_chelation_pair_guarantees_minimum_240_minute_distance()`
- `test_overslept_shift_preserves_post_dose_spacing()`
- `test_infeasible_schedule_returns_accurate_conflict_report()`

Additional tests must be added for every new clinical rule or drug interaction added to `clinical_data/data/top_50_drugs.json`.

### 5.2 Property-Based Testing
Using fuzzing / property-based testing with [`glados`](https://pub.dev/packages/glados) (Dart property-based testing library):
- Generate **10,000 randomized user daily routines** (wake times between 04:00 and 12:00, varying meal times).
- Assert that in **zero cases** does the solver output a schedule where a chelation pair is within 239 minutes of each other.
- Assert that in **zero cases** does the solver produce an `OptimalSchedule` when the constraints are mathematically infeasible for the given routine.

### 5.3 Determinism and Latency Benchmarks
- **Measured baseline:** The CSP solver currently converges in **7 ms** for a representative 10-drug, 3-meal, 16-hour scenario.
- **NFR budget:** Solver execution must complete in $<100$ms on standard mobile hardware (NFR-2).
- **CI gate:** The continuous integration pipeline must fail if solver execution exceeds **100 ms** on the benchmark fixture. There is no need to artificially tighten this gate — the 7 ms measured performance provides a 14× headroom buffer.

---

## 6. Privacy & Security Rules (HIPAA / GDPR Ready)

1. **Local-First Processing:** Medication names, schedules, and compliance logs reside on the user's local device.
2. **Encrypted Storage (Production):** Production Flutter builds use **SQLCipher** with AES-256 encryption. The development web demo (`core_engine/bin/serve_web.dart`) uses a plaintext `user_store.json` for convenience only — this must never be used in any patient-facing deployment.
3. **No Third-Party Analytics Leaks:** Never pass medication names or health diagnoses to telemetry or crash-reporting tools (e.g., Sentry, Firebase Analytics). Sanitize all logs before any off-device transmission.
4. **Caregiver Consent:** Caregiver phone numbers and the escalation relay (ADR-005) require explicit bilateral verification before any SMS/WhatsApp alerts are dispatched.
