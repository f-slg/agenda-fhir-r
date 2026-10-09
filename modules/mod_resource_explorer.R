mod_resource_explorer_ui <- function(id){
  ns <- shiny::NS(id)
  DT::DTOutput(ns("table"))
}

mod_resource_explorer_server <- function(id,store){
  shiny::moduleServer(id,function(input,output,session){
    resource_index <- shiny::reactive({
      rs <- all_resources(store)
      if(!length(rs)) return(data.frame())
      do.call(rbind,lapply(rs,function(r)
        data.frame(
          key=paste0(r$resourceType,"/",r$id),
          resourceType=r$resourceType,
          id=r$id,
          versionId=r$meta$versionId %||% "",
          lastUpdated=r$meta$lastUpdated %||% "",
          status=r$status %||% r$participantStatus %||% "",
          channel=extract_extension_value(r,APP_CONFIG$channel_extension_url) %||% "",
          stringsAsFactors=FALSE
        )
      ))
    })

    output$table <- DT::renderDT(
      DT::datatable(resource_index(),rownames=FALSE,filter="top",selection="single",options=list(scrollX=TRUE,pageLength=15))
    )

    selected_key <- shiny::reactive({
      i <- input$table_rows_selected
      if(!length(i) || !nrow(resource_index())) return(NULL)
      resource_index()$key[[i[[1]]]]
    })

    list(index=resource_index,selected_key=selected_key)
  })
}
