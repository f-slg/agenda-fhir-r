apply_entry_to_state <- function(state,entry) {
  method <- toupper(entry$request$method %||% ""); url <- entry$request$url %||% ""; r <- entry$resource
  if (method == "POST") {
    rt <- r$resourceType; id <- r$id %||% new_id(tolower(rt)); if(!is.null(state$resources[[rt]][[id]])) stop("Conflict creating ",rt,"/",id)
    r$id <- id; r <- versioned_resource(r,NULL); state <- set_resource_in_state(state,r); return(list(state=state,resource=r,status=201L))
  }
  if (method == "PUT") {
    parts <- strsplit(url,"/",fixed=TRUE)[[1]]; if(length(parts)<2) stop("PUT url must be ResourceType/id")
    rt <- parts[[1]]; id <- parts[[2]]; previous <- state$resources[[rt]][[id]]; if(is.null(previous)) stop("Resource not found for PUT: ",url)
    r$resourceType <- rt; r$id <- id; r <- versioned_resource(r,previous); state <- set_resource_in_state(state,r); return(list(state=state,resource=r,status=200L))
  }
  stop("Unsupported transaction method: ",method)
}
fhir_transaction <- function(store,bundle,source="system",user=APP_CONFIG$default_user) {
  if (!identical(bundle$resourceType,"Bundle") || !identical(bundle$type,"transaction")) return(list(success=FALSE,http_status=400L,outcome=make_operation_outcome(diagnostics="Bundle.type must be transaction")))
  v <- validate_resource(bundle,NULL); if(!v$valid) return(list(success=FALSE,http_status=422L,outcome=v$outcome))
  original <- store(); staged <- original; results <- list()
  err <- tryCatch({
    for (i in seq_along(bundle$entry)) {
      a <- apply_entry_to_state(staged,bundle$entry[[i]]); staged <- a$state
      rv <- validate_resource(a$resource,staged); if(!rv$valid) stop(rv$outcome$issue[[1]]$diagnostics)
      results[[i]] <- list(status=a$status,location=paste0(a$resource$resourceType,"/",a$resource$id,"/_history/",a$resource$meta$versionId),resource=a$resource)
    }
    NULL
  }, error=function(e)e)
  if (inherits(err,"error")) {
    failed <- append_trace_state(original,"POST",APP_CONFIG$base_url,422,"Bundle",bundle$id,source)
    failed <- append_audit_state(failed,user,"TRANSACTION","Bundle",bundle$id,source,"failure"); failed <- append_audit_resource_state(failed,user,"TRANSACTION","Bundle","",source,"failure"); failed$last_transaction_bundle <- bundle; store(failed)
    return(list(success=FALSE,http_status=422L,outcome=make_operation_outcome(diagnostics=conditionMessage(err))))
  }
  staged <- append_trace_state(staged,"POST",APP_CONFIG$base_url,200,"Bundle",bundle$id,source)
  staged <- append_audit_state(staged,user,"TRANSACTION","Bundle",bundle$id,source,"success")
  staged <- append_audit_resource_state(staged,user,"TRANSACTION","Bundle","",source,"success")
  staged$last_transaction_bundle <- bundle
  response <- c(base_resource("Bundle",new_id("tx-response")),list(type="transaction-response",entry=lapply(results,function(x) list(response=list(status=as.character(x$status),location=x$location)))))
  staged$last_transaction_response <- response
  store(staged)
  list(success=TRUE,http_status=200L,response=response,resources=lapply(results,`[[`,"resource"))
}
book_appointment <- function(store, patient_id, insurer_name, location_id, service_id, practitioner_role_id=NULL, slot_id, consultation_type, channel="web", source=channel) {
  state <- store(); slot <- state_resource(state,"Slot",slot_id); if(is.null(slot)) return(list(success=FALSE,http_status=404L,outcome=make_operation_outcome(diagnostics="Slot not found")))
  if(!identical(slot$status,"free")) return(list(success=FALSE,http_status=409L,outcome=make_operation_outcome(diagnostics="Slot is no longer free")))
  patient_ref <- paste0("Patient/",patient_id); location_ref <- paste0("Location/",location_id); service <- state_resource(state,"HealthcareService",service_id)
  minutes <- get_consultation_duration(insurer_name,consultation_type)
  start <- slot$start; desired_end <- iso_time(parse_fhir_datetime(start) + minutes*60)
  if (parse_fhir_datetime(desired_end) > parse_fhir_datetime(slot$end)) return(list(success=FALSE,http_status=422L,outcome=make_operation_outcome(diagnostics="Slot duration is shorter than consultation rule")))
  app_id <- new_id("app"); ar_id <- new_id("apr")
  app <- make_appointment(app_id,patient_ref,paste0("Slot/",slot_id),start,desired_end,service$name,location_ref,if(!is.null(practitioner_role_id)) paste0("PractitionerRole/",practitioner_role_id) else NULL,channel,"booked",consultation_type,minutes)
  slot2 <- slot; slot2$status <- "busy"
  responder <- if(!is.null(practitioner_role_id)) paste0("PractitionerRole/",practitioner_role_id) else paste0("HealthcareService/",service_id)
  apr <- make_appointment_response(ar_id,paste0("Appointment/",app_id),responder,"accepted",start,desired_end,"Disponibilidad aceptada por ACME Salud")
  prov <- make_provenance(new_id("prov"),c(paste0("Appointment/",app_id),paste0("Slot/",slot_id)),activity="appointment-booking")
  b <- make_transaction_bundle(list(transaction_entry(slot2,"PUT",paste0("Slot/",slot_id)),transaction_entry(app,"POST","Appointment"),transaction_entry(apr,"POST","AppointmentResponse"),transaction_entry(prov,"POST","Provenance")))
  tx <- fhir_transaction(store,b,source=source,user="scheduler")
  tx$bundle <- b; tx$appointment_id <- app_id; tx
}
cancel_appointment <- function(store, appointment_id, reason="patient-request", source="front-desk") {
  state <- store(); app <- state_resource(state,"Appointment",appointment_id); if(is.null(app)) return(list(success=FALSE,http_status=404L,outcome=make_operation_outcome(diagnostics="Appointment not found")))
  if(identical(app$status,"cancelled")) return(list(success=FALSE,http_status=409L,outcome=make_operation_outcome(diagnostics="Appointment already cancelled")))
  app2 <- app; app2$status <- "cancelled"; app2$cancelationReason <- cc("urn:acme:appointment-cancel-reason",reason,reason)
  entries <- list(transaction_entry(app2,"PUT",paste0("Appointment/",appointment_id)))
  for (sref in app$slot %||% list()) { sid <- get_ref_id(sref$reference); s <- state_resource(state,"Slot",sid); if(!is.null(s)){s$status <- "free"; entries <- append(entries,list(transaction_entry(s,"PUT",paste0("Slot/",sid))))}}
  responses <- Filter(function(r) identical(r$appointment$reference,paste0("Appointment/",appointment_id)),unname(state$resources$AppointmentResponse))
  for (r in responses) {r$participantStatus <- "declined"; r$comment <- paste("Cancelled:",reason); entries <- append(entries,list(transaction_entry(r,"PUT",paste0("AppointmentResponse/",r$id))))}
  prov <- make_provenance(new_id("prov"),paste0("Appointment/",appointment_id),activity="appointment-cancellation")
  entries <- append(entries,list(transaction_entry(prov,"POST","Provenance")))
  b <- make_transaction_bundle(entries); tx <- fhir_transaction(store,b,source=source,user="scheduler"); tx$bundle <- b; tx
}
start_encounter <- function(store,appointment_id,source="clinician") {
  state <- store(); app <- state_resource(state,"Appointment",appointment_id); if(is.null(app)) return(list(success=FALSE,http_status=404L,outcome=make_operation_outcome(diagnostics="Appointment not found")))
  patient_ref <- Filter(function(z) startsWith(z$actor$reference %||% "","Patient/"), app$participant)[[1]]$actor$reference
  pr <- Filter(function(z) startsWith(z$actor$reference %||% "","PractitionerRole/"), app$participant); pr_ref <- if(length(pr)) pr[[1]]$actor$reference else NULL
  enc <- make_encounter(new_id("enc"),patient_ref,paste0("Appointment/",appointment_id),pr_ref)
  app2 <- app; app2$status <- "fulfilled"
  prov <- make_provenance(new_id("prov"),c(paste0("Appointment/",appointment_id),paste0("Encounter/",enc$id)),activity="encounter-start")
  b <- make_transaction_bundle(list(transaction_entry(app2,"PUT",paste0("Appointment/",appointment_id)),transaction_entry(enc,"POST","Encounter"),transaction_entry(prov,"POST","Provenance")))
  tx <- fhir_transaction(store,b,source=source,user="clinician"); tx$encounter_id <- enc$id; tx$bundle <- b; tx
}
build_clinical_transaction <- function(store, encounter_id, bp=NULL, condition_text=NULL, request_text=NULL, request_category="laboratory", care_plan=NULL) {
  state <- store(); enc <- state_resource(state,"Encounter",encounter_id)
  if(is.null(enc)) return(list(success=FALSE,outcome=make_operation_outcome(diagnostics="Encounter not found")))
  enc2 <- enc; enc2$status <- "finished"; enc2$period$end <- fhir_now(); patient_ref <- enc$subject$reference
  entries <- list(transaction_entry(enc2,"PUT",paste0("Encounter/",encounter_id))); targets <- paste0("Encounter/",encounter_id)
  if(!is.null(bp) && length(bp)==2) {o<-make_bp_observation(new_id("obs-bp"),patient_ref,paste0("Encounter/",encounter_id),bp[[1]],bp[[2]]); entries<-append(entries,list(transaction_entry(o,"POST","Observation"))); targets<-c(targets,paste0("Observation/",o$id))}
  if(nzchar(condition_text %||% "")) {cnd<-make_condition(new_id("cond"),patient_ref,paste0("Encounter/",encounter_id),condition_text); entries<-append(entries,list(transaction_entry(cnd,"POST","Condition"))); targets<-c(targets,paste0("Condition/",cnd$id))}
  if(nzchar(request_text %||% "")) {sr<-make_service_request(new_id("sr"),patient_ref,paste0("Encounter/",encounter_id),request_text,request_category); entries<-append(entries,list(transaction_entry(sr,"POST","ServiceRequest"))); targets<-c(targets,paste0("ServiceRequest/",sr$id))}
  if(nzchar(care_plan %||% "")) {cp<-make_care_plan(new_id("cp"),patient_ref,paste0("Encounter/",encounter_id),care_plan); entries<-append(entries,list(transaction_entry(cp,"POST","CarePlan"))); targets<-c(targets,paste0("CarePlan/",cp$id))}
  prov<-make_provenance(new_id("prov"),targets,activity="clinical-transaction"); entries<-append(entries,list(transaction_entry(prov,"POST","Provenance")))
  list(success=TRUE,bundle=make_transaction_bundle(entries))
}
finalize_encounter <- function(store, encounter_id, bp=NULL, condition_text=NULL, request_text=NULL, request_category="laboratory", care_plan=NULL, source="clinician") {
  prep <- build_clinical_transaction(store,encounter_id,bp,condition_text,request_text,request_category,care_plan)
  if(!isTRUE(prep$success)) return(list(success=FALSE,http_status=404L,outcome=prep$outcome))
  tx <- fhir_transaction(store,prep$bundle,source=source,user="clinician"); tx$bundle<-prep$bundle; tx
}
