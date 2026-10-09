# Hallazgos previos separados de la intervención visual

## Corregidos en la infraestructura de pruebas

1. El preflight comparaba con `identical()` una longitud entera con una constante double y reportaba “Patient esperaba 10 y encontró 10”. Ahora compara valores.
2. El cargador de testthat asumía el directorio raíz aunque testthat cambia al directorio de pruebas. Ahora resuelve rutas desde la raíz.
3. Preflight y pruebas accedían a `reactiveVal` fuera de un consumidor reactivo. Se ejecutan dentro de `shiny::isolate()`; no se desactivan las protecciones del servidor.

## Conservados porque pertenecen a datos o reglas funcionales

- El seed utiliza fechas fijas de septiembre/octubre de 2026. La disponibilidad incluye Slots libres de fechas pasadas; no se alteró el seed ni se impuso una nueva regla temporal.
- Al iniciar Encounter, `start_encounter()` marca Appointment como `fulfilled`, mientras Encounter queda `in-progress`. Los KPIs originales resumen Appointment y por ello “En atención” no refleja necesariamente los Encounter activos. No se alteró esta regla ni se presentó una reconciliación de estados como si fuera un cambio puramente visual.
- La disponibilidad se calcula al pulsar Consultar. Después de una escritura puede requerir una nueva consulta; la transacción sigue siendo la autoridad para aceptar/rechazar la reserva.
- El flujo clínico original registra únicamente presión arterial entre los signos vitales. Los demás signos añadidos a la vista son de solo lectura y pueden carecer de Observation.
- El stepper del paciente conserva la orientación de etapas del flujo original; no incorpora una nueva máquina de estados de reserva.

Estos puntos requieren decisiones funcionales separadas para modificarse. Las capturas y verificaciones no equivalen a certificación de uso clínico productivo.
