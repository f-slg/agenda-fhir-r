# Arquitectura

```text
Patient Portal ───┐
Scheduler ────────┼── Application Services ── FHIR Operations ── SIMULATED FHIR CORE
Clinician ────────┤                                      │
FHIR Studio ──────┘                             Resources / History / Transactions
AI Copilot ─ local retrieval ─ Gemini(optional)          │
                                             Provenance / Audit / REST Trace
```

## Principio

FHIR no es una capa decorativa del frontend. Es el **modelo de estado compartido**. Todos los módulos llaman `fhir_create`, `fhir_read`, `fhir_update`, `fhir_search` o `fhir_transaction`.

## Arquitectura objetivo

```text
Web / Mobile / HIS → API/BFF → FHIR Server R4 → Database
```

El prototipo actual valida el modelado y los flujos. No afirma tener HAPI FHIR, SMART on FHIR, OAuth, servidor terminológico ni persistencia clínica productiva.
