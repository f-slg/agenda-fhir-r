mod_scheduler_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(
      class="page-heading page-heading-pro",
      htmltools::tags$div(
        htmltools::tags$div(class="page-kicker","OPERACIÓN DE AGENDAMIENTO"),
        htmltools::tags$h2("Consola del agendador"),
        htmltools::tags$p("Vista operativa común para call center, admisiones, recepción y HIS sobre un único FHIR Store.")
      ),
      htmltools::tags$div(
        class="page-actions",
        htmltools::tags$span(class="context-pill live","● Store sincronizado"),
        htmltools::tags$span(class="context-pill","FHIR R4")
      )
    ),
    bslib::navset_card_tab(
      bslib::nav_panel(
        "Agenda operativa",
        htmltools::tags$div(class="scheduler-dashboard", shiny::uiOutput(ns("agenda_kpis"))),
        shiny::dateInput(ns("week_start"),"Semana de referencia", value=Sys.Date(), language="es", format="dd/mm/yyyy", weekstart=1),
        shiny::uiOutput(ns("weekly_agenda")),
        htmltools::tags$div(
          class="section-divider-label",
          htmltools::tags$span("Detalle y gestión"),
          htmltools::tags$small("Seleccione una cita en la tabla para operar sobre ella")
        ),
        htmltools::tags$div(
          class="responsive-grid inspector-layout",
          htmltools::tags$div(
            class="agenda-table-panel",
            htmltools::tags$div(
              class="panel-heading-inline",
              htmltools::tags$div(htmltools::tags$strong("Citas del repositorio"), htmltools::tags$small("Appointment · todos los canales")),
              htmltools::tags$span(class="technical-tag","FHIR Search view")
            ),
            DT::DTOutput(ns("appointments"))
          ),
          htmltools::tags$aside(
            class="appointment-inspector",
            htmltools::tags$div(class="inspector-title","Cita seleccionada"),
            shiny::uiOutput(ns("selected_info")),
            htmltools::tags$div(class="form-section-label","Gestión"),
            shiny::selectInput(
              ns("cancel_reason"),"Motivo de cancelación",
              choices=c(
                "Solicitud del paciente"="patient-request",
                "Cambio de disponibilidad"="provider-unavailable",
                "Duplicada"="duplicate"
              )
            ),
            shiny::actionButton(ns("cancel"),"Cancelar cita",class="btn-danger w-100"),
            htmltools::tags$div(class="inspector-separator"),
            shiny::actionButton(ns("reset"),"Restaurar datos de demo",class="btn-outline-secondary w-100")
          )
        )
      ),
      bslib::nav_panel(
        "Nueva cita · Call Center",
        htmltools::tags$div(
          class="workflow-header",
          htmltools::tags$div(class="workflow-number","01"),
          htmltools::tags$div(htmltools::tags$strong("Nueva solicitud"),htmltools::tags$span("Identifique paciente, cobertura y necesidad de atención.")),
          htmltools::tags$div(class="workflow-line"),
          htmltools::tags$div(class="workflow-number","02"),
          htmltools::tags$div(htmltools::tags$strong("Disponibilidad"),htmltools::tags$span("Consulte Schedule/Slot y confirme el horario."))
        ),
        htmltools::tags$div(
          class="responsive-grid request-layout",
          htmltools::tags$section(
            class="workflow-panel",
            htmltools::tags$div(class="workflow-panel-title","Datos de la solicitud"),
            shiny::selectInput(ns("new_patient"),"Paciente",choices=NULL),
            shiny::uiOutput(ns("new_coverage")),
            shiny::selectInput(ns("new_location"),"Sede",choices=NULL),
            shiny::selectInput(ns("new_service"),"Servicio",choices=NULL),
            shiny::uiOutput(ns("new_role_ui")),
            shiny::selectInput(ns("new_consult_type"),"Tipo de consulta",choices=NULL),
            shiny::actionButton(ns("new_search"),"Consultar disponibilidad",class="btn-outline-primary w-100")
          ),
          htmltools::tags$section(
            class="workflow-panel workflow-panel-accent",
            htmltools::tags$div(class="workflow-panel-title","Disponibilidad FHIR"),
            shiny::uiOutput(ns("new_duration")),
            shiny::uiOutput(ns("new_availability_summary")),
            shiny::uiOutput(ns("new_calendar")),
            shiny::selectInput(ns("new_slot"),"Horario disponible",choices=NULL),
            shiny::actionButton(ns("new_book"),"Crear cita desde Call Center",class="btn-primary w-100"),
            htmltools::tags$hr(),
            shiny::uiOutput(ns("new_result"))
          )
        )
      )
    )
  )
}

