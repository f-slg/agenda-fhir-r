cat("=== FHIR Clinical Flow | PRE-FLIGHT ===\n")
cat("R:", R.version.string, "\n")
cat("Directorio:", normalizePath(getwd(), winslash = "/", mustWork = FALSE), "\n")
cat(".libPaths():\n")
cat(paste0("  - ", .libPaths(), collapse = "\n"), "\n\n")

if (getRversion() < "4.3.0") stop("Se requiere R >= 4.3.0", call. = FALSE)

required <- c("shiny", "bslib", "jsonlite", "htmltools", "DT")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(
    "Paquetes faltantes: ", paste(missing, collapse = ", "),
    ". Ejecute: Rscript scripts/00_install_packages.R",
    call. = FALSE
  )
}

cat("Paquetes runtime:\n")
for (pkg in required) {
  cat(sprintf("  %-10s %s\n", pkg, as.character(utils::packageVersion(pkg))))
}
if (requireNamespace("visNetwork", quietly = TRUE)) {
  cat(sprintf("  %-10s %s\n", "visNetwork", as.character(utils::packageVersion("visNetwork"))))
} else {
  cat("  visNetwork  no instalado; se usará fallback textual del grafo\n")
}
cat("\n")

files <- c(
  "app.R", "R/config.R", "R/utils.R", "R/business_rules.R",
  "R/fhir_resources.R", "R/fhir_references.R", "R/fhir_validation.R",
  "R/fhir_store.R", "R/fhir_search.R", "R/fhir_bundle.R",
  "R/fhir_transaction.R", "R/seed.R", "R/ui.R", "R/server.R",
  "modules/mod_patient_portal.R", "modules/mod_scheduler.R",
  "modules/mod_clinician.R", "modules/mod_fhir_studio.R", "www/app.css"
)
missing_files <- files[!file.exists(files)]
if (length(missing_files)) {
  stop("Faltan archivos: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

source_order <- c(
  "R/config.R", "R/utils.R", "R/business_rules.R", "R/fhir_resources.R",
  "R/fhir_references.R", "R/fhir_validation.R", "R/audit.R", "R/provenance.R",
  "R/fhir_store.R", "R/fhir_search.R", "R/fhir_bundle.R", "R/fhir_transaction.R",
  "R/seed.R"
)
for (f in source_order) source(f, local = FALSE, encoding = "UTF-8")

seed <- build_seed_resources()
stopifnot(length(seed) > 40)
state <- new_empty_state()
for (r in seed) state <- set_resource_in_state(state, r)

expected <- c(
  Patient = 10,
  Location = 3,
  Practitioner = 6,
  Appointment = 12,
  AppointmentResponse = 12,
  Encounter = 8
)
for (rt in names(expected)) {
  actual <- length(state$resources[[rt]])
  if (actual != unname(expected[[rt]])) {
    stop(sprintf("Seed inválido: %s esperaba %s y encontró %s", rt, expected[[rt]], actual), call. = FALSE)
  }
}

stopifnot(
  !is.null(state$resources$Schedule[["sch-cardio-sur"]]),
  !is.null(state$resources$Slot[["slot-cardio-20261007-0800"]])
)

for (r in seed) {
  v <- validate_resource(r, state)
  if (!v$valid) {
    stop(
      "Validation failed for ", resource_ref(r), ": ",
      v$outcome$issue[[1]]$diagnostics,
      call. = FALSE
    )
  }
}

invisible(jsonlite::toJSON(seed[[1]], auto_unbox = TRUE))

# Smoke test transaccional aislado.
shiny::isolate({
store <- seed_store()
slot_before <- state_resource(store(), "Slot", "slot-cardio-20261007-0800")
stopifnot(identical(slot_before$status, "free"))

tx <- book_appointment(
  store,
  "pat-001", "Salud Completa", "loc-sur", "hs-cardio-sur",
  "role-fonseca-cardio", "slot-cardio-20261007-0800",
  "control-specialist", "call-center", "preflight"
)
stopifnot(isTRUE(tx$success))
stopifnot(identical(state_resource(store(), "Slot", "slot-cardio-20261007-0800")$status, "busy"))

search_hit <- fhir_search(
  store, "Appointment", list(patient = "pat-001"),
  source = "preflight", record = FALSE
)
stopifnot(any(vapply(search_hit$resources, function(x) identical(x$id, tx$appointment_id), logical(1))))

# Smoke test de componentes visuales Clinical UI.
slot_preview <- slot_calendar_ui(list(state_resource(store(), "Slot", "slot-cardio-20261008-0800")))
stopifnot(inherits(slot_preview, "shiny.tag"))
calendar_preview <- appointment_calendar_ui(data.frame(
  fecha = c("2026-10-09", "2026-10-10"),
  hora = c("09:00", "08:00"),
  estado = c("booked", "booked"),
  stringsAsFactors = FALSE
))
stopifnot(inherits(calendar_preview, "shiny.tag"))
stopifnot(inherits(status_badge("booked"), "shiny.tag"))
professional_df <- data.frame(
  id = c("app-a", "app-b"),
  paciente = c("Paciente A", "Paciente B"),
  fecha = c("2026-10-09", "2026-10-09"),
  hora = c("08:00", "09:00"),
  fin = c("08:45", "09:30"),
  servicio = c("Cardiología", "Medicina general"),
  estado = c("booked", "fulfilled"),
  canal = c("web", "call-center"),
  stringsAsFactors = FALSE
)
stopifnot(inherits(week_schedule_ui(professional_df), "shiny.tag"))
stopifnot(inherits(appointment_kpis_ui(professional_df), "shiny.tag"))
preview_slot <- state_resource(store(), "Slot", "slot-cardio-20261008-0800")
if (!is.null(preview_slot)) stopifnot(inherits(availability_summary_ui(list(preview_slot)), "shiny.tag"))

# Compile all module UIs and the shared responsive shell (without starting a server).
for (f in list.files("modules", pattern="[.]R$", full.names=TRUE)) source(f, local=FALSE)
source("R/ui.R")
stopifnot(grepl("appointment-inspector", as.character(mod_scheduler_ui("qa")), fixed=TRUE))
stopifnot(grepl("booking-layout", as.character(mod_patient_portal_ui("qa")), fixed=TRUE))
stopifnot(grepl("Sin registro", as.character(clinical_vitals_ui(list())), fixed=TRUE))
stopifnot(grepl("responsive-grid", as.character(mod_ai_copilot_ui("qa")), fixed=TRUE))
invisible(htmltools::renderTags(app_ui()))
cat("\nPRE-FLIGHT OK\n")
cat("Siguiente paso:\n  Rscript scripts/02_run_app.R\n")

})
