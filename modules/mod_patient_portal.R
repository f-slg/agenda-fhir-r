mod_patient_portal_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(
      class="page-heading page-heading-pro",
      htmltools::tags$div(
        htmltools::tags$div(class="page-kicker","EXPERIENCIA DEL PACIENTE"),
        htmltools::tags$h2("Portal del paciente"),
        htmltools::tags$p("Encuentre y reserve una cita usando disponibilidad clínica compartida en tiempo real dentro del FHIR Store simulado.")
      ),
      htmltools::tags$div(class="page-actions",htmltools::tags$span(class="context-pill live","● Disponibilidad conectada"),htmltools::tags$span(class="context-pill","Canal: web"))
    ),
    htmltools::tags$div(
      class="booking-stepper",
      htmltools::tags$div(class="booking-step active",htmltools::tags$span("1"),htmltools::tags$div(htmltools::tags$strong("Perfil"),htmltools::tags$small("Paciente y cobertura"))),
      htmltools::tags$div(class="booking-step-line"),
      htmltools::tags$div(class="booking-step active",htmltools::tags$span("2"),htmltools::tags$div(htmltools::tags$strong("Atención"),htmltools::tags$small("Sede y servicio"))),
      htmltools::tags$div(class="booking-step-line"),
      htmltools::tags$div(class="booking-step",htmltools::tags$span("3"),htmltools::tags$div(htmltools::tags$strong("Horario"),htmltools::tags$small("Schedule + Slot"))),
      htmltools::tags$div(class="booking-step-line"),
      htmltools::tags$div(class="booking-step",htmltools::tags$span("4"),htmltools::tags$div(htmltools::tags$strong("Confirmación"),htmltools::tags$small("Appointment")))
    ),
    htmltools::tags$div(
          class="responsive-grid booking-layout",
      htmltools::tags$section(
        class="booking-filter-panel",
        htmltools::tags$div(class="workflow-panel-title","Preferencias de atención"),
        shiny::selectInput(ns("patient"),"Paciente",choices=NULL),
        shiny::uiOutput(ns("coverage")),
        shiny::selectInput(ns("location"),"Sede",choices=NULL),
        shiny::selectInput(ns("service"),"Servicio",choices=NULL),
        shiny::uiOutput(ns("practitioner_ui")),
        shiny::selectInput(ns("consult_type"),"Tipo de consulta",choices=NULL),
        shiny::actionButton(ns("search_slots"),"Consultar disponibilidad",class="btn-primary w-100")
      ),
      htmltools::tags$section(
        class="booking-results-panel",
        htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Horarios disponibles"),htmltools::tags$small("Seleccione el horario que mejor se adapte a usted")),htmltools::tags$span(class="technical-tag","Schedule / Slot")),
        shiny::uiOutput(ns("duration")),
        shiny::uiOutput(ns("availability_summary")),
        shiny::uiOutput(ns("availability_calendar")),
        htmltools::tags$div(class="slot-selector", shiny::uiOutput(ns("slot_cards"))),
        shiny::actionButton(ns("book_selected"),"Confirmar horario seleccionado",class="btn-primary w-100"),
        shiny::uiOutput(ns("booking_result"))
      )
    ),
    htmltools::tags$section(
      class="appointments-panel",
      htmltools::tags$div(class="panel-heading-inline",htmltools::tags$div(htmltools::tags$strong("Mis citas"),htmltools::tags$small("Historial y próximas atenciones del paciente seleccionado")),htmltools::tags$span(class="technical-tag","Appointment search")),
      shiny::uiOutput(ns("my_appointments_calendar")),
      DT::DTOutput(ns("my_appointments"))
    )
  )
}
mod_patient_portal_server <- function(id,store,selected_patient,selected_appointment){
  shiny::moduleServer(id,function(input,output,session){
    ns <- session$ns
    patients <- shiny::reactive(unname(store()$resources$Patient))
    locations <- shiny::reactive(unname(store()$resources$Location))

    shiny::observe({
      ch <- setNames(vapply(patients(),`[[`,character(1),"id"),vapply(patients(),resource_display,character(1)))
      shiny::updateSelectInput(session,"patient",choices=ch,selected=selected_patient())
    })

    shiny::observe({
      ch <- setNames(vapply(locations(),`[[`,character(1),"id"),vapply(locations(),resource_display,character(1)))
      shiny::updateSelectInput(session,"location",choices=ch,selected="loc-sur")
    })

    patient_insurer <- shiny::reactive({
      shiny::req(input$patient)
      covs <- Filter(function(x) identical(x$beneficiary$reference,paste0("Patient/",input$patient)),unname(store()$resources$Coverage))
      if(!length(covs)) return(NULL)
      state_resource(store(),"Organization",get_ref_id(covs[[1]]$payor[[1]]$reference))
    })

    output$coverage <- shiny::renderUI({
      pay <- patient_insurer()
      htmltools::tags$div(class="coverage-box",htmltools::tags$strong("Cobertura"),htmltools::tags$span(resource_display(pay)))
    })

    shiny::observe({
      shiny::req(input$location)
      services <- Filter(
        function(x) paste0("Location/",input$location) %in% extract_references(x),
        unname(store()$resources$HealthcareService)
      )
      ch <- setNames(vapply(services,`[[`,character(1),"id"),vapply(services,resource_display,character(1)))
      shiny::updateSelectInput(session,"service",choices=ch)
    })

    output$practitioner_ui <- shiny::renderUI({
      shiny::req(input$service)
      roles <- Filter(
        function(x) paste0("HealthcareService/",input$service) %in% extract_references(x),
        unname(store()$resources$PractitionerRole)
      )
      if(!length(roles)) return(htmltools::tags$div(class="muted-box","Medicina general: disponibilidad por servicio/sede; profesional no obligatorio."))
      role_labels <- vapply(roles,function(x){
        p <- state_resource(store(),"Practitioner",get_ref_id(x$practitioner$reference))
        resource_display(p)
      },character(1))
      choices <- setNames(vapply(roles,`[[`,character(1),"id"),role_labels)
      shiny::selectInput(ns("role"),"Profesional",choices=choices)
    })

    shiny::observe({
      shiny::req(input$service)
      svc <- state_resource(store(),"HealthcareService",input$service)
      choices <- if(is_specialist_service(svc$name))
        c("Primera vez"="first-specialist","Control"="control-specialist","Control telemedicina"="tele-control-specialist")
      else
        c("Primera vez"="first-general","Control"="control-general","Control telemedicina"="tele-control-general")
      shiny::updateSelectInput(session,"consult_type",choices=choices)
    })

    selected_role_id <- shiny::reactive({
      shiny::req(input$service)
      roles <- Filter(
        function(x) paste0("HealthcareService/",input$service) %in% extract_references(x),
        unname(store()$resources$PractitionerRole)
      )
      if(!length(roles)) return(NULL)
      ids <- vapply(roles,`[[`,character(1),"id")
      if(!is.null(input$role) && input$role %in% ids) input$role else ids[[1]]
    })

    output$duration <- shiny::renderUI({
      shiny::req(patient_insurer(),input$consult_type)
      mins <- get_consultation_duration(patient_insurer()$name,input$consult_type)
      htmltools::tags$div(class="coverage-box",htmltools::tags$strong("Duración según cobertura"),htmltools::tags$span(paste(mins,"minutos")))
    })

    available_slots <- shiny::eventReactive(input$search_slots,{
      shiny::req(input$patient,input$location,input$service)
      schedules <- Filter(function(s){
        refs <- vapply(s$actor,`[[`,character(1),"reference")
        paste0("HealthcareService/",input$service) %in% refs &&
          paste0("Location/",input$location) %in% refs &&
          (is.null(selected_role_id()) || paste0("PractitionerRole/",selected_role_id()) %in% refs)
      },unname(store()$resources$Schedule))
      if(!length(schedules)) return(list())
      srefs <- paste0("Schedule/",vapply(schedules,`[[`,character(1),"id"))
      Filter(function(s) identical(s$status,"free") && s$schedule$reference %in% srefs,unname(store()$resources$Slot))
    },ignoreInit=TRUE)

    output$availability_summary <- shiny::renderUI(availability_summary_ui(available_slots()))

    output$availability_calendar <- shiny::renderUI({
      slots <- available_slots()
      if(!length(slots)) return(NULL)
      slot_calendar_ui(slots)
    })

    output$slot_cards <- shiny::renderUI({
      slots <- available_slots()
      if(!length(slots)) return(htmltools::tags$div(class="empty-state","Seleccione los criterios y consulte disponibilidad."))
      slot_labels <- vapply(slots,function(s)
        paste(format(parse_fhir_datetime(s$start),"%d/%m/%Y · %H:%M"),"—",format(parse_fhir_datetime(s$end),"%H:%M")),
        character(1)
      )
      choices <- setNames(vapply(slots,`[[`,character(1),"id"),slot_labels)
      shiny::radioButtons(ns("slot_choice"),NULL,choices=choices,selected=unname(choices[[1]]))
    })

    last_result <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$book_selected,{
      shiny::req(input$slot_choice,input$patient,input$location,input$service,input$consult_type,patient_insurer())
      tx <- book_appointment(
        store,
        input$patient,
        patient_insurer()$name,
        input$location,
        input$service,
        selected_role_id(),
        input$slot_choice,
        input$consult_type,
        "web",
        "patient-portal"
      )
      last_result(tx)
      if(isTRUE(tx$success)){
        selected_patient(input$patient)
        selected_appointment(tx$appointment_id)
        shiny::showNotification("Cita reservada en el FHIR Store simulado",type="message")
      } else shiny::showNotification(tx$outcome$issue[[1]]$diagnostics,type="error")
    })

    output$booking_result <- shiny::renderUI({
      x <- last_result()
      if(is.null(x)) return(NULL)
      if(!isTRUE(x$success)) return(htmltools::tags$div(class="alert alert-danger",x$outcome$issue[[1]]$diagnostics))
      app <- state_resource(store(),"Appointment",x$appointment_id)
      svc <- first_coding_display(app$serviceType[[1]])
      htmltools::tags$div(
        class="confirmation confirmation-pro",
        htmltools::tags$div(class="confirmation-icon","✓"),
        htmltools::tags$div(
        htmltools::tags$h4("Cita confirmada"),
        htmltools::tags$p(htmltools::tags$strong(svc)),
        htmltools::tags$p(paste(format(parse_fhir_datetime(app$start),"%d/%m/%Y %H:%M"),"—",format(parse_fhir_datetime(app$end),"%H:%M"))),
        htmltools::tags$small(paste0("FHIR: Appointment/",app$id))
        )
      )
    })

    output$my_appointments_calendar <- shiny::renderUI({
      shiny::req(input$patient)
      apps <- Filter(function(a) paste0("Patient/",input$patient) %in% extract_references(a),unname(store()$resources$Appointment))
      if(!length(apps)) return(NULL)
      df <- do.call(rbind,lapply(apps,function(a)
        data.frame(
          id=a$id,
          fecha=substr(a$start,1,10),
          hora=substr(a$start,12,16),
          servicio=first_coding_display(a$serviceType[[1]]),
          estado=a$status,
          stringsAsFactors=FALSE
        )
      ))
      appointment_calendar_ui(df, max_days=7, title="Próximas y recientes")
    })

    output$my_appointments <- DT::renderDT({
      shiny::req(input$patient)
      apps <- Filter(function(a) paste0("Patient/",input$patient) %in% extract_references(a),unname(store()$resources$Appointment))
      df <- if(length(apps)) do.call(rbind,lapply(apps,function(a)
        data.frame(
          id=a$id,
          fecha=substr(a$start,1,10),
          inicio=substr(a$start,12,16),
          servicio=first_coding_display(a$serviceType[[1]]),
          estado=a$status,
          canal=extract_extension_value(a,APP_CONFIG$channel_extension_url) %||% "",
          stringsAsFactors=FALSE
        )
      )) else data.frame()
      DT::datatable(df,rownames=FALSE,options=list(scrollX=TRUE,dom="t",pageLength=10))
    })
  })
}
