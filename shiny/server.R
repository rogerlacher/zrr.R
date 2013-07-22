library(shiny)
library(googleVis)
library(calibrate)

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
      # restrict to 1 timestamp
      mdm <- subset(mdm,Date == mdm[1,"Date"])
      gvisMotionChart(mdm, idvar="Country.Name", timevar="Date", options=list(height=580, width=800))                
    }
  })
  
  output$mdm <- renderPlot({
    if (length(rMDMTable()) > 0)  {
      mdm <- rMDMTable()
      # restrict to 1 timestamp
      mdm <- subset(mdm,Date == mdm[1,"Date"])
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
    # restrict to 1 timestamp
    #gvisGeoChart(subset(r,Date == r[1,"Date"])[,c("Code",input$heatRisk)], "Code", input$heatRisk)
    gvisGeoChart(subset(r,Date == levels(r[,"Date"])[input$heatIndex])[,c("Code",input$heatRisk)], "Code", input$heatRisk)
  })     
  
  # MDM as a table
  output$table <- renderTable({
    # display MDM table
    #head(rMDMTable(),n=length(input$countries))
    rMDMTable()
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
})