if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Falta testthat. Ejecute scripts/00_install_packages.R", call. = FALSE)
}
shiny::isolate(testthat::test_dir("tests/testthat", reporter = "summary"))
