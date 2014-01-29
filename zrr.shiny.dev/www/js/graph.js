<style>

.node {
  stroke: #fff;
  stroke-width: 1.5px;
}

.link {
  stroke: #999;
  stroke-opacity: .6;
}

</style>

<!--<script src="http://d3js.org/d3.v3.min.js"></script> -->
<script src="js/d3.v3.min.js"></script>
<script type="text/javascript">var networkOutputBinding = new Shiny.OutputBinding();
  $.extend(networkOutputBinding, {
    find: function(scope) {
      return $(scope).find('.shiny-network-output');
    },
    renderValue: function(el, data) {
            
      var headers = [];
      var matrix = [];
      for (risk in data) {
        headers.push(risk);
        matrix.push(data[risk]);
      }

      var width = 800;
      var height = 800;
     /* var innerRadius = Math.min(width, height) * .41;
		  var outerRadius = innerRadius * 1.1;*/
      var innerRadius = Math.min(width, height) * .25;
  	  var outerRadius = innerRadius * 1.1;      
      var fill = d3.scale.ordinal()
    		.domain(d3.range(4))
    		.range(["#000000", "#FFDD89", "#957244", "#F26223"]);      
      
      var chord = d3.layout.chord()
        	.padding(.05)
      		.sortSubgroups(d3.descending)
      		.matrix(matrix);      
      
      //remove the old graph
      var svg = d3.select(el).select("svg");      
      svg.remove();
      
      $(el).html("");
      
      //append a new one
      svg = d3.select(el).append("svg");

      svg.attr("width", width)
          .attr("height", height)
          .attr("transform", "translate(400,400)")
      	  .append("g")
      		.attr("transform", "translate(" + width/2 + "," + height/2 + ")");
    
      svg.append("g").selectAll("path")
    		.data(chord.groups)
    	  .enter().append("path")
    		.style("fill", function(d) { return fill(d.index); })
    		.style("stroke", function(d) { return fill(d.index); })
    		.attr("d", d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius))        
    		.on("mouseover", fade(.1))
    		.on("mouseout", fade(1));
    
    	var ticks = svg.append("g").selectAll("g")
    		.data(chord.groups)
    	  .enter().append("g").selectAll("g")
    		.data(groupTicks)
    	  .enter().append("g")
    		.attr("transform", function(d) {
    		  return "rotate(" + (d.angle * 180 / Math.PI - 90) + ")"
    			  + "translate(" + outerRadius + ",0)";
    		});
    
    	ticks.append("line")
    		.attr("x1", 1)
    		.attr("y1", 0)
    		.attr("x2", 5)
    		.attr("y2", 0)
    		.style("stroke", "#000");
    
    	ticks.append("text")
    		.attr("x", 8)
    		.attr("dy", ".35em")
    		.attr("transform", function(d) { return d.angle > Math.PI ? "rotate(180)translate(-16)" : null; })
    		.style("text-anchor", function(d) { return d.angle > Math.PI ? "end" : null; })
    		.text(function(d) { return d.label; });
    
    	svg.append("g")
    		.attr("class", "chord")
    	  .selectAll("path")
    		.data(chord.chords)
    	  .enter().append("path")
    		.attr("d", d3.svg.chord().radius(innerRadius))
    		.style("fill", function(d) { return fill(d.target.index); })
    		.style("opacity", 1);
    
    	// Returns an array of tick angles and labels, given a group.
    	function groupTicks(d) {
    	  var k = (d.endAngle - d.startAngle) / d.value;
    	  var index = d.index;
    	  return d3.range(0, d.value, 1000).map(function(v, i) {
    		return {
    		  angle: v * k + d.startAngle,
    		  //label: i % 5 ? null : v / 1000 + "k"
    		  label: headers[index]
    		};
    	  });
    	}
    
    	// Returns an event handler for fading a given chord group.
    	function fade(opacity) {
    	  return function(g, i) {
    		svg.selectAll(".chord path")
    			.filter(function(d) { return d.source.index != i && d.target.index != i; })
    		  .transition()
    			.style("opacity", opacity);
    	  };
    	}
    	      
    }
  });
  Shiny.outputBindings.register(networkOutputBinding, 'trestletech.networkbinding');
  
  </script>
