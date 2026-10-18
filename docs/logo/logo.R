# -----------------------------------------------------------------------------
# Agenda FHIR · Logo (hexágono)
#
# Misma familia visual que geoecu y pobecu (azul marino y dorado). El
# calendario representa el flujo del prototipo: Schedule (la agenda), Slot
# (intervalos libres, contorno), Appointment (citas reservadas, dorado) y una
# cita atendida (marca de verificación). No usa el logo de HL7 FHIR.
#
# Uso: Rscript docs/logo/logo.R   (genera www/logo.png)
# -----------------------------------------------------------------------------
library(grid)

azul   <- "#0F2233"
azul2  <- "#1B3A52"
dorado <- "#F2B705"
blanco <- "#F4F6F8"
teal   <- "#3FB8A6"

alto <- 1200
ancho <- round(alto * sqrt(3) / 2)
png("www/logo.png", width = ancho, height = alto, bg = "transparent",
    type = "cairo", antialias = "subpixel")

hexagono <- function(r) {
  ang <- pi / 2 + (0:5) * pi / 3
  list(x = 0.5 + r * cos(ang) * alto / ancho / 2, y = 0.5 + r * sin(ang) / 2)
}
h_ext <- hexagono(0.995); h_med <- hexagono(0.955); h_int <- hexagono(0.925)

grid.newpage()
grid.polygon(h_ext$x, h_ext$y, gp = gpar(fill = dorado, col = NA))
grid.polygon(h_med$x, h_med$y,
             gp = gpar(col = NA, fill = radialGradient(c(azul2, azul),
                                                       cx1 = 0.5, cy1 = 0.6, r2 = 0.7)))
grid.polygon(h_int$x, h_int$y,
             gp = gpar(fill = NA, col = adjustcolor(dorado, 0.35), lwd = 1.6))

# --- Calendario ----------------------------------------------------------------
pushViewport(viewport(x = 0.5, y = 0.575, width = 0.56, height = 0.40))
lw <- 7
# Cuerpo
grid.roundrect(x = 0.5, y = 0.44, width = 0.96, height = 0.82, r = unit(0.06, "snpc"),
               gp = gpar(fill = adjustcolor(blanco, 0.06), col = blanco, lwd = lw))
# Barra superior
grid.roundrect(x = 0.5, y = 0.79, width = 0.96, height = 0.13, r = unit(0.06, "snpc"),
               gp = gpar(fill = blanco, col = blanco, lwd = lw))
grid.rect(x = 0.5, y = 0.745, width = 0.96, height = 0.04,
          gp = gpar(fill = blanco, col = NA))
# Anillas
for (xa in c(0.27, 0.73)) {
  grid.roundrect(x = xa, y = 0.9, width = 0.055, height = 0.16, r = unit(0.02, "snpc"),
                 gp = gpar(fill = dorado, col = azul, lwd = 5))
}
# Cuadrícula de slots: 5 columnas x 4 filas
estado <- matrix(c("libre", "cita", "libre", "libre", "cita",
                   "cita", "libre", "atendida", "cita", "libre",
                   "libre", "cita", "libre", "cita", "libre",
                   "libre", "libre", "cita", "libre", "libre"),
                 nrow = 4, byrow = TRUE)
xs <- seq(0.13, 0.87, length.out = 5)
ys <- seq(0.61, 0.13, length.out = 4)
lado <- 0.115
for (i in 1:4) for (j in 1:5) {
  e <- estado[i, j]
  relleno <- switch(e, libre = NA, cita = dorado, atendida = teal)
  borde <- switch(e, libre = adjustcolor(blanco, 0.75), cita = dorado, atendida = teal)
  grid.roundrect(x = xs[j], y = ys[i], width = lado, height = lado * 1.05,
                 r = unit(0.015, "snpc"),
                 gp = gpar(fill = relleno, col = borde, lwd = 4))
  if (e == "atendida") {
    grid.lines(x = xs[j] + c(-0.035, -0.008, 0.04), y = ys[i] + c(0, -0.03, 0.035),
               gp = gpar(col = azul, lwd = 9, lineend = "round", linejoin = "round"))
  }
}
popViewport()

# --- Nombre ----------------------------------------------------------------------
tam <- 128
g1 <- textGrob("agenda", gp = gpar(fontsize = tam, fontface = "bold"))
g2 <- textGrob("fhir", gp = gpar(fontsize = tam, fontface = "bold"))
w1 <- convertWidth(grobWidth(g1), "npc", valueOnly = TRUE)
w2 <- convertWidth(grobWidth(g2), "npc", valueOnly = TRUE)
x0 <- 0.5 - (w1 + w2) / 2
grid.text("agenda", x = x0, y = 0.245, just = "left",
          gp = gpar(fontsize = tam, fontface = "bold", col = blanco))
grid.text("fhir", x = x0 + w1, y = 0.245, just = "left",
          gp = gpar(fontsize = tam, fontface = "bold", col = dorado))

invisible(dev.off())
message("Escrito: www/logo.png")
