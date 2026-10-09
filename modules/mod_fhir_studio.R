mod_fhir_studio_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(
      class="page-heading page-heading-pro",
      htmltools::tags$div(
        htmltools::tags$div(class="page-kicker","INTEROPERABILITY WORKBENCH"),
        htmltools::tags$h2("FHIR Studio"),
        htmltools::tags$p("Inspección técnica del repositorio, referencias, transacciones, validación y trazabilidad del prototipo.")
      ),
      htmltools::tags$div(class="page-actions",htmltools::tags$span(class="context-pill technical","FHIR R4 4.0.1"),htmltools::tags$span(class="context-pill live","● SIMULATED CORE"))
    ),
    htmltools::tags$div(
      class="studio-command-strip",
      htmltools::tags$div(htmltools::tags$span("01"),htmltools::tags$strong("Inspect"),htmltools::tags$small("Resources / JSON")),
      htmltools::tags$div(htmltools::tags$span("02"),htmltools::tags$strong("Understand"),htmltools::tags$small("Graph / History")),
      htmltools::tags$div(htmltools::tags$span("03"),htmltools::tags$strong("Validate"),htmltools::tags$small("OperationOutcome")),
      htmltools::tags$div(htmltools::tags$span("04"),htmltools::tags$strong("Trace"),htmltools::tags$small("REST / Audit"))
    ),
    bslib::navset_card_tab(
      bslib::nav_panel("Resources",mod_resource_explorer_ui(ns("resources"))),
      bslib::nav_panel("JSON",mod_json_viewer_ui(ns("json"))),
      bslib::nav_panel("Graph",mod_fhir_graph_ui(ns("graph"))),
      bslib::nav_panel("Transactions",htmltools::tags$div(class="studio-code-panel",htmltools::tags$div(class="studio-code-header",htmltools::tags$strong("Latest Bundle transaction"),htmltools::tags$span("request + response")),htmltools::tags$pre(class="json-view",shiny::textOutput(ns("latest_bundle"))))),
      bslib::nav_panel("REST Trace",mod_rest_trace_ui(ns("trace"))),
      bslib::nav_panel("Validation",mod_validation_ui(ns("validation"))),
      bslib::nav_panel("History",shiny::uiOutput(ns("history"))),
      bslib::nav_panel("Audit",mod_audit_ui(ns("audit"))),
      bslib::nav_panel("Capability",htmltools::tags$div(class="studio-code-panel",htmltools::tags$div(class="studio-code-header",htmltools::tags$strong("Simulated CapabilityStatement"),htmltools::tags$span("Supported resources & interactions")),htmltools::tags$pre(class="json-view",shiny::textOutput(ns("capability"))))),
      bslib::nav_panel(
        "Architecture",
        htmltools::tags$div(
          class="architecture-panel architecture-panel-pro",
          htmltools::tags$div(class="architecture-comparison",
            htmltools::tags$section(class="architecture-card current",htmltools::tags$div(class="architecture-card-label","PROTOTIPO ACTUAL"),htmltools::tags$h4("Validación funcional local"),htmltools::tags$pre("Patient / Scheduler / Clinician\n            ↓\n         R / Shiny\n            ↓\n Simulated FHIR Core\n            ↓\nFHIR Resources + JSON\n            ↓\nBundle / Audit / History")),
            htmltools::tags$div(class="architecture-evolve","→",htmltools::tags$small("EVOLUCIONA")),
            htmltools::tags$section(class="architecture-card target",htmltools::tags$div(class="architecture-card-label","ARQUITECTURA OBJETIVO"),htmltools::tags$h4("Plataforma FHIR productiva"),htmltools::tags$pre("Web / Mobile / HIS\n        ↓\n     API / BFF\n        ↓\n  FHIR Server R4\n        ↓\nDatabase + Services"))
          ),
          htmltools::tags$div(class="architecture-note",htmltools::tags$strong("Principio de migración:")," el prototipo valida contrato, recursos y flujos; el siguiente paso sustituye el Store simulado sin rediseñar las experiencias de usuario.")
        )
      )
    )
  )
}
mod_fhir_studio_server <- function(id,store){
  shiny::moduleServer(id,function(input,output,session){
    explorer <- mod_resource_explorer_server("resources",store)
    selected_resource <- mod_json_viewer_server("json",store,explorer$selected_key)
    mod_fhir_graph_server("graph",store,explorer$selected_key)
    mod_rest_trace_server("trace",store)
    mod_validation_server("validation",store,selected_resource)
    mod_audit_server("audit",store)

    output$history <- shiny::renderUI({
      r <- selected_resource()
      if(is.null(r)) return(htmltools::tags$div(class="empty-state","Seleccione un recurso en Resources."))
      h <- fhir_history(store,r$resourceType,r$id)
      htmltools::tags$div(
        class="history-grid",
        lapply(h,function(v)
          htmltools::tags$details(
            htmltools::tags$summary(paste("Version",v$meta$versionId,"·",v$meta$lastUpdated)),
            htmltools::tags$pre(class="json-view compact",json_pretty(v))
          )
        )
      )
    })

    output$capability <- shiny::renderText({
      cap <- state_resource(store(),"CapabilityStatement","simulated-acme-capability")
      json_pretty(cap)
    })

    output$latest_bundle <- shiny::renderText({
      b <- store()$last_transaction_bundle
      if(is.null(b)) return("Aún no hay transacciones Bundle. Reserve una cita o procese una atención clínica.")
      json_pretty(list(request=b,response=store()$last_transaction_response))
    })
  })
}
