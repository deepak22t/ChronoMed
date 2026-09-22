# Low-Level Design (LLD) & System Architecture
## Project Name: ChronoMed
**Document Version:** 1.1.0  
**Status:** Approved for Engineering Implementation

> [!NOTE]
> This document reflects the **actual implemented codebase** as of Phase 3 (Web Demo Server complete). All Dart model definitions match the exact field names in `core_engine/lib/src/models/`.

---

## 1. Architectural Philosophy: Hexagonal / Clean Architecture

To ensure the core mathematical scheduling logic remains 100% deterministic, testable, and isolated from UI or third-party platform dependencies, ChronoMed adheres to **Hexagonal (Ports & Adapters) Architecture**:

```
+-------------------------------------------------------------------------+
|                              ADAPTERS                                   |
|  [Mobile UI: Flutter]    [Web Demo: serve_web.dart]  [Local Alarm Mgr] |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                         APPLICATION SERVICES                            |
|       ScheduleService      DoseLogService      CaregiverNotifier        |
+------------------------------------+------------------------------------+
                                     |
                                     v
+------------------------------------+------------------------------------+
|                             CORE DOMAIN                                 |
|   - Constraint Satisfaction Engine (CSP Solver)                         |
|   - Clinical Pharmacokinetic Rules Engine                               |
|   - Daily Timeline & Interval Math                                      |
+------------------------------------+------------------------------------+
                                     ^
                                     |
+------------------------------------+------------------------------------+
|                         INFRASTRUCTURE / DATA                           |
|  JSON disk store (current)   DrugRegistry   Background Worker (planned) |
+-------------------------------------------------------------------------+
```

---

## 2. Core Domain Data Models

All models live in `core_engine/lib/src/models/`. The snippets below are the **authoritative** representations — field names match the actual source files exactly.

### 2.1 Daily Routine Model (`routine.dart`, `meal.dart`)

```dart
// meal.dart
enum MealType { breakfast, lunch, dinner, snack }

class MealAnchor {
  final String id;
  final MealType type;
  final int startTimeMinutes;     // e.g. 510 (08:30 AM)
  final int durationMinutes;      // default: 30 minutes

  int get endTimeMinutes => startTimeMinutes + durationMinutes;
  String get displayName;         // e.g. "Breakfast"

  const MealAnchor({
    required this.id,
    required this.type,
    required this.startTimeMinutes,
    this.durationMinutes = 30,
  });
}

// routine.dart
class Routine {
  final String id;
  final String userId;
  final int wakeTimeMinutes;      // 0-1439 (minutes from 00:00, e.g. 420 = 07:00 AM)
  final int sleepTimeMinutes;     // 0-1439 (e.g. 1380 = 11:00 PM)
  final List<MealAnchor> meals;

  const Routine({
    required this.id,
    required this.userId,
    required this.wakeTimeMinutes,
    required this.sleepTimeMinutes,
    required this.meals,
  });
}
```

> [!NOTE]
> `Routine` does **not** have a `beveragePreferences` field. Beverage handling is out of scope for the current implementation.

---

### 2.2 Medication & Clinical Rules Model (`medication.dart`, `pharmacokinetic_rule.dart`)

```dart
// pharmacokinetic_rule.dart
enum CircadianWindow { morning, afternoon, evening, bedtime, anyTime }

class PharmacokineticRule {
  final bool requiresEmptyStomach;
  final bool requiresFood;
  final CircadianWindow circadianPreference;       // default: anyTime

  /// Bilateral drug-to-drug minimum separation requirements.
  final List<DrugSeparationConstraint> separationConstraints;

  const PharmacokineticRule({
    this.requiresEmptyStomach = false,
    this.requiresFood = false,
    this.circadianPreference = CircadianWindow.anyTime,
    this.separationConstraints = const [],
  });
}

class DrugSeparationConstraint {
  final String targetIdentifier;            // Drug name or identifier to separate from
  final int minimumSeparationMinutes;       // e.g. 240 minutes for Cation–Thyroid pair
  final String clinicalRationale;           // e.g. "Chelation reduces absorption by 80%"

  const DrugSeparationConstraint({
    required this.targetIdentifier,
    required this.minimumSeparationMinutes,
    required this.clinicalRationale,
  });
}

// medication.dart
class Medication {
  final String id;
  final String name;
  final String dosage;             // e.g. "50 mcg", "500 mg"
  final PharmacokineticRule rules;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.rules,
  });
}
```

> [!NOTE]
> `Medication` does **not** have `brandName`, `rxcui`, or `form` fields in the current implementation. These may be added in a later phase if RxNorm integration is required.

---

### 2.3 Solved Schedule & Dose Log Model (`schedule_result.dart`)

