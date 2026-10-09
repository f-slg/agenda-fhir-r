extract_references <- function(x) {
  out <- character()
  walk <- function(node) {
    if (is.list(node)) {
      if (!is.null(node$reference) && is.character(node$reference) && length(node$reference)==1) out <<- c(out,node$reference)
      for (z in node) walk(z)
    }
  }
  walk(x); unique(out)
}
reference_exists_in_state <- function(state, reference) {
  if (!grepl("^[A-Za-z]+/[^/]+$", reference)) return(FALSE)
  type <- get_ref_type(reference); id <- get_ref_id(reference)
  !is.null(state$resources[[type]][[id]])
}
validate_references_state <- function(state, resource) {
  refs <- extract_references(resource)
  broken <- refs[!vapply(refs, function(z) reference_exists_in_state(state,z), logical(1))]
  list(valid=!length(broken), broken=broken)
}
