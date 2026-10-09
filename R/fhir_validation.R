validation_issue <- function(path, message, severity="error") list(severity=severity,code="invalid",expression=list(path),diagnostics=message)
validate_resource <- function(resource, state=NULL) {
  issues <- list()
  add <- function(path,msg) issues[[length(issues)+1]] <<- validation_issue(path,msg)
  if (is.null(resource$resourceType) || !nzchar(resource$resourceType)) add("resourceType","resourceType es obligatorio")
  if (is.null(resource$id) || !nzchar(resource$id)) add("id","id es obligatorio en este simulador")
  rt <- resource$resourceType %||% ""
  if (identical(rt,"Slot")) {
    if (is.null(resource$schedule$reference)) add("Slot.schedule","Slot.schedule es obligatorio")
    if (!(resource$status %||% "") %in% c("busy","free","busy-unavailable","busy-tentative","entered-in-error")) add("Slot.status","Slot.status inválido")
    if (is.null(resource$start) || is.null(resource$end)) add("Slot.start/end","Slot requiere start y end")
  }
  if (identical(rt,"Appointment")) {
    if (!(resource$status %||% "") %in% c("proposed","pending","booked","arrived","fulfilled","cancelled","noshow","entered-in-error","checked-in","waitlist")) add("Appointment.status","Appointment.status inválido")
    if (xor(is.null(resource$start), is.null(resource$end))) add("Appointment.start/end","start y end deben coexistir")
    if (!is.null(resource$cancelationReason) && !(resource$status %||% "") %in% c("cancelled","noshow")) add("Appointment.cancelationReason","cancelationReason solo es válido para cancelled/noshow")
    if (is.null(resource$participant) || !length(resource$participant)) add("Appointment.participant","Debe existir al menos un participante")
  }
  if (identical(rt,"AppointmentResponse")) {
    if (is.null(resource$appointment$reference)) add("AppointmentResponse.appointment","appointment es obligatorio")
    if (!(resource$participantStatus %||% "") %in% c("accepted","declined","tentative","needs-action")) add("AppointmentResponse.participantStatus","participantStatus inválido")
  }
  if (identical(rt,"Encounter")) {
    if (is.null(resource$subject$reference)) add("Encounter.subject","subject es obligatorio para la demo")
    if (!(resource$status %||% "") %in% c("planned","arrived","triaged","in-progress","onleave","finished","cancelled","entered-in-error","unknown")) add("Encounter.status","Encounter.status inválido")
  }
  if (identical(rt,"Observation") && is.null(resource$subject$reference)) add("Observation.subject","subject es obligatorio")
  if (identical(rt,"Bundle") && identical(resource$type,"transaction")) {
    for (i in seq_along(resource$entry %||% list())) {
      if (is.null(resource$entry[[i]]$request$method)) add(paste0("Bundle.entry[",i,"].request.method"),"request.method es obligatorio")
      if (is.null(resource$entry[[i]]$request$url)) add(paste0("Bundle.entry[",i,"].request.url"),"request.url es obligatorio")
    }
  }
  if (!is.null(state) && !identical(rt,"Bundle")) {
    refs <- validate_references_state(state,resource)
    if (!refs$valid) for (b in refs$broken) add("Reference",paste("Referencia rota:",b))
  }
  list(valid=!length(issues), outcome=c(base_resource("OperationOutcome",new_id("oo")),list(issue=if(length(issues)) issues else list(list(severity="information",code="informational",diagnostics="Validation OK")))))
}
