mod_home_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$section(
      class="hero hero-pro",
      htmltools::tags$div(
        class="hero-grid",
        htmltools::tags$div(
          htmltools::tags$div(class="eyebrow","FHIR CAMP · PROYECTO INTEGRADOR"),
          htmltools::tags$h1("FHIR Clinical Flow"),
          htmltools::tags$p(class="hero-sub","Una experiencia clínica interoperable, desde la disponibilidad hasta la atención."),
          htmltools::tags$p(class="hero-copy",APP_CONFIG$subtitle),
          htmltools::tags$div(
            class="hero-badges",
            htmltools::tags$span(class="hero-badge primary","FHIR R4"),
            htmltools::tags$span(class="hero-badge","Synthetic data"),
            htmltools::tags$span(class="hero-badge","Human-reviewed AI"),
            htmltools::tags$span(class="hero-badge","Shared state")
          )
        ),
        htmltools::tags$div(
          class="hero-clinical-card",
          htmltools::tags$div(class="hero-clinical-card-top",htmltools::tags$div(htmltools::tags$span(class="pulse-dot"),htmltools::tags$strong("Flujo interoperable activo")),htmltools::tags$span(class="technical-tag","SIMULATED CORE")),
          htmltools::tags$div(
            class="hero-path hero-path-pro",
            htmltools::tags$div(class="hero-path-step",htmltools::tags$span(class="hero-path-index","01"),htmltools::tags$div(htmltools::tags$strong("Disponibilidad"),htmltools::tags$small("Schedule + Slot"))),
            htmltools::tags$div(class="hero-path-connector"),
            htmltools::tags$div(class="hero-path-step",htmltools::tags$span(class="hero-path-index","02"),htmltools::tags$div(htmltools::tags$strong("Reserva"),htmltools::tags$small("Appointment + Response"))),
            htmltools::tags$div(class="hero-path-connector"),
            htmltools::tags$div(class="hero-path-step",htmltools::tags$span(class="hero-path-index","03"),htmltools::tags$div(htmltools::tags$strong("Atención"),htmltools::tags$small("Encounter + Clinical resources"))),
            htmltools::tags$div(class="hero-path-connector"),
            htmltools::tags$div(class="hero-path-step",htmltools::tags$span(class="hero-path-index","04"),htmltools::tags$div(htmltools::tags$strong("Trazabilidad"),htmltools::tags$small("Bundle + Audit + Provenance")))
          )
        )
      )
    ),
    htmltools::tags$div(
      class="metric-grid",
      htmltools::tags$div(class="metric-card",htmltools::tags$span(class="metric-icon pro","PT"),htmltools::tags$div(htmltools::tags$span(class="metric-label","Pacientes sintéticos"),shiny::textOutput(ns("n_patient"),inline=TRUE))),
      htmltools::tags$div(class="metric-card",htmltools::tags$span(class="metric-icon pro","SL"),htmltools::tags$div(htmltools::tags$span(class="metric-label","Slots disponibles"),shiny::textOutput(ns("n_slots"),inline=TRUE))),
      htmltools::tags$div(class="metric-card",htmltools::tags$span(class="metric-icon pro","AP"),htmltools::tags$div(htmltools::tags$span(class="metric-label","Citas en store"),shiny::textOutput(ns("n_apps"),inline=TRUE))),
      htmltools::tags$div(class="metric-card",htmltools::tags$span(class="metric-icon pro","RT"),htmltools::tags$div(htmltools::tags$span(class="metric-label","Operaciones REST"),shiny::textOutput(ns("n_trace"),inline=TRUE)))
    ),
    htmltools::tags$div(
      class="home-pro-grid",
      htmltools::tags$section(
        class="section-shell architecture-shell",
        htmltools::tags$div(class="section-title-row",htmltools::tags$div(htmltools::tags$div(class="page-kicker","ARQUITECTURA"),htmltools::tags$h3("Un contrato, múltiples experiencias")),htmltools::tags$span(class="technical-tag","Shared FHIR state")),
        htmltools::tags$div(
          class="arch-flow arch-flow-pro",
          htmltools::tags$div(class="arch-node","Paciente / Call Center / Médico"),
          htmltools::tags$div(class="arch-arrow","→"),
          htmltools::tags$div(class="arch-node","FHIR Operations"),
          htmltools::tags$div(class="arch-arrow","→"),
          htmltools::tags$div(class="arch-node emphasis","Simulated FHIR Core"),
          htmltools::tags$div(class="arch-arrow","→"),
          htmltools::tags$div(class="arch-node","FHIR Resources")
        ),
        htmltools::tags$div(class="principle","Las interfaces cambian. El contrato interoperable permanece.")
      ),
      htmltools::tags$section(
        class="section-shell proof-shell",
        htmltools::tags$div(class="page-kicker","QUÉ DEMUESTRA"),
        htmltools::tags$h3("Más que una agenda"),
        htmltools::tags$div(class="proof-list",
          htmltools::tags$div(class="proof-item",htmltools::tags$span("✓"),htmltools::tags$div(htmltools::tags$strong("Estado compartido"),htmltools::tags$small("La misma cita es visible en todos los canales."))),
          htmltools::tags$div(class="proof-item",htmltools::tags$span("✓"),htmltools::tags$div(htmltools::tags$strong("Trazabilidad"),htmltools::tags$small("Versiones, REST trace, Provenance y AuditEvent."))),
          htmltools::tags$div(class="proof-item",htmltools::tags$span("✓"),htmltools::tags$div(htmltools::tags$strong("Continuidad clínica"),htmltools::tags$small("Appointment evoluciona hacia Encounter y recursos clínicos."))),
          htmltools::tags$div(class="proof-item",htmltools::tags$span("✓"),htmltools::tags$div(htmltools::tags$strong("Arquitectura evolutiva"),htmltools::tags$small("Lista para sustituir el Core simulado por un servidor FHIR real.")))
        )
      )
    )
  )
}

mod_home_server <- function(id,store){
  shiny::moduleServer(id,function(input,output,session){
    output$n_patient <- shiny::renderText(length(store()$resources$Patient))
    output$n_slots <- shiny::renderText(sum(vapply(store()$resources$Slot,function(x) identical(x$status,"free"),logical(1))))
    output$n_apps <- shiny::renderText(length(store()$resources$Appointment))
    output$n_trace <- shiny::renderText(nrow(store()$rest_trace))
  })
}
