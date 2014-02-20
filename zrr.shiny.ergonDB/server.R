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
      as.data.frame(lapply(r$mdm, format_num))
      #r$mdm;
    }        
  })     
  
  # helper function to display more digits on values table
  format_num <- function(col) {
    if (is.numeric(col))
      sprintf('%1.9f', col)
    else
      col
  }
  
  # Conditionally create output widgets for xRisks and yRisks
  # based on the xRiskCategory and yRiskCategory selections
  # ========================================================= #
  
  # countries selection menu
  output$countries <- renderUI({
    selectInput("countries", "Choose your Countries:", 
                choices = countries()[,"GEO_NAME"], multiple=TRUE,
                select = sample(countries()[,"GEO_NAME"],5))  
  })  
  
  # x Risks category selection
  output$xRiskCategory <- renderUI({
    selectInput("xRiskCategory", "Choose x risks Category:", 
                choices = riskcats(), multiple=TRUE)
                
  })
  
  # x-Risks selection menu
  output$xRisks <- renderUI({
    riskSelection <- unlist(subset(risknames(),
                                   INDICATOR_CATEGORY %in% input$xRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("xRisks", "Choose x Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })
  
  # y Risks category selection
  output$yRiskCategory <- renderUI({
    selectInput("yRiskCategory", "Choose y risks Category:", 
                choices = riskcats(), multiple=TRUE)
    
  })
  
  # y-Risks selection menu
  output$yRisks <- renderUI({
    riskSelection <- unlist(subset(risknames(),
                                   INDICATOR_CATEGORY %in% input$yRiskCategory,
                                   select=INDICATOR_NAME),use.names=FALSE)
    selectInput("yRisks", "Choose y Risk:", 
                choices = riskSelection, multiple=TRUE)      
  })
  
  # period
  output$period <- renderUI({
    periods   <-  sqlQuery(con,
                   paste("SELECT ID as PERIOD_ID, VALIDFROM as PERIOD ",
                         "FROM ", schema, ".TBL_SNAPSHOT WHERE DATASETID=",input$dataSet, sep=""));
    sliderInput("period", "Choose Time:", 
                #min=1,
                #max=length(periods[,"PERIOD"]),
                min=periods[1,1],
                max=periods[length(periods[,1]),1],
                value=periods[length(periods[,1]),1],
                step=1);
#       dateInput("period","Choose Date:", 
#                 value="2013-12-01",
#                 min="2006-01-01",
#                 max="2013-12-01",
#                 startview = "month")
  })


  # Reactive input: get countries, risks, period selection
  # Perform calculations and return results
  # ========================================================= #
  
  # query the risk values using filters countries, risks, period
  riskValues <- reactive({
    if(!is.null(input$countries) && !is.null(input$xRisks) && !is.null(input$yRisks)) {    
        calculateMDM(input$countries,input$xRisks,input$yRisks,input$period);      
    }
  })
  
  riskcats <- reactive({
    riskcats  <-  levels(factor(risknames()[,"INDICATOR_CATEGORY"]));
    riskcats;
  })  
  
  
  risknames <- reactive({
    risknames <-  sqlQuery(con,
               paste("SELECT r.ID as INDICATOR_ID, r.NAME as INDICATOR_NAME, rg.NAME as INDICATOR_CATEGORY, ",
                     "r.DESCRIPTION as INDICATOR_DESC, r.INTERPOLATION_INFO as INDICATOR_COMPOSITION, ",
                     "r.SOURCE as INDICATOR_SOURCE ",
                     "FROM ",schema, ".TBL_RISK as r JOIN ", schema, ".TBL_RISKGROUP as rg ",
                     "ON r.RISKGROUPID = rg.ID WHERE DATASETID='",input$dataSet,"'", sep=""));
    risknames;
  })

  countries <- reactive({
    countries <-  sqlQuery(con,
                           paste("SELECT ID as GEO_UNIT_ID, SHORTNAME as GEO_CODE, MIDDLENAME as GEO_NAME ", 
                                 "FROM ", schema, ".TBL_COUNTRY WHERE DATASETID=",input$dataSet, " ",
                                 "ORDER by MIDDLENAME ASC", sep=""));
    countries;
  })
  
  calculateMDM <- function(sCountries,sxRisks,syRisks,sPeriod) {
    # period <- periods[sPeriod,][,"PERIOD_ID"]    
    period <- sPeriod;
    risknames <- risknames();
    countries <- countries();
    
    # get the risk values for the selected time period
    # need to work around ODBC 2^16 length restriction
    query <- paste("SELECT LEN(FULLCLOB) FROM riskroom.TBL_RISKFORCOUNTRY WHERE SNAPSHOTID=", period)
    len   <- sqlQuery(con,query)[1,1]
    breakby <- 65530  #, no, 65535 itself won't work, as 65535 seems to be ODBC limit...
    x <- seq(0,len/breakby)
    
    clobPiece <- function(i) {
      query <- paste("SELECT SUBSTRING(FULLCLOB,",i*breakby,",",breakby,") FROM riskroom.TBL_RISKFORCOUNTRY WHERE SNAPSHOTID=", period);
      as.character(sqlQuery(con,query)[,1])}
    
    clob <- aaply(.data=x,.margins=1,.fun=clobPiece)
    clob <- paste(clob,sep="",collapse="")
    r     <- strsplit(clob,",")[[1]]
    
    FK_GEO_UNIT     <- as.integer(r[seq(1,length(r),3)])
    FK_INDICATOR    <- as.integer(r[seq(2,length(r),3)])
    INDICATOR_VALUE <- as.double(r[seq(3,length(r),3)])
    riskVals        <- data.frame(FK_GEO_UNIT, FK_INDICATOR, INDICATOR_VALUE)
    
    # values, country and risk names for x-Wall
    xrIds <- subset(risknames, INDICATOR_NAME %in% sxRisks, select=INDICATOR_ID)
    #  xrIds <- paste(xrIds[,1],collapse=",")      
    
    xRisks <- data.frame(subset(riskVals, FK_INDICATOR %in% xrIds[,1]), WALL='x')
    xBpdata <- getFiveNums(xRisks)
    xRisks <- merge(xRisks,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
    xRisks <- merge(xRisks,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]    
    xRisks <- subset(xRisks, GEO_NAME %in% sCountries)
    
    # values, country and risk names for y-Wall
    yrIds <- subset(risknames, INDICATOR_NAME %in% syRisks, select=INDICATOR_ID)
    #  yrIds <- paste(yrIds[,1],collapse=",")
    yRisks <- data.frame(subset(riskVals, FK_INDICATOR %in% yrIds[,1]), WALL='y')
    yBpdata <- getFiveNums(yRisks)
    yRisks <- merge(yRisks,countries,by.x="FK_GEO_UNIT",by.y="GEO_UNIT_ID")[,c("FK_GEO_UNIT","GEO_NAME","FK_INDICATOR","INDICATOR_VALUE","WALL")]
    yRisks <- merge(yRisks,risknames,by.x="FK_INDICATOR",by.y="INDICATOR_ID")[,c("FK_GEO_UNIT","FK_INDICATOR","GEO_NAME","INDICATOR_NAME","INDICATOR_VALUE","WALL")]    
    yRisks <- subset(yRisks, GEO_NAME %in% sCountries)
      
    # calculate mdm
    mdm <- cbind(rMDM(xRisks,yRisks),0.1)
    mdm <- as.data.frame(mdm)
        
    results <- list(mdm = mdm, xRisks = xRisks, yRisks = yRisks, xbpd = xBpdata, ybpd = yBpdata)
    return(results)
  }

  
})



# ===================================== Functions ===========================================#
# Functions that can go outside server.R-> store these in different file to unclutter server.R



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

# calculates the MDM values
# ===================================================
rMDM  <- function(xRisks, yRisks) {    
  df <- rbind(rx=xRisks[,c("INDICATOR_VALUE","GEO_NAME","WALL")],
              ry=yRisks[,c("INDICATOR_VALUE","GEO_NAME","WALL")]);
  mdm <- ddply(df,.(GEO_NAME),function(d) rMDM1Country(d));    
  
  
  # scaling factor -> how much exactly of MDM space should be used?
  # TODO: in order to be completely congruent to current online tool, rescale before narrowing down
  #       ccountries.
  sF  <- 0.8;
  v   <- mdm[,"V1"];
  mdm[,"V1"] <- ((v - min(v)) / (max(v) - min(v))) * sF + (1-sF)/2;
  v   <- mdm[,"V2"];
  mdm[,"V2"] <- ((v - min(v)) / (max(v) - min(v))) * sF + (1-sF)/2
  
  mdm;
}

rMDM1Country <- function(df) {
    
  
    rx  = subset(df,WALL=="x",select="INDICATOR_VALUE")
    ry  = subset(df,WALL=="y",select="INDICATOR_VALUE")
  
    vx2   <- nrow(rx);
    vy2   <- nrow(ry);
    vx    <- sqrt(vx2);
    vy    <- sqrt(vy2);
  
    rx2   <- rx^2;
    rx1m2 <- (rx-1)^2;
    ry2   <- ry^2;
    ry1m2 <- (ry-1)^2;
    
    ln2   <- sum(rx2) + sum(ry2);
    la2   <- sum(rx1m2) + sum(ry1m2);
    lx2   <- sum(rx1m2) + sum(ry2);
    ly2   <- sum(ry1m2) + sum(rx2);    
        
    hx    <- 0.5 * (ln2 - ly2 + vy2) / vy;
    hy    <- 0.5 * (ly2 - la2 + vx2) / vx;
    
    qx    <- 0.5 * (sqrt(ln2-hx^2) - sqrt(lx2-hx^2) + vx) / vx;
    qy    <- 0.5 * (sqrt(ln2-hy^2) - sqrt(ly2-hy^2) + vy) / vy;
            
    # Rescaling for Reporting Discrepancies, LJK 21.01.2013
    # TODO: Check with Hansruedi if this has been really implemented
   # qx    <- qx * sqrt(vx2/(vx2 + vy2));
  #  qy    <- qy * sqrt(vy2/(vx2 + vy2));
    
    ret   <- c(qx,qy);
    ret;
    
} 