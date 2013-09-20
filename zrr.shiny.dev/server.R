require(rCharts)
require(stringr)
library(shiny)

# Define server logic required to generate and plot a random distribution
shinyServer(function(input, output) {
  
  # query the risk values using filters countries, risks, period
  getRiskValues <- reactive({
    cIds <- subset(countries, GEO_NAME %in% input$countries, select=GEO_UNIT_ID)
    cIds <- paste(cIds[,1], collapse=",")    
    xrIds <- subset(risknames, INDICATOR_NAME %in% input$xRisks, select=INDICATOR_ID)
    xrIds <- paste(xrIds[,1],collapse=",")
    yrIds <- subset(risknames, INDICATOR_NAME %in% input$yRisks, select=INDICATOR_ID)
    yrIds <- paste(yrIds[,1],collapse=",")
    period <- periods[input$period,][,"PERIOD_ID"]
    
    query <- paste("SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'x' as 'WALL' ",
                   "FROM RR_INDICATOR_VALUE",tblext[envId]," ",
                   "WHERE FK_TIME_PERIOD = ",period," ",
                   "AND FK_INDICATOR IN (", as.character(xrIds),") ", 
                   "AND FK_GEO_UNIT IN (", as.character(cIds), ") UNION ",
                   "SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'y' as 'WALL' ",
                   "FROM RR_INDICATOR_VALUE",tblext[envId]," ",
                   "WHERE FK_TIME_PERIOD = ",period," ",
                   "AND FK_INDICATOR IN (", as.character(yrIds),") ", 
                   "AND FK_GEO_UNIT IN (", as.character(cIds), ")",sep="")    
    
    browser()
    results <- sqlQuery(con,query)
    results <- merge(results,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
    results <- merge(results,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]
    return(results)
  })
  
  
  output$mdmPlot <- renderChart({
  })
  
  
  
  output$xRiskWall <- renderChart({    
    r <- getRiskValues();

    p1 <- hPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                data=subset(r,WALL=="x"), type="line",group="GEO_NAME", title="x Risks");
    p1$series(draggableY=TRUE)
    p1$plotOptions(        
      series = list(
        cursor = "ns-resize",
        point = list(
          events = list(
            drop = "#! function() { whatif(this); } !#" )
        ),
        stickyTracking = TRUE
      )
    );    
    p1$addParams(dom = 'xRiskWall');
    return(p1);
        
  })
  
  
  output$yRiskWall <- renderChart({    
    r <- getRiskValues();
    
    p1 <- hPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                data=subset(r,WALL=="y"), type="line",group="GEO_NAME", title="y Risks");    
    p1$plotOptions(        
      series = list(
        cursor = "ns-resize",
        point = list(
          events = list(
            drop = "#! function() { whatif(this); } !#" )
        ),
        stickyTracking = TRUE
      )
    );    
    p1$addParams(dom = 'yRiskWall');
    return(p1);

    })
  
  
#   output$xRiskWall <- renderChart({
#     names(iris) = gsub("\\.", "", names(iris))
#     p1 <- rCharts::Highcharts$new()
#     sapply(1:10,function(x) {
#       p1$series(data=rnorm(10), draggableY = TRUE)
#     })
#     p1$plotOptions(
#       series = list(
#         cursor = "ns-resize",
#         point = list(
#           events = list(
# #            drag = "#! function() {  $('#drag').html( 
# #                            'Dragging <b>' + this.series.name + '</b>, <b>' +
# #                            this.category + '</b> to <b>' + 
# #                            Highcharts.numberFormat(e.newY, 2) + '</b>'
# #                        ); } !#",
#             drop = "#! function() { whatif(this); } !#" )
#         # TODO: need to figure out how to hand over the delta between starting / end position
#         #       possibly best to adapt the draggable-points.js 
# #            drop = "#! function() { $('#drop').html(
# #                            'In <b>' + this.series.name + '</b>, <b>' +
# #                            this.category + '</b> was set to <b>' + 
# #                            Highcharts.numberFormat(this.y, 2) + '</b>'
# #                        ); } !#"  )
#          ),
#         stickyTracking = TRUE
#       )
#     )
#     #p1 <- hPlot(input$x, input$y, data = iris, type = c("line", "bubble"), group = "Species", size=1)
#     p1$addParams(dom = 'xRiskWall')
#     return(p1)
#   })
  
  
  # conditionally create output widgets for xRisks and yRisks
  # based on the xRiskCategory and yRiskCategory selections
  output$xRisks <- renderUI({
    riskSelection <- unlist(subset(risknames,
                                   INDICATOR_CATEGORY==input$xRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("xRisks", "Choose x Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })
  
  output$yRisks<- renderUI({
    riskSelection <- unlist(subset(risknames,
                                   INDICATOR_CATEGORY==input$yRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("yRisks", "Choose y Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })
})