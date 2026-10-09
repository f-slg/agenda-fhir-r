mod_ai_copilot_ui <- function(id){
  ns<-shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(
      class="page-heading page-heading-pro",
      htmltools::tags$div(htmltools::tags$div(class="page-kicker","AI-ASSISTED CLINICAL WORKFLOW"),htmltools::tags$h2("FHIR Clinical Copilot"),htmltools::tags$p("Recuperación local, propuestas estructuradas y revisión humana antes de cualquier escritura FHIR.")),
      htmltools::tags$div(class="page-actions",shiny::uiOutput(ns("mode")),htmltools::tags$span(class="context-pill","Human in the loop"))
    ),
    htmltools::tags$div(class="ai-safety-banner",htmltools::tags$strong("Guardrail activo:")," la IA no consulta ni escribe directamente en el Store. R recupera el contexto, la IA propone y una persona revisa."),
    htmltools::tags$div(
          class="responsive-grid form-layout",
      htmltools::tags$section(class="workflow-panel",htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Resumen longitudinal"),htmltools::tags$small("Contexto recuperado desde recursos FHIR")),htmltools::tags$span(class="technical-tag","RAG local")),shiny::selectInput(ns("patient"),"Paciente",choices=NULL),shiny::actionButton(ns("summary"),"Generar resumen",class="btn-primary w-100"),htmltools::tags$div(class="ai-output",shiny::textOutput(ns("summary_out"))),shiny::uiOutput(ns("sources"))),
      htmltools::tags$section(class="workflow-panel workflow-panel-accent",htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Extracción estructurada"),htmltools::tags$small("Texto libre → propuesta clínica revisable")),htmltools::tags$span(class="technical-tag","No auto-save")),shiny::textAreaInput(ns("note"),"Texto clínico","Paciente refiere cefalea de tres días. TA 150/95.",rows=5),shiny::actionButton(ns("extract"),"Generar propuesta",class="btn-outline-primary w-100"),shiny::uiOutput(ns("proposal")),htmltools::tags$p(class="small text-muted","La propuesta NO se guarda automáticamente. Debe revisarse y aprobarse dentro del flujo clínico."))
    )
  )
}
mod_ai_copilot_server <- function(id,store,selected_patient,selected_encounter){shiny::moduleServer(id,function(input,output,session){
  output$mode<-shiny::renderUI(htmltools::tags$span(class="context-pill technical",paste("AI MODE:",ai_mode())))
  shiny::observe({ps<-unname(store()$resources$Patient);ch<-setNames(vapply(ps,`[[`,character(1),"id"),vapply(ps,resource_display,character(1)));shiny::updateSelectInput(session,"patient",choices=ch,selected=selected_patient())})
  summary_text<-shiny::eventReactive(input$summary,{shiny::req(input$patient);local<-local_longitudinal_summary(store,input$patient);if(identical(ai_mode(),"Gemini connected")){ctx<-patient_context(store,input$patient);prompt<-paste("Resume de forma clínica y prudente estos datos FHIR sintéticos. No diagnostiques. Datos:",json_pretty(ctx));g<-gemini_generate(prompt);paste(local,"\n\n",g$text)}else local})
  output$summary_out<-shiny::renderText(summary_text())
  output$sources<-shiny::renderUI({shiny::req(input$patient);ctx<-patient_context(store,input$patient);refs<-unlist(lapply(ctx,function(xs)vapply(xs,resource_ref,character(1))),use.names=FALSE);htmltools::tags$div(class="source-list",htmltools::tags$strong("Sources"),lapply(unique(refs),htmltools::code))})
  proposal<-shiny::eventReactive(input$extract,{eid<-selected_encounter();if(is.null(eid)){encs<-Filter(function(e) identical(e$subject$reference,paste0("Patient/",input$patient)),unname(store()$resources$Encounter));eid<-if(length(encs))encs[[1]]$id else "enc-proposal-only"};ai_structured_proposal_local(input$note,paste0("Patient/",input$patient),paste0("Encounter/",eid))})
  output$proposal<-shiny::renderUI({p<-proposal();if(!length(p))return(htmltools::tags$div(class="empty-state","No se identificaron elementos estructurables en el fallback local."));htmltools::tags$div(class="proposal-box",htmltools::tags$strong("PROPUESTA DE IA / SIMULACIÓN"),lapply(p,function(x)htmltools::tags$pre(class="json-view compact",json_pretty(x))),htmltools::tags$div(class="review-actions",htmltools::tags$span(class="badge text-bg-warning","REVISIÓN HUMANA REQUERIDA"),htmltools::tags$span("Aprobar mediante el flujo clínico, modificar o rechazar.")))})
})}
