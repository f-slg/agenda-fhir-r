# QA — Professional Clinical UI 1.3

## Alcance

Revisión de la evolución visual aplicada sobre la versión Clinical UI funcional, sin modificar el modelo del FHIR Store ni las operaciones de agenda/atención.

## Comprobaciones realizadas en el entorno de construcción

- delimitadores `()` y `{}` balanceados en todos los archivos `.R`: **PASS**;
- outputs Shiny nuevos presentes para todos los `uiOutput()`, `DTOutput()` y `textOutput()` modificados: **PASS**;
- CSS parseado con `tinycss2` sin errores de sintaxis: **PASS**;
- preview HTML parseado correctamente: **PASS**;
- previsualización real renderizada con Chromium/Playwright a 1600×1200: **PASS**;
- no existen llamadas directas problemáticas `htmltools::ul()`, `details()`, `small()`, etc.: **PASS**;
- `bslib::font_system()` no se utiliza: **PASS**;
- no se añadió `renv` ni nuevas dependencias de runtime: **PASS**;
- agenda semanal deriva de `Appointment`; disponibilidad deriva de `Slot`: **PASS por inspección de código**;
- tabla operativa se conserva junto a la vista temporal: **PASS**.

## Componentes nuevos cubiertos por `scripts/01_preflight.R`

- `week_schedule_ui()`;
- `appointment_kpis_ui()`;
- `availability_summary_ui()`;
- componentes previos de calendario y status badges.

## Limitación del QA

El entorno de construcción no dispone de un ejecutable R, por lo que esta edición no se ejecutó aquí con `shiny::runApp()`. El proyecto base sí corresponde a la rama que el usuario ya logró arrancar. La prueba definitiva en Ubuntu es:

```bash
Rscript scripts/01_preflight.R
Rscript scripts/02_run_app.R
```

El `preflight` fue ampliado específicamente para detectar fallos en los nuevos helpers antes del inicio de la interfaz.
