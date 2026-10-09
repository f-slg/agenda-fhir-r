options(shiny.maxRequestSize = 10 * 1024^2)

required <- c("shiny", "bslib", "jsonlite", "htmltools", "DT")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(
    "Faltan paquetes: ", paste(missing, collapse = ", "),
    ". Ejecute primero: Rscript scripts/00_install_packages.R",
    call. = FALSE
  )
}

source_order <- c(
  "R/config.R", "R/utils.R", "R/business_rules.R", "R/fhir_resources.R",
  "R/fhir_references.R", "R/fhir_validation.R", "R/audit.R", "R/provenance.R",
  "R/fhir_store.R", "R/fhir_search.R", "R/fhir_bundle.R", "R/fhir_transaction.R",
  "R/seed.R", "R/ai_gateway.R",
  "modules/mod_home.R", "modules/mod_patient_portal.R", "modules/mod_scheduler.R",
  "modules/mod_clinician.R", "modules/mod_resource_explorer.R", "modules/mod_json_viewer.R",
  "modules/mod_fhir_graph.R", "modules/mod_rest_trace.R", "modules/mod_validation.R",
  "modules/mod_audit.R", "modules/mod_fhir_studio.R", "modules/mod_ai_copilot.R",
  "R/ui.R", "R/server.R"
)

missing_files <- source_order[!file.exists(source_order)]
if (length(missing_files)) {
  stop("Faltan archivos del proyecto: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

for (f in source_order) source(f, local = FALSE, encoding = "UTF-8")

shiny::shinyApp(ui = app_ui(), server = app_server)
