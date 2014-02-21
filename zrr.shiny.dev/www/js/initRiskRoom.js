// Initialization of the RiskRoom Output Binding / Widget
// this only needs to be done once.

// TODO: need to find a way to parametrize the ouput-binding-selector ('.riskroom-output')


$(document).ready(function() {


    var rootElement = d3.select('.riskroom-output');
    // buttons    
        
    var menuBar = rootElement.append("div")            
        .attr("class","menubar")
        .attr("id","menubar");      
      
    menuBar.append("button").html("3D");
    menuBar.append("button").html("MDM");
    menuBar.append("button").html("x-Wall");
    menuBar.append("button").html("y-Wall");
    

   //  create the container & room
   //var riskroom = d3.select(el).append("div")
   var riskroom = rootElement.append("div")
        .attr("class","cube")
        .attr("id","riskroom");        
    // Floor
    riskroom.append("div")
        .attr("class","bottom-3d")
        .attr("id","mdmPane")
      .append("div")
        .attr("id","mdmPlot")
        .attr("class","shiny-html-output");
    // x-Wall          
    riskroom.append("div")
        .attr("class","back-3d")
        .attr("id","xRiskPane")
      .append("div")
        .attr("id","xRiskWall")
        .attr("class","shiny-html-output");
    // y-Wall          
    riskroom.append("div")
        .attr("class","left-3d")
        .attr("id","yRiskPane")
      .append("div")
        .attr("id","yRiskWall")
        .attr("class","shiny-html-output");         
 

    
    // TODO: completely change the data structures passed to Javascript /
    //       toJSON to simplify handling!!!
    //       quite probably we need MDM calcs in JavaScript anyway....
    //
    // for now...
    
    // add the highcharts for walls and floor    
    // do something reasonable with data
    
        
    // (re)draw the MDM            
    $('#mdmPlot').highcharts(
      {      
      chart: {      
        type: 'bubble',
        zoomType: 'xy'
      },
      title:{
        text: 'Minimal Distortion Map'
      },
      xAxis: {
        min: 0,
        max: 1
      },
      yAxis: {
        min: 0,
        max: 1
      }
      // series: mDataSeries  
    });  
    
    
    initWall('xRiskWall');
    initWall('yRiskWall');
    
    // Risk Walls
    function initWall(wallId) {
    
      $('#' + wallId).highcharts({      
        chart: {      
          zoomType: 'xy'
        },
        title:{
          text: 'x-Risk Wall'
        },        
        xAxis: {
          categories: [],
          title: {
              text: 'Risk Key.'
          }
	      },
        plotOptions: {
          series: {
            stickyTracking: true,
            cursor: 'ns-resize',
            marker: {
              radius: 3
            },
            point: {
              events: {
                drop: function() {
                    console.writeln("whatif-drop");
                    whatif(this);
                }
              }
            }
          }            
        }
        //series: mSeries
      });      
    }

});