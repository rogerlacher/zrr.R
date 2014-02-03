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
      xRisks = data.xRisks;
      ybpd = data.ybpd;
      yRisks = data.yRisks;
      
      
      
      // buttons    
      /*
      d3.select(".menubar").remove();
      var menuBar = d3.select(el).append("div")            
          .attr("class","menubar")
          .attr("id","menubar");      
        
      menuBar.append("button").html("3D");
      menuBar.append("button").html("MDM");
      menuBar.append("button").html("x-Wall");
      menuBar.append("button").html("y-Wall");
      */
      
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
      var mSeries = [];
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
      
      renderWall(xbpd, xRisks, '#xRiskWall');
      renderWall(ybpd, yRisks, '#yRiskWall');
      
      function renderWall(bpData, riskData, wallId) {
        // add the highcharts for walls and floor
        // do something reasonable with data
        mDataSeries = [];      
        bpData[0].forEach(
          function(element,index,array){
            mData = [];
            mData[0] = parseFloat(bpData[1][index]); //lw
            mData[1] = parseFloat(bpData[2][index]); //q1
            mData[2] = parseFloat(bpData[3][index]); //med
            mData[3] = parseFloat(bpData[4][index]); //q3
            mData[4] = parseFloat(bpData[5][index]); //uw
            mDataSeries.push(mData);
          })
          
        mSeries = [];
        // add the boxplots
        mSeries.push({
            data: mDataSeries,
            name: 'Boxplots',
            type: 'boxplot'          
          });
          
        var mCategories = [];
        mData = {};
        riskData.GEO_NAME.forEach(
          function(country,index,array){
            // axis categories
            riskname = riskData.INDICATOR_NAME[index];          
            if(mCategories.indexOf(riskname) <0) {
              mCategories.push(riskname);            
            }                  
            
            if(!mData[country]) {
              mData[country] = []; 
              
            }
            mData[country].push(parseFloat(riskData.INDICATOR_VALUE[index]));
        })  
        for(c in mData){
          mSeries.push({
            name: c,
            data: mData[c],
            type: 'line',
            draggableY: true,
            dragMinY: 0,
            dragMaxY: 1
          });
        }
          
        // Risk Walls
        $(wallId).highcharts({      
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
          },
          series: mSeries
        }) 
      }
      
       // some pseudo-what-if behavior
      function whatif(point) { 
        point.series.data.forEach(
          function(element,index,array){
          // point has a method "update"      
          if(element.name != point.name) {    // point.id does not work...    
            element.update(element.y + (0.5-Math.random())/10);                  
            }       
        });
      }
      
    }
  });
  Shiny.outputBindings.register(riskroomOutputBinding, 'zurich.riskroombinding');
  
  </script>
