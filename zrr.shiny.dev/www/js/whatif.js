/*
 * LibZRR - Javascript implementation of basic Zurich Risk Room algorithms
 * 
 * Created: 27.09.2013
 * Author:  Roger Lacher, 
 *
 * Usage: call library functions like LibZRR.whatif(arg);
 */


LibZRR = window.LibZRR || {};

/* follow the module pattern */
var LibZRR = (function() {
  
  /*
   * private variables and function implementations
   */
   
  var crim;
  var xRisks;
  var yRisks;  
  
  var oppositeWallId {
    xRiskWall: 'yRiskWall',
    yRiskWall: 'xRiskWall'
  };
  
  // perform a what-if calculation
  _whatif = function(point) {
    // point.series.data returns an array of points
    jQuery.each(point.series.data, function() {
      // point has a method "update"
      if(this.id != point.id) {
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
    console.log('copying wall data....')
    xRisks = chart.series;
    console.log(xRisks)
  }  
  
  /*
   * Public library "methods" - these will survive the closure 
   * (library invocation) and ensure private vars and methods stay
   * available
   *
   */
  return {
      whatif: _whatif,      
      copyWallData: _copyWallData
  };
  
}());