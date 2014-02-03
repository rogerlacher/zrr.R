<link rel="stylesheet" type="text/css" href="../css/zrr.css"/>
<script src="js/highcharts.js"></script>
<script src="js/highcharts-more.js"></script>
<script src="js/draggable-points.js"></script>
<script type="text/javascript">
/*
 * LibZRR - Javascript implementation of basic Zurich Risk Room algorithms
 * 
 * Created: 27.09.2013
 * Author:  Roger Lacher, 
 *
 * Usage: call library functions like LibZRR.whatif(arg);
 */


//LibZRR = window.LibZRR || {};
/* follow the module pattern */
var LibZRR = (function() {
  
  /*
   * private variables and function implementations
   */
   
  var crim;
  var xRisks;
  var yRisks;  
  
  var oppositeWallId = {
    xRiskWall: 'yRiskWall',
    yRiskWall: 'xRiskWall'
  };
  
  // perform a what-if calculation
  _whatif = function(point) {
    // point.series.data returns an array of points
    jQuery.each(point.series.data, function() {
      // point has a method "update"      
      if(this.name != point.name) {    // point.id does not work...    
        this.update(this.y + (0.5-Math.random())/10);
      }
    });    
    /*
    // todo: update floor & other wall
    jQuery().highcharts({
      chart: {
        backgroundColor: '#FCCCC5'
      }
    });
    */
    
    // change the background color of the MDM plot for a test
/*    jQuery("#mdmPlot").highcharts({
        chart: { 
          backgroundColor: '#FCCCC5'          
        }
    }) */
  }
  
  // copy this risk wall data onto corresponding javascript datastructure
  _copyWallData = function(chart) {
    xRisks = chart.series;
    console.log(xRisks)
  }  
  
  
  /* switch between views */
  _view3D = function() {
    $("#mdmPane").attr("class","bottom-3d");
    $("#xRiskPane").attr("class","back-3d");
    $("#yRiskPane").attr("class","left-3d");    
  }  
  _viewMDM = function() {
    _view3D();
    $("#mdmPane").removeClass("bottom-3d");
  }
  _viewxWall = function() {
    _view3D();
    $("#xRiskPane").removeClass("back-3d");
  }
  _viewyWall = function() {
    _view3D();
    $("#yRiskPane").removeClass("left-3d");
  }
  // having fun with 3d transitions
  _shuffle = function() {
    var oldstyles = {};
    $('div').each(function() {      
      oldstyles[$(this)] = $(this).css("style");      
      $(this).css("transform","translate3d(12,42,32) rotate3d(23deg,39deg,30deg)");
    })    
    $('div').each(function(){
      $(this).css("style", oldstyles[$(this)]);
    })
  }
  
  /*
   * Public library "methods" - these will survive the closure 
   * (library invocation) and ensure private vars and methods stay
   * available
   *
   */
  return {
      whatif: _whatif,      
      copyWallData: _copyWallData,
      view3D: _view3D,
      viewMDM: _viewMDM,      
      viewxWall: _viewxWall,
      viewyWall: _viewyWall,
      shuffle: _shuffle
  };
  
}());
</script>