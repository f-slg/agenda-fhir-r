# Guion de demo — 12 a 15 minutos

1. **Inicio:** presentar el problema: tres sedes y múltiples canales; un solo contrato interoperable.
2. **FHIR Studio / Resources:** mostrar Patient, Coverage, Locations, HealthcareServices, PractitionerRoles, Schedules y Slots.
3. **Portal Paciente:** Carlos Andrade → Salud Completa → Sede Sur → Cardiología → Alonso Fonseca → consultar disponibilidad → reservar.
4. **Agendador:** mostrar que la cita apareció sin sincronización adicional porque comparte Store.
5. **FHIR Studio:** abrir Appointment JSON; mostrar canal, Slot y participantes; revisar REST Trace.
6. **Portal Clínico:** seleccionar cita e iniciar atención; esto crea Encounter ligado a Appointment.
7. Registrar TA 150/95, condición y ServiceRequest; finalizar Encounter.
8. **Timeline:** demostrar que la historia se construye desde recursos FHIR, no desde una segunda estructura.
9. **FHIR Studio:** validar Observation, Condition, ServiceRequest, History, Provenance y Audit.
10. **Cancelación:** en Agendador cancelar otra cita; enseñar `cancelationReason` y liberación de Slot.
11. **AI Copilot:** solo si es estable. Mostrar recuperación local y propuesta sujeta a revisión humana.
12. **Cierre:** “Las interfaces cambian. El contrato interoperable permanece.”
