mod_json_viewer_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::uiOutput(ns("header")),
    htmltools::tags$div(class="json-toolbar",
      htmltools::tags$button(type="button", class="btn btn-outline-secondary", `data-copy-target`=ns("json"), "Copiar JSON"),
      shiny::downloadButton(ns("download"),"Descargar JSON",class="btn-outline-primary btn-sm"),
      htmltools::tags$span(class="copy-feedback", role="status", `aria-live`="polite")
    ),
    htmltools::tags$pre(class="json-view", tabindex="0", shiny::textOutput(ns("json")))
  )
}

mod_json_viewer_server <- function(id,store,selected_key){
  shiny::moduleServer(id,function(input,output,session){
    selected_resource <- shiny::reactive({
      key <- selected_key(); shiny::req(key)
      parts <- strsplit(key,"/",fixed=TRUE)[[1]]
      state_resource(store(),parts[[1]],parts[[2]])
    })

    output$header <- shiny::renderUI({
      key <- selected_key()
      if(is.null(key)) return(htmltools::tags$div(class="empty-state","Seleccione un recurso en Resources."))
      htmltools::tags$div(class="context-pill technical",key)
    })
    output$json <- shiny::renderText({r<-selected_resource();json_pretty(r)})
    output$download <- shiny::downloadHandler(
      filename=function(){paste0(gsub("/","-",selected_key()),".json")},
      content=function(file) writeLines(json_pretty(selected_resource()),file,useBytes=TRUE)
    )
    selected_resource
  })
}
