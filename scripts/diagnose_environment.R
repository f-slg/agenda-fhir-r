cat("=== Diagnóstico de entorno ===\n")
cat("R:", R.version.string, "\n")
cat("R_HOME:", R.home(), "\n")
cat("R_LIBS_USER:", Sys.getenv("R_LIBS_USER"), "\n")
cat("RENV_PROJECT:", Sys.getenv("RENV_PROJECT"), "\n")
cat(".libPaths():\n")
cat(paste0("  - ", .libPaths(), collapse = "\n"), "\n\n")

pkgs <- c("shiny","bslib","jsonlite","htmltools","DT","visNetwork","testthat","httr2")
for (pkg in pkgs) {
  ok <- requireNamespace(pkg, quietly = TRUE)
  if (ok) {
    cat(sprintf("%-12s OK  %s  [%s]\n", pkg, as.character(utils::packageVersion(pkg)), dirname(find.package(pkg))))
  } else {
    cat(sprintf("%-12s NO INSTALADO\n", pkg))
  }
}
