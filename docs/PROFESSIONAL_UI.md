# Professional Clinical UI 1.3

## Objetivo

Elevar FHIR Clinical Flow desde una demo funcional a una superficie que visualmente se acerque a software clínico moderno, sin cambiar el modelo FHIR, las transacciones ni la fuente de verdad.

## Principios

1. **El calendario no es otra agenda.** Se dibuja a partir de `Appointment` y `Slot` existentes.
2. **La tabla no desaparece.** Sigue siendo la superficie precisa para selección y operación.
3. **El color tiene significado.** Azul reservado, ámbar en atención, teal atendido, rojo cancelado.
4. **FHIR Studio conserva una identidad técnica.** La experiencia de usuario y la inspección FHIR son superficies distintas del mismo producto.
5. **Sin nuevas dependencias de runtime.** La agenda semanal es Shiny + HTML/CSS.

## Agenda semanal profesional

La Consola del Agendador incorpora:

- eje horario;
- columnas por fecha;
- bloques posicionados por hora de inicio y duración;
- layout en carriles para citas coincidentes;
- leyenda de estados;
- KPIs de carga;
- inspector lateral;
- tabla operativa debajo de la vista temporal.

Los eventos se construyen desde el `data.frame` derivado de recursos `Appointment`. No existe un calendario paralelo persistido.

## Portal Paciente

La experiencia se organiza como:

1. Perfil / cobertura
2. Sede / servicio / profesional
3. Schedule / Slot
4. Confirmación de Appointment

Se agregan resumen de disponibilidad, calendario de fechas, tarjetas de horarios y confirmación clínica sobria.

## Portal Clínico

El portal se presenta como un command center clínico:

- agenda semanal;
- tabla de agenda;
- contexto del Encounter activo;
- signos vitales;
- problema, solicitud y plan;
- preparación y procesamiento explícito del Bundle;
- timeline longitudinal construida desde recursos del Store.

## FHIR Studio

Se convierte en un workbench técnico con cuatro verbos de lectura:

- Inspect
- Understand
- Validate
- Trace

La sección Architecture compara explícitamente prototipo actual y arquitectura objetivo.

## Compatibilidad

Diseñado sobre la versión estable para R 4.5.x. No se incorporan `renv`, FullCalendar ni dependencias de frontend adicionales.
