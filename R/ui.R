app_theme <- function() {
  # Use a plain CSS font stack instead of bslib::font_system().
  # bslib 0.12.0 accepts a character font stack in base_font, while
  # font_system() is not an exported bslib function in this environment.
  bslib::bs_theme(
    version = 5,
    bg = "#ffffff",
    fg = "#172033",
    primary = "#175fba",
    secondary = "#64748B",
    success = "#2F855A",
    warning = "#B7791F",
    danger = "#C2414B",
    base_font = '"Segoe UI", Inter, Arial, sans-serif'
  )
}

app_assets_ui <- function(asset_dir = "www") {
  # Embed raw assets, outside Sass. A sourced shinyApp object does not always
  # register the app directory's www route, unlike runApp(appDir = ".").
  files <- file.path(asset_dir, c("app.css", "ui.js"))
  if (any(!file.exists(files))) {
    stop("Faltan recursos de interfaz: ", paste(files[!file.exists(files)], collapse = ", "), call. = FALSE)
  }
  shiny::tagList(
    shiny::includeCSS(files[[1]]),
    shiny::includeScript(files[[2]])
  )
}

app_ui <- function() {
  bslib::page_navbar(
    title = htmltools::tags$div(
      class = "brand",
      htmltools::tags$img(
        class = "brand-logo",
        alt = "HL7 FHIR",
        src = paste0("data:image/png;base64,", jsonlite::base64_enc(
          readBin("www/hl7-fhir-logo.png", what = "raw", n = file.info("www/hl7-fhir-logo.png")$size)
        ))
      ),
      htmltools::tags$span("FHIR TEAM")
    ),
    theme = app_theme(),
    fillable = FALSE,
    window_title = APP_CONFIG$app_name,
    header = shiny::tagList(app_assets_ui(), htmltools::tags$div(
      class = "demo-strip",
      htmltools::tags$span("FHIR R4 4.0.1"),
      htmltools::tags$span("SIMULATED FHIR CORE"),
      htmltools::tags$span("SYNTHETIC DATA ONLY"),
      htmltools::tags$span("FHIR CAMP")
    )),
    bslib::nav_panel("Inicio", mod_home_ui("home")),
    bslib::nav_panel("Portal Paciente", mod_patient_portal_ui("patient")),
    bslib::nav_panel("Agendador", mod_scheduler_ui("scheduler")),
    bslib::nav_panel("Portal Clínico", mod_clinician_ui("clinician")),
    bslib::nav_panel("FHIR Studio", mod_fhir_studio_ui("studio")),
    bslib::nav_panel("AI Copilot", mod_ai_copilot_ui("ai")),
    footer = htmltools::tags$div(
      class = "app-footer",
      "FHIR Core simulado para fines educativos y de demostración. No constituye un sistema clínico productivo."
    )
  )
}
