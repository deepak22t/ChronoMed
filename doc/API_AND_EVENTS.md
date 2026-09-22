# API Contracts, Event Schemas & Error Codes
## Project Name: ChronoMed
**Document Version:** 2.0.0  
**Status:** Updated to reflect actual Dart implementation

> [!NOTE]
> This document supersedes the previous version which documented a TypeScript interface and imaginary endpoints. All contracts below reflect the **actual running codebase**.

---

## 1. Core Engine In-Process Interface (Pure Dart)

These are the direct, in-process function boundaries between callers and the mathematical solver. No HTTP involved — all calls are synchronous Dart function invocations within the same process.

### 1.1 `ChronoMedSolver` — Compute an Optimal Daily Schedule

Located in `core_engine/lib/src/csp_solver.dart`.

```dart
import 'package:core_engine/src/models/routine.dart';
import 'package:core_engine/src/models/medication.dart';
import 'package:core_engine/src/models/schedule_result.dart';

// Instantiate the solver with the user's routine and medication list,
// then call solve(). The result is a sealed DailyScheduleResult.
final DailyScheduleResult result = ChronoMedSolver(
  routine: Routine(
    id: 'user_1',
    userId: 'user_1',
    wakeTimeMinutes: 420,    // 07:00 AM
    sleepTimeMinutes: 1380,  // 11:00 PM
    meals: [
      MealAnchor(id: 'm1', type: MealType.breakfast, startTimeMinutes: 510),
      MealAnchor(id: 'm2', type: MealType.lunch,     startTimeMinutes: 780),
      MealAnchor(id: 'm3', type: MealType.dinner,    startTimeMinutes: 1140),
    ],
  ),
  medications: [
    Medication(
      id: 'med_1',
      name: 'Levothyroxine',
      dosage: '50 mcg',
      rules: PharmacokineticRule(
        requiresEmptyStomach: true,
        circadianPreference: CircadianWindow.morning,
        separationConstraints: [
          DrugSeparationConstraint(
            targetIdentifier: 'Calcium Carbonate',
            minimumSeparationMinutes: 240,
            clinicalRationale: 'Chelation reduces absorption by ~80%',
          ),
        ],
      ),
    ),
  ],
).solve(); // Returns DailyScheduleResult (sealed class)
```

**Typical solve time:** ~7 ms measured for a standard 5–10 medication regimen.

---

### 1.2 `DynamicRecalibrator` — Handle Overslept / Late Wake Scenarios

Located in `core_engine/lib/src/dynamic_recalibrator.dart`.

```dart
import 'package:core_engine/src/dynamic_recalibrator.dart';

// Called when the user wakes up later than their configured wakeTimeMinutes.
// Locks already-taken doses as immutable constraints and re-solves for
// minimum perturbation of remaining doses.
final DailyScheduleResult result = DynamicRecalibrator.recalibrateForDelayedWakeUp(
  baselineRoutine: routine,          // Original Routine with configured wake time
  actualWakeTimeMinutes: 555,        // 09:15 AM — the real wake time today
  medications: meds,                 // List<Medication>
  targetDate: 'TODAY',               // Date string for the resulting schedule
); // Returns DailyScheduleResult (same sealed class as ChronoMedSolver)
```

---

### 1.3 Sealed Result Types — `DailyScheduleResult`

All solver and recalibrator calls return a `DailyScheduleResult`. Use Dart's exhaustive pattern matching to handle all three outcomes:

```dart
switch (result) {
  case OptimalSchedule(:final doses, :final solveDurationMs):
    // ✅ Happy path — a valid schedule was found.
    // doses: List<ScheduledDose>
    // solveDurationMs: int — measured solve time (typically 7 ms)
    for (final dose in doses) {
      print('${dose.formattedTime} — ${dose.medicationName}');
      print('  Instruction: ${dose.clinicalInstruction}');
      print('  Food note:   ${dose.safeFoodWindowNote}');
    }

  case InfeasibleConflict(:final errorCode, :final conflictingMedications,
                          :final clinicalExplanation, :final actionableAdvice):
    // ❌ No valid schedule exists — surface to user with full clinical context.
    // errorCode: String — default 'CHRONO_1001'
    // conflictingMedications: List<String>
    // clinicalExplanation: String
    // actionableAdvice: String
    print('[$errorCode] Cannot schedule: $conflictingMedications');
    print(clinicalExplanation);
    print(actionableAdvice);

  case RecalibratedSchedule(:final doses, :final shiftReason, :final shiftsSummary):
    // ⚠️ Schedule was solvable only after shifting one or more doses.
    // doses: List<ScheduledDose> — the adjusted schedule
    // shiftReason: String — human-readable explanation of why shifts occurred
    // shiftsSummary: List<String> — per-dose shift descriptions
    print('Recalibrated: $shiftReason');
    for (final shift in shiftsSummary) { print('  • $shift'); }
}
```

