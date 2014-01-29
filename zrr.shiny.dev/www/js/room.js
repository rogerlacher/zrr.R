<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<link rel="stylesheet" type="text/css" href="../css/zrr.css"/>
<script src="js/highcharts.js"></script>
<script src="js/highcharts-more.js"></script>
<script src="js/draggable-points.js"></script>
<script type="text/javascript">var riskroomOutputBinding = new Shiny.OutputBinding();
  $.extend(riskroomOutputBinding, {
    find: function(scope) {
      return $(scope).find('.riskroom-output');
    },
    renderValue: function(el, data) {
      
      mdm = data.mdm;
      xbpd = data.xbpd;
      
      // buttons
      d3.select(el).append("button").html("3D");
      d3.select(el).append("button").html("MDM");
      d3.select(el).append("button").html("x-Wall");
      d3.select(el).append("button").html("y-Wall");
      //  create the container & room
     var riskroom = d3.select(el).append("div")
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
      var mDataSeries = [];
      mdm.sCountries.forEach(
        function(element,index,array){
          mElement = {};
          mElement["name"] = element;      
          mPoint = {};
          mPoint["x"] = parseFloat(mdm.u[index]);
          mPoint["y"] = parseFloat(mdm.v[index]);
          mData = [];
          mData.push(mPoint);
          mElement["data"] = mData;
          mDataSeries.push(mElement);
        })
            
      // MDM            
      $('#mdmPlot').highcharts({      
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
        },
        series: mDataSeries
      })    
      
      // add the highcharts for walls and floor
      // do something reasonable with data
      mDataSeries = [];      
      xbpd.forEach(
        function(element,index,array){
          mData = [];
          mData[0] = parseFloat(xbpd[1][index]); //lw
          mData[1] = parseFloat(xbpd[2][index]); //q1
          mData[2] = parseFloat(xbpd[3][index]); //med
          mData[3] = parseFloat(xbpd[4][index]); //q3
          mData[4] = parseFloat(xbpd[5][index]); //uw
          mDataSeries.push(mData);
        })
        
      mSeries = [];
      // add the boxplots
      mSeries.push({
          data: mDataSeries,
          name: 'Boxplots',
          type: 'boxplot'          
        });
        
      mCategories = [];
      data.xRisks.GEO_NAME.forEach(
        function(element,index,array){
          if(!mCountries[element]) {
            mCategories.push(element);
            mData = [];            
          }
          mData.push(parseFloat(data.xRisks.INDICATOR_VALUE[index]));        
      })      
        
      // Risk Walls
      $('#xRiskWall').highcharts({      
        chart: {      
          zoomType: 'xy'
        },
        title:{
          text: 'x-Risk Wall'
        },        
        xAxis: {
          categories: mCategories,
	        title: {
	            text: 'Risk Key.'
	        }
	      },
        series: mSeries
      }) 
        /*
    plyr::ddply(data, .(group), function(x) {
      g <- unique(x$group)
      i <- which(groups == g)
      
      x$group <- NULL  # fix        
        rChart$series(
        data = toJSONArray2(x, json = F, names = F),
        name = g,
        type = types[[i]],
        marker = list(radius = radius),
        draggableY = TRUE,
        
        ## what-if bindings        
        cursor = "ns-resize",
        point = list(
          events = list(
            drop = "#! function() { LibZRR.whatif(this); } !#" )        
        ),
        stickyTracking = TRUE        
      )       
      */

      $('#yRiskWall').highcharts({      
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
        },
        series: mDataSeries
      })  

      // add what-if behavior
      
 
    }
  });
  Shiny.outputBindings.register(riskroomOutputBinding, 'zurich.riskroombinding');
  
  </script>
