# Intervención UI/UX — 8 de octubre de 2026

El proyecto existente fue modificado directamente. No se reconstruyó la aplicación y no se añadieron paquetes de ejecución.

## Diagnóstico previo

- `www/app.css` contenía dos capas de diseño que redefinían navbar, tipografía, cards y breakpoints, muchos colores literales y reglas `!important`.
- `page_navbar(fillable=TRUE)` y grids pensadas para llenar alturas convivían con contenido clínico de altura natural.
- El calendario imponía un mínimo global de 930 px, columnas de 170 px y bloques con altura mínima de 38 px que podían cruzarse aunque los intervalos reales no se cruzaran. El ancho mínimo porcentual de 8% también fallaba con muchas citas simultáneas.
- Varios grids usaban mínimos intrínsecos y paneles estrechos de 9/3 columnas; los textos técnicos y tablas podían forzar anchuras mayores.
- La “semana” era una selección de fechas con citas, a veces repartidas entre septiembre y octubre.

## Cambios

- CSS reorganizado en 14 secciones: tokens, base, layout, navegación, formularios, superficies, estados, Home, paciente, agendador, calendario, clínica, consola técnica y responsive. Sin reglas `!important`.
- Segoe UI / Inter / Arial; texto principal de 14 px, auxiliar de 12–13 px, títulos de 28–32 px, superficies sobrias y tokens semánticos.
- Contenedor de hasta 1600 px con padding variable. Flujo de documento natural; Grid con `minmax(0,…)` y paneles adaptables. Inspector debajo de la tabla desde menos de 1200 px.
- Agenda de lunes a domingo, selector de semana en Agendador y fechas vacías visibles. Siete días en pantallas grandes; cinco columnas cómodas y desplazamiento interno en laptops. Los fines de semana siguen disponibles mediante scroll.
- Eje horario de 07:00–19:00 ampliable a los datos, encabezados y eje sticky, ventana de altura limitada. La escala vertical se adapta a citas cortas para conservar cuatro líneas legibles. Columnas por concurrencia, sin mínimos porcentuales que provoquen invasiones. Nombres largos usan elipsis con texto completo en tooltip y etiqueta accesible.
- Calendarios de disponibilidad y horarios seleccionables adaptables, foco visible, estados seleccionados y deshabilitados.
- KPIs compactos, estados semánticos consistentes, inspector con profesional resuelto desde referencias existentes, búsqueda en tabla del agendador.
- Portal clínico con presión arterial editable original y FC, FR, temperatura, SpO2, peso, talla e IMC como lecturas de Observation. Se muestra “Sin registro” si no existe una medición; no se inventan datos ni se agregan escrituras clínicas.
- Tablas con scroll local y reajuste de ancho al abrir pestañas. JSON con scroll interno, Copiar y Descargar visibles. JavaScript limitado a portapapeles y medición de tablas.
- CSS y JavaScript incorporados mediante `includeCSS()` / `includeScript()`, sin depender de rutas HTTP de `www`. El CSS se interpreta en el navegador, fuera de Sass, y funciona tanto con `runApp(".")` como al ejecutar el objeto Shiny de `source("app.R")`.
- Preflight reparado y ampliado; regresión para citas cortas, concurrencia elevada, horarios tardíos, badges y construcción del UI.

## Preservación funcional

`docs/qa-responsive/core-integrity.json` compara SHA-256 contra el proyecto original. `app.R`, `R/server.R`, configuración, seed, Store, Search, recursos, validación, reglas de negocio, Bundle, transacciones, auditoría, Provenance, referencias, gateway AI y JSON de seed permanecen idénticos.

El FHIR Store no fue sustituido. Schedule/Slot siguen siendo la fuente de disponibilidad y Appointment la fuente de citas. El calendario solo proyecta los datos existentes; el selector de semana no modifica ningún recurso. Las pruebas existentes de reserva, liberación de Slot, búsqueda entre canales y transacción clínica pasan.

## Archivos originales modificados

- `R/ui.R`
- `R/utils.R`
- `modules/mod_ai_copilot.R`
- `modules/mod_audit.R`
- `modules/mod_clinician.R`
- `modules/mod_json_viewer.R`
- `modules/mod_patient_portal.R`
- `modules/mod_resource_explorer.R`
- `modules/mod_rest_trace.R`
- `modules/mod_scheduler.R`
- `scripts/01_preflight.R`
- `scripts/03_tests.R`
- `tests/testthat.R`
- `tests/testthat/helper-load.R`
- `www/app.css`

## Archivos nuevos de soporte

- `www/ui.js`
- `tests/testthat/test-ui-layout.R`
- `scripts/04_visual_qa.cjs`
- `scripts/05_calendar_fixture.R`
- `scripts/06_interaction_qa.cjs`
- Este informe, `docs/QA_RESPONSIVE.md`, `docs/ISSUES_PREEXISTENTES.md` y la carpeta `docs/qa-responsive/` con capturas, galería, mediciones, logs y comprobantes de integridad.

## Ejecución

Desde la raíz del proyecto: `Rscript scripts/01_preflight.R`, `Rscript scripts/03_tests.R`, `Rscript scripts/02_run_app.R`.

Se mantienen los requisitos de R y paquetes indicados en el README original. El ZIP es el proyecto R/Shiny completo, no un binario con R incorporado. Playwright solo se usa en QA de desarrollo; no es dependencia de la aplicación. Los scripts de navegador aceptan `PLAYWRIGHT_MODULE` y `QA_BROWSER` si se utiliza una instalación existente.

Consulte `docs/QA_RESPONSIVE.md` y abra `docs/qa-responsive/index.html` para ver las evidencias.
