# ChronoMed Engineering Documentation Hub

**Repository:** `project1/`
**Classification:** Clinical-Grade Healthcare Software — Edge-First, Privacy-Preserving Architecture
**Standard:** Production Engineering Reference

> **ChronoMed** is a clinical-grade, constraint-satisfaction medication choreographer. It models polypharmacy as a mathematical problem and computes safe, conflict-free daily medication schedules in **7ms** — 100% on-device, 100% offline, 100% deterministic.

---

## 🏗️ Current Build Status

```
+-----------------------------------------------------------------------+
|                  CHRONOMED BUILD STATUS DASHBOARD                     |
+-----------------------------------------------------------------------+
|  ✅  COMPLETE    Core CSP Engine     (core_engine/)    7ms · 4/4 ✓   |
|  ✅  COMPLETE    Drug Registry       (clinical_data/)  <1ms · 4/4 ✓  |
|  ✅  COMPLETE    Web Demo Server     (serve_web.dart)  port 8080      |
|  🔄  IN PROGRESS Flutter Mobile App (app/)             skeleton       |
|  📋  PLANNED     SQLCipher Persist   (Drift ORM)       Phase 4        |
|  📋  PLANNED     Cloud Relay         (FastAPI/WA)      Phase 5        |
+-----------------------------------------------------------------------+
```

**Quick start — run the Clinical Studio demo:**
```powershell
cd core_engine
dart run bin/serve_web.dart
# Open http://localhost:8080
```

---

## 📚 Documentation Index

| Document | Purpose & Scope | Audience |
|---|---|---|
| 📄 **[PRD.md](./PRD.md)** | **Product Requirements**<br>Product vision, target personas (Sarah, Raj, Alex), functional requirements, user journeys, release matrix. Phase status: ✅ Phase 1 complete, 🔄 Phase 2 in progress. | Product Managers, Founders, Engineers |
| 🏗️ **[HLD.md](./HLD.md)** | **High-Level System Architecture**<br>Edge-first topology, Pure Dart AOT engine, data flows (A–D), build status dashboard, security boundary matrix, fault-tolerance design. | System Architects, Tech Leads |
| ⚙️ **[LLD.md](./LLD.md)** | **Low-Level Design & Data Models**<br>Exact Dart domain model field names, formal CSP constraint formulation (math), dose state machine, planned SQLCipher schema, 7ms benchmark. | Core & Backend Engineers |
| 🛠️ **[TECH_STACK.md](./TECH_STACK.md)** | **Technology Stack & Rationale**<br>Why Flutter (not React Native), why Pure Dart (not Python/OR-Tools), Drift ORM, SQLCipher, serve_web.dart demo bridge, 5-phase implementation status. | Full-Stack Developers, DevOps |
| 🏛️ **[ADR.md](./ADR.md)** | **Architecture Decision Records**<br>ADR-001 through ADR-005: 15-minute discretization, Flutter/Dart over alternatives, SQLCipher, dual-tier alarms, QStash caregiver relay. All in Nygard format. | Senior Engineers, Auditors |
| 🔌 **[API_AND_EVENTS.md](./API_AND_EVENTS.md)** | **API Contracts & Error Codes**<br>Pure Dart in-process interfaces (`ChronoMedSolver`, `DynamicRecalibrator`), all 8 real REST endpoints with JSON examples, planned Phase 5 caregiver webhooks. | Integration Engineers, Frontend |
| 🛡️ **[SECURITY_AND_COMPLIANCE.md](./SECURITY_AND_COMPLIANCE.md)** | **Security, Privacy & HIPAA/GDPR**<br>STRIDE threat model, AES-256 hardware keystore encryption, Dart PHI scrubber, dev-mode plaintext warning, right-to-be-forgotten lifecycle. | Security Engineers, Compliance |
| 📖 **[RULES_AND_GUARDRAILS.md](./RULES_AND_GUARDRAILS.md)** | **Clinical Guardrails & Production Standards**<br>Zero-Hallucination Mandate, fail-closed medical safety, Dart code standards (no magic numbers), `glados` property-based testing, 7ms CI gate. | All Developers, Code Reviewers |
| 🚀 **[DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)** | **Developer Setup & Implementation Guide**<br>Actual `project1/` directory structure, 5-phase roadmap with status, PowerShell run commands, PR checklist. | New Contributors, Developers |

