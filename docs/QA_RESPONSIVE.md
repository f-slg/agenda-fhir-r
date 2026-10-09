# Matriz QA — 8 de octubre de 2026

Aplicación real R/Shiny ejecutada localmente en R 4.5.2, shiny 1.14.0, bslib 0.12.0, DT 0.34.0 y navegador Brave/Chromium mediante Playwright. No se usaron mockups para las capturas de módulos.

## Resultado de geometría y navegación

| Resolución | Vistas | Overflow global | Cruces de citas | Cruces de paneles | Shiny/JS |
|---|---:|---:|---:|---:|---|
| 1920 × 1080 | 15 | 0 | 0 | 0 | OK |
| 1600 × 900 | 15 | 0 | 0 | 0 | OK |
| 1440 × 900 | 15 | 0 | 0 | 0 | OK |
| 1366 × 768 | 15 | 0 | 0 | 0 | OK |
| 1280 × 800 | 15 | 0 | 0 | 0 | OK |
| 1024 × 768 | 15 | 0 | 0 | 0 | OK |

Las 15 vistas por resolución incluyen Home, Portal Paciente con horarios cargados, Agendador con inspector, Portal Clínico, AI Copilot y las diez pestañas de FHIR Studio. Se guardaron 90 capturas completas y las mediciones correspondientes. Las capturas son de página completa: su altura puede ser mayor que la altura del viewport probado.

Se inspeccionaron visualmente capturas representativas de las seis resoluciones, con especial atención a 1366 × 768 y 1024 × 768. La medición automática comprueba ancho del documento, intersecciones entre eventos y entre hijos de los grids principales, y errores visibles de Shiny. No representa una prueba exhaustiva de cada combinación posible de datos ni de otros navegadores.

## Citas simultáneas

Fixture de 15 citas, trece simultáneas, intervalos de 15 minutos y una cita a las 20:00: **sin intersecciones ni overflow global en las seis resoluciones**. Todos los eventos permanecen en la representación. Los datos del fixture están aislados del Store de la aplicación.

## Flujos interactivos comprobados a 1366 × 768

- Reserva desde Portal Paciente y confirmación de Appointment.
- Lectura del mismo Appointment en Agendador, cancelación y notificación de Slot liberado.
- Inicio de Encounter, preparación del Bundle clínico y procesamiento hasta estado finished.
- Copiar JSON al portapapeles, validarlo como JSON y descargar el recurso.

La tabla del agendador se vuelve a renderizar tras cancelar; la prueba reselecciona la cita para inspeccionar el estado actualizado.

## Preflight y pruebas R

`Rscript scripts/01_preflight.R`: **OK**. Construcción del seed, validación, transacción de reserva, búsquedas, calendarios, badges, KPI, inspector, helpers de layout y render de app_ui.

`Rscript scripts/03_tests.R`: **OK**. Suite original de Store, Bundle, reserva/cancelación, continuidad entre canales y flujo clínico, más regresión geométrica y estados UI. El aviso de caché Sass de solo lectura en el entorno restringido no impidió compilar el tema ni ejecutar la aplicación.

## Evidencias

- `qa-responsive/index.html`: galería local por resolución.
- `qa-responsive/measurements.json`: resultados de las 90 vistas.
- `qa-responsive/interactions.json`: pruebas interactivas y concurrencia.
- `qa-responsive/calendar-stress.html`: fixture visual de concurrencia.
- `qa-responsive/preflight.log` y `qa-responsive/tests.log`.
- `qa-responsive/core-integrity.json`: SHA-256 de los archivos funcionales preservados.
- `ISSUES_PREEXISTENTES.md`: limitaciones funcionales anteriores, separadas de esta intervención.

El ZIP conserva el proyecto completo y requiere el entorno R y los paquetes originales. No añade dependencias de ejecución.

## Corrección de carga de recursos tras reporte del usuario

Se reprodujo la página sin diseño al ejecutar `runApp(source("app.R")$value)`: el CSS personalizado no se aplicaba y `ui.js` devolvía 404. La prueba original de carpeta no cubría esta modalidad.

`R/ui.R` incorpora ahora los archivos de estilo y JavaScript en el HTML mediante `includeCSS()` e `includeScript()`. No se modificaron datos ni operaciones FHIR.

Validación nueva: ambos modos de arranque, Home en las seis resoluciones (12 comprobaciones), agenda visible, JavaScript de portapapeles y ausencia de errores HTTP/JS en ambos modos. Las 14 comprobaciones pasan. Evidencias en `qa-startup/results.json`, `qa-startup/object-home.png` y `qa-startup/directory-home.png`. El script reproducible es `scripts/07_startup_qa.cjs`.

`tests/testthat/test-ui-assets.R` comprueba la incorporación de CSS/JS y el error explícito si faltan archivos. El preflight y la suite R pasan. La QA general ahora comprueba también estilos calculados y respuestas HTTP fallidas para evitar aceptar una página sin diseño.

Para actualizar una sesión que ya estaba abierta en RStudio, detener la aplicación y volver a pulsar Run App; refrescar solamente el navegador no reconstruye el objeto UI que quedó en memoria.
