# Security, Privacy & Regulatory Compliance (HIPAA / GDPR)
## Project Name: ChronoMed
**Document Version:** 1.0.0  
**Status:** Approved for Implementation

---

## 1. Regulatory Context & Compliance Posture

ChronoMed processes **Protected Health Information (PHI)** under the United States **HIPAA (Health Insurance Portability and Accountability Act)** and **Special Category Data (Health Data)** under the European Union **GDPR (General Data Protection Regulation)**.

Because ChronoMed operates on an **Edge-First Architecture**, the vast majority of compliance liability is mitigated by design: **the backend never stores unencrypted patient medical histories**.

---

## 2. Cryptographic Standards & Key Management

```
+-------------------------------------------------------------------------+
|                  HARDWARE-BACKED KEY MANAGEMENT                         |
+-------------------------------------------------------------------------+
|  [Android Keystore / StrongBox]   OR   [Apple Secure Enclave / Keychain] |
|                                   |                                     |
|           Generates & Stores: 256-bit Master Key (AES-GCM)              |
|                                   |                                     |
|                                   v                                     |
|              Unlocks: Local SQLCipher Database at Runtime               |
+-------------------------------------------------------------------------+
```

### 2.1 Encryption at Rest (AES-256)
- The entire local SQLite database is encrypted via **SQLCipher** utilizing 256-bit AES encryption in CBC mode with HMAC-SHA512 page authentication.
- **Master Key Derivation:** The database key is dynamically fetched from the platform's hardware security module (Android Keystore / iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- If device biometric authentication (Face ID / Fingerprint) is enabled, the encryption key requires local biometric validation before release to the application.

### 2.2 Encryption in Transit (TLS 1.3)
- All network interactions with the cloud relay, WhatsApp API, and NIH RxNav endpoints strictly require **TLS 1.3**.
- **Certificate Pinning:** The mobile client enforces SSL certificate pinning for the ChronoMed cloud relay endpoints to prevent Man-in-the-Middle (MitM) attacks on public Wi-Fi networks.

---

## 3. STRIDE Threat Model & Mitigations

| Threat Category | Potential Vulnerability | ChronoMed Engineering Mitigation |
|---|---|---|
| **Spoofing** | Malicious actor fakes a caregiver escalation webhook. | Escalation requests are signed using **HMAC-SHA256** with an ephemeral shared secret generated at onboarding. |
| **Tampering** | Malware modifies local database to delay a critical cardiac medication. | SQLCipher page-level HMAC integrity verification detects any raw file tampering and halts startup with `CHRONO_5001`. |
| **Repudiation** | User claims the app never fired an alarm for a missed dose. | Append-only local dose audit log records every alarm trigger, user interaction, screen-on event, and snooze timestamp. |
| **Information Disclosure** | Third-party analytics SDK (e.g., Crashlytics) captures drug names in crash logs. | **PHI Sanitization Filter:** A custom logging interceptor strips all medication names, dosages, and clinical notes before any telemetry is generated. |
| **Denial of Service** | Background worker killed by aggressive Android OS battery management. | Foreground Service declaration combined with Android `USE_EXACT_ALARM` and `BATTERY_OPTIMIZATIONS_IGNORED` prompt. |
| **Elevation of Privilege** | Compromised mobile app gains unauthorized access to caregiver contact details. | Application operates within standard OS sandboxing; contacts are accessed strictly through explicit user-selected picker. |

---

## 4. Protected Health Information (PHI) Scrubbing Policy

Under no circumstances shall any log, telemetry payload, or crash dump contain unmasked PHI.

> [!CAUTION]
> **Development Phase Warning:** The current `core_engine/bin/serve_web.dart` demo server persists state to `data/user_store.json` as **plaintext JSON**. This is acceptable only for local development on a developer's machine. Before any patient-facing deployment, the persistence layer **must** be migrated to the encrypted Drift ORM + SQLCipher backend described in ADR-003. The demo server must never be exposed on a public-facing port or used in a clinical context.

### PHI Log Sanitizer (Dart — `app/lib/core/logging/phi_sanitizer.dart`)

All logging in the Flutter production app **must** pass through the `PhiSanitizer` utility before any external telemetry call:

```dart
// app/lib/core/logging/phi_sanitizer.dart

/// Keys whose values contain Protected Health Information (PHI).
/// Values under these keys are ALWAYS redacted before any log or telemetry emission.
const _phiKeys = {
  'medicationName',
  'dosage',
  'rxcui',
  'clinicalInstruction',
  'patientName',
  'caregiverPhone',
};

/// Strips PHI fields from a log context map before sending to analytics or
/// crash-reporting tools (e.g., Firebase Crashlytics, Sentry).
/// 
/// RULE: This function MUST be called on every map before it is passed to
/// any external telemetry, logging, or crash-reporting SDK.
Map<String, Object?> sanitizeLogContext(Map<String, Object?> context) {
  return {
    for (final entry in context.entries)
      entry.key: _phiKeys.contains(entry.key) ? '[REDACTED_PHI]' : entry.value,
  };
}
```

#### Example Usage:
```dart
// ❌ WRONG — never pass raw context to analytics:
FirebaseCrashlytics.instance.log(
  'Dose toggled: ${dose.medicationName} at ${dose.formattedTime}'
);

// ✅ CORRECT — always sanitize first:
final safeContext = sanitizeLogContext({
  'medicationName': dose.medicationName,
  'scheduledMinute': dose.scheduledMinute,
});
FirebaseCrashlytics.instance.log('Dose toggled: $safeContext');
```

---

## 5. Patient Data Rights & GDPR Compliance (Right to be Forgotten)

1. **One-Tap Complete Wipe:** The Settings screen provides a *"Delete All Health Data"* button.
   - When tapped, the app securely deletes the SQLCipher database file, invalidates the Android Keystore / iOS Keychain key, and purges all scheduled native alarms.
2. **Zero Secondary Cloud Residuals:** Because the cloud relay is stateless and does not store user profiles, deleting the local database completely erases the user's digital footprint.
3. **Explicit Consent & Granular Permissions:** Caregiver notifications require explicit dual-opt-in confirmation via SMS/WhatsApp before the patient's schedule is linked.