mod_scheduler_server <- function(id,store,selected_patient,selected_appointment){
  shiny::moduleServer(id,function(input,output,session){
    rows <- shiny::reactive({
      apps <- unname(store()$resources$Appointment)
      if(!length(apps)) return(data.frame())
      do.call(rbind,lapply(apps,function(a){
        patient_ref <- Filter(function(z) startsWith(z,"Patient/"),extract_references(a))
        p <- if(length(patient_ref)) state_resource(store(),"Patient",get_ref_id(patient_ref[[1]])) else NULL
        data.frame(
          id=a$id,
          paciente=resource_display(p),
          fecha=substr(a$start %||% "",1,10),
          hora=substr(a$start %||% "",12,16),
          fin=substr(a$end %||% "",12,16),
          servicio=first_coding_display(a$serviceType[[1]]),
          estado=a$status,
          canal=extract_extension_value(a,APP_CONFIG$channel_extension_url) %||% "",
          stringsAsFactors=FALSE
        )
      }))
    })

    output$appointments <- DT::renderDT({
      df <- rows()
      if(nrow(df)) df <- df[,c("id","paciente","fecha","hora","fin","servicio","estado","canal"),drop=FALSE]
      DT::datatable(
        df,
        selection="single",
        rownames=FALSE,
        colnames=c("ID","Paciente","Fecha","Inicio","Fin","Servicio","Estado","Canal"),
        options=list(scrollX=TRUE,pageLength=10,dom="ftip",autoWidth=TRUE,order=list(list(2,"asc"),list(3,"asc")))
      )
    })

    output$agenda_kpis <- shiny::renderUI(appointment_kpis_ui(rows(), "Pulso de la agenda"))
    output$weekly_agenda <- shiny::renderUI({
      week_schedule_ui(rows(), title="Agenda semanal", max_days=7, start_hour=7, end_hour=19, start_date=input$week_start %||% Sys.Date())
    })

    chosen <- shiny::reactive({
      i <- input$appointments_rows_selected
      if(!length(i) || !nrow(rows())) return(NULL)
      rows()[i,,drop=FALSE]
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

    output$selected_info <- shiny::renderUI({
      x <- chosen()
      if(is.null(x)) return(htmltools::tags$div(class="inspector-empty",htmltools::tags$div(class="inspector-empty-icon","↖"),htmltools::tags$strong("Sin selección"),htmltools::tags$span("Seleccione una cita en la tabla.")))
      appointment <- state_resource(store(), "Appointment", x$id[[1]])
      participants <- Filter(function(z) grepl("^Practitioner(Role)?/", z), extract_references(appointment))
      professionals <- vapply(participants, function(z) {
        r <- state_resource(store(), get_ref_type(z), get_ref_id(z))
        if (identical(get_ref_type(z), "PractitionerRole") && !is.null(r$practitioner$reference))
          r <- state_resource(store(), "Practitioner", get_ref_id(r$practitioner$reference))
        resource_display(r)
      }, character(1))
      professional_label <- if (length(professionals)) paste(unique(professionals), collapse=", ") else "Agenda por servicio"
      initials <- paste0(substr(x$paciente,1,1), substr(sub(".*\\s+", "", x$paciente),1,1))
      htmltools::tags$div(
        class="appointment-profile",
        htmltools::tags$div(class="patient-avatar",toupper(initials)),
        htmltools::tags$div(class="appointment-profile-main",htmltools::tags$strong(x$paciente),htmltools::tags$span(x$servicio)),
        status_badge(x$estado),
        htmltools::tags$div(
          class="appointment-facts",
          htmltools::tags$div(htmltools::tags$span("Profesional"),htmltools::tags$strong(professional_label)),
          htmltools::tags$div(htmltools::tags$span("Fecha"),htmltools::tags$strong(paste(x$fecha,x$hora))),
          htmltools::tags$div(htmltools::tags$span("Fin"),htmltools::tags$strong(x$fin)),
          htmltools::tags$div(htmltools::tags$span("Canal"),htmltools::tags$strong(x$canal)),
          htmltools::tags$div(htmltools::tags$span("FHIR"),htmltools::tags$code(paste0("Appointment/",x$id)))
        )
      )
    })

    shiny::observeEvent(input$cancel,{
      x <- chosen(); shiny::req(x)
      tx <- cancel_appointment(store,x$id[[1]],input$cancel_reason,"scheduler")
      if(isTRUE(tx$success)) shiny::showNotification("Cita cancelada; Slot liberado",type="message")
      else shiny::showNotification(tx$outcome$issue[[1]]$diagnostics,type="error")
    })

    shiny::observeEvent(input$reset,{
      shiny::showModal(shiny::modalDialog(
        title="Restaurar demo",
        "Se restaurarán exactamente los datos sintéticos iniciales.",
        footer=shiny::tagList(
          shiny::modalButton("Volver"),
          shiny::actionButton(session$ns("confirm_reset"),"Restaurar",class="btn-danger")
        )
      ))
    })

    shiny::observeEvent(input$confirm_reset,{
      store(seed_store()())
      selected_appointment(NULL)
      selected_patient("pat-001")
      shiny::removeModal()
      shiny::showNotification("Demo restaurada",type="message")
    })

    # ---- Creación desde Call Center ----
    shiny::observe({
      ps <- unname(store()$resources$Patient)
      ch <- setNames(vapply(ps,`[[`,character(1),"id"),vapply(ps,resource_display,character(1)))
      shiny::updateSelectInput(session,"new_patient",choices=ch,selected="pat-001")
    })

    shiny::observe({
      ls <- unname(store()$resources$Location)
      ch <- setNames(vapply(ls,`[[`,character(1),"id"),vapply(ls,resource_display,character(1)))
      shiny::updateSelectInput(session,"new_location",choices=ch,selected="loc-sur")
    })

    output$new_coverage <- shiny::renderUI({
      shiny::req(input$new_patient)
      covs <- Filter(function(x) identical(x$beneficiary$reference,paste0("Patient/",input$new_patient)),unname(store()$resources$Coverage))
      pay <- if(length(covs)) state_resource(store(),"Organization",get_ref_id(covs[[1]]$payor[[1]]$reference)) else NULL
      htmltools::tags$div(class="coverage-box",htmltools::tags$strong("Cobertura"),htmltools::tags$span(resource_display(pay)))
    })

    shiny::observe({
      shiny::req(input$new_location)
      services <- Filter(
        function(x) paste0("Location/",input$new_location) %in% extract_references(x),
        unname(store()$resources$HealthcareService)
      )
      ch <- setNames(vapply(services,`[[`,character(1),"id"),vapply(services,resource_display,character(1)))
      shiny::updateSelectInput(session,"new_service",choices=ch)
    })

    output$new_role_ui <- shiny::renderUI({
      shiny::req(input$new_service)
      roles <- Filter(
        function(x) paste0("HealthcareService/",input$new_service) %in% extract_references(x),
        unname(store()$resources$PractitionerRole)
      )
      if(!length(roles)) return(htmltools::tags$div(class="muted-box","Medicina general: agenda por servicio/sede."))
      role_labels <- vapply(roles,function(x){
        p <- state_resource(store(),"Practitioner",get_ref_id(x$practitioner$reference))
        resource_display(p)
      },character(1))
      choices <- setNames(vapply(roles,`[[`,character(1),"id"),role_labels)
      shiny::selectInput(session$ns("new_role"),"Profesional",choices=choices)
    })

    shiny::observe({
      shiny::req(input$new_service)
      svc <- state_resource(store(),"HealthcareService",input$new_service)
      choices <- if(is_specialist_service(svc$name))
        c("Primera vez"="first-specialist","Control"="control-specialist","Control telemedicina"="tele-control-specialist")
      else
        c("Primera vez"="first-general","Control"="control-general","Control telemedicina"="tele-control-general")
      shiny::updateSelectInput(session,"new_consult_type",choices=choices)
    })

    selected_new_role_id <- shiny::reactive({
      shiny::req(input$new_service)
      roles <- Filter(
        function(x) paste0("HealthcareService/",input$new_service) %in% extract_references(x),
        unname(store()$resources$PractitionerRole)
      )
      if(!length(roles)) return(NULL)
      ids <- vapply(roles,`[[`,character(1),"id")
      if(!is.null(input$new_role) && input$new_role %in% ids) input$new_role else ids[[1]]
    })

    new_insurer <- shiny::reactive({
      shiny::req(input$new_patient)
      covs <- Filter(function(x) identical(x$beneficiary$reference,paste0("Patient/",input$new_patient)),unname(store()$resources$Coverage))
      if(!length(covs)) return(NULL)
      state_resource(store(),"Organization",get_ref_id(covs[[1]]$payor[[1]]$reference))$name
    })

    output$new_duration <- shiny::renderUI({
      shiny::req(new_insurer(),input$new_consult_type)
      mins <- get_consultation_duration(new_insurer(),input$new_consult_type)
      htmltools::tags$div(class="coverage-box",htmltools::tags$strong("Duración por regla"),htmltools::tags$span(paste(mins,"minutos")))
    })

    new_slots <- shiny::eventReactive(input$new_search,{
      shiny::req(input$new_location,input$new_service)
      schedules <- Filter(function(s){
        refs <- vapply(s$actor,`[[`,character(1),"reference")
        paste0("HealthcareService/",input$new_service) %in% refs &&
          paste0("Location/",input$new_location) %in% refs &&
          (is.null(selected_new_role_id()) || paste0("PractitionerRole/",selected_new_role_id()) %in% refs)
      },unname(store()$resources$Schedule))
      if(!length(schedules)) return(list())
      srefs <- paste0("Schedule/",vapply(schedules,`[[`,character(1),"id"))
      Filter(function(s) identical(s$status,"free") && s$schedule$reference %in% srefs,unname(store()$resources$Slot))
    },ignoreInit=TRUE)

    output$new_availability_summary <- shiny::renderUI(availability_summary_ui(new_slots()))
    output$new_calendar <- shiny::renderUI({
      slots <- new_slots()
      if(!length(slots)) return(NULL)
      slot_calendar_ui(slots)
    })

    shiny::observeEvent(new_slots(),{
      slots <- new_slots()
      ch <- if(length(slots)) {
        labels <- vapply(slots,function(s) paste(format(parse_fhir_datetime(s$start),"%d/%m %H:%M"),"–",format(parse_fhir_datetime(s$end),"%H:%M")),character(1))
        setNames(vapply(slots,`[[`,character(1),"id"),labels)
      } else character()
      shiny::updateSelectInput(session,"new_slot",choices=ch)
    },ignoreInit=TRUE)

    last_new <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$new_book,{
      shiny::req(input$new_patient,input$new_location,input$new_service,input$new_slot,new_insurer(),input$new_consult_type)
      tx <- book_appointment(
        store,
        input$new_patient,
        new_insurer(),
        input$new_location,
        input$new_service,
        selected_new_role_id(),
        input$new_slot,
        input$new_consult_type,
        "call-center",
        "scheduler-call-center"
      )
      last_new(tx)
      if(isTRUE(tx$success)){
        selected_patient(input$new_patient)
        selected_appointment(tx$appointment_id)
        shiny::showNotification("Cita creada desde Call Center",type="message")
      }
    })

    output$new_result <- shiny::renderUI({
      x <- last_new()
      if(is.null(x)) return(htmltools::tags$div(class="empty-state","Consulte disponibilidad y seleccione un Slot."))
      if(!isTRUE(x$success)) return(htmltools::tags$div(class="alert alert-danger",x$outcome$issue[[1]]$diagnostics))
      htmltools::tags$div(
        class="confirmation confirmation-pro",
        htmltools::tags$div(class="confirmation-icon","✓"),
        htmltools::tags$div(
          htmltools::tags$h4("Cita creada"),
          htmltools::tags$p(paste0("Appointment/",x$appointment_id)),
          htmltools::tags$small("Canal registrado: call-center")
        )
      )
    })
  })
}
