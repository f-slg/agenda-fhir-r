mod_rest_trace_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    htmltools::tags$div(class="context-pill technical","SIMULATED REST TRACE"),
    DT::DTOutput(ns("trace"))
  )
}
mod_rest_trace_server <- function(id,store){
  shiny::moduleServer(id,function(input,output,session){
    output$trace <- DT::renderDT(
      DT::datatable(store()$rest_trace,rownames=FALSE,options=list(scrollX=TRUE,pageLength=15,order=list(list(0,"desc"))))
    )
  })
}
