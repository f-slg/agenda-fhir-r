make_provenance <- function(id, targets, agent_display="FHIR Clinical Flow", activity="record-update", ai_assisted=FALSE, entity_refs=NULL) {
  x <- c(base_resource("Provenance",id), list(target=lapply(targets,ref), recorded=fhir_now(), activity=cc("http://terminology.hl7.org/CodeSystem/v3-DataOperation","UPDATE",activity), agent=list(list(type=cc("http://terminology.hl7.org/CodeSystem/provenance-participant-type","assembler","Assembler"),who=list(display=agent_display)))))
  if (ai_assisted) x$reason <- list(cc("urn:acme:provenance-reason","ai-assisted","AI-assisted proposal approved by human"))
  if (length(entity_refs %||% character())) x$entity <- lapply(entity_refs,function(z) list(role="source",what=ref(z)))
  x
}
