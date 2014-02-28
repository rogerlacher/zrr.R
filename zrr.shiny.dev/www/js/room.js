<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
<link rel="stylesheet" type="text/css" href="../css/zrr.css"/>
<script src="js/d3.v3.min.js"></script>
<script src="js/highcharts.js"></script>
<script src="js/highcharts-more.js"></script>
<script src="js/draggable-points.js"></script>
<script src="js/initRiskRoom.js"></script>
<script type="text/javascript">
var riskroomOutputBinding = new Shiny.OutputBinding();

$.extend(riskroomOutputBinding, {
  find: function(scope) {
    return $(scope).find('.riskroom-output');
  },
  renderValue: function(el, data) {
    
    // only update if there's data to update...
    
    if (data.mdm != null) {
    
      mdm = data.mdm;
      xbpd = data.xbpd;
      xRisks = data.xRisks;
      ybpd = data.ybpd;
      yRisks = data.yRisks;
      
      
      // get a handle to the MDM plot
      var mdmPlot = $('#mdmPlot').highcharts();
      // make sure all series get removed
      while(mdmPlot.series.length > 0)
            mdmPlot.series[0].remove(true);
      
      
      var mSeries = [];
      //var mDataSeries = [];
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
          //mDataSeries.push(mElement);
          mdmPlot.addSeries(mElement, true);
        })
      
      function renderWall(bpData, riskData, wallId) {
        // add the highcharts for walls and floor
        // do something reasonable with data
        
        var wall = $('#' + wallId).highcharts();
        // remove old series
        while(wall.series.length > 0)
            wall.series[0].remove(true);
              
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
          
        //mSeries = [];
        // add the boxplots
        //mSeries.push({
        wall.addSeries({
            data: mDataSeries,
            name: 'Boxplots',
            type: 'boxplot'          
          }, true);
          
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
        
        wall.xAxis[0].setCategories(null,true);
        wall.xAxis[0].setCategories(mCategories,true);
          
        
        for(c in mData){
          //mSeries.push({
          wall.addSeries({
            name: c,
            data: mData[c],
            type: 'line',
            draggableY: true,
            dragMinY: 0,
            dragMaxY: 1
          }, true);
        }
          
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
    
          
      renderWall(xbpd, xRisks, 'xRiskWall');
      renderWall(ybpd, yRisks, 'yRiskWall');
    
    } //  if (data.mdm != null) 
    
  }
});

Shiny.outputBindings.register(riskroomOutputBinding, 'zurich.riskroombinding');

</script>
