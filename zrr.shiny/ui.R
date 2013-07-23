library(shiny)

# ZRR prototype
shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Zurich Risk Room"),
  
  # Sidebar with controls including 1 control that gets
  # created by uiOutput
  sidebarPanel(
    selectInput("countries", "Choose your Countries:", 
                choices = countries[,"Country.Name"], multiple=TRUE),
    
    selectInput("xRiskCategory", "Choose x risks Category:", 
                choices = rcats),
    uiOutput("xRisks"),
    
    selectInput("yRiskCategory", "Choose y risks Category:", 
                choices = rcats),
    uiOutput("yRisks"),
    
    sliderInput("heatIndex", "Choose Time:", 
                min=1,
                max=length(levels(r[,"Date"])),
                value=length(levels(r[,"Date"])),
                step=1)
    
  ),
  
  # Display Risk Room elements as tabset
  mainPanel(
    tabsetPanel(
      tabPanel("MDM MotionChart", htmlOutput("motion")), 
      tabPanel("MDM", plotOutput("mdm")),
      tabPanel("Risk Walls", plotOutput("walls")), 
      tabPanel("Choropleth",                
               selectInput("heatRisk", "Choose Risk to display:", 
                           choices = rnames),              
               htmlOutput("choropleth")),
      tabPanel("S&P Country Ratings", htmlOutput("spratings")),
      tabPanel("Recent Quakes", htmlOutput("quakes")),
      tabPanel("Table", tableOutput("table"))
      )
  )
))