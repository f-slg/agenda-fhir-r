ui_nodes <- function(x, cls) {
  found <- list()
  visit <- function(z) {
    if (inherits(z, "shiny.tag")) {
      if (cls %in% strsplit(z$attribs$class %||% "", " ")[[1]]) found[[length(found)+1L]] <<- z
      lapply(z$children, visit)
    } else if (is.list(z)) lapply(z, visit)
    invisible(NULL)
  }
  visit(x); found
}
fixture_agenda <- function() data.frame(
  fecha=rep("2026-10-09",15), hora=c(rep("08:00",12),"08:15","08:30","20:00"),
  fin=c(rep("08:30",12),"08:30","08:45","20:15"), estado="booked",
  paciente="Paciente de prueba",servicio="Servicio de prueba",canal="web"
)
test_that("short, concurrent and late appointments have readable non-overlapping bounds", {
  ui <- week_schedule_ui(fixture_agenda(), start_date=as.Date("2026-10-08"))
  events <- ui_nodes(ui,"week-event")
  expect_length(events,15)
  geometry <- t(vapply(events,function(x) {
    as.numeric(regmatches(x$attribs$style,gregexpr("[0-9]+[.][0-9]+",x$attribs$style))[[1]])
  },numeric(4)))
  expect_true(all(geometry[,2]>=86))
  for(i in 1:14) for(j in (i+1):15) {
    a<-geometry[i,]; b<-geometry[j,]
    overlap <- a[1]<b[1]+b[2] && b[1]<a[1]+a[2] && a[3]<b[3]+b[4] && b[3]<a[3]+a[4]
    expect_false(overlap)
  }
  expect_match(ui_nodes(ui,"week-calendar-board")[[1]]$attribs$style,"2080px",fixed=TRUE)
  expect_true(all(vapply(events,function(e) identical(e$attribs$tabindex,"0"),logical(1))))
})
test_that("empty calendars and semantic statuses render safely", {
  expect_match(as.character(week_schedule_ui(data.frame())),"No existen citas")
  for(status in c("planned","busy","noshow","tentative","booked","cancelled","fulfilled"))
    expect_match(as.character(status_badge(status)),paste0("status-",status),fixed=TRUE)
  expect_match(as.character(appointment_kpis_ui(fixture_agenda())),"Reservadas")
})
