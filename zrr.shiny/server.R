library(shiny)
library(googleVis)
library(calibrate)
#library(WDI)
library(ggplot2)
library(reshape2)

# server logic for ZRR
shinyServer(function(input, output) {
    
  
  #calculate the rMDM from the inputs
  rMDMTable <- reactive({    
    if(length(input$countries)>0 && length(input$xRisks)>0  && length(input$yRisks)> 0) {
      # subset dataset by selected input countries
      r1 <- subset(r,Country.Name %in% input$countries)
      # restrict to selected timestamp
      r1 <- subset(r1,Date == levels(r[,"Date"])[input$timeIndex])      
      # call the rMDM algorithm    
      rMDM_Motion(r1,match(input$xRisks, colnames(r)), match(input$yRisks, colnames(r)))      
     }
  })
  
  output$mdm <- renderPlot({
    if (length(rMDMTable()) > 0)  {
      mdm <- rMDMTable()
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
    r1 <- subset(r,Country.Name %in% input$countries)
    # restrict to selected timestamp
    r1 <- subset(r1,Date == levels(r[,"Date"])[input$timeIndex])
    xRisks <- t(r1[,input$xRisks])            
    #yRisks <- t(r1[,input$yRisks])
    
    Molten <- melt(xRisks)
    # TODO: need to see how to get back Risk and Country labels....
    Molten[,1]<-as.numeric(as.factor(Molten[,1]))
    Molten[,2]<-as.factor(Molten[,2])
    print(ggplot(Molten, aes(x = Var1, y = value, colour = Var2)) + geom_line())
  })
  
  # Choropleth map for selected risk
  output$choropleth <- renderGvis({
    # display choropleth map of selected risk
    # restrict to selected timestamp
    gvisGeoChart(subset(r,Date == levels(r[,"Date"])[input$timeIndex])[,c("Code",input$heatRisk)], "Code", input$heatRisk)    
  })     
  
  # MDM as a table
  output$table <- renderTable({
    # display MDM table
    if (length(rMDMTable()) > 0) {
      rMDMTable()[,-2]
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
  
  if(FALSE) {
    
  
    # Google Motion MDM
    output$motion <- renderGvis({
      if (length(rMDMTable()) > 0) {
        # display MDM Scatter Plot
        mdm <- rMDMTable()
        # restrict to selected timestamp
        #mdm <- subset(mdm, Date == levels(r[,"Date"])[input$timeIndex])
        gvisMotionChart(mdm, idvar="Country.Name", timevar="Date", options=list(height=580, width=800))                
      }
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
        DF <- WDI(country=countryCodes$Code,indicator=theIndicator, start=1990, end=2013)
       # ggplot(DF, mapping=aes(year, as.symbol(theIndicator), color=country))+geom_line(stat="identity")+theme_bw()+xlab("Year")+labs(title=input$wdiIndicator)+ylab("")      
        ggplot(DF, mapping=aes(year, 3, color=country))+geom_line(stat="identity")+theme_bw()+xlab("Year")+labs(title=input$wdiIndicator)+ylab("")      
      }
    })

    output$wdiIndicator <- renderUI({
      wdiIndicators <- WDIsearch(string = input$wdiSearch)[,"name"]
      selectInput("wdiIndicator", "Choose Indicator:", 
                  choices = wdiIndicators, multiple=FALSE)      
    })
    
  }    

})