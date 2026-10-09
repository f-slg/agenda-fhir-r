CONSULTATION_RULES <- data.frame(
  insurer = rep(c("Salud Cooperativa","Salud Completa"), 6),
  consultation_type = rep(c(
    "first-general","first-specialist","control-general","control-specialist",
    "tele-control-general","tele-control-specialist"
  ), each=2),
  minutes = c(30,45, 45,60, 20,30, 30,45, 15,25, 20,30),
  stringsAsFactors = FALSE
)
get_consultation_duration <- function(insurer, consultation_type) {
  x <- CONSULTATION_RULES[CONSULTATION_RULES$insurer == insurer & CONSULTATION_RULES$consultation_type == consultation_type, , drop=FALSE]
  if (!nrow(x)) stop("No existe regla de duración para aseguradora/tipo de consulta")
  x$minutes[[1]]
}
is_specialist_service <- function(service_name) !identical(tolower(service_name), "medicina general")
default_consultation_type <- function(service_name, telemedicine=FALSE, control=FALSE) {
  kind <- if (is_specialist_service(service_name)) "specialist" else "general"
  if (telemedicine && control) return(paste0("tele-control-", kind))
  paste0(if (control) "control-" else "first-", kind)
}
