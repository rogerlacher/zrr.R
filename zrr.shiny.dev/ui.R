require(rCharts)
library(shiny)


includeDraggableJS <- function() {
  tagList(tags$head(
    tags$script(src = "https://rawgithub.com/highslide-software/draggable-points/master/draggable-points.js")
  ))
}

# Define UI for application that plots random distributions 
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Hello Shiny!"),
  
  # Sidebar with a slider input for number of observations
  sidebarPanel(
    sliderInput("obs", 
                "Number of observations:", 
                min = 1,
                max = 1000, 
                value = 500),
    selectInput(inputId = "x",
                label = "Choose X",
                choices = c('SepalLength', 'SepalWidth', 'PetalLength', 'PetalWidth'),
                selected = "SepalLength"),
    selectInput(inputId = "y",
                label = "Choose Y",
                choices = c('SepalLength', 'SepalWidth', 'PetalLength', 'PetalWidth'),
                selected = "SepalWidth")
  ),
  
  # Show a plot of the generated distribution
  mainPanel(
    tabsetPanel(
      tabPanel("DistPlot", plotOutput("distPlot")),
      tabPanel("rChart",showOutput("polyChart", "polycharts")),
      tabPanel("rChart",showOutput("highChart", "highcharts"))
      ),
    includeDraggableJS()
  )
))
