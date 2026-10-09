# Wireframes funcionales

## Portal Paciente

```text
┌──────────────────────────────────────────────────────────────────┐
│ FHIR Clinical Flow                          Canal: web            │
├───────────────────────┬──────────────────────────────────────────┤
│ Paciente              │ Horarios disponibles                    │
│ Cobertura             │ ○ 07/10/2026 · 08:00 — 09:00           │
│ Sede                  │ ○ 07/10/2026 · 09:30 — 10:30           │
│ Servicio              │                                          │
│ Profesional           │ [ Confirmar horario seleccionado ]      │
│ Tipo de consulta      │                                          │
│ [Consultar]           │ Appointment/{id}                         │
├───────────────────────┴──────────────────────────────────────────┤
│ Mis citas                                                        │
└──────────────────────────────────────────────────────────────────┘
```

## Consola Agendador

```text
┌──────────────────────────────────────────────────────────────────┐
│ Agenda | Nueva cita · Call Center                                │
├───────────────────────────────────────┬──────────────────────────┤
│ paciente | fecha | servicio | canal   │ Detalle                  │
│ ...                                   │ [Cancelar cita]          │
│                                       │ [RESET DEMO]             │
└───────────────────────────────────────┴──────────────────────────┘
```

## Portal Clínico

```text
┌───────────────────────────┬──────────────────────────────────────┐
│ Agenda clínica            │ Atención activa                     │
│ paciente / hora / estado  │ TA 150 / 95                         │
│ [INICIAR ATENCIÓN]        │ Condition / ServiceRequest          │
│                           │ [PREPARAR TRANSACCIÓN]               │
│                           │ Bundle JSON                          │
│                           │ [PROCESAR TRANSACCIÓN SIMULADA]     │
├───────────────────────────┴──────────────────────────────────────┤
│ Timeline FHIR                                                     │
└──────────────────────────────────────────────────────────────────┘
```

## FHIR Studio

```text
Resources | JSON | Graph | Transactions | REST Trace | Validation
History   | Audit | Capability | Architecture
```