#### `ScheduledDose` Field Reference

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique dose ID |
| `medicationId` | `String` | Foreign key to `Medication.id` |
| `medicationName` | `String` | Display name |
| `dosage` | `String` | e.g. `"50 mcg"` |
| `scheduledMinute` | `int` | Minute of day (0–1439) |
| `actualTakenMinute` | `int?` | Null until confirmed taken |
| `status` | `DoseStatus` | `scheduled \| due \| taken \| snoozed \| missed \| escalated` |
| `clinicalInstruction` | `String` | e.g. `"Take 60 min before breakfast with water"` |
| `safeFoodWindowNote` | `String` | Food safety note for this dose |
| `formattedTime` | `String` (getter) | e.g. `"07:00 AM"` |

---

## 2. Development REST API (`serve_web.dart`)

The development server lives in `core_engine/bin/serve_web.dart` and serves the **Clinical Studio** web UI as well as a REST API for interacting with the live schedule state.

**Start the server:**
```powershell
cd core_engine
dart run bin/serve_web.dart
# → Listening on http://localhost:8080
```

All request/response bodies use `Content-Type: application/json`.

---

### `GET /`

Serves the full **Clinical Studio** HTML/JS UI — an interactive browser-based demo of the scheduling engine.

**Response:** `200 OK` — HTML document (the full web app).

---

### `GET /api/state`

Returns the complete current application state as JSON — routine, medications, and today's computed schedule.

**Response:**
```json
{
  "routine": {
    "wakeMinutes": 420,
    "sleepMinutes": 1380,
    "meals": [
      { "id": "m1", "type": "breakfast", "startTimeMinutes": 510, "durationMinutes": 30 },
      { "id": "m2", "type": "lunch",     "startTimeMinutes": 780, "durationMinutes": 30 },
      { "id": "m3", "type": "dinner",    "startTimeMinutes": 1140, "durationMinutes": 30 }
    ]
  },
  "medications": [
    { "id": "med_1", "name": "Levothyroxine", "dosage": "50 mcg" }
  ],
  "schedule": {
    "type": "OptimalSchedule",
    "date": "2026-09-22",
    "userId": "user_1",
    "solveDurationMs": 7,
    "doses": [
      {
        "id": "dose_1",
        "medicationId": "med_1",
        "medicationName": "Levothyroxine",
        "dosage": "50 mcg",
        "scheduledMinute": 420,
        "actualTakenMinute": null,
        "status": "scheduled",
        "clinicalInstruction": "Take 60 min before breakfast with a full glass of water.",
        "safeFoodWindowNote": "Breakfast safely opens at 08:30 AM.",
        "formattedTime": "07:00 AM"
      }
    ]
  }
}
```

---

### `POST /api/dose/toggle`

Marks a dose as taken (or toggles it back to scheduled if already taken).

**Request:**
```json
{ "doseId": "dose_1" }
```

**Response:**
```json
{ "success": true, "newStatus": "taken" }
```

---

### `POST /api/medication/add`

Adds a new medication to the user's current medication list and recomputes the schedule.

**Request:**
```json
{
  "name": "Calcium Carbonate",
  "dosage": "500 mg",
  "condition": "Bone Health",
  "hasCationConflict": true
}
```

**Response:**
```json
{ "success": true, "medicationId": "med_2" }
```

---

### `POST /api/medication/delete`

Removes a medication by ID and recomputes the schedule.

**Request:**
```json
{ "medicationId": "med_2" }
```

**Response:**
```json
{ "success": true }
```

---

### `POST /api/routine/update`

Updates the user's daily routine (wake, meals, sleep times) and recomputes the schedule. All values are minutes from midnight (0–1439).

**Request:**
```json
{
  "wakeMinutes": 420,
  "breakfastMinutes": 510,
  "lunchMinutes": 780,
  "dinnerMinutes": 1140,
  "sleepMinutes": 1380
}
```

**Response:**
```json
{ "success": true }
```

---

### `POST /api/sim/overslept`

Simulates an overslept scenario — shifts the wake time forward by **+2 hours 15 minutes** and triggers `DynamicRecalibrator` to recalculate the day's schedule. No request body required.

**Request:** _(empty body)_

**Response:**
```json
{
  "success": true,
  "simulatedWakeMinutes": 555,
  "scheduleType": "RecalibratedSchedule",
  "shiftReason": "Wake time delayed by 135 minutes. Downstream doses shifted to preserve clinical separation windows."
}
```

---

### `POST /api/sim/reset`

