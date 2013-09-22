require(rCharts)
require(stringr)
library(shiny)
library(plyr)



# Define server logic required to generate and plot a random distribution
shinyServer(function(input, output) {
  
  # query the risk values using filters countries, risks, period
  getRiskValues <- reactive({
#     cIds <- subset(countries, GEO_NAME %in% input$countries, select=GEO_UNIT_ID)
#     cIds <- paste(cIds[,1], collapse=",")    
#     xrIds <- subset(risknames, INDICATOR_NAME %in% input$xRisks, select=INDICATOR_ID)
#     xrIds <- paste(xrIds[,1],collapse=",")
#     yrIds <- subset(risknames, INDICATOR_NAME %in% input$yRisks, select=INDICATOR_ID)
#     yrIds <- paste(yrIds[,1],collapse=",")
    period <- periods[input$period,][,"PERIOD_ID"]
    
#     query <- paste("SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'x' as WALL ",
#                    "FROM RR_INDICATOR_VALUE",tblext[envId]," ",
#                    "WHERE FK_TIME_PERIOD = ",period," ",
#                    "AND FK_INDICATOR IN (", as.character(xrIds),") ", 
#                    "AND FK_GEO_UNIT IN (", as.character(cIds), ") UNION ",
#                    "SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'y' as WALL ",
#                    "FROM RR_INDICATOR_VALUE",tblext[envId]," ",
#                    "WHERE FK_TIME_PERIOD = ",period," ",
#                    "AND FK_INDICATOR IN (", as.character(yrIds),") ", 
#                    "AND FK_GEO_UNIT IN (", as.character(cIds), ")",sep="")    
 
    # First: select all
    query <- paste("SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE ",
                   "FROM RR_INDICATOR_VALUE",tblext[envId]," ",
                   "WHERE FK_TIME_PERIOD = ",period ,sep="")
    
    results <- sqlQuery(con,query)
    results <- merge(results,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
    results <- merge(results,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]
    return(results)
  })
  
  
  output$mdmPlot <- renderChart({
#    p1 <- Highcharts$new()
#    return(p1)
  })
  
  
  
  output$xRiskWall <- renderChart({    
    r <- getRiskValues();

    p1 <- riskWallPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                data=subset(r,WALL=="x"), type="line",group="GEO_NAME", title="x Risks");
  
    p1$addParams(dom = 'xRiskWall');
    return(p1);
        
  })
  
  
  output$yRiskWall <- renderChart({    
    r <- getRiskValues();
    p1 <- riskWallPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                data=subset(r,WALL=="y"), type="line",group="GEO_NAME", title="y Risks");    

    p1$addParams(dom = 'yRiskWall');
    return(p1);

    })
  
  
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

# ========================= Functions -> store in different file =====================#
# Plot Risk Room Wall using HighCharts
# Plot includes boxplots & draggableY event listener for "what-if"
# What-if calculations implemented in javascript -> cf. file "whatif.js"
#
riskWallPlot <- function(..., radius = 3, title = NULL, subtitle = NULL, group.na = NULL){
  rChart <- Highcharts$new()
  
  # Get layers
  d <- getLayer(...)
  
  data <- data.frame(
    x = d$data[[d$x]],
    y = d$data[[d$y]]
  )
  
  if (!is.null(d$group)) {
    data$group <- as.character(d$data[[d$group]])
    if (!is.null(group.na)) {
      data$group[is.na(data$group)] <- group.na
    }
  }
  if (!is.null(d$size)) data$size <- d$data[[d$size]]
  
  nrows <- nrow(data)
  data <- na.omit(data)  # remove remaining observations with NA's
  
  if (nrows != nrow(data)) warning("Observations with NA has been removed")
  
  data <- data[order(data$x, data$y), ]  # order data (due to line charts)
  
  if ("bubble" %in% d$type && is.null(data$size)) stop("'size' is missing")
  
  if (!is.null(d$group)) {
    groups <- sort(unique(data$group))
    types <- rep(d$type, length(groups))  # repeat types to match length of groups
    
    plyr::ddply(data, .(group), function(x) {
      g <- unique(x$group)
      i <- which(groups == g)
      
      x$group <- NULL  # fix
      rChart$series(
        data = toJSONArray2(x, json = F, names = F),
        name = g,
        type = types[[i]],
        marker = list(radius = radius),
        draggableY = TRUE
      )
      return(NULL)
    })
  } else {
    
    rChart$series(
      data = toJSONArray2(data, json = F, names = F),
      type = d$type[[1]],
      marker = list(radius = radius),
      draggableY = TRUE
    )
    
    rChart$legend(enabled = FALSE)
  }
  
  # Fix defaults
  
  ## xAxis
  if (is.categorical(data$x)) {
    rChart$xAxis(title = list(text = d$x), categories = unique(as.character(data$x)), replace = T)
  } else {
    rChart$xAxis(title = list(text = d$x), replace = T)
  }
  
  ## yAxis
  if (is.categorical(data$y)) {
    rChart$yAxis(title = list(text = d$y), categories = unique(as.character(data$y)), replace = T)
  } else {
    rChart$yAxis(title = list(text = d$y), replace = T)
  }
  
  ## title
  rChart$title(text = title, replace = T)
  
  ## subtitle
  rChart$subtitle(text = subtitle, replace = T)
  
  
  ## what-if bindings
  rChart$plotOptions(        
    series = list(
      cursor = "ns-resize",
      point = list(
        events = list(
          drop = "#! function() { whatif(this); } !#" )
      ),
      stickyTracking = TRUE
    )
  );  
  
  return(rChart$copy())
}
