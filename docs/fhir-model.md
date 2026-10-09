# Modelo común ACME

```text
Organization (ACME / aseguradoras)
  ├─ Location
  │   └─ HealthcareService
  │       └─ PractitionerRole ── Practitioner
  │             └─ Schedule ── Slot
  │                           └─ Appointment ── AppointmentResponse
  └─ Coverage ── Patient ─────────────┘
                         └─ Encounter
                             ├─ Observation
                             ├─ Condition
                             ├─ ServiceRequest
                             └─ CarePlan
```

El recurso `Slot` es el bloqueo concreto de disponibilidad. `Appointment` contiene la reserva, y `Encounter` documenta que la atención ocurrió.
