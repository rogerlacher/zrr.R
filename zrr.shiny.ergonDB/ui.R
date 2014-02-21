require(rCharts)
library(shiny)


includeResources <- function() {
  tagList(tags$head(
    tags$link(rel='stylesheet', type='text/css', href='css/zrr-styles.css'),
    tags$script(src = "js/draggable-points.js"),
    tags$script(src = "js/zrrlib.js")
  ))
}



# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
    
  # Application title
  headerPanel("Zurich Risk Room","Zurich Risk Room"),
  
  # Sidebar with a slider input for number of observations
  sidebarPanel(
    selectInput("dataSet", "Choose your Dataset:", 
                choices = dataSets, multiple=FALSE),
    
    uiOutput("countries"),
    
    uiOutput("xRiskCategory"),
    uiOutput("xRisks"),
    
    uiOutput("yRiskCategory"),
    uiOutput("yRisks"),
  
    selectInput("algorithm","Select calculation algorithm",
                c("rMDM" = "rMDM",
                  "euclid" = "euclid",
                  "mean" = "mean",
                  "median" = "median")),
    
    checkboxGroupInput("options","Select calculation options",
                       c("Laurence-Trafo" = "lt",
                            "With Scaling" = "sc"),
                       selected = "With Scaling")
    
    # uiOutput("period"),
    
    #tag("div",list(id="drag", class="drag"))
  ),
  
  # Show a plot of the generated distribution  
  mainPanel(
    tabsetPanel(
      tabPanel("MDM Plot", showOutput("mdmPlot","Highcharts")),
      tabPanel("x Risk Walls",showOutput("xRiskWall", "Highcharts")),
      tabPanel("y Risk Walls",showOutput("yRiskWall", "Highcharts")),         
      tabPanel("Values Table", tableOutput("table")),
      tabPanel("Data Explorer", htmlOutput("Hello Shiny"))
      ),
    uiOutput("period"),
    includeResources()
  )
))