# Assumptions

1. **Identificador duplicado en la fuente.** Sede Centro y Sede Sur aparecen con `1100155555-2`. No se corrige silenciosamente. Se conserva como `Location.identifier.value`, mientras los IDs técnicos son `loc-centro` y `loc-sur`.
2. **Medicina general.** El caso no entrega profesionales de medicina general. En la demo su disponibilidad se publica mediante `Schedule.actor = HealthcareService + Location`; no se inventan médicos.
3. **Obstetricia vs Gineco Obstetricia.** Se conservan los textos fuente. `HealthcareService` usa “Obstetricia” y el `PractitionerRole` de Elmer Luna usa “Gineco Obstetricia”.
4. **Zona horaria.** La demo usa `America/Guayaquil`.
5. **Datos.** Todos los pacientes y eventos son sintéticos.
6. **Persistencia.** El Store es en memoria; reiniciar la sesión o `RESET DEMO` restaura el seed.
