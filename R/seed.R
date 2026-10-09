build_seed_resources <- function() {
  r <- list()
  add <- function(x) r[[length(r)+1]] <<- x
  add(make_org("org-acme","ACME Salud","prov","1100155555"))
  add(make_org("org-salud-completa","Salud Completa","ins","SC-001")); add(make_org("org-salud-cooperativa","Salud Cooperativa","ins","SCO-001"))
  add(make_location("loc-norte","Sede Norte","1100155555-1")); add(make_location("loc-centro","Sede Centro","1100155555-2")); add(make_location("loc-sur","Sede Sur","1100155555-2"))
  services <- list(
    c("hs-general-norte","Medicina general","loc-norte"),c("hs-pediatria-norte","Pediatría","loc-norte"),c("hs-obstetricia-norte","Obstetricia","loc-norte"),
    c("hs-general-centro","Medicina general","loc-centro"),c("hs-nefro-centro","Nefrología","loc-centro"),c("hs-gastro-centro","Gastroenterología","loc-centro"),
    c("hs-general-sur","Medicina general","loc-sur"),c("hs-onco-sur","Oncología","loc-sur"),c("hs-cardio-sur","Cardiología","loc-sur"))
  for(s in services) add(make_service(s[[1]],s[[2]],paste0("Location/",s[[3]])))
  practitioners <- list(
    c("prac-casas","Gregorio","Casas","111222333"),c("prac-luna","Elmer","Luna","222333444"),c("prac-chavez","Luis Manuel","Chávez","333444555"),
    c("prac-silva","Álvaro","Silva","444777333"),c("prac-narvaez","Diego","Narváez","555222999"),c("prac-fonseca","Alonso","Fonseca","777666555"))
  for(p in practitioners) add(make_practitioner(p[[1]],p[[2]],p[[3]],p[[4]]))
  roles <- list(
    c("role-casas-ped","prac-casas","hs-pediatria-norte","loc-norte","Pediatría"),c("role-luna-ob","prac-luna","hs-obstetricia-norte","loc-norte","Gineco Obstetricia"),
    c("role-chavez-nefro","prac-chavez","hs-nefro-centro","loc-centro","Nefrología"),c("role-silva-gastro","prac-silva","hs-gastro-centro","loc-centro","Gastroenterología"),
    c("role-narvaez-onco","prac-narvaez","hs-onco-sur","loc-sur","Oncología"),c("role-fonseca-cardio","prac-fonseca","hs-cardio-sur","loc-sur","Cardiología"))
  for(z in roles) add(make_practitioner_role(z[[1]],paste0("Practitioner/",z[[2]]),"Organization/org-acme",paste0("HealthcareService/",z[[3]]),paste0("Location/",z[[4]]),z[[5]]))
  patients <- list(
    c("pat-001","Carlos","Andrade","1974-03-12","ACME-0001","org-salud-completa"),c("pat-002","María","Torres","1986-08-02","ACME-0002","org-salud-cooperativa"),
    c("pat-003","José","Mora","1968-11-21","ACME-0003","org-salud-completa"),c("pat-004","Ana","Vega","1991-01-15","ACME-0004","org-salud-cooperativa"),
    c("pat-005","Lucía","Paredes","2018-05-09","ACME-0005","org-salud-completa"),c("pat-006","Mateo","Ruiz","2015-07-19","ACME-0006","org-salud-cooperativa"),
    c("pat-007","Diana","Castro","1980-09-10","ACME-0007","org-salud-completa"),c("pat-008","Pedro","Soto","1959-12-03","ACME-0008","org-salud-cooperativa"),
    c("pat-009","Sofía","López","1998-04-27","ACME-0009","org-salud-completa"),c("pat-010","Miguel","Reyes","1977-06-30","ACME-0010","org-salud-cooperativa"))
  for(i in seq_along(patients)){p<-patients[[i]];add(make_patient(p[[1]],p[[2]],p[[3]],p[[4]],p[[5]]));add(make_coverage(sprintf("cov-%03d",i),paste0("Patient/",p[[1]]),paste0("Organization/",p[[6]])))}
  month_start <- "2026-10-01T08:00:00-05:00"; month_end <- "2026-10-31T18:00:00-05:00"
  schedule_defs <- list(
    c("sch-cardio-sur","HealthcareService/hs-cardio-sur","PractitionerRole/role-fonseca-cardio","Location/loc-sur","Cardiología"),
    c("sch-onco-sur","HealthcareService/hs-onco-sur","PractitionerRole/role-narvaez-onco","Location/loc-sur","Oncología"),
    c("sch-nefro-centro","HealthcareService/hs-nefro-centro","PractitionerRole/role-chavez-nefro","Location/loc-centro","Nefrología"),
    c("sch-gastro-centro","HealthcareService/hs-gastro-centro","PractitionerRole/role-silva-gastro","Location/loc-centro","Gastroenterología"),
    c("sch-ped-norte","HealthcareService/hs-pediatria-norte","PractitionerRole/role-casas-ped","Location/loc-norte","Pediatría"),
    c("sch-ob-norte","HealthcareService/hs-obstetricia-norte","PractitionerRole/role-luna-ob","Location/loc-norte","Obstetricia"),
    c("sch-general-norte","HealthcareService/hs-general-norte","","Location/loc-norte","Medicina general"),
    c("sch-general-centro","HealthcareService/hs-general-centro","","Location/loc-centro","Medicina general"),
    c("sch-general-sur","HealthcareService/hs-general-sur","","Location/loc-sur","Medicina general"))
  for(s in schedule_defs){actors<-c(s[[2]],s[[4]]);if(nzchar(s[[3]]))actors<-c(actors,s[[3]]);add(make_schedule(s[[1]],actors,month_start,month_end,paste("Agenda",s[[5]])))}
  # Slots deterministas alrededor de la demo. Ventanas de 60 min; la regla de negocio define cuánto se ocupa.
  slots <- list(
    c("slot-cardio-20261007-0800","sch-cardio-sur","2026-10-07T08:00:00-05:00","2026-10-07T09:00:00-05:00","Cardiología"),
    c("slot-cardio-20261007-0930","sch-cardio-sur","2026-10-07T09:30:00-05:00","2026-10-07T10:30:00-05:00","Cardiología"),
    c("slot-cardio-20261008-0800","sch-cardio-sur","2026-10-08T08:00:00-05:00","2026-10-08T09:00:00-05:00","Cardiología"),
    c("slot-onco-20261007-1000","sch-onco-sur","2026-10-07T10:00:00-05:00","2026-10-07T11:00:00-05:00","Oncología"),
    c("slot-nefro-20261007-0900","sch-nefro-centro","2026-10-07T09:00:00-05:00","2026-10-07T10:00:00-05:00","Nefrología"),
    c("slot-gastro-20261007-1100","sch-gastro-centro","2026-10-07T11:00:00-05:00","2026-10-07T12:00:00-05:00","Gastroenterología"),
    c("slot-ped-20261007-0800","sch-ped-norte","2026-10-07T08:00:00-05:00","2026-10-07T09:00:00-05:00","Pediatría"),
    c("slot-ob-20261007-1000","sch-ob-norte","2026-10-07T10:00:00-05:00","2026-10-07T11:00:00-05:00","Obstetricia"),
    c("slot-gen-norte-20261007-1300","sch-general-norte","2026-10-07T13:00:00-05:00","2026-10-07T14:00:00-05:00","Medicina general"),
    c("slot-gen-centro-20261007-1400","sch-general-centro","2026-10-07T14:00:00-05:00","2026-10-07T15:00:00-05:00","Medicina general"),
    c("slot-gen-sur-20261007-1500","sch-general-sur","2026-10-07T15:00:00-05:00","2026-10-07T16:00:00-05:00","Medicina general"))
  for(s in slots) add(make_slot(s[[1]],paste0("Schedule/",s[[2]]),s[[3]],s[[4]],"free",s[[5]]))
  # Historia sintética: 12 citas, 8 encounters y eventos clínicos relacionados.
  hist <- list(
    c("pat-001","sch-cardio-sur","hs-cardio-sur","loc-sur","role-fonseca-cardio","2026-09-15T09:00:00-05:00","fulfilled","control-specialist","Cardiología"),
    c("pat-002","sch-nefro-centro","hs-nefro-centro","loc-centro","role-chavez-nefro","2026-09-16T10:00:00-05:00","fulfilled","first-specialist","Nefrología"),
    c("pat-003","sch-gastro-centro","hs-gastro-centro","loc-centro","role-silva-gastro","2026-09-17T11:00:00-05:00","fulfilled","control-specialist","Gastroenterología"),
    c("pat-004","sch-onco-sur","hs-onco-sur","loc-sur","role-narvaez-onco","2026-09-18T08:00:00-05:00","fulfilled","first-specialist","Oncología"),
    c("pat-005","sch-ped-norte","hs-pediatria-norte","loc-norte","role-casas-ped","2026-09-19T09:00:00-05:00","fulfilled","first-specialist","Pediatría"),
    c("pat-006","sch-general-norte","hs-general-norte","loc-norte","","2026-09-20T13:00:00-05:00","fulfilled","first-general","Medicina general"),
    c("pat-007","sch-ob-norte","hs-obstetricia-norte","loc-norte","role-luna-ob","2026-09-22T10:00:00-05:00","fulfilled","control-specialist","Obstetricia"),
    c("pat-008","sch-cardio-sur","hs-cardio-sur","loc-sur","role-fonseca-cardio","2026-09-24T08:00:00-05:00","fulfilled","control-specialist","Cardiología"),
    c("pat-009","sch-general-centro","hs-general-centro","loc-centro","","2026-09-26T14:00:00-05:00","cancelled","first-general","Medicina general"),
    c("pat-010","sch-onco-sur","hs-onco-sur","loc-sur","role-narvaez-onco","2026-09-28T10:00:00-05:00","cancelled","control-specialist","Oncología"),
    c("pat-002","sch-nefro-centro","hs-nefro-centro","loc-centro","role-chavez-nefro","2026-10-09T09:00:00-05:00","booked","control-specialist","Nefrología"),
    c("pat-001","sch-cardio-sur","hs-cardio-sur","loc-sur","role-fonseca-cardio","2026-10-10T08:00:00-05:00","booked","control-specialist","Cardiología")
  )
  for(i in seq_along(hist)) {
    h <- hist[[i]]
    patient_id <- h[[1]]; schedule_id <- h[[2]]; service_id <- h[[3]]; location_id <- h[[4]]
    role_id <- h[[5]]; start_time <- h[[6]]; app_status <- h[[7]]; consultation_type <- h[[8]]; service_name <- h[[9]]
    slot_id <- sprintf("slot-hist-%03d",i); app_id <- sprintf("app-%03d",i); response_id <- sprintf("apr-%03d",i)
    end_time <- iso_time(parse_fhir_datetime(start_time) + 45*60)
    slot_status <- if(identical(app_status,"cancelled")) "free" else "busy"
    add(make_slot(slot_id,paste0("Schedule/",schedule_id),start_time,iso_time(parse_fhir_datetime(start_time)+60*60),slot_status,service_name))
    app <- make_appointment(
      app_id,paste0("Patient/",patient_id),paste0("Slot/",slot_id),start_time,end_time,service_name,
      paste0("Location/",location_id),if(nzchar(role_id)) paste0("PractitionerRole/",role_id) else NULL,
      c("web","call-center","mobile","front-desk")[[((i-1) %% 4)+1]],app_status,consultation_type,45
    )
    if(identical(app_status,"cancelled")) app$cancelationReason <- cc("urn:acme:appointment-cancel-reason","patient-request","patient-request")
    add(app)
    responder <- if(nzchar(role_id)) paste0("PractitionerRole/",role_id) else paste0("HealthcareService/",service_id)
    add(make_appointment_response(response_id,paste0("Appointment/",app_id),responder,if(identical(app_status,"cancelled"))"declined" else "accepted",start_time,end_time,if(identical(app_status,"cancelled"))"Cancelación sintética" else "Disponibilidad aceptada"))
    if(i <= 8) {
      enc_id <- sprintf("enc-%03d",i)
      enc <- make_encounter(enc_id,paste0("Patient/",patient_id),paste0("Appointment/",app_id),if(nzchar(role_id)) paste0("PractitionerRole/",role_id) else NULL,"finished",start_time)
      enc$period$end <- end_time; add(enc)
      add(make_bp_observation(sprintf("obs-bp-%03d",i),paste0("Patient/",patient_id),paste0("Encounter/",enc_id),135+i,84+(i %% 7),iso_time(parse_fhir_datetime(start_time)+8*60)))
      if(i %in% c(1,3,7)) add(make_condition(sprintf("cond-%03d",i),paste0("Patient/",patient_id),paste0("Encounter/",enc_id),if(i==1)"Hipertensión arterial" else "Problema clínico sintético"))
      if(i %in% c(1,2,4)) add(make_service_request(sprintf("sr-%03d",i),paste0("Patient/",patient_id),paste0("Encounter/",enc_id),"Laboratorio de control","laboratory"))
    }
  }
  add(make_capability_statement())
  r
}
seed_store <- function() new_fhir_store(build_seed_resources())
