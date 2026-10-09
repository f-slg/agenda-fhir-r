mod_clinician_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(
      class="page-heading page-heading-pro",
      htmltools::tags$div(
        htmltools::tags$div(class="page-kicker","ESPACIO CLÍNICO"),
        htmltools::tags$h2("Portal clínico"),
        htmltools::tags$p("Agenda, atención y registro clínico sintético conectado al mismo contrato interoperable.")
      ),
      htmltools::tags$div(class="page-actions",htmltools::tags$span(class="context-pill live","● Sesión clínica"),htmltools::tags$span(class="context-pill","Usuario: médico"))
    ),
    shiny::uiOutput(ns("clinical_kpis")),
    shiny::uiOutput(ns("clinical_week")),
    htmltools::tags$div(
      class="clinical-command-grid",
      htmltools::tags$section(
        class="clinical-side-panel",
        htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Agenda de atención"),htmltools::tags$small("Seleccione una cita reservada")),htmltools::tags$span(class="technical-tag","Appointment")),
        DT::DTOutput(ns("agenda")),
        shiny::actionButton(ns("start"),"Iniciar atención",class="btn-primary w-100 mt-2")
      ),
      htmltools::tags$section(
        class="clinical-main-panel",
        htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Workspace clínico"),htmltools::tags$small("Registro sintético sujeto a transacción FHIR")),htmltools::tags$span(class="technical-tag","Encounter")),
        shiny::uiOutput(ns("encounter_info")),
        htmltools::tags$div(class="form-section-label","Signos vitales"),
        htmltools::tags$div(
          class="vitals-grid",
          htmltools::tags$div(class="vital-input",htmltools::tags$span(class="vital-icon","SYS"),shiny::numericInput(ns("sys"),"TA sistólica",150,min=50,max=260)),
          htmltools::tags$div(class="vital-input",htmltools::tags$span(class="vital-icon","DIA"),shiny::numericInput(ns("dia"),"TA diastólica",95,min=30,max=160))
        ),
        shiny::uiOutput(ns("vitals_context")),
        htmltools::tags$div(class="form-section-label","Evaluación y plan"),
        htmltools::tags$div(
          class="responsive-grid form-layout",
          shiny::textInput(ns("condition"),"Problema clínico sintético","Hipertensión arterial"),
          shiny::textInput(ns("request"),"Solicitud","Perfil renal")
        ),
        shiny::selectInput(ns("request_cat"),"Tipo de solicitud",choices=c("Laboratorio"="laboratory","Imagen"="imaging","Interconsulta"="referral")),
        shiny::textAreaInput(ns("care_plan"),"Plan (opcional)","Control de presión arterial y seguimiento."),
        htmltools::tags$div(
          class="clinical-action-row",
          shiny::actionButton(ns("prepare"),"Preparar transacción",class="btn-outline-primary"),
          shiny::actionButton(ns("process"),"Procesar transacción simulada",class="btn-success")
        ),
        shiny::uiOutput(ns("transaction_preview"))
      )
    ),
    htmltools::tags$section(
      class="timeline-panel",
      htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Historia longitudinal"),htmltools::tags$small("Timeline generada desde recursos FHIR del Store")),htmltools::tags$span(class="technical-tag","Patient context")),
      shiny::uiOutput(ns("timeline"))
    )
  )
}

