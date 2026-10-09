ai_mode <- function() if(nzchar(Sys.getenv("GEMINI_API_KEY"))) "Gemini connected" else "Simulation"
patient_context <- function(store, patient_id) {
  types <- c("Encounter","Observation","Condition","ServiceRequest","CarePlan","Appointment")
  out <- lapply(types,function(t) fhir_search(store,t,list(patient=patient_id),source="ai-context",record=FALSE)$resources); names(out)<-types; out
}
local_longitudinal_summary <- function(store, patient_id) {
  ctx <- patient_context(store,patient_id)
  sprintf("Resumen local sintético: %d encuentros, %d observaciones, %d condiciones y %d solicitudes de servicio.",length(ctx$Encounter),length(ctx$Observation),length(ctx$Condition),length(ctx$ServiceRequest))
}
gemini_generate <- function(prompt, model=APP_CONFIG$gemini_model) {
  key <- Sys.getenv("GEMINI_API_KEY"); if(!nzchar(key)) return(list(ok=FALSE,text="AI MODE: Simulation — GEMINI_API_KEY no configurada."))
  if(!requireNamespace("httr2",quietly=TRUE)) return(list(ok=FALSE,text="Instale httr2 para habilitar Gemini."))
  url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/",model,":generateContent")
  req <- httr2::request(url) |> httr2::req_headers(`x-goog-api-key`=key) |> httr2::req_body_json(list(contents=list(list(parts=list(list(text=prompt))))))
  tryCatch({resp<-httr2::req_perform(req);body<-httr2::resp_body_json(resp,simplifyVector=FALSE);txt<-body$candidates[[1]]$content$parts[[1]]$text %||% "Sin respuesta";list(ok=TRUE,text=txt)},error=function(e) list(ok=FALSE,text=paste("Gemini error:",conditionMessage(e))))
}
ai_structured_proposal_local <- function(note, patient_ref, encounter_ref) {
  # Fallback determinista para demo; no persiste nada.
  bp <- regexec("(?:TA|PA)\\s*(\\d{2,3})\\s*/\\s*(\\d{2,3})",note,ignore.case=TRUE,perl=TRUE);m<-regmatches(note,bp)[[1]]
  proposals <- list()
  if(length(m)>=3) proposals$Observation <- make_bp_observation(new_id("ai-obs-bp"),patient_ref,encounter_ref,as.numeric(m[[2]]),as.numeric(m[[3]]))
  if(grepl("cefalea",note,ignore.case=TRUE)) proposals$Condition <- make_condition(new_id("ai-cond"),patient_ref,encounter_ref,"Cefalea")
  proposals
}
