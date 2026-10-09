resource_matches <- function(r, params) {
  if (!length(params)) return(TRUE)
  for (nm in names(params)) {
    value <- as.character(params[[nm]])
    ok <- switch(nm,
      identifier = any(vapply(r$identifier %||% list(), function(z) identical(as.character(z$value),value), logical(1))),
      patient = {
        pr <- if (grepl("/",value)) value else paste0("Patient/",value)
        pr %in% extract_references(r)
      },
      schedule = identical(r$schedule$reference %||% "", if(grepl("/",value)) value else paste0("Schedule/",value)),
      status = identical(as.character(r$status %||% ""),value),
      date = startsWith(as.character(r$start %||% r$effectiveDateTime %||% ""),value),
      actor = {
        ar <- if(grepl("/",value)) value else value
        any(vapply(r$actor %||% list(), function(z) identical(z$reference,ar),logical(1)))
      },
      appointment = identical(r$appointment$reference %||% "", if(grepl("/",value)) value else paste0("Appointment/",value)),
      TRUE
    )
    if (!isTRUE(ok)) return(FALSE)
  }
  TRUE
}
fhir_search <- function(store,type,params=list(),source="system",user=APP_CONFIG$default_user,record=TRUE) {
  state <- store(); resources <- unname(state$resources[[type]])
  hits <- Filter(function(r) resource_matches(r,params), resources)
  query <- if(length(params)) paste0("?",paste(paste0(names(params),"=",vapply(params,as.character,character(1))),collapse="&")) else ""
  if (isTRUE(record)) {
    state <- append_trace_state(state,"GET",paste0(APP_CONFIG$base_url,"/",type,query),200,type,"",source)
    state <- append_audit_state(state,user,"SEARCH",type,"",source,"success")
    state <- append_audit_resource_state(state,user,"SEARCH",type,"",source,"success")
    store(state)
  }
  bundle <- c(base_resource("Bundle",new_id("search")),list(type="searchset",total=length(hits),entry=lapply(hits,function(r) list(fullUrl=paste0(APP_CONFIG$base_url,"/",r$resourceType,"/",r$id),resource=r,search=list(mode="match")))))
  list(success=TRUE,http_status=200L,bundle=bundle,resources=hits)
}