mod_clinician_server <- function(id,store,selected_patient,selected_appointment,selected_encounter){
  shiny::moduleServer(id,function(input,output,session){
    output$vitals_context <- shiny::renderUI({
      pid <- selected_patient()
      observations <- Filter(function(r) identical(r$subject$reference, paste0("Patient/", pid)) &&
        !r$status %in% c("cancelled", "entered-in-error"), unname(store()$resources$Observation))
      clinical_vitals_ui(observations)
    })
    agenda_rows <- shiny::reactive({
      apps <- Filter(function(a) a$status %in% c("booked","fulfilled"),unname(store()$resources$Appointment))
      if(!length(apps)) return(data.frame())
      do.call(rbind,lapply(apps,function(a){
        pr <- Filter(function(z) startsWith(z,"Patient/"),extract_references(a))
        p <- if(length(pr)) state_resource(store(),"Patient",get_ref_id(pr[[1]])) else NULL
        data.frame(
          id=a$id,
          paciente=resource_display(p),
          fecha=substr(a$start,1,10),
          hora=substr(a$start,12,16),
          fin=substr(a$end %||% "",12,16),
          servicio=first_coding_display(a$serviceType[[1]]),
          estado=a$status,
          canal=extract_extension_value(a,APP_CONFIG$channel_extension_url) %||% "",
          stringsAsFactors=FALSE
        )
      }))
    })

    output$clinical_kpis <- shiny::renderUI(appointment_kpis_ui(agenda_rows(), "Actividad clínica"))
    output$clinical_week <- shiny::renderUI(week_schedule_ui(agenda_rows(), title="Agenda clínica semanal", max_days=7, start_hour=7, end_hour=19))

    output$agenda <- DT::renderDT({
      df <- agenda_rows()
      if(nrow(df)) df <- df[,c("paciente","fecha","hora","servicio","estado"),drop=FALSE]
      DT::datatable(df,selection="single",rownames=FALSE,colnames=c("Paciente","Fecha","Hora","Servicio","Estado"),options=list(scrollX=TRUE,dom="t",pageLength=10,order=list(list(1,"asc"),list(2,"asc"))))
    })

    chosen <- shiny::reactive({
      i <- input$agenda_rows_selected
      if(!length(i) || !nrow(agenda_rows())) return(NULL)
      agenda_rows()[i,,drop=FALSE]
    })

    shiny::observe({
      x <- chosen()
      if(!is.null(x)){
        selected_appointment(x$id[[1]])
        app <- state_resource(store(),"Appointment",x$id[[1]])
        pr <- Filter(function(z) startsWith(z,"Patient/"),extract_references(app))
        if(length(pr)) selected_patient(get_ref_id(pr[[1]]))
      }
    })

    shiny::observeEvent(input$start,{
      x <- chosen(); shiny::req(x)
      if(!identical(x$estado[[1]],"booked")){
        shiny::showNotification("La cita ya fue iniciada o completada.",type="warning")
        return()
      }
      tx <- start_encounter(store,x$id[[1]])
      if(isTRUE(tx$success)){
        selected_encounter(tx$encounter_id)
        shiny::showNotification("Encounter iniciado",type="message")
      } else shiny::showNotification(tx$outcome$issue[[1]]$diagnostics,type="error")
    })

    output$encounter_info <- shiny::renderUI({
      eid <- selected_encounter()
      if(is.null(eid)) return(htmltools::tags$div(class="encounter-empty",htmltools::tags$div(class="encounter-empty-icon","＋"),htmltools::tags$strong("No hay atención activa"),htmltools::tags$span("Seleccione una cita reservada e inicie el Encounter.")))
      e <- state_resource(store(),"Encounter",eid)
      if(is.null(e)) return(NULL)
      pid <- selected_patient()
      p <- state_resource(store(),"Patient",pid)
      pname <- resource_display(p)
      initials <- if(nzchar(pname)) paste0(substr(pname,1,1),substr(sub(".*\\s+","",pname),1,1)) else "PT"
      htmltools::tags$div(
        class="encounter-patient-card",
        htmltools::tags$div(class="patient-avatar large",toupper(initials)),
        htmltools::tags$div(class="encounter-patient-main",htmltools::tags$span(class="encounter-label","Atención activa"),htmltools::tags$strong(pname),htmltools::tags$code(paste0("Patient/",pid))),
        htmltools::tags$div(class="encounter-status",status_badge(e$status),htmltools::tags$code(paste0("Encounter/",e$id)))
      )
    })

    prepared_bundle <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$prepare,{
      eid <- selected_encounter(); shiny::req(eid)
      enc <- state_resource(store(),"Encounter",eid)
      if(is.null(enc) || !identical(enc$status,"in-progress")){
        shiny::showNotification("No existe un Encounter activo para preparar.",type="warning")
        return()
      }
      prep <- build_clinical_transaction(
        store,eid,c(input$sys,input$dia),input$condition,input$request,input$request_cat,input$care_plan
      )
      if(!isTRUE(prep$success)){
        shiny::showNotification(prep$outcome$issue[[1]]$diagnostics,type="error")
        return()
      }
      prepared_bundle(prep$bundle)
      shiny::showNotification("Bundle preparado. Revíselo antes de procesar.",type="message")
    })

    output$transaction_preview <- shiny::renderUI({
      b <- prepared_bundle()
      if(is.null(b)) return(htmltools::tags$div(class="transaction-empty",htmltools::tags$span("Bundle pendiente"),"Prepare la transacción para revisar los recursos antes del commit."))
      htmltools::tags$div(
        class="proposal-box proposal-box-pro",
        htmltools::tags$div(class="proposal-header",htmltools::tags$span(class="context-pill technical","Bundle.type = transaction"),htmltools::tags$span(class="review-state","PENDIENTE DE PROCESAR")),
        htmltools::tags$pre(class="json-view compact",json_pretty(b))
      )
    })

    shiny::observeEvent(input$process,{
      b <- prepared_bundle(); shiny::req(b)
      tx <- fhir_transaction(store,b,source="clinician",user="clinician")
      if(isTRUE(tx$success)){
        prepared_bundle(NULL)
        shiny::showNotification("Transacción clínica procesada",type="message")
      } else shiny::showNotification(tx$outcome$issue[[1]]$diagnostics,type="error")
    })

    output$timeline <- shiny::renderUI({
      pid <- selected_patient(); shiny::req(pid)
      types <- c("Appointment","Encounter","Observation","Condition","ServiceRequest","CarePlan")
      items <- list()
      for(t in types){
        rs <- Filter(function(r) paste0("Patient/",pid) %in% extract_references(r),unname(store()$resources[[t]]))
        for(r in rs){
          when <- r$effectiveDateTime %||% r$recordedDate %||% r$authoredOn %||% r$period$start %||% r$start %||% r$meta$lastUpdated
          label <- switch(
            t,
            Observation=first_coding_display(r$code),
            Condition=first_coding_display(r$code),
            ServiceRequest=first_coding_display(r$code),
            CarePlan=r$description %||% "CarePlan",
            Appointment=first_coding_display(r$serviceType[[1]]),
            Encounter=paste("Encounter",r$status),
            t
          )
          items[[length(items)+1]] <- list(type=t,id=r$id,when=when,label=label)
        }
      }
      if(!length(items)) return(htmltools::tags$div(class="empty-state","Sin eventos"))
      ord <- order(vapply(items,function(x) x$when,character(1)),decreasing=TRUE)
      htmltools::tags$div(
        class="timeline timeline-pro",
        lapply(items[ord],function(x)
          htmltools::tags$div(
            class=paste("timeline-item",paste0("timeline-",tolower(x$type))),
            htmltools::tags$div(class="timeline-dot"),
            htmltools::tags$div(
              class="timeline-card",
              htmltools::tags$div(class="timeline-card-top",htmltools::tags$strong(x$label),htmltools::tags$span(class="timeline-type",x$type)),
              htmltools::tags$div(class="timeline-meta",htmltools::tags$span(x$when),htmltools::tags$code(paste0(x$type,"/",x$id)))
            )
          )
        )
      )
    })
  })
}
