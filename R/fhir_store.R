new_empty_state <- function() {
  resources <- setNames(lapply(SUPPORTED_RESOURCE_TYPES, function(x) list()), SUPPORTED_RESOURCE_TYPES)
  list(resources=resources, history=setNames(lapply(SUPPORTED_RESOURCE_TYPES,function(x) list()),SUPPORTED_RESOURCE_TYPES), rest_trace=empty_trace_df(), audit=empty_audit_df(), generation=1L, last_transaction_bundle=NULL, last_transaction_response=NULL)
}
new_fhir_store <- function(seed_resources=list()) {
  state <- new_empty_state()
  for (r in seed_resources) {
    state$resources[[r$resourceType]][[r$id]] <- r
    state$history[[r$resourceType]][[r$id]] <- list(r)
  }
  shiny::reactiveVal(state)
}
state_resource <- function(state,type,id) state$resources[[type]][[id]]
set_resource_in_state <- function(state, resource, keep_history=TRUE) {
  rt <- resource$resourceType; id <- resource$id
  state$resources[[rt]][[id]] <- resource
  if (keep_history) {
    h <- state$history[[rt]][[id]] %||% list()
    state$history[[rt]][[id]] <- append(h,list(resource))
  }
  state
}
versioned_resource <- function(resource, previous=NULL) {
  v <- if (is.null(previous)) 1L else as.integer(previous$meta$versionId %||% "0") + 1L
  resource$meta <- list(versionId=as.character(v), lastUpdated=fhir_now()); resource
}
fhir_create <- function(store, resource, source="system", user=APP_CONFIG$default_user) {
  state <- store(); rt <- resource$resourceType; id <- resource$id %||% new_id(tolower(rt))
  if (!is.null(state$resources[[rt]][[id]])) return(list(success=FALSE,http_status=409L,resource=NULL,outcome=make_operation_outcome(diagnostics="Resource already exists")))
  resource$id <- id; resource <- versioned_resource(resource,NULL)
  val <- validate_resource(resource,state)
  if (!val$valid) return(list(success=FALSE,http_status=422L,resource=NULL,outcome=val$outcome))
  state <- set_resource_in_state(state,resource)
  state <- append_trace_state(state,"POST",paste0(APP_CONFIG$base_url,"/",rt),201,rt,id,source)
  state <- append_audit_state(state,user,"CREATE",rt,id,source,"success")
  state <- append_audit_resource_state(state,user,"CREATE",rt,id,source,"success")
  store(state); list(success=TRUE,http_status=201L,resource=resource,outcome=val$outcome)
}
fhir_read <- function(store, type, id, source="system", user=APP_CONFIG$default_user) {
  state <- store(); r <- state$resources[[type]][[id]]
  status <- if(is.null(r)) 404L else 200L
  state <- append_trace_state(state,"GET",paste0(APP_CONFIG$base_url,"/",type,"/",id),status,type,id,source)
  state <- append_audit_state(state,user,"READ",type,id,source,if(status==200)"success" else "failure")
  state <- append_audit_resource_state(state,user,"READ",type,if(status==200) id else "",source,if(status==200)"success" else "failure")
  store(state)
  if (is.null(r)) list(success=FALSE,http_status=404L,resource=NULL,outcome=make_operation_outcome(code_value="not-found",diagnostics="Resource not found")) else list(success=TRUE,http_status=200L,resource=r,outcome=NULL)
}
fhir_update <- function(store, resource, source="system", user=APP_CONFIG$default_user) {
  state <- store(); rt <- resource$resourceType; id <- resource$id; previous <- state$resources[[rt]][[id]]
  if (is.null(previous)) return(list(success=FALSE,http_status=404L,resource=NULL,outcome=make_operation_outcome(code_value="not-found",diagnostics="Resource not found")))
  resource <- versioned_resource(resource,previous)
  val <- validate_resource(resource,state)
  if (!val$valid) return(list(success=FALSE,http_status=422L,resource=NULL,outcome=val$outcome))
  state <- set_resource_in_state(state,resource)
  state <- append_trace_state(state,"PUT",paste0(APP_CONFIG$base_url,"/",rt,"/",id),200,rt,id,source)
  state <- append_audit_state(state,user,"UPDATE",rt,id,source,"success")
  state <- append_audit_resource_state(state,user,"UPDATE",rt,id,source,"success")
  store(state); list(success=TRUE,http_status=200L,resource=resource,outcome=val$outcome)
}
fhir_delete <- function(store,type,id,source="reset-demo",user=APP_CONFIG$default_user,physical=FALSE) {
  if (!physical) return(list(success=FALSE,http_status=400L,outcome=make_operation_outcome(diagnostics="Clinical physical delete disabled; use status transition")))
  state <- store(); if (is.null(state$resources[[type]][[id]])) return(list(success=FALSE,http_status=404L,outcome=make_operation_outcome(code_value="not-found",diagnostics="Resource not found")))
  state$resources[[type]][[id]] <- NULL
  state <- append_trace_state(state,"DELETE",paste0(APP_CONFIG$base_url,"/",type,"/",id),200,type,id,source)
  state <- append_audit_state(state,user,"DELETE",type,id,source,"success"); state <- append_audit_resource_state(state,user,"DELETE",type,"",source,"success"); store(state)
  list(success=TRUE,http_status=200L,outcome=NULL)
}
fhir_history <- function(store,type,id) store()$history[[type]][[id]] %||% list()
all_resources <- function(store,type=NULL) {
  state <- store()
  if (!is.null(type)) return(unname(state$resources[[type]]))
  unlist(lapply(state$resources,unname),recursive=FALSE)
}
