# ChronoMed

> **Clinical-Grade Polypharmacy & Nutrition Living Timeline**  
> Pure Deterministic Constraint-Satisfaction Scheduling Engine powered by Flutter & Dart.

---

## 🌟 The Problem ChronoMed Solves
Existing medication reminders (Apple Health, Medisafe) are **static alarms**. They do not understand that:
* **Levothyroxine** must be taken on an empty stomach ($\ge 60$m before breakfast, coffee, or milk).
* **Calcium & Iron** bind to thyroid medications and quinolones via **chelation**, destroying up to 80% bioavailability unless spaced by $\ge 4$ hours.
* **Metformin** requires food within 30 minutes to prevent severe gastrointestinal distress.
* **Statins** require evening/bedtime chronotherapy to inhibit peak nocturnal cholesterol synthesis.

When a patient sleeps in on a weekend or reschedules a meal, ChronoMed's **pure Dart CSP engine** dynamically recalculates a collision-free 24-hour timeline in **$<10$ milliseconds**.

---

## 📚 Master Documentation Hub
For complete production-grade specifications, architecture diagrams, and clinical guardrails, refer to the [`doc/`](./doc/) directory:

- 📄 **[PRD (Product Requirements Document)](./doc/PRD.md)**
- 🏗️ **[HLD (High-Level Architecture & System Topology)](./doc/HLD.md)**
- ⚙️ **[LLD (Low-Level Design & Database Schema)](./doc/LLD.md)**
- 🛠️ **[TECH_STACK (Technology Matrix & Rationales)](./doc/TECH_STACK.md)**
- 🏛️ **[ADR (Architecture Decision Records)](./doc/ADR.md)**
- 🔌 **[API & Events Specification](./doc/API_AND_EVENTS.md)**
- 🛡️ **[Security, Privacy & HIPAA/GDPR Compliance](./doc/SECURITY_AND_COMPLIANCE.md)**
- 📖 **[Clinical Guardrails & Production Standards](./doc/RULES_AND_GUARDRAILS.md)**
- 🚀 **[Developer Setup & Implementation Guide](./doc/DEVELOPMENT_GUIDE.md)**

---

## 🏗️ Repository Architecture

```
chronomed/
├── doc/               # 10 Enterprise Architecture & Compliance Documents
├── core_engine/       # Pure Dart Constraint Satisfaction Engine (Zero UI, <10ms)
│   ├── lib/           # Interval Math, CSP Solver, Dynamic Recalibrator
│   ├── bin/           # CLI Simulation Runner (run_simulation.dart)
│   └── test/          # 100% Clinical Rule & Latency Unit Tests
├── clinical_data/     # Curated Top 50 Polypharmacy Drugs JSON & Registry
└── app/               # Flutter Client (Living Timeline, CustomPainter, Drift DB)
```

---

## 🚀 Quickstart & Simulation

To run the standalone clinical simulation in terminal:
```bash
cd core_engine
dart run bin/run_simulation.dart
```

To run clinical safety unit tests:
```bash
cd core_engine
dart test
```
