# Deterministic visual regression fixture; never connected to the application Store.
source("R/config.R")
source("R/utils.R")
fixture <- data.frame(fecha=rep("2026-10-09",15), hora=c(rep("08:00",12),"08:15","08:30","20:00"),
 fin=c(rep("08:30",12),"08:30","08:45","20:15"), estado="booked",paciente="Paciente sintético con nombre extenso",servicio="Servicio clínico de prueba",canal="web")
page <- htmltools::tags$html(lang="es",htmltools::tags$head(
 htmltools::tags$meta(charset="utf-8"),htmltools::tags$meta(name="viewport",content="width=device-width, initial-scale=1"),
 htmltools::tags$title("QA — agenda simultánea"),
 htmltools::tags$style(htmltools::HTML(paste(readLines("www/app.css"),collapse="\n")))),
 htmltools::tags$body(htmltools::tags$div(class="container-fluid",
 htmltools::tags$h1("Prueba de concurrencia visual"),
 htmltools::tags$p("Datos sintéticos de QA: trece citas simultáneas, citas de 15 minutos y una cita a las 20:00. Desplace la agenda para inspeccionar las columnas."),
 week_schedule_ui(fixture,start_date=as.Date("2026-10-08")))))
htmltools::save_html(page,"docs/qa-responsive/calendar-stress.html")
