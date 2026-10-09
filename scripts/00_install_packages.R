cat("=== FHIR Clinical Flow | instalación limpia ===\n")
cat("R:", R.version.string, "\n")
cat("Plataforma:", R.version$platform, "\n\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Usar explícitamente la librería del usuario y NO renv.
r_minor <- paste0(R.version$major, ".", strsplit(R.version$minor, "\\.")[[1]][1])
user_lib <- Sys.getenv("R_LIBS_USER", unset = "")
if (!nzchar(user_lib)) {
  user_lib <- file.path(
    path.expand("~"), "R",
    paste0(R.version$platform, "-library"),
    r_minor
  )
}
user_lib <- path.expand(user_lib)
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(unique(c(user_lib, .libPaths())))

cat("Librería de usuario seleccionada:\n  ", user_lib, "\n", sep = "")
cat(".libPaths():\n")
cat(paste0("  - ", .libPaths(), collapse = "\n"), "\n\n")

runtime <- c("shiny", "bslib", "jsonlite", "htmltools", "DT")
recommended <- c("visNetwork")
development <- c("testthat")
optional_ai <- if (nzchar(Sys.getenv("GEMINI_API_KEY"))) "httr2" else character()
packages <- unique(c(runtime, recommended, development, optional_ai))

installed_ok <- vapply(
  packages,
  function(pkg) requireNamespace(pkg, quietly = TRUE),
  logical(1)
)
missing <- packages[!installed_ok]

if (length(missing)) {
  cat("Instalando paquetes faltantes:\n  ", paste(missing, collapse = ", "), "\n\n", sep = "")
  install.packages(missing, lib = user_lib, dependencies = TRUE)
} else {
  cat("Todos los paquetes requeridos ya están instalados.\n")
}

# Revalidar después de instalar.
status <- vapply(
  packages,
  function(pkg) requireNamespace(pkg, quietly = TRUE),
  logical(1)
)

cat("\nEstado final:\n")
for (pkg in packages) {
  cat(sprintf("  %-12s %s\n", pkg, if (status[[pkg]]) "OK" else "FALTA"))
}

if (!all(status)) {
  failed <- names(status)[!status]
  stop(
    "No se pudieron instalar/cargar: ", paste(failed, collapse = ", "),
    ". Revise el mensaje de compilación de CRAN.",
    call. = FALSE
  )
}

cat("\nINSTALL OK\n")
cat("Siguiente paso:\n  Rscript scripts/01_preflight.R\n")
