mod_fhir_graph_ui <- function(id){
  ns <- shiny::NS(id)
  if(requireNamespace("visNetwork",quietly=TRUE))
    visNetwork::visNetworkOutput(ns("network"),height="560px")
  else
    shiny::uiOutput(ns("fallback"))
}

mod_fhir_graph_server <- function(id,store,selected_key){
  shiny::moduleServer(id,function(input,output,session){
    graph_data <- shiny::reactive({
      key <- selected_key(); shiny::req(key)
      parts <- strsplit(key,"/",fixed=TRUE)[[1]]
      center <- state_resource(store(),parts[[1]],parts[[2]])
      refs <- extract_references(center)
      nodes <- data.frame(id=key,label=key,group=center$resourceType,stringsAsFactors=FALSE)
      edges <- data.frame(from=character(),to=character(),stringsAsFactors=FALSE)
      if(length(refs)){
        for(z in refs){
          nodes <- rbind(nodes,data.frame(id=z,label=z,group=get_ref_type(z),stringsAsFactors=FALSE))
          edges <- rbind(edges,data.frame(from=key,to=z,stringsAsFactors=FALSE))
        }
      }
      # Añadir una segunda capa: recursos que apuntan al recurso seleccionado.
      incoming <- Filter(function(r) key %in% extract_references(r),all_resources(store))
      for(r in incoming){
        rk <- resource_ref(r)
        nodes <- rbind(nodes,data.frame(id=rk,label=rk,group=r$resourceType,stringsAsFactors=FALSE))
        edges <- rbind(edges,data.frame(from=rk,to=key,stringsAsFactors=FALSE))
      }
      nodes <- nodes[!duplicated(nodes$id),,drop=FALSE]
      edges <- edges[!duplicated(edges),,drop=FALSE]
      list(nodes=nodes,edges=edges)
    })

    if(requireNamespace("visNetwork",quietly=TRUE)){
      output$network <- visNetwork::renderVisNetwork({
        g <- graph_data()
        visNetwork::visNetwork(g$nodes,g$edges) |>
          visNetwork::visNodes(shape="box",font=list(size=15)) |>
          visNetwork::visEdges(arrows="to",smooth=FALSE) |>
          visNetwork::visOptions(highlightNearest=TRUE,nodesIdSelection=TRUE) |>
          visNetwork::visLayout(randomSeed=42)
      })
    } else {
      output$fallback <- shiny::renderUI({
        g <- graph_data()
        if(!nrow(g$edges)) return(htmltools::tags$div(class="empty-state","El recurso seleccionado no contiene relaciones visibles."))
        htmltools::tags$div(
          class="ref-graph",
          htmltools::tags$div(class="graph-center",selected_key()),
          lapply(seq_len(nrow(g$edges)),function(i)
            htmltools::tags$div(class="graph-edge",htmltools::tags$code(g$edges$from[[i]]),htmltools::tags$span("→"),htmltools::tags$code(g$edges$to[[i]]))
          )
        )
      })
    }
  })
}