```dart
// schedule_result.dart
enum DoseStatus { scheduled, due, taken, snoozed, missed, escalated }

class ScheduledDose {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final int scheduledMinute;            // minute of the day (0-1439)
  final int? actualTakenMinute;         // null until the dose is confirmed taken
  final DoseStatus status;
  final String clinicalInstruction;     // e.g. "Take 60 min before breakfast with water"
  final String safeFoodWindowNote;

  String get formattedTime;             // e.g. "07:00 AM"

  const ScheduledDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledMinute,
    this.actualTakenMinute,
    this.status = DoseStatus.scheduled,
    required this.clinicalInstruction,
    required this.safeFoodWindowNote,
  });
}

/// Sealed result type returned by ChronoMedSolver.solve() and
/// DynamicRecalibrator.recalibrateForDelayedWakeUp().
sealed class DailyScheduleResult {}

final class OptimalSchedule extends DailyScheduleResult {
  final String date;                    // "YYYY-MM-DD"
  final String userId;
  final List<ScheduledDose> doses;
  final int solveDurationMs;            // measured: ~7 ms in practice

  OptimalSchedule({
    required this.date,
    required this.userId,
    required this.doses,
    required this.solveDurationMs,
  });
}

final class InfeasibleConflict extends DailyScheduleResult {
  final String errorCode;               // default: 'CHRONO_1001'
  final List<String> conflictingMedications;
  final String clinicalExplanation;
  final String actionableAdvice;

  InfeasibleConflict({
    this.errorCode = 'CHRONO_1001',
    required this.conflictingMedications,
    required this.clinicalExplanation,
    required this.actionableAdvice,
  });
}

final class RecalibratedSchedule extends DailyScheduleResult {
  final String date;
  final String userId;
  final List<ScheduledDose> doses;
  final String shiftReason;
  final List<String> shiftsSummary;

  RecalibratedSchedule({
    required this.date,
    required this.userId,
    required this.doses,
    required this.shiftReason,
    required this.shiftsSummary,
  });
}
```

---

## 3. Constraint Satisfaction Engine Specification

### 3.1 Mathematical Formulation

Let $M = \{m_1, m_2, \dots, m_n\}$ be the set of prescribed medications.  
For each $m_i \in M$, let variable $T_i \in [T_{\text{wake}}, T_{\text{sleep}}]$ represent the execution minute.

#### Domain Discretization:
To guarantee rapid convergence on mobile CPUs, the continuous timeline $[T_{\text{wake}}, T_{\text{sleep}}]$ is discretized into **15-minute intervals**:
$$D = \{ t \in \mathbb{N} \mid T_{\text{wake}} \le t \le T_{\text{sleep}} \land t \equiv 0 \pmod{15} \}$$

#### Formal Constraints:

1. **Fasting Constraint (Empty Stomach):**
   $$\forall \text{meal } k \in \text{Meals}, \quad (T_i \le \text{Start}_k - \text{PreBuffer}_i) \lor (T_i \ge \text{End}_k + \text{PostBuffer}_i)$$
   Where standard $\text{PreBuffer} = 60\text{m}$, $\text{PostBuffer} = 120\text{m}$ (see `constants/clinical_buffers.dart`).

2. **Prandial Constraint (With Food):**
   $$\exists \text{meal } k \in \text{Meals}, \quad \text{Start}_k \le T_i \le \text{Start}_k + \text{FoodWindow}_i$$
   Where standard $\text{FoodWindow} = 30\text{m}$.

3. **Drug Separation Constraint (`separationConstraints`):**
   $$\forall (m_i, m_j) \in \text{separationConstraints}, \quad |T_i - T_j| \ge \Delta_{ij}$$
   Where $\Delta_{ij} = 240\text{m}$ for multivalent cations (Calcium/Iron/Magnesium vs Levothyroxine/Quinolones).

4. **Circadian Window Constraint (`circadianPreference`):**
   $$L_{\text{circadian}}(m_i) \le T_i \le U_{\text{circadian}}(m_i)$$

### 3.2 Solving Algorithm: Forward Checking with Minimum Remaining Values (MRV)

Instead of an unguided brute force, the engine uses **Backtracking with Constraint Propagation**:

1. **Variable Ordering (MRV):** Prioritize assigning medications with the tightest constraints first (e.g., empty-stomach medications with separation constraints have the fewest valid slots).
2. **Forward Checking:** Immediately prune invalid domain values from unassigned variables after placing a medication.
3. **Deterministic Fallback:** If $D(T_i) = \emptyset$, trigger the **Clinical Conflict Reporter**, isolating the minimal unsatisfiable subset (MUS) to tell the user exactly which drugs cannot fit in their daily schedule.

---

## 4. Dynamic Recalibration Engine ("I Overslept / Took It Late")

When a user marks a dose taken at time $T_{\text{actual}}$ such that $|T_{\text{actual}} - T_{\text{scheduled}}| > 30\text{ minutes}$:

