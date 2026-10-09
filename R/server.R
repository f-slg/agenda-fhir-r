app_server <- function(input, output, session) {
  store <- seed_store()
  selected_patient <- shiny::reactiveVal("pat-001")
  selected_appointment <- shiny::reactiveVal(NULL)
  selected_encounter <- shiny::reactiveVal(NULL)
  mod_home_server("home",store)
  mod_patient_portal_server("patient",store,selected_patient,selected_appointment)
  mod_scheduler_server("scheduler",store,selected_patient,selected_appointment)
  mod_clinician_server("clinician",store,selected_patient,selected_appointment,selected_encounter)
  mod_fhir_studio_server("studio",store)
  mod_ai_copilot_server("ai",store,selected_patient,selected_encounter)
  session$userData$fhir_store <- store
}
