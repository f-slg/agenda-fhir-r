required <- c("shiny", "bslib", "jsonlite", "htmltools", "DT")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(
    "Faltan paquetes: ", paste(missing, collapse = ", "),
    ". Ejecute primero: Rscript scripts/00_install_packages.R",
    call. = FALSE
  )
}

cat("FHIR Clinical Flow\n")
cat("Abriendo http://127.0.0.1:3838\n")
shiny::runApp(
  appDir = ".",
  host = "127.0.0.1",
  port = 3838,
  launch.browser = TRUE
)
