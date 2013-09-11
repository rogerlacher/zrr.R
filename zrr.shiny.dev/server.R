require(rCharts)
library(shiny)

# Define server logic required to generate and plot a random distribution
shinyServer(function(input, output) {
  
  output$polyChart <- renderChart({
    names(iris) = gsub("\\.", "", names(iris))
    p1 <- rPlot(input$x, input$y, data = iris, color = "Species", 
                facet = "Species", type = 'point')
    p1$addParams(dom = 'polyChart')
    return(p1)
  })

  output$highChart <- renderChart({
    names(iris) = gsub("\\.", "", names(iris))
    p1 <- rCharts::Highcharts$new()
    sapply(1:10,function(x) {
      p1$series(data=rnorm(10), draggableY = TRUE)
    })
    p1$plotOptions(
      series = list(
        cursor = "ns-resize",
        point = list(
          events = list(
            drag = "#! function() { $('#drag').html(
                            'Dragging <b>' + this.series.name + '</b>, <b>' +
                            this.category + '</b> to <b>' + 
                            Highcharts.numberFormat(e.newY, 2) + '</b>'
                        ); } !#",
            drop = "#! function() { $('#drop').html(
                            'In <b>' + this.series.name + '</b>, <b>' +
                            this.category + '</b> was set to <b>' + 
                            Highcharts.numberFormat(this.y, 2) + '</b>'
                        ); } !#"  )
          ),
        stickyTracking = TRUE
      )
    )
    #p1 <- hPlot(input$x, input$y, data = iris, type = c("line", "bubble"), group = "Species", size=1)
    p1$addParams(dom = 'highChart')
    return(p1)
  })
  
  # Expression that generates a plot of the distribution. The expression
  # is wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should be automatically 
  #     re-executed when inputs change
  #  2) Its output type is a plot 
  #
  output$distPlot <- renderPlot({
    
    # generate an rnorm distribution and plot it
    dist <- rnorm(input$obs)
    hist(dist)
  })
})