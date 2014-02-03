require(rCharts)
require(stringr)
library(shiny)
library(plyr)


shinyServer(function(input, output) {
    
  
  # Risk Room Charts (MDM, x and y walls, table display)
  # ========================================================= #
  
  # The MDM scatter plot
  output$mdmPlot <- renderChart({
    r <- riskValues();      
    if (length(r)) {        
      
      p1 <- Highcharts$new()        
      p1$chart(type='bubble',zoomType='xy')
      p1$xAxis(min=0,max=1)        
      p1$yAxis(min=0,max=1)
      apply(r$mdm,1,function(x) {
        p1$series(
          name = as.character(x[1]),
          data = list(as.numeric(x[2:4]))
        )
      })
      p1$addParams(dom = 'mdmPlot');
      return(p1)         
    }      
  })
  
  # The x Risk Wall
  output$xRiskWall <- renderChart({    
    r <- riskValues();        
    p1 <- riskWallPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                        data=r$xRisks, bpd = r$xbpd, type="line",
                        group="GEO_NAME", title="x Risks");        
    p1$addParams(dom = 'xRiskWall');
    return(p1);
        
  })
  
  # The y Risk Wall
  output$yRiskWall <- renderChart({    
    r <- riskValues();
    p1 <- riskWallPlot(x="INDICATOR_NAME",y="INDICATOR_VALUE",
                        data=r$yRisks, bpd = r$ybpd, type="line",
                        group="GEO_NAME", title="y Risks");
    p1$addParams(dom = 'yRiskWall');
    return(p1);

    })
  
  # The table output
  output$table <- renderTable({
    r <- riskValues();
    if (length(r)) {
      r$mdm;
    }        
  })     
  
  
  # Conditionally create output widgets for xRisks and yRisks
  # based on the xRiskCategory and yRiskCategory selections
  # ========================================================= #
  
  # x-Risks selection menu
  output$xRisks <- renderUI({
    riskSelection <- unlist(subset(risknames,
                                   INDICATOR_CATEGORY==input$xRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("xRisks", "Choose x Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })
  
  # y-Risks selection menu
  output$yRisks<- renderUI({
    riskSelection <- unlist(subset(risknames,
                                   INDICATOR_CATEGORY==input$yRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("yRisks", "Choose y Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })


  # Reactive input: get countries, risks, period selection
  # Perform calculations and return results
  # ========================================================= #
  
  # query the risk values using filters countries, risks, period
  riskValues <- reactive({      
    if(!is.null(input$countries) && !is.null(input$xRisks) && !is.null(input$yRisks)) {    
        calculateMDM(input$countries,input$xRisks,input$yRisks,input$period)      
    }
  })
})








# ===================================== Functions ===========================================#
# Functions that can go outside server.R-> store these in different file to unclutter server.R


calculateMDM <- function(sCountries,sxRisks,syRisks,sPeriod) {
  period <- periods[sPeriod,][,"PERIOD_ID"]    
  xrIds <- subset(risknames, INDICATOR_NAME %in% sxRisks, select=INDICATOR_ID)
  xrIds <- paste(xrIds[,1],collapse=",")    
  query <- paste("SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'x' as WALL ",
                 "FROM RR_INDICATOR_VALUE"," ",
                 "WHERE FK_TIME_PERIOD = ",period," ",
                 "AND FK_INDICATOR IN (", as.character(xrIds),")",sep="")
  xRisks  <- sqlQuery(con,query)
  xBpdata <- getFiveNums(xRisks)
  xRisks <- merge(xRisks,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
  xRisks <- merge(xRisks,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]    
  xRisks <- subset(xRisks, GEO_NAME %in% sCountries)
  
  yrIds <- subset(risknames, INDICATOR_NAME %in% syRisks, select=INDICATOR_ID)
  yrIds <- paste(yrIds[,1],collapse=",")
  query <- paste("SELECT FK_INDICATOR, FK_GEO_UNIT, INDICATOR_VALUE, 'y' as WALL ",
                 "FROM RR_INDICATOR_VALUE"," ",
                 "WHERE FK_TIME_PERIOD = ",period," ",
                 "AND FK_INDICATOR IN (", as.character(yrIds),")",sep="")
  yRisks  <- sqlQuery(con,query)
  yBpdata <- getFiveNums(yRisks)
  yRisks <- merge(yRisks,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
  yRisks <- merge(yRisks,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]    
  yRisks <- subset(yRisks, GEO_NAME %in% sCountries)
  
  # calculate mdm
  u <- aggregate(xRisks[,"INDICATOR_VALUE"],by=list(xRisks[,"GEO_NAME"]),FUN=rMdm)[,2]
  v <- aggregate(yRisks[,"INDICATOR_VALUE"],by=list(yRisks[,"GEO_NAME"]),FUN=rMdm)[,2]
  mdm <- cbind(sCountries,u,v,0.1)
  mdm <- as.data.frame(mdm)
  
  results <- list(mdm = mdm, xRisks = xRisks, yRisks = yRisks, xbpd = xBpdata, ybpd = yBpdata)
  return(results)
}


# Plot Risk Room Wall using HighCharts
# Plot includes boxplots & draggableY event listener for "what-if"
# What-if calculations implemented in javascript -> cf. file "zrrlib.js"
#
riskWallPlot <- function(..., radius = 3, title = NULL, subtitle = NULL, group.na = NULL){
  rChart <- Highcharts$new()
    
  
  # Get layers
  d <- getLayer(...)
  
  data <- data.frame(
    x = d$data[[d$x]],
    y = d$data[[d$y]]
  )  
  
  # add boxplots
  bd <- d$bpd[1][[1]]
  for(i in 2:length(d$bpd)) {
    bd <- rbind(bd,d$bpd[i][[1]])
  }
  rChart$series(        
    name = "Boxplots",
    data = bd,
    type = "boxplot" 
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
        draggableY = TRUE,
        
        ## what-if bindings        
        cursor = "ns-resize",
        point = list(
          events = list(
            drop = "#! function() { LibZRR.whatif(this); } !#" )        
        ),
        stickyTracking = TRUE        
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
    rChart$yAxis(min=0, max=1, title = list(text = d$y), categories = unique(as.character(data$y)), replace = T)
  } else {
    rChart$yAxis(min=0, max=1, title = list(text = d$y), replace = T)
  }
  
  ## title
  rChart$title(text = title, replace = T)
  
  ## subtitle
  rChart$subtitle(text = subtitle, replace = T)
  
  
  ## load event -> trigger copy of data onto javascript data structures
 rChart$chart(events = list(
     load = "#! function() { LibZRR.copyWallData(this); } !#" )
 )
  
  return(rChart$copy())
}

# calculates the boxplot fivenums on the "results" dataframe,
# adds them and returns the dataframe
# results is expected as "FK_INDICATOR","FK_GEO_UNIT","INDICATOR_VALUE","WALL"
# TODO: THERE MUST BE A MORE EFFICIENT WAY TO DO THIS!! ALSO, BELOW CODE CREATES
# LOADS OF COMPLAINTS ABOUT FACTOR LEVELS....
getFiveNums <- function(results) {
  t <- tapply(results[,"INDICATOR_VALUE"],factor(results[,"FK_INDICATOR"]),fivenum)  
  return(t);                                    
}

# calculates the l2 norm of a vector v
# ===================================================
l2 <- function(v) {
  ret <- sum(v^2);
  return(ret);
}

# mdm-aggregation of a set of risks onto wall
rMdm <- function(v) {
  # for now....
  ret <- sqrt(l2(v)/length(v))
  return(ret);
}