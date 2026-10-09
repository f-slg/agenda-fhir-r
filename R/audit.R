empty_audit_df <- function() data.frame(timestamp=character(),user=character(),action=character(),resourceType=character(),resourceId=character(),channel=character(),result=character(),stringsAsFactors=FALSE)
empty_trace_df <- function() data.frame(timestamp=character(),method=character(),url=character(),status=integer(),resourceType=character(),resourceId=character(),duration_ms=integer(),source=character(),stringsAsFactors=FALSE)
append_audit_state <- function(state,user,action,resourceType="",resourceId="",channel="system",result="success") {
  state$audit <- rbind(state$audit,data.frame(timestamp=fhir_now(),user=user,action=action,resourceType=resourceType,resourceId=resourceId,channel=channel,result=result,stringsAsFactors=FALSE)); state
}
append_trace_state <- function(state,method,url,status,resourceType="",resourceId="",source="system",duration_ms=sample(4:25,1)) {
  state$rest_trace <- rbind(state$rest_trace,data.frame(timestamp=fhir_now(),method=method,url=url,status=as.integer(status),resourceType=resourceType,resourceId=resourceId,duration_ms=as.integer(duration_ms),source=source,stringsAsFactors=FALSE)); state
}
make_audit_event_resource <- function(id, action="E", outcome="0", user="demo-user", target_ref=NULL, channel="system") {
  entity <- if (!is.null(target_ref)) list(list(what=ref(target_ref))) else NULL
  x <- c(base_resource("AuditEvent",id), list(type=coding_item("http://terminology.hl7.org/CodeSystem/audit-event-type","rest","RESTful Operation"), action=action, recorded=fhir_now(), outcome=outcome, agent=list(list(requestor=TRUE,who=list(display=user),altId=user)), source=list(observer=ref("Organization/org-acme"),type=list(coding_item("urn:acme:audit-source","simulated-core","Simulated FHIR Core"))), subtype=list(coding_item("urn:acme:channel",channel,channel))))
  if (!is.null(entity)) x$entity <- entity
  x
}


audit_action_code <- function(action) {
  switch(toupper(action), CREATE="C", READ="R", UPDATE="U", DELETE="D", SEARCH="R", TRANSACTION="E", "E")
}
append_audit_resource_state <- function(state, user, action, resourceType="", resourceId="", channel="system", result="success") {
  id <- new_id("audit")
  target <- if (nzchar(resourceType) && nzchar(resourceId) && !is.null(state$resources[[resourceType]][[resourceId]])) paste0(resourceType,"/",resourceId) else NULL
  ae <- make_audit_event_resource(id, action=audit_action_code(action), outcome=if(identical(result,"success"))"0" else "8", user=user, target_ref=target, channel=channel)
  state$resources$AuditEvent[[id]] <- ae
  state$history$AuditEvent[[id]] <- list(ae)
  state
}
