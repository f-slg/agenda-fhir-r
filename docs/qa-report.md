# QA report — FHIR Clinical Flow 0.2.0 clean R45

Esta distribución fue preparada para instalación limpia con R >= 4.3 y específicamente orientada a R 4.5.x.

- Sin activación automática de renv: PASS
- Sin renv.lock distribuido: PASS
- app.R verifica solo dependencias runtime realmente utilizadas: PASS
- bslib::font_system eliminado: PASS
- Instalador usa librería normal del usuario: PASS
- Preflight valida seed y reserva transaccional: PASS
- Portal Paciente, Agendador y Portal Clínico comparten un único Store: PASS
- visNetwork tiene fallback cuando no está disponible: PASS

La ejecución real de R/Shiny debe validarse en el Ubuntu del usuario mediante `scripts/01_preflight.R`.
