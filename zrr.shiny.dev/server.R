require(stringr)
library(shiny)
library(plyr)


crimMatrix <- function(expr, env=parent.frame(), quoted=FALSE) {
  # Convert expr to a function
  func <- shiny::exprToFunction(expr, env, quoted)
  
  function() {
    value <- func()
    value
  }
}

riskRoom <- function(expr, env=parent.frame(), quoted=FALSE) {
  # Convert expr to a function
  func <- shiny::exprToFunction(expr, env, quoted)
  
  function() {
    value <- func()
    value
  }
}

shinyServer(function(input, output) {     
  
  
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
  

  # The table output
  output$table <- renderTable({
    r <- riskValues();
    if (length(r)) {
      r$mdm;
    }        
  })
  
  # The risk room
  output$rr1 <- riskRoom({
    r <- riskValues();
    if (length(r)) {
#       series = list();
#       apply(r$mdm,1,function(x) {
#         series(
#           name = as.character(x[1]),
#           data = list(as.numeric(x[2:4]))
#         )
#       })
      r;
    }   
  });
  
  # CRIM cords
  output$mainnet <- crimMatrix({
    data[input$sourceRisks];
  });
  
  
  # CRIM table
  output$crimtable = renderDataTable({
    data[input$sourceRisks];
  }, 
  options = list(bSortClasses = TRUE))  
  
  
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


# calculates the boxplot fivenums on the "results" dataframe
# results is expected as "FK_INDICATOR","FK_GEO_UNIT","INDICATOR_VALUE","WALL"
getFiveNums <- function(results) {
  t <- ddply(results[,c("FK_INDICATOR","INDICATOR_VALUE")],.(FK_INDICATOR),summarize,
             "lowerwhisker"=quantile(INDICATOR_VALUE,0.25)-1.5*(quantile(INDICATOR_VALUE,0.75)-quantile(INDICATOR_VALUE,0.25)),
             "percentile25"=quantile(INDICATOR_VALUE,0.25),
             "median"=quantile(INDICATOR_VALUE,0.5),
             "percentile75"=quantile(INDICATOR_VALUE,0.75),
             "upperwhisker"=quantile(INDICATOR_VALUE,0.75)+1.5*(quantile(INDICATOR_VALUE,0.75)-quantile(INDICATOR_VALUE,0.25)))
  return(t(t));                                    
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