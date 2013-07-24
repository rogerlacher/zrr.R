library(shiny)
library(googleVis)
library(calibrate)
library(ggplot2)

# server logic for ZRR
shinyServer(function(input, output) {
    
  
  #calculate the rMDM from the inputs
  rMDMTable <- reactive({    
    if(length(input$countries)>0 && length(input$xRisks)>0  && length(input$yRisks)> 0) {
      # subset dataset by selected input countries
      #c1 <- subset(countries,Name %in% input$countries)["ISO.3166.1"]
      #r1 <- subset(r,ISO.3166.1 %in% c1[,1])
      r1 <- subset(r,Country.Name %in% input$countries)
      # call the rMDM algorithm    
      rMDM_Motion(r1,match(input$xRisks, colnames(r)), match(input$yRisks, colnames(r)))      
     }
  })
  
  # MDM
  output$motion <- renderGvis({
    if (length(rMDMTable()) > 0) {
      # display MDM Scatter Plot
      mdm <- rMDMTable()
      # restrict to selected timestamp
      #mdm <- subset(mdm, Date == levels(r[,"Date"])[input$heatIndex])
      gvisMotionChart(mdm, idvar="Country.Name", timevar="Date", options=list(height=580, width=800))                
    }
  })
  
  output$mdm <- renderPlot({
    if (length(rMDMTable()) > 0)  {
      mdm <- rMDMTable()
      # restrict to selected timestamp
      mdm <- subset(mdm,Date == levels(r[,"Date"])[input$heatIndex])
      x <- mdm[,"qx"];
      y <- mdm[,"qy"];       
      plot(x,y, main="ZRR rMDM Plot",asp=1, xlim=c(0,1), ylim=c(0,1), 
           xlab="xRisks", ylab="yRisks");
      textxy(x,y,mdm[,"Country.Name"]);
    }
  })
  
  # Risk Walls
  output$walls <- renderPlot({
    # display Risk Walls
  })
  
  # Choropleth map for selected risk
  output$choropleth <- renderGvis({
    # display choropleth map of selected risk
    # restrict to selected timestamp
    gvisGeoChart(subset(r,Date == levels(r[,"Date"])[input$heatIndex])[,c("Code",input$heatRisk)], "Code", input$heatRisk)
  })     
  
  # Country Ratings
  output$spratings <- renderGvis({
    gvisGeoChart(x, "Country", "Ranking",
                 options=list(gvis.editor="S&P",
                              projection="kavrayskiy-vii",
                              colorAxis="{colors:['#91BFDB', '#FC8D59']}"));
  })
  
  # Recent Earthquakes
  output$quakes <- renderGvis({
    gvisGeoChart(eq, "loc", "Depth", "Magnitude",
                 options=list(displayMode="Markers", 
                              colorAxis="{colors:['purple', 'red', 'orange', 'grey']}",
                              backgroundColor="lightblue"), chartid="EQ");
  })

  # World Bank Development Indicators
  output$wdi <- renderPlot({
    if(length(input$countries)>0) {
      countryCodes <- subset(countries,Country.Name %in% input$countries, select="Code")
      inds <- WDIsearch(string = input$wdiIndicator)
      theIndicator <- inds[inds[,"name"] == input$wdiIndicator,"indicator"]
      DF <- WDI(country=countryCodes,indicator=theIndicator, start=1990, end=2013)
      ggplot(DF, mapping=aes(year, theIndicator, color=country))+geom_line(stat="identity")+theme_bw()+xlab("Year")+labs(title=input$wdiIndicator)+ylab("")      
    }
  })
  

  # MDM as a table
  output$table <- renderTable({
    # display MDM table
    if (length(rMDMTable()) > 0) {
      subset(rMDMTable(),Date == levels(r[,"Date"])[input$heatIndex])[,-2]
    }        
  })     
  
  # conditionally create output widgets for xRisks and yRisks
  # based on the xRiskCategory and yRiskCategory selections
  output$xRisks <- renderUI({
    riskSelection <- unlist(rh[[input$xRiskCategory]],use.names=FALSE)
    selectInput("xRisks", "Choose x Risk:", 
                  choices = riskSelection, multiple=TRUE)      
  })
  
  output$yRisks<- renderUI({
    riskSelection <- unlist(rh[[input$yRiskCategory]],use.names=FALSE)
    selectInput("yRisks", "Choose y Risk:", 
                  choices = riskSelection, multiple=TRUE)      
  })
  
  output$wdiIndicator <- renderUI({
    wdiIndicators <- WDIsearch(string = input$wdiSearch)[,"name"]
    selectInput("wdiIndicator", "Choose Indicator:", 
                choices = wdiIndicators, multiple=FALSE)      
  })
})