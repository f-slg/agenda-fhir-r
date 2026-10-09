mod_validation_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(shiny::uiOutput(ns("result")),shiny::uiOutput(ns("references")))
}
mod_validation_server <- function(id,store,selected_resource){
  shiny::moduleServer(id,function(input,output,session){
    output$result <- shiny::renderUI({
      r <- selected_resource()
      if(is.null(r)) return(htmltools::tags$div(class="empty-state","Seleccione un recurso en Resources."))
      v <- validate_resource(r,store())
      htmltools::tags$div(
        class=if(v$valid) "alert alert-success" else "alert alert-danger",
        htmltools::tags$strong(if(v$valid) "Validation OK" else "Validation issues"),
        htmltools::tags$ul(lapply(v$outcome$issue,function(x) htmltools::tags$li(x$diagnostics)))
      )
    })
    output$references <- shiny::renderUI({
      r <- selected_resource()
      if(is.null(r)) return(NULL)
      refs <- validate_references_state(store(),r)
      if(refs$valid) htmltools::tags$div(class="alert alert-success","Referencias resolubles en el Store.")
      else htmltools::tags$div(class="alert alert-danger",paste("Referencias rotas:",paste(refs$broken,collapse=", ")))
    })
  })
}
