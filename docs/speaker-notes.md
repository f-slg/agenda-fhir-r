# Notas del presentador — FHIR Clinical Flow

## 1. FHIR Clinical Flow
El proyecto parte de un requerimiento administrativo sencillo: unificar agendas de tres sedes. La decisión de arquitectura fue evitar tres agendas conectadas por sincronización y construir un único modelo de estado interoperable. En esta demo no afirmamos disponer de un servidor FHIR productivo; simulamos localmente sus operaciones principales para validar el modelo y el flujo.

## 2. El problema
ACME Salud expone servicios distintos por sede y recibe solicitudes desde web, call center, móvil y ventanilla/HIS. Si cada canal mantiene su propia agenda, la interoperabilidad se vuelve un problema posterior. Aquí hacemos lo contrario: todos los canales operan sobre los mismos recursos.

## 3. La decisión
FHIR no aparece al final como formato de exportación. Patient, Coverage, Schedule, Slot y Appointment son el contrato común del sistema. Por eso una cita creada por call center puede ser vista inmediatamente por el portal del paciente sin replicar estructuras.

## 4. Modelo común
Organization representa ACME y las aseguradoras; Location las sedes; HealthcareService los servicios; Practitioner y PractitionerRole separan persona de función; Schedule y Slot modelan disponibilidad; Appointment la reserva y AppointmentResponse la respuesta del participante.

## 5. Disponibilidad
La UI nunca inventa horas. Primero consulta Schedule y después Slot. Para especialidades, Schedule.actor combina HealthcareService, PractitionerRole y Location. Para medicina general no inventamos profesionales ausentes en el enunciado: usamos servicio más sede.

## 6. Cobertura y duración
Coverage conecta Patient con la Organization pagadora. La duración no está hardcodeada en la interfaz: un motor de reglas separado recibe aseguradora y tipo de consulta y devuelve minutos.

## 7. Reserva transaccional
Reservar implica varias mutaciones relacionadas. El prototipo construye un Bundle transaction con actualización de Slot, creación de Appointment, AppointmentResponse y Provenance. Se valida sobre un estado staged y solo entonces se hace commit. Esto permite demostrar atomicidad conceptual.

## 8. Interoperabilidad entre canales
Portal Paciente y Consola Agendador no se sincronizan entre sí. Ambos consultan el mismo Simulated FHIR Core. La sincronización surge de compartir contrato y fuente de verdad.

## 9. Portal del paciente
Aquí ocultamos jerga técnica. El usuario identifica paciente, cobertura, sede, servicio, profesional, tipo y Slot. Al confirmar, el backend genera recursos FHIR y el portal muestra un resumen derivado de Appointment.

## 10. Agendador
La vista operativa permite revisar canal de origen, crear desde call center y cancelar. Cancelar no elimina Appointment: cambia el estado, registra cancelationReason, declina AppointmentResponse y libera Slot.

## 11. Portal clínico
Appointment es planificación; Encounter es atención realizada. Al iniciar atención, se crea Encounter relacionado con Appointment. Al terminar se prepara un nuevo Bundle clínico que el usuario puede revisar antes de procesar.

## 12. Observations
La presión arterial se representa como Observation con components; se usan LOINC para el panel, sistólica y diastólica, y UCUM para mmHg. El propósito es demostrar semántica estándar sin convertir la demo en una HCE completa.

## 13. FHIR Studio
FHIR Studio es la interfaz para la audiencia técnica: Resources, JSON, Graph, Transactions, REST Trace, Validation, History, Audit, Capability y Architecture. El grafo se genera desde referencias reales del Store.

## 14. Trazabilidad
Provenance documenta la producción o transición relevante de recursos. AuditEvent y el registro técnico permiten explicar quién hizo qué, desde qué canal y con qué resultado, evitando datos sensibles innecesarios.

## 15. IA asistida
Gemini es opcional. R recupera primero el contexto FHIR local; la IA recibe solo ese contexto y genera una propuesta. La propuesta no se persiste directamente. Debe pasar por validación y revisión humana.

## 16. Arquitectura actual
La demo usa R/Shiny y un Store en memoria. Las operaciones FHIR, history, transaction, validation y search se simulan con alta fidelidad suficiente para enseñanza y validación de diseño.

## 17. Arquitectura objetivo
En producción se sustituiría el Store simulado por un servidor FHIR R4 real detrás de API/BFF, con persistencia, seguridad y gobernanza. La interfaz podría cambiar sin romper el contrato.

## 18. Limitaciones
No hay HAPI FHIR, SMART on FHIR real, OAuth real, Keycloak, MPI, terminología productiva, PACS/DICOM ni facturación. Esta transparencia es parte de la calidad técnica del proyecto.

## 19. Roadmap
El siguiente paso no es añadir más pantallas: es sustituir la simulación por infraestructura real, perfilar recursos, integrar terminología y autenticación y aplicar pruebas de conformidad.

## 20. Cierre
Partimos de una agenda. El resultado es una demostración de contrato interoperable que continúa desde disponibilidad hasta atención, trazabilidad e IA asistida. Las interfaces cambian; el contrato interoperable permanece.
