require(rCharts)
library(shiny)

crimChord <- function (outputId) 
{
  HTML(paste("<div id=\"", outputId, "\" class=\"shiny-network-output\"><svg /></div>", sep=""))
}


threeDeeView <- function() {
  HTML(paste("<button onclick=\"LibZRR.view3D();\">3D</button>",
            "<button onclick=\"LibZRR.viewMDM();\">MDM</button>",
            "<button onclick=\"LibZRR.viewxWall();\">x-Wall</button>",
            "<button onclick=\"LibZRR.viewyWall();\">y-Wall</button>",
            "<div class=\"container\">",
              "<div id=\"riskroom\" class=\"cube\">",
                "<div id=\"mdmPane\" class=\"bottom-3d\">",
                  "<div id=\"mdmPlot\" class=\"shiny-html-output\"></div>",
                "</div>",
                "<div id=\"xRiskPane\" class=\"back-3d\">",
                  "<div id=\"xRiskWall\" class=\"shiny-html-output\"></div>",
                "</div>",
                "<div id=\"yRiskPane\" class=\"left-3d\">",
                  "<div id=\"yRiskWall\" class=\"shiny-html-output\"></div",
                "</div>",
              "</div>",          
            "</div>", sep=""))
}

includeDraggableJS <- function() {
  tagList(tags$head(
    #tags$script(src = "https://rawgithub.com/highslide-software/draggable-points/master/draggable-points.js"),
    tags$script(src = "js/draggable-points.js"),
    #tags$script(src = "js/drag.js"),
    tags$script(src = "js/zrrlib.js")
  ))
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
    includeHTML("www/js/zrrlib.js"),
    includeHTML("www/js/graph.js"),
    tabsetPanel(
      #tabPanel("MDM Plot", showOutput("mdmPlot","Highcharts")),
      #tabPanel("x Risk Walls",showOutput("xRiskWall", "Highcharts")),
      #tabPanel("y Risk Walls",showOutput("yRiskWall", "Highcharts")),         
      tabPanel("Chords",crimChord(outputId = "mainnet")),
      tabPanel("Table", dataTableOutput("crimtable")),      
      tabPanel("Values Table", tableOutput("table")),
      tabPanel("ThreeD", threeDeeView())     
    ),
    includeDraggableJS()
  )  

))
