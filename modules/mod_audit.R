mod_audit_ui <- function(id){
  ns <- shiny::NS(id)
  DT::DTOutput(ns("audit"))
}
mod_audit_server <- function(id,store){
  shiny::moduleServer(id,function(input,output,session){
    output$audit <- DT::renderDT(
      DT::datatable(store()$audit,rownames=FALSE,options=list(scrollX=TRUE,pageLength=15,order=list(list(0,"desc"))))
    )
  })
}
