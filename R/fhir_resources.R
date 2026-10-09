base_resource <- function(resourceType, id, version="1") list(resourceType=resourceType, id=id, meta=list(versionId=as.character(version), lastUpdated=fhir_now()))
make_patient <- function(id, given, family, birthDate, identifier_value) {
  c(base_resource("Patient",id), list(identifier=list(identifier("urn:acme:patient",identifier_value)), active=TRUE,
    name=list(list(use="official", family=family, given=list(given))), birthDate=birthDate))
}
make_org <- function(id, name, org_type="insurer", identifier_value=NULL) {
  x <- c(base_resource("Organization",id), list(active=TRUE, name=name, type=list(cc("http://terminology.hl7.org/CodeSystem/organization-type", org_type, org_type))))
  if (!is.null(identifier_value)) x$identifier <- list(identifier("urn:acme:organization",identifier_value))
  x
}
make_location <- function(id, name, identifier_value) c(base_resource("Location",id), list(status="active", name=name, identifier=list(identifier("urn:acme:location",identifier_value))))
make_service <- function(id, name, location_ref) c(base_resource("HealthcareService",id), list(active=TRUE, name=name, location=list(ref(location_ref))))
make_practitioner <- function(id, given, family, license) c(base_resource("Practitioner",id), list(active=TRUE, identifier=list(identifier("urn:acme:professional-license",license)), name=list(list(use="official",family=family,given=list(given)))))
make_practitioner_role <- function(id, practitioner_ref, org_ref, service_ref, location_ref, specialty) c(base_resource("PractitionerRole",id), list(active=TRUE, practitioner=ref(practitioner_ref), organization=ref(org_ref), healthcareService=list(ref(service_ref)), location=list(ref(location_ref)), specialty=list(cc("http://snomed.info/sct", NULL, specialty))))
make_coverage <- function(id, patient_ref, payor_ref) c(base_resource("Coverage",id), list(status="active", beneficiary=ref(patient_ref), payor=list(ref(payor_ref))))
make_schedule <- function(id, actor_refs, planning_start, planning_end, name=NULL) c(base_resource("Schedule",id), list(active=TRUE, actor=lapply(actor_refs, ref), planningHorizon=list(start=planning_start,end=planning_end), comment=name %||% "Agenda mensual ACME"))
make_slot <- function(id, schedule_ref, start, end, status="free", service_name=NULL) {
  x <- c(base_resource("Slot",id), list(schedule=ref(schedule_ref), status=status, start=start, end=end))
  if (!is.null(service_name)) x$serviceType <- list(cc("urn:acme:service", gsub(" ","-",tolower(service_name)), service_name))
  x
}
make_appointment <- function(id, patient_ref, slot_ref, start, end, service_name, location_ref, practitioner_role_ref=NULL, channel="web", status="booked", consultation_type="first-specialist", minutes=NULL) {
  parts <- list(list(actor=ref(patient_ref), status="accepted"), list(actor=ref(location_ref), status="accepted"))
  if (!is.null(practitioner_role_ref)) parts <- append(parts, list(list(actor=ref(practitioner_role_ref), status="accepted")))
  x <- c(base_resource("Appointment",id), list(status=status, serviceType=list(cc("urn:acme:service", gsub(" ","-",tolower(service_name)), service_name)), appointmentType=cc("urn:acme:consultation-type", consultation_type, consultation_type), start=start, end=end, slot=list(ref(slot_ref)), participant=parts, extension=list(make_channel_extension(channel))))
  if (!is.null(minutes)) x$minutesDuration <- as.integer(minutes)
  x
}
make_appointment_response <- function(id, appointment_ref, actor_ref, status="accepted", start=NULL, end=NULL, comment=NULL) {
  x <- c(base_resource("AppointmentResponse",id), list(appointment=ref(appointment_ref), actor=ref(actor_ref), participantStatus=status))
  if (!is.null(start)) x$start <- start
  if (!is.null(end)) x$end <- end
  if (!is.null(comment)) x$comment <- comment
  x
}
make_encounter <- function(id, patient_ref, appointment_ref, practitioner_role_ref=NULL, status="in-progress", start=fhir_now()) {
  part <- if (!is.null(practitioner_role_ref)) list(list(individual=ref(practitioner_role_ref))) else NULL
  x <- c(base_resource("Encounter",id), list(status=status, class=coding_item("http://terminology.hl7.org/CodeSystem/v3-ActCode","AMB","ambulatory"), subject=ref(patient_ref), appointment=list(ref(appointment_ref)), period=list(start=start)))
  if (!is.null(part)) x$participant <- part
  x
}
make_bp_observation <- function(id, patient_ref, encounter_ref, systolic, diastolic, effective=fhir_now()) c(base_resource("Observation",id), list(status="final", category=list(cc("http://terminology.hl7.org/CodeSystem/observation-category","vital-signs","Vital Signs")), code=cc("http://loinc.org","85354-9","Blood pressure panel with all children optional"), subject=ref(patient_ref), encounter=ref(encounter_ref), effectiveDateTime=effective, component=list(
  list(code=cc("http://loinc.org","8480-6","Systolic blood pressure"), valueQuantity=list(value=as.numeric(systolic),unit="mmHg",system="http://unitsofmeasure.org",code="mm[Hg]")),
  list(code=cc("http://loinc.org","8462-4","Diastolic blood pressure"), valueQuantity=list(value=as.numeric(diastolic),unit="mmHg",system="http://unitsofmeasure.org",code="mm[Hg]"))
)))
make_vital_observation <- function(id, patient_ref, encounter_ref, loinc, display, value, unit, ucum, effective=fhir_now()) c(base_resource("Observation",id), list(status="final", category=list(cc("http://terminology.hl7.org/CodeSystem/observation-category","vital-signs","Vital Signs")), code=cc("http://loinc.org",loinc,display), subject=ref(patient_ref), encounter=ref(encounter_ref), effectiveDateTime=effective, valueQuantity=list(value=as.numeric(value),unit=unit,system="http://unitsofmeasure.org",code=ucum)))
make_condition <- function(id, patient_ref, encounter_ref, text, code_value=NULL) c(base_resource("Condition",id), list(clinicalStatus=cc("http://terminology.hl7.org/CodeSystem/condition-clinical","active","Active"), verificationStatus=cc("http://terminology.hl7.org/CodeSystem/condition-ver-status","provisional","Provisional"), code=cc("urn:acme:condition", code_value %||% gsub(" ","-",tolower(text)), text), subject=ref(patient_ref), encounter=ref(encounter_ref), recordedDate=fhir_now()))
make_service_request <- function(id, patient_ref, encounter_ref, text, category="laboratory") c(base_resource("ServiceRequest",id), list(status="active", intent="order", category=list(cc("urn:acme:service-request-category",category,category)), code=cc("urn:acme:service-request",gsub(" ","-",tolower(text)),text), subject=ref(patient_ref), encounter=ref(encounter_ref), authoredOn=fhir_now()))
make_care_plan <- function(id, patient_ref, encounter_ref, description) c(base_resource("CarePlan",id), list(status="active", intent="plan", subject=ref(patient_ref), encounter=ref(encounter_ref), description=description, period=list(start=fhir_now())))
make_operation_outcome <- function(severity="error", code_value="invalid", diagnostics="Validation failed") c(base_resource("OperationOutcome",new_id("oo")), list(issue=list(list(severity=severity,code=code_value,diagnostics=diagnostics))))
make_capability_statement <- function() {
  resources <- lapply(setdiff(SUPPORTED_RESOURCE_TYPES, c("CapabilityStatement")), function(rt) list(type=rt, interaction=list(list(code="read"),list(code="search-type"),list(code="create"),list(code="update"))))
  c(base_resource("CapabilityStatement","simulated-acme-capability"), list(status="active",date=fhir_now(),kind="instance",fhirVersion="4.0.1",format=list("json"),description="SIMULATED CAPABILITY STATEMENT — educational prototype, not a live FHIR endpoint.",rest=list(list(mode="server",resource=resources))))
}
