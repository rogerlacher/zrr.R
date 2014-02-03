library(shiny)

crimChord <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}

riskRoom3D <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"riskroom-output\"></div>", sep=""))
}

shinyUI(pageWithSidebar(    
  
  # Application title
  #headerPanel("Risk Room", "Risk Room"),
  headerPanel("","Risk Room"),
  
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
    
    tag("div",list(id="drag", class="drag")),

    HTML("<hr />"),
    
    selectInput(inputId = "sourceRisks",
                label="Select the source risks:",
                choices = risks,
                selected = sample(risks,round(length(risks)/3)),
                multiple = TRUE)    
  ),
  
  # Show a plot of the generated distribution
  mainPanel(
    includeHTML("www/js/room.js"),
    includeHTML("www/js/graph.js"),
    tabsetPanel(         
      tabPanel("Chords",crimChord(outputId = "mainnet")),
      tabPanel("Table", dataTableOutput("crimtable")),
      tabPanel("Values Table", tableOutput("table")),
      tabPanel("ThreeD", riskRoom3D(outputId =  "rr1"))     
    )
  )  

))
