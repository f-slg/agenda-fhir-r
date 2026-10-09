APP_CONFIG <- list(
  app_name = "FHIR Clinical Flow",
  subtitle = "Prototipo integrador de atención y agendamiento basado en HL7 FHIR R4",
  fhir_version = "4.0.1",
  timezone = "America/Guayaquil",
  base_url = "/fhir",
  synthetic_only = TRUE,
  simulated_core = TRUE,
  channel_extension_url = "https://acme.example.org/fhir/StructureDefinition/appointment-origin-channel",
  default_user = "demo-user",
  gemini_model = Sys.getenv("GEMINI_MODEL", unset = "gemini-2.5-flash")
)
SUPPORTED_RESOURCE_TYPES <- c(
  "Patient","Organization","Coverage","Location","HealthcareService","Practitioner",
  "PractitionerRole","Schedule","Slot","Appointment","AppointmentResponse","Encounter",
  "Observation","Condition","ServiceRequest","CarePlan","Provenance","AuditEvent",
  "Bundle","OperationOutcome","CapabilityStatement"
)