Resets all state (routine, medications, schedule) to factory defaults. No request body required.

**Request:** _(empty body)_

**Response:**
```json
{ "success": true }
```

---

### `GET /api/search?q={query}`

Searches the drug knowledge base (`clinical_data`) for a drug matching the query string.

**Example:** `GET /api/search?q=metformin`

**Response:**
```json
{
  "results": [
    {
      "name": "Metformin",
      "condition": "Type 2 Diabetes",
      "requiresFood": true,
      "requiresEmptyStomach": false,
      "circadianPreference": "anyTime",
      "separationConstraints": []
    }
  ]
}
```

---

## 3. Planned Production Cloud Relay (Phase 5)

> [!IMPORTANT]
> **PLANNED — Not Yet Implemented.** The endpoints in this section describe the intended design for the Phase 5 cloud relay service, which will handle asynchronous caregiver escalations and WhatsApp integration. No `cloud_relay/` package exists in the repository yet.

The cloud relay is a stateless microservice that handles time-delayed notifications without storing medical history.

### 3.1 Schedule Escalation Timer
`POST /v1/escalations/schedule`

Registers a delayed 45-minute countdown job with a serverless queue (Upstash QStash). If the patient does not confirm taking the dose within 45 minutes, the queue fires the caregiver webhook.

**Request Payload:**
```json
{
  "escalationToken": "uuid-v4-hmac-signed-token",
  "caregiverPhone": "+15551234567",
  "caregiverChannel": "WHATSAPP",
  "patientDisplayName": "Papa",
  "medicationDisplayName": "Morning Heart Medication",
  "scheduledTimeFormatted": "08:00 AM",
  "delayMinutes": 45
}
```

**Response (200 OK):**
```json
{
  "status": "QUEUED",
  "jobId": "qstash_job_987654321",
  "triggerAt": "2026-09-22T08:45:00Z"
}
```

---

### 3.2 Cancel Escalation Timer (Dose Taken Locally)
`POST /v1/escalations/cancel`

Dispatched when the patient confirms taking their dose locally. Cancels the pending caregiver alert.

**Request Payload:**
```json
{
  "escalationToken": "uuid-v4-hmac-signed-token",
  "jobId": "qstash_job_987654321"
}
```

**Response (200 OK):**
```json
{
  "status": "CANCELED",
  "message": "Caregiver alert was successfully aborted."
}
```

---

### 3.3 Caregiver Inbound WhatsApp Webhook
`POST /v1/webhooks/whatsapp/inbound`

Handles incoming replies from caregivers via the Meta WhatsApp Cloud API (e.g., caregiver texting "Handled").

**Webhook Payload (Meta Cloud API Standard):**
```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "changes": [{
      "value": {
        "messages": [{
          "from": "15551234567",
          "id": "wamid.HBgLM...",
          "timestamp": "1726950000",
          "text": { "body": "Handled, I just called him" },
          "type": "text"
        }]
      }
    }]
  }]
}
```

---

## 4. Error Codes Dictionary

Every error in ChronoMed follows a strict taxonomy. Solver errors are returned as `InfeasibleConflict.errorCode` (a Dart field, not an HTTP status code). REST API validation errors use standard HTTP status codes.

| Error Code | Return Context | Category | Description | Patient / UI Action |
|---|---|---|---|---|
| `CHRONO_1001` | `InfeasibleConflict.errorCode` (default) | Clinical Infeasibility | Drug separation constraint cannot be satisfied within the user's waking hours. | Prompt user to review bedtime or consult their doctor to stagger doses across alternate days. |
| `CHRONO_1002` | `InfeasibleConflict.errorCode` | Clinical Infeasibility | Multiple empty-stomach drugs collide with continuous meal/snack windows. | Prompt user to widen the gap between breakfast and lunch. |
| `CHRONO_2001` | REST `404 Not Found` | Knowledge Base | Scanned drug name could not be resolved in the drug registry (`top_50_drugs.json`). | Allow manual user entry of empty-stomach / food rules with clear disclaimer. |
| `CHRONO_3001` | REST `400 Bad Request` | Routine Validation | Sleep time occurs before wake time without overnight shift flag. | Request user to verify AM/PM settings for their daily sleep schedule. |
| `CHRONO_4001` | REST `503 Service Unavailable` | Gateway Relay (Planned) | Upstash QStash or WhatsApp Cloud API failed to accept escalation webhook. | Local device retries with exponential backoff and triggers local fallback alarm. |
| `CHRONO_5001` | Runtime Exception | Security / Crypto (Planned) | SQLCipher database decryption failed (invalid hardware keystore key). | Halt immediately to prevent data corruption; trigger secure recovery flow. |
