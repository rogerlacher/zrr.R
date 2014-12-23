library(shiny)

crimChord <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}


# TODO: Initialise the riskroom-output by invoking initRiskRoom.js rather than by below HTML...
riskRoomOutput <- function (outputId) 
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
    includeHTML("www/js/graph.js"),
    tabsetPanel(         
      tabPanel("Chords",crimChord(outputId = "mainnet")),
      tabPanel("ThreeD", riskRoomOutput(outputId =  "myRiskRoom")),
      tabPanel("Table", dataTableOutput("crimtable")),
      tabPanel("Values Table", tableOutput("table"))      
    ),
    includeHTML("www/js/x3d_room.js")
  )  

))
