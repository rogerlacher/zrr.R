require(rCharts)
library(shiny)


includeDraggableJS <- function() {
  tagList(tags$head(
    #tags$script(src = "https://rawgithub.com/highslide-software/draggable-points/master/draggable-points.js"),
    tags$script(src = "js/draggable-points.js"),
    #tags$script(src = "js/drag.js"),
    tags$script(src = "js/whatif.js")
  ))
}


# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Zurich Risk Room Prototype"),
  
  # Sidebar with a slider input for number of observations
  sidebarPanel(
    selectInput("countries", "Choose your Countries:", 
                choices = countries[,"GEO_NAME"], multiple=TRUE,
                select = sample(countries[,"GEO_NAME"],5)),
    
    selectInput("xRiskCategory", "Choose x risks Category:", 
                choices = riskcats),
    uiOutput("xRisks"),
    
    selectInput("yRiskCategory", "Choose y risks Category:", 
                choices = riskcats, selected = riskcats[3]),
    uiOutput("yRisks"),
    
    sliderInput("period", "Choose Time:", 
                min=1,
                max=length(periods[,"PERIOD"]),
                value=1,
                step=1),
    
    tag("div",list(id="drag", class="drag"))
  ),
  
  # Show a plot of the generated distribution
  mainPanel(
    tabsetPanel(
      tabPanel("MDM Plot", showOutput("mdmPlot","Highcharts")),
      tabPanel("x Risk Walls",showOutput("xRiskWall", "Highcharts")),
      tabPanel("y Risk Walls",showOutput("yRiskWall", "Highcharts")),
      tabPanel("Values Table", tableOutput("table"))
      ),
    includeDraggableJS()
  )
))