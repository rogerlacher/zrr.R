/*
 * LibZRR - Javascript implementation of basic Zurich Risk Room algorithms
 * 
 * Created: 27.09.2013
 * Author:  Roger Lacher, 
 *
 * Usage: call library functions like LibZRR.whatif(arg);
 */


LibZRR = window.LibZRR || {};

LibZRR = function() {
  
  /*
   * private variables and function implementations
   */
   
  var crim;
  var xRisks;
  var yRisks;  
  
  // perform a what-if calculation
  _whatif = function(chart) {
    jQuery.each(chart.series.data, function() {
      this.y = this.y + (0.5-Math.random())/10;
      chart.series.redraw();
    });
    
    // change the background color of the MDM plot for a test
    jQuery("#mdmPlot").highcharts({
        chart: { 
          backgroundColor: '#FCCCC5'          
        }
    })
  };
  
  // copy this risk wall data onto corresponding javascript datastructure
  _copyWallData = function(chart) {
    alert('blabla');
    xRisks = chart.series;
  };  
  
  
  /*
   * Public library "methods" - these will survive the closure 
   * (library invocation) and ensure private vars and methods stay
   * available
   *
   */
  return {
      "whatif": _whatif, 
      "copyWallData": _copyWallData;
  }
  
}();