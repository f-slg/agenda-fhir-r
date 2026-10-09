# Clinical UI 1.2

La actualización visual está diseñada para que FHIR Clinical Flow se perciba como software clínico profesional y no como una interfaz Shiny genérica.

## Principios visuales

1. **Claridad clínica**: fondos claros, alto contraste, densidad moderada y jerarquía predecible.
2. **Color con significado**: el color no decora; comunica estado operativo.
3. **FHIR permanece visible, pero no invade la experiencia del paciente**.
4. **Calendario derivado del Store**: no existe una segunda agenda visual independiente.
5. **Sin nuevas dependencias de calendario**: menor riesgo para la demo.

## Semántica de color

- Azul: cita reservada / acción principal.
- Verde: disponibilidad, aceptación y finalización exitosa.
- Teal: episodio atendido / flujo clínico completado.
- Ámbar: atención en progreso o advertencia.
- Rojo: cancelación, rechazo o error.
- Gris: estado neutral o técnico.

## Nuevas vistas temporales

### Portal Paciente

La consulta de disponibilidad muestra una vista por fecha con:

- día de semana;
- número y mes;
- cantidad de horarios;
- rango horario;
- indicador de disponibilidad.

Los horarios continúan seleccionándose a partir de los `Slot` reales del Store simulado.

### Mis citas

Se resume el historial/proximidad de `Appointment` por fecha antes de la tabla detallada.

### Agendador

La agenda operativa dispone de un resumen calendario con estados, seguido de la tabla DT seleccionable.

### Portal Clínico

La agenda del médico usa la misma representación temporal de `Appointment` y mantiene la selección de fila para iniciar `Encounter`.

## Archivos modificados

- `www/app.css`
- `R/ui.R`
- `R/utils.R`
- `modules/mod_home.R`
- `modules/mod_patient_portal.R`
- `modules/mod_scheduler.R`
- `modules/mod_clinician.R`

La capa FHIR, las transacciones y el seed permanecen sin cambios funcionales.
