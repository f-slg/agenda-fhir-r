# Decisiones FHIR R4

- Se usa **FHIR R4 4.0.1**.
- `Practitioner` representa a la persona; `PractitionerRole`, su función/servicio/sede.
- `Schedule.actor` modela la unidad agendable. Para especialidades combina `HealthcareService`, `PractitionerRole` y `Location`; para medicina general usa servicio + sede.
- Los horarios provienen exclusivamente de `Slot`; la UI no fabrica horas.
- `AppointmentResponse` se usa como respuesta de un participante, no como comprobante comercial. El resumen al paciente se deriva de `Appointment` y referencias.
- El canal de origen no tiene un elemento base R4 que represente exactamente el requerimiento. Se usa la extensión local `https://acme.example.org/fhir/StructureDefinition/appointment-origin-channel` con valores `web`, `call-center`, `mobile`, `front-desk`.
- Cancelar una cita no elimina el recurso: `Appointment.status` pasa a `cancelled`, se usa `Appointment.cancelationReason`, `AppointmentResponse.participantStatus` pasa a `declined` y el `Slot.status` vuelve a `free`.
- Las operaciones multi-recurso se empaquetan como `Bundle.type = transaction` y se aplican de forma atómica en el Store simulado.
- `Provenance` documenta creación/transición de recursos importantes. La tabla técnica de auditoría demuestra READ/CREATE/UPDATE/SEARCH/TRANSACTION sin almacenar datos sensibles innecesarios.
- La IA jamás persiste directamente. Recuperación local → propuesta → validación → revisión humana → mapeo FHIR → Store.
