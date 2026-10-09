# HTMLTools compatibility fix

Target environment observed: R 4.5.2, htmltools 0.5.9, shiny 1.14.0, bslib 0.12.0.

All direct HTML tag calls of the form `htmltools::<tag>()` were normalized to
`htmltools::tags$<tag>()` for robust compatibility. This includes `ul`, `li`,
`details`, `summary`, `small`, `div`, `span`, headings, `p`, `pre`, `code`,
`strong`, and `hr`.

The runtime remains renv-free for the clean R 4.5.x bootstrap path.

The internal helper formerly named `code()` was renamed to `coding_item()` to avoid
masking `shiny::code` when Shiny attaches its namespace.
