source(file.path(project_root, "R/ui.R"))

test_that("CSS and JS are embedded without depending on www HTTP routes", {
  markup <- htmltools::renderTags(app_assets_ui(file.path(project_root,"www")))
  rendered <- paste(markup$head,markup$html)
  expect_match(rendered,"--color-brand:",fixed=TRUE)
  expect_match(rendered,".hero-grid",fixed=TRUE)
  expect_match(rendered,"data-copy-target",fixed=TRUE)
  expect_match(rendered,"adjustVisibleTables",fixed=TRUE)
  expect_false(grepl('href="app.css"',rendered,fixed=TRUE))
  expect_false(grepl('src="ui.js"',rendered,fixed=TRUE))
})

test_that("missing UI assets fail clearly instead of silently losing styling", {
  expect_error(app_assets_ui(file.path(tempdir(),"missing-fhir-assets")),"Faltan recursos de interfaz")
})
