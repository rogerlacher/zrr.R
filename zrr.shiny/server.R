
# server logic for ZRR
shinyServer(function(input, output) {
    
  
  #calculate the rMDM from the inputs
  rMDMTable <- reactive({
    if(length(input$countries)>0 && length(input$xRisks)>0  && length(input$yRisks)> 0) {
      # subset dataset by selected input countries
      #r1 <- subset(r,Country.Name %in% input$countries)
      # restrict to selected timestamp
      #r1 <- subset(r1,Date == levels(r[,"Date"])[input$timeIndex])      
      # call the rMDM algorithm    
      #rMDM_Motion(r1,match(input$xRisks, colnames(r)), match(input$yRisks, colnames(r)))
      
      # TODO: This is all very inefficient, as the same things are calculated over and over 
      #       again:
      #      -> match(risks|countries)   -> only used here to get positions
      #                                  -> positions are then again used to look up values
      #                                     such as risk %in% risklevels[p] in function rMDMm
      #              -> simplify the expression: "risk %in% risklevels[match(input$xRisks,risklevels)]"
      #rMDMm_Motion(rm,input$timeIndex,match(input$xRisks,risklevels),
      #             match(input$yRisks,risklevels),match(input$countries,countrylevels))
      rMDMmS(rm,input$timeIndex,input$xRisks,input$yRisks,input$countries)
     }
  })
  
  # Risk Room Floor
  output$mdm <- renderPlot({
    if (length(rMDMTable()) > 0)  {
      mdm <- rMDMTable();
      p <- ggplot(data=mdm,aes(x=qx,y=qy)) + labs(title="Risk Room floor") + xlab("x-Risks") + ylab("y-Risks") + xlim(0,1) + ylim(0,1);
      p <- p + geom_point(aes(size=abs(rnorm(length(Country.Name))),color=factor(Country.Name)));
      p <- p + geom_text(aes(label=Country.Name), size=3);
      print(p);
    }
  })  
  
  # Risk Walls
  output$walls <- renderPlot({
    # restrict molten dataset to selected timestamp
    rmx <- subset(rm,Date == levels(rm[,"Date"])[input$timeIndex] & risk %in% input$xRisks)
    rmxc <- subset(rmx,Country.Name %in% input$countries)
    rmy = subset(rm,Date == levels(rm[,"Date"])[input$timeIndex] & risk %in% input$yRisks)
    rmyc <- subset(rmy,Country.Name %in% input$countries)
    
    xRisks <- ggplot() + geom_boxplot(data=rmx,aes(x=risk,y=value)) + xlab("x-Risks") + ylab("Value")
    xRisks <- xRisks + geom_line(data=rmxc,aes(x=risk,y=value,group=Country.Name,color=Country.Name))
    xRisks <- xRisks + geom_point(data=rmxc,aes(x=risk,y=value,group=Country.Name,color=Country.Name))         

    yRisks <- ggplot() + geom_boxplot(data=rmy,aes(x=risk,y=value)) + xlab("y-Risks") + ylab("Value")
    yRisks <- yRisks + geom_line(data=rmyc,aes(x=risk,y=value,group=Country.Name,color=Country.Name))
    yRisks <- yRisks + geom_point(data=rmyc,aes(x=risk,y=value,group=Country.Name,color=Country.Name))         
    
    stackedplot <- grid.arrange(xRisks, yRisks, nrow=2)
    print(stackedplot)
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