---

## 🏛️ System Architecture (One-Page Summary)

```
+===========================================================================+
|                    EDGE LAYER (USER'S DEVICE)                             |
|                                                                           |
|  [Flutter UI — 120 FPS Impeller canvas]  [Google ML Kit OCR — offline]   |
|                         |                                                 |
|  +----------------------v--------------------------------------------+   |
|  |        CORE ENGINE — Pure Dart 3.5 AOT Native (core_engine/)      |   |
|  |   ChronoMedSolver (csp_solver.dart) ........... 7ms measured      |   |
|  |   DynamicRecalibrator (dynamic_recalibrator.dart) ... overslept   |   |
|  |   IntervalMath (interval_math.dart) ........... 0–1439 min-of-day |   |
|  |   DrugRegistry (clinical_data/) ............... 50 FDA profiles   |   |
|  +--------------------------------------------------------------------+   |
|                         |                                                 |
|  [Current]  data/user_store.json  (JSON, dev only)                        |
|  [Planned]  Drift ORM + SQLCipher AES-256  (Phase 4 Flutter mobile)       |
|                                                                           |
|  ┌─ Web Demo (dev only) ─────────────────────────────────────────────┐   |
|  │  serve_web.dart — Dart HTTP server, port 8080                     │   |
|  │  Serves Clinical Studio UI + 8 REST endpoints                    │   |
|  └────────────────────────────────────────────────────────────────────┘   |
+=============================|=============================================+
                              | HTTPS / TLS 1.3 (PLANNED — not yet built)
                              v
+===========================================================================+
|                  CLOUD RELAY LAYER (PLANNED — Phase 5)                    |
|   FastAPI stateless microservice — Zero patient data stored               |
|   Upstash QStash (45-min escalation timer)                                |
|   Meta WhatsApp Cloud API + Twilio SMS (caregiver notifications)          |
+===========================================================================+
```

---

## 🔒 The Zero-Hallucination Mandate

```
+-----------------------------------------------------------------------+
|                   THE ZERO-HALLUCINATION MANDATE                      |
+-----------------------------------------------------------------------+
|  Large Language Models (LLMs) are STRICTLY FORBIDDEN from             |
|  calculating medication timings or drug-drug interactions.            |
|                                                                       |
|  All scheduling is 100% deterministic, mathematical, symbolic code.  |
|  Every clinical rule references an FDA citation in source code.       |
+-----------------------------------------------------------------------+
```

**Reference:** See [`RULES_AND_GUARDRAILS.md § 2`](./RULES_AND_GUARDRAILS.md) for the full mandate.

---

## ⚡ Key Technical Facts

| Metric | Value | Source |
|---|---|---|
| CSP Solver Latency | **7 ms** | Measured — `core_engine/test/clinical_rules_test.dart` |
| Drug Registry Lookup | **< 1 ms** | Measured — `clinical_data/test/drug_registry_test.dart` |
| Unit Tests | **8 / 8 passing** | 4 × core_engine + 4 × clinical_data |
| FDA Drug Profiles | **50** | `clinical_data/data/top_50_drugs.json` |
| Core Engine Deps | **1** (`meta: ^1.11.0`) | `core_engine/pubspec.yaml` |
| Timeline Resolution | **15-minute intervals** | 96 discrete slots per day (ADR-001) |
| Chelation Gap | **≥ 240 minutes** | `constants/clinical_buffers.dart` |
| Fasting Pre-Meal Buffer | **≥ 60 minutes** | `constants/clinical_buffers.dart` |
| Fasting Post-Meal Buffer | **≥ 120 minutes** | `constants/clinical_buffers.dart` |
