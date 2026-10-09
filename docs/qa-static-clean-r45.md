# QA estático — distribución clean R45

Verificaciones realizadas antes de empaquetar:

- No existe `.Rprofile` que active `renv`.
- No se distribuye `renv.lock` ni carpeta `renv/`.
- `app.R` exige únicamente `shiny`, `bslib`, `jsonlite`, `htmltools` y `DT`.
- `dplyr` y `purrr` no son dependencias directas del código actual.
- `bslib::font_system()` no se utiliza; la tipografía se define con una pila CSS estándar.
- `visNetwork` es complementario y el módulo incluye fallback textual.
- `httr2` solo se utiliza si se habilita Gemini.
- Los archivos R pasan una revisión estática de balance de paréntesis y llaves.
- `scripts/00_install_packages.R` instala en la librería normal del usuario.
- `scripts/01_preflight.R` valida estructura, seed, recursos y una reserva transaccional.

Limitación: el entorno de generación no dispone de un ejecutable R; por ello la validación de runtime debe ejecutarse en Ubuntu con `scripts/01_preflight.R`.
