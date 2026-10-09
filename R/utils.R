`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x
format_fhir_time <- function(x) {
  z <- format(as.POSIXct(x, tz = APP_CONFIG$timezone), "%Y-%m-%dT%H:%M:%S%z")
  sub("([+-][0-9]{2})([0-9]{2})$", "\\1:\\2", z)
}
fhir_now <- function() format_fhir_time(Sys.time())
iso_time <- function(x) format_fhir_time(x)
resource_ref <- function(x) paste0(x$resourceType, "/", x$id)
ref <- function(x, display = NULL) Filter(Negate(is.null), list(reference = x, display = display))
coding_item <- function(system = NULL, code = NULL, display = NULL) Filter(Negate(is.null), list(system=system, code=code, display=display))
cc <- function(system = NULL, code = NULL, display = NULL, text = display) {
  x <- list(coding = list(coding_item(system, code, display)))
  if (!is.null(text)) x$text <- text
  x
}
identifier <- function(system, value, use = "official") list(use=use, system=system, value=value)
new_id <- function(prefix) paste0(prefix, "-", format(Sys.time(), "%Y%m%d%H%M%S"), "-", sprintf("%04d", sample.int(9999,1)))
get_ref_id <- function(reference) sub("^[^/]+/", "", reference %||% "")
get_ref_type <- function(reference) sub("/.*$", "", reference %||% "")
resource_display <- function(r) {
  if (is.null(r)) return("")
  if (!is.null(r$name)) {
    if (is.character(r$name)) return(r$name[[1]])
    n <- r$name[[1]]
    return(trimws(paste(c(n$given %||% character(), n$family %||% ""), collapse=" ")))
  }
  r$title %||% r$description %||% paste(r$resourceType, r$id)
}
first_coding_display <- function(x) {
  if (is.null(x)) return(NA_character_)
  x$text %||% x$coding[[1]]$display %||% x$coding[[1]]$code %||% NA_character_
}
json_pretty <- function(x) jsonlite::toJSON(x, pretty=TRUE, auto_unbox=TRUE, null="null", na="null")
parse_fhir_datetime <- function(x) {
  x2 <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", x)
  as.POSIXct(x2, format="%Y-%m-%dT%H:%M:%S%z", tz=APP_CONFIG$timezone)
}
minutes_between <- function(start, end) as.numeric(difftime(parse_fhir_datetime(end), parse_fhir_datetime(start), units="mins"))
extract_extension_value <- function(resource, url) {
  ex <- resource$extension %||% list()
  hit <- Filter(function(z) identical(z$url, url), ex)
  if (!length(hit)) return(NULL)
  hit[[1]]$valueCode %||% hit[[1]]$valueString %||% NULL
}
make_channel_extension <- function(channel) list(url=APP_CONFIG$channel_extension_url, valueCode=channel)
status_badge <- function(status) {
  safe <- if (is.null(status) || !nzchar(status)) "default" else gsub("[^a-z0-9-]", "-", tolower(status))
  known <- c("booked","free","accepted","finished","active","in-progress","fulfilled","cancelled","declined","entered-in-error","planned","busy","noshow","tentative")
  cls <- if (safe %in% known) paste0("status-", safe) else "status-default"
  htmltools::tags$span(class=paste("status-chip", cls), status %||% "unknown")
}


calendar_date_window <- function(dates, max_days = 7) {
  dates <- sort(unique(dates[nzchar(dates)]))
  if (!length(dates)) return(character())
  today <- Sys.Date()
  dvals <- as.Date(dates)
  upcoming <- dates[!is.na(dvals) & dvals >= today]
  recent <- dates[!is.na(dvals) & dvals < today]
  selected <- head(upcoming, max_days)
  if (length(selected) < max_days && length(recent)) {
    selected <- c(tail(recent, max_days - length(selected)), selected)
  }
  sort(unique(selected))
}

clinical_date_parts <- function(x) {
  d <- as.Date(substr(x, 1, 10))
  if (is.na(d)) return(list(weekday="", day="", month=""))
  weekdays_es <- c("LUN","MAR","MIÉ","JUE","VIE","SÁB","DOM")
  months_es <- c("ENE","FEB","MAR","ABR","MAY","JUN","JUL","AGO","SEP","OCT","NOV","DIC")
  list(
    weekday = weekdays_es[[as.integer(format(d, "%u"))]],
    day = format(d, "%d"),
    month = months_es[[as.integer(format(d, "%m"))]]
  )
}

slot_calendar_ui <- function(slots, max_days = 7) {
  if (!length(slots)) return(NULL)
  dates <- calendar_date_window(vapply(slots, function(s) substr(s$start, 1, 10), character(1)), max_days)
  htmltools::tags$div(
    class = "calendar-shell",
    htmltools::tags$div(
      class = "calendar-shell-header",
      htmltools::tags$div(class = "calendar-shell-title", "Disponibilidad por fecha"),
      htmltools::tags$div(class = "calendar-shell-sub", "Vista calendario del FHIR Store")
    ),
    htmltools::tags$div(
      class = "mini-calendar",
      lapply(dates, function(d) {
        day_slots <- Filter(function(s) identical(substr(s$start, 1, 10), d), slots)
        starts <- sort(vapply(day_slots, function(s) format(parse_fhir_datetime(s$start), "%H:%M"), character(1)))
        ends <- sort(vapply(day_slots, function(s) format(parse_fhir_datetime(s$end), "%H:%M"), character(1)))
        p <- clinical_date_parts(d)
        htmltools::tags$div(
          class = "calendar-day available",
          htmltools::tags$div(class = "calendar-weekday", p$weekday),
          htmltools::tags$div(
            class = "calendar-date",
            htmltools::tags$span(class = "day-num", p$day),
            htmltools::tags$span(class = "month", p$month)
          ),
          htmltools::tags$div(class = "calendar-count", paste(length(day_slots), if (length(day_slots) == 1) "horario" else "horarios")),
          htmltools::tags$div(class = "calendar-range", paste0(starts[[1]], " – ", tail(ends, 1))),
          htmltools::tags$div(class = "calendar-status-line", htmltools::tags$span(class = "calendar-dot-label free", "Disponible"))
        )
      })
    )
  )
}

appointment_calendar_ui <- function(df, max_days = 7, title = "Agenda por fecha") {
  if (is.null(df) || !nrow(df) || !all(c("fecha", "hora", "estado") %in% names(df))) {
    return(htmltools::tags$div(class = "empty-state", "No existen citas para mostrar en calendario."))
  }
  dates <- calendar_date_window(df$fecha, max_days)
  htmltools::tags$div(
    class = "calendar-shell",
    htmltools::tags$div(
      class = "calendar-shell-header",
      htmltools::tags$div(class = "calendar-shell-title", title),
      htmltools::tags$div(class = "calendar-shell-sub", "Resumen visual · misma fuente FHIR")
    ),
    htmltools::tags$div(
      class = "mini-calendar",
      lapply(dates, function(d) {
        x <- df[df$fecha == d, , drop = FALSE]
        st <- table(x$estado)
        p <- clinical_date_parts(d)
        hours <- sort(x$hora[nzchar(x$hora)])
        has_cancelled <- any(x$estado %in% c("cancelled", "declined"))
        has_booked <- any(x$estado %in% c("booked", "in-progress"))
        has_done <- any(x$estado %in% c("fulfilled", "finished"))
        tone <- if (sum(c(has_cancelled, has_booked, has_done)) > 1) "mixed" else if (has_booked) "booked" else if (has_done) "mixed" else ""
        status_items <- list()
        if (!is.na(st["booked"]) && st["booked"] > 0) status_items[[length(status_items)+1]] <- htmltools::tags$span(class="calendar-dot-label booked", paste(st["booked"], "reservada"))
        if (!is.na(st["fulfilled"]) && st["fulfilled"] > 0) status_items[[length(status_items)+1]] <- htmltools::tags$span(class="calendar-dot-label fulfilled", paste(st["fulfilled"], "atendida"))
        if (!is.na(st["cancelled"]) && st["cancelled"] > 0) status_items[[length(status_items)+1]] <- htmltools::tags$span(class="calendar-dot-label cancelled", paste(st["cancelled"], "cancelada"))
        htmltools::tags$div(
          class = paste("calendar-day", tone),
          htmltools::tags$div(class = "calendar-weekday", p$weekday),
          htmltools::tags$div(
            class = "calendar-date",
            htmltools::tags$span(class = "day-num", p$day),
            htmltools::tags$span(class = "month", p$month)
          ),
          htmltools::tags$div(class = "calendar-count", paste(nrow(x), if (nrow(x) == 1) "cita" else "citas")),
          if (length(hours)) htmltools::tags$div(class = "calendar-range", paste0(hours[[1]], if (length(hours) > 1) paste0(" – ", tail(hours,1)) else "")) else NULL,
          htmltools::tags$div(class = "calendar-status-line", status_items)
        )
      })
    )
  )
}

# ---- Professional scheduling UI helpers ---------------------------------
appointment_kpis_ui <- function(df, title = "Resumen operativo") {
  if (is.null(df) || !nrow(df)) {
    return(htmltools::tags$div(class = "kpi-strip empty", "Sin citas para resumir."))
  }
  status <- tolower(df$estado %||% character())
  total <- nrow(df)
  booked <- sum(status == "booked", na.rm = TRUE)
  active <- sum(status == "in-progress", na.rm = TRUE)
  done <- sum(status %in% c("fulfilled", "finished"), na.rm = TRUE)
  cancelled <- sum(status %in% c("cancelled", "declined"), na.rm = TRUE)
  today <- sum(df$fecha == format(Sys.Date(), "%Y-%m-%d"), na.rm = TRUE)
  item <- function(label, value, tone = "neutral") {
    htmltools::tags$div(
      class = paste("kpi-item", paste0("tone-", tone)),
      htmltools::tags$span(class = "kpi-value", value),
      htmltools::tags$span(class = "kpi-label", label)
    )
  }
  htmltools::tags$div(
    class = "kpi-panel",
    htmltools::tags$div(class = "kpi-panel-title", title),
    htmltools::tags$div(
      class = "kpi-strip",
      item("Total", total, "navy"),
      item("Hoy", today, "blue"),
      item("Reservadas", booked, "blue"),
      item("En atención", active, "amber"),
      item("Atendidas", done, "teal"),
      item("Canceladas", cancelled, "red")
    )
  )
}

calendar_status_label <- function(status) {
  switch(
    tolower(status %||% ""),
    booked = "Reservada",
    `in-progress` = "En atención",
    fulfilled = "Atendida",
    finished = "Finalizada",
    cancelled = "Cancelada",
    declined = "Rechazada",
    accepted = "Aceptada",
    free = "Disponible",
    status %||% "Sin estado"
  )
}

week_schedule_ui <- function(df, title = "Agenda semanal", max_days = 7,
                             start_hour = 7, end_hour = 19, pixels_per_hour = 120, start_date = Sys.Date()) {
  needed <- c("fecha", "hora", "estado")
  if (is.null(df) || !nrow(df) || !all(needed %in% names(df))) {
    return(htmltools::tags$div(class = "empty-state", "No existen citas para mostrar en la agenda semanal."))
  }

  anchor <- as.Date(start_date)
  if (is.na(anchor)) anchor <- Sys.Date()
  monday <- anchor - as.integer(format(anchor, "%u")) + 1L
  dates <- as.character(seq(monday, by="day", length.out=max_days))
  if (!length(dates)) return(htmltools::tags$div(class = "empty-state", "No existen fechas válidas para la agenda."))

  if (!"fin" %in% names(df)) df$fin <- ""
  if (!"paciente" %in% names(df)) df$paciente <- "Paciente"
  if (!"servicio" %in% names(df)) df$servicio <- "Atención"
  if (!"canal" %in% names(df)) df$canal <- ""

  # Scale the visual time axis to fit four readable lines even for short visits.
  # This is a projection only: Appointment times and the Store are never changed.
  clock_minutes <- function(v) suppressWarnings(as.integer(substr(v, 1, 2)) * 60 + as.integer(substr(v, 4, 5)))
  starts <- clock_minutes(df$hora)
  ends <- clock_minutes(df$fin)
  fallback <- which(!is.finite(ends) | (!is.na(starts) & ends <= starts))
  ends[fallback] <- starts[fallback] + 45
  valid <- is.finite(starts) & is.finite(ends)
  if (any(valid)) {
    start_hour <- min(start_hour, floor(min(starts[valid]) / 60))
    end_hour <- max(end_hour, ceiling(max(ends[valid]) / 60))
    pixels_per_hour <- max(pixels_per_hour, 90 * 60 / min(ends[valid] - starts[valid]))
  }

  min_to_px <- function(minute) ((minute - start_hour * 60) / 60) * pixels_per_hour
  body_height <- (end_hour - start_hour) * pixels_per_hour

  time_labels <- lapply(seq(start_hour, end_hour - 1), function(h) {
    htmltools::tags$div(
      class = "week-time-label",
      style = sprintf("top:%spx;", (h - start_hour) * pixels_per_hour),
      sprintf("%02d:00", h)
    )
  })

  day_columns <- lapply(dates, function(d) {
    x <- df[df$fecha == d, , drop = FALSE]
    p <- clinical_date_parts(d)
    if (nrow(x)) {
      start_min <- suppressWarnings(as.integer(substr(x$hora, 1, 2)) * 60 + as.integer(substr(x$hora, 4, 5)))
      end_min <- suppressWarnings(as.integer(substr(x$fin, 1, 2)) * 60 + as.integer(substr(x$fin, 4, 5)))
      end_min[is.na(end_min)] <- start_min[is.na(end_min)] + 45
      end_min[end_min <= start_min] <- start_min[end_min <= start_min] + 45
      keep <- !is.na(start_min) & start_min < end_hour * 60 & end_min > start_hour * 60
      x <- x[keep, , drop = FALSE]
      start_min <- start_min[keep]
      end_min <- end_min[keep]
      if (length(start_min)) {
        start_min <- pmax(start_min, start_hour * 60)
        end_min <- pmin(end_min, end_hour * 60)
      }
      ord <- order(start_min, end_min)
      x <- x[ord, , drop = FALSE]
      start_min <- start_min[ord]
      end_min <- end_min[ord]

      lane_end <- numeric()
      lanes <- integer(nrow(x))
      for (i in seq_len(nrow(x))) {
        available <- which(lane_end <= start_min[[i]])
        lane <- if (length(available)) available[[1]] else length(lane_end) + 1L
        if (lane > length(lane_end)) lane_end <- c(lane_end, end_min[[i]]) else lane_end[[lane]] <- end_min[[i]]
        lanes[[i]] <- lane
      }
      lane_count <- if (length(lanes)) max(lanes, 1L) else 1L

      events <- lapply(seq_len(nrow(x)), function(i) {
        top <- max(0, min_to_px(start_min[[i]]))
        height <- ((end_min[[i]] - start_min[[i]]) / 60) * pixels_per_hour - 4
        width <- 94 / lane_count
        left <- 3 + (lanes[[i]] - 1) * width
        tone <- gsub("[^a-z0-9-]", "-", tolower(x$estado[[i]] %||% "default"))
        htmltools::tags$div(
          class = paste("week-event", paste0("event-", tone)),
          tabindex = "0",
          role = "group",
          `aria-label` = paste(x$hora[[i]], x$paciente[[i]], x$servicio[[i]], calendar_status_label(x$estado[[i]]), sep = " · "),
          style = sprintf("top:%.1fpx;height:%.1fpx;left:%.1f%%;width:%.1f%%;", top, height, left, width - 1.2),
          title = paste(x$paciente[[i]], x$servicio[[i]], x$hora[[i]], x$estado[[i]], sep = " · "),
          htmltools::tags$div(class = "week-event-time", paste0(x$hora[[i]], if (nzchar(x$fin[[i]])) paste0("–", x$fin[[i]]) else "")),
          htmltools::tags$div(class = "week-event-patient", x$paciente[[i]]),
          htmltools::tags$div(class = "week-event-service", x$servicio[[i]]),
          htmltools::tags$div(
            class = "week-event-meta",
            htmltools::tags$span(calendar_status_label(x$estado[[i]])),
            if (nzchar(x$canal[[i]])) htmltools::tags$span(paste0(" · ", x$canal[[i]])) else NULL
          )
        )
      })
    } else {
      lane_count <- 1L
      events <- list()
    }

    htmltools::tags$div(
      class = "week-day-wrap",
      style = sprintf("min-width:%spx;", max(180, lane_count * 160)),
      htmltools::tags$div(
        class = paste("week-day-header", if (identical(d, format(Sys.Date(), "%Y-%m-%d"))) "is-today" else ""),
        htmltools::tags$span(class = "week-day-name", p$weekday),
        htmltools::tags$span(class = "week-day-number", p$day),
        htmltools::tags$span(class = "week-day-month", p$month),
        htmltools::tags$span(class = "week-day-count", paste(nrow(x), if (nrow(x) == 1) "cita" else "citas"))
      ),
      htmltools::tags$div(
        class = "week-day-column",
        style = sprintf("height:%spx;--hour-height:%spx;", body_height, pixels_per_hour),
        events
      )
    )
  })

  date_range <- paste(format(as.Date(dates[[1]]), "%d/%m"), "–", format(as.Date(tail(dates, 1)), "%d/%m/%Y"))
  htmltools::tags$div(
    class = "week-calendar-shell",
    htmltools::tags$div(
      class = "week-calendar-toolbar",
      htmltools::tags$div(
        htmltools::tags$div(class = "week-calendar-title", title),
        htmltools::tags$div(class = "week-calendar-range", date_range)
      ),
      htmltools::tags$div(
        class = "week-calendar-legend",
        htmltools::tags$span(class = "legend-dot booked", "Reservada"),
        htmltools::tags$span(class = "legend-dot active", "En atención"),
        htmltools::tags$span(class = "legend-dot done", "Atendida"),
        htmltools::tags$span(class = "legend-dot cancelled", "Cancelada")
      )
    ),
    htmltools::tags$div(
      class = "week-calendar-scroll",
      tabindex = "0", role = "region", `aria-label` = "Agenda: desplace para consultar horas y días",
      htmltools::tags$div(
        class = "week-calendar-board",
        style = paste0("--days:", length(dates), ";--day-tracks:", paste(vapply(day_columns, function(day) {
          width <- gsub("[^0-9]", "", day$attribs$style)
          paste0("minmax(max(", width, "px,var(--day-width)),1fr)")
        }, character(1)), collapse=" "), ";"),
        htmltools::tags$div(
          class = "week-time-wrap",
          htmltools::tags$div(class = "week-time-header", "Hora"),
          htmltools::tags$div(class = "week-time-rail", style = sprintf("height:%spx;", body_height), time_labels)
        ),
        day_columns
      )
    )
  )
}

availability_summary_ui <- function(slots) {
  if (!length(slots)) return(NULL)
  dates <- unique(vapply(slots, function(s) substr(s$start, 1, 10), character(1)))
  start_num <- vapply(slots, function(s) as.numeric(parse_fhir_datetime(s$start)), numeric(1))
  starts <- as.POSIXct(start_num, origin = "1970-01-01", tz = APP_CONFIG$timezone)
  htmltools::tags$div(
    class = "availability-summary",
    htmltools::tags$div(class = "availability-summary-icon", "✓"),
    htmltools::tags$div(
      htmltools::tags$strong(paste(length(slots), "horarios disponibles")),
      htmltools::tags$span(paste("en", length(dates), if (length(dates) == 1) "fecha" else "fechas", "· desde", format(min(starts, na.rm = TRUE), "%d/%m %H:%M")))
    )
  )
}

# Read-only projection of additional vitals; the existing blood-pressure workflow stays intact.
clinical_vitals_ui <- function(observations) {
  fields <- c(FC="8867-4", FR="9279-1", Temperatura="8310-5", SpO2="2708-6", Peso="29463-7", Talla="8302-2", IMC="39156-5")
  htmltools::tags$div(class="vitals-grid vitals-context", lapply(names(fields), function(label) {
    matches <- Filter(function(r) any(vapply(r$code$coding %||% list(), function(c) identical(c$system,"http://loinc.org") && identical(c$code, unname(fields[[label]])), logical(1))), observations)
    if (length(matches)) {
      order <- order(vapply(matches,function(r) r$effectiveDateTime %||% r$meta$lastUpdated %||% "",character(1)),decreasing=TRUE)
      measurement <- matches[[order[[1]]]]$valueQuantity
    } else measurement <- NULL
    htmltools::tags$div(class="vital-input",htmltools::tags$span(class="vital-icon",label),
      htmltools::tags$strong(if (is.null(measurement$value)) "Sin registro" else paste(measurement$value, measurement$unit %||% "")))
  }))
}
