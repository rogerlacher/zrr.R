function whatif(chart) {
  jQuery.each(chart.series.data, function() {
    this.y = this.y + (0.5-Math.random())/10;
  });
  // or:
  //chart.series.data = chart.series.data.reverse();
  // or:
  // ...... replace by what-if algorithm  
  chart.series.redraw();
}