```
[ User Logs Late Dose ] 
         |
         v
1. Lock past events (Doses marked TAKEN remain fixed).
         |
         v
2. Update current state: Set T_actual as immutable constraint.
         |
         v
3. Identify downstream dependent medications:
   - Doses requiring spacing from T_actual (via separationConstraints)
   - Meals scheduled within invalid fasting windows
         |
         v
4. Run Local Perturbation Minimization:
   Minimize: SUM(|T_new_j - T_original_j|) for remaining un-taken doses
   Subject to: All Hard Clinical Constraints preserved.
         |
         v
5. Push Delta Notification to user:
   "Morning Thyroid taken at 09:30 AM. Breakfast safely opens at 10:30 AM. 
    Calcium shifted to 03:30 PM."
```

---

## 5. Dose State Machine & Caregiver Escalation

Each `ScheduledDose` transitions through a strict state machine (values defined in `DoseStatus` enum):

```
                  +---------------+
                  |   SCHEDULED   |
                  +-------+-------+
                          | (Time reaches scheduledMinute)
                          v
                  +---------------+
      +---------->|      DUE      |
      |           +---+---+---+---+
      |               |   |   |
(Snooze 15m)          |   |   +--------------------------+
      |               |   |                              |
      |               |   | (User confirms)              | (Time > T + 45 min)
      |               |   v                              v
      +-- [SNOOZED] <-+ [TAKEN]                    +------------+
                                                   |   MISSED   |
                                                   +-----+------+
                                                         | (Trigger Alert)
                                                         v
                                                   +------------+
                                                   | ESCALATED  |
                                                   | (Caregiver |
                                                   |   Notified)|
                                                   +------------+
```

---

## 6. Database Schema

> [!IMPORTANT]
> **Current persistence (Phases 1–3):** State is stored in `core_engine/data/user_store.json` — plain JSON on disk, managed by `serve_web.dart`.
>
> **Planned (Phase 4 — Flutter Mobile):** The schema below will be implemented using **SQLCipher + Drift ORM** for AES-256 encrypted local storage on Android/iOS. It is **not yet implemented**.

```sql
-- PLANNED: Phase 4 Flutter Mobile (SQLCipher + Drift ORM)

-- User Routine
CREATE TABLE user_routines (
    user_id TEXT PRIMARY KEY,
    wake_minutes INTEGER NOT NULL,
    sleep_minutes INTEGER NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Daily Meals
CREATE TABLE user_meals (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    meal_type TEXT CHECK(meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
    start_minutes INTEGER NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    FOREIGN KEY(user_id) REFERENCES user_routines(user_id)
);

-- User Medications
CREATE TABLE user_medications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    requires_empty_stomach BOOLEAN DEFAULT 0,
    requires_food BOOLEAN DEFAULT 0,
    circadian_preference TEXT DEFAULT 'ANY_TIME',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clinical Separation Constraints (Drug Pairs)
-- Maps to DrugSeparationConstraint: targetIdentifier, minimumSeparationMinutes, clinicalRationale
CREATE TABLE drug_separation_rules (
    drug_name_a TEXT NOT NULL,
    target_identifier TEXT NOT NULL,
    min_separation_minutes INTEGER NOT NULL,
    clinical_rationale TEXT NOT NULL,
    PRIMARY KEY (drug_name_a, target_identifier)
);

-- Daily Generated Schedule
CREATE TABLE daily_schedules (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    schedule_date DATE NOT NULL,
    status TEXT NOT NULL,
    UNIQUE(user_id, schedule_date)
);

-- Individual Doses
-- Maps to ScheduledDose: scheduledMinute, actualTakenMinute, clinicalInstruction
CREATE TABLE scheduled_doses (
    id TEXT PRIMARY KEY,
    schedule_id TEXT NOT NULL,
    medication_id TEXT NOT NULL,
    scheduled_minute INTEGER NOT NULL,
    actual_taken_minute INTEGER,
    status TEXT DEFAULT 'SCHEDULED',
    clinical_instruction TEXT NOT NULL,
    safe_food_window_note TEXT NOT NULL,
    escalated_at TIMESTAMP,
    FOREIGN KEY(schedule_id) REFERENCES daily_schedules(id)
);

-- Caregiver Emergency Contacts
CREATE TABLE caregiver_contacts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    channel TEXT CHECK(channel IN ('SMS', 'WHATSAPP')),
    is_active BOOLEAN DEFAULT 1
);
```

---

## 7. Performance & Latency Budgets

| Metric | Measured / Budget | Notes |
|---|---|---|
| **CSP Solving Time** | **7 ms measured** | For a typical 5–10 medication regimen; well within mobile budget |
| **SQLite Read/Write** | ≤ 10 ms | Planned for Phase 4 (SQLCipher on mobile flash storage) |
| **Dynamic Recalibration End-to-End** | ≤ 80 ms | From user button press to UI re-render |
| **Memory Footprint** | ≤ 25 MB | For background monitoring worker |
