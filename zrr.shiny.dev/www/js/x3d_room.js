<link rel="stylesheet" type="text/css" href="../css/zrr.css"/>
<link rel="stylesheet" type="text/css" href="../css/x3dom.css"/>
<script src="js/d3.v3.min.js"></script>
<script type="text/javascript">
var riskroomOutputBinding = new Shiny.OutputBinding();

$.extend(riskroomOutputBinding, {
  find: function(scope) {
    return $(scope).find('.riskroom-output');
  },
  renderValue: function(el, data) {
    
    // only update if there's data to update...
    
    if (data.mdm != null) {


          var MDM_EDGE = 10;    // edge length of mdm
          var WALL_HEIGHT = 8;  // height of risk room walls

          // TODO: prepare a better JSON data format to get rid of below data trafos
/* ================= GET RID OF THESE BY USING BETTER DATA MODEL !! ===============================*/          
          mdm = [];
          data.mdm.sCountries.forEach(function(element,index,array) {
            var mPoint = {};
            mPoint['country'] = element;
            mPoint['u'] = parseFloat(data.mdm.u[index]);
            mPoint['v'] = parseFloat(data.mdm.v[index]);
            mdm.push(mPoint);
          });

          xRisks = data.xRisks;
          yRisks = data.yRisks;

          var xBoxPlotData = [];
          data.xbpd[0].forEach(function(element,index,array) {
            var mBplot = {};
            mBplot['lw'] = data.xbpd[1][index];
            mBplot['lq'] = data.xbpd[2][index];
            mBplot['md'] = data.xbpd[3][index];
            mBplot['uq'] = data.xbpd[4][index];
            mBplot['uw'] = data.xbpd[5][index];
            xBoxPlotData.push(mBplot);
          });

          var yBoxPlotData = [];
          data.ybpd[0].forEach(function(element,index,array) {
            var mBplot = {};
            mBplot['lw'] = data.ybpd[1][index];
            mBplot['lq'] = data.ybpd[2][index];
            mBplot['md'] = data.ybpd[3][index];
            mBplot['uq'] = data.ybpd[4][index];
            mBplot['uw'] = data.ybpd[5][index];
            yBoxPlotData.push(mBplot);
          });

/* ================= GET RID OF THESE BY USING BETTER DATA MODEL !! ===============================*/          
/* ================= MUCH CLEANER X3D: separate shapes from transformations by saying stuff like:

     <Shape DEF='CUBE2'>
        <Appearance>
        <Material specularColor='.2 .2 .2' />
          <ImageTexture url='http://x3dom.org/x3dom/example/texture/generic/webgl_256.jpg'/>
        </Appearance>
        <Box/>
      </Shape>
      ...
      ...
      <Transform DEF='XFORM0b' center='0 7 7' translation="0 0 1" rotation="0 0 1 3.14">
        <Shape USE='CUBE2'/>
      </Transform>
      ....

      ( One may even define transforms on transforms:

        <Transform DEF='XFORM1a' rotation="0 1 0 1.23">
          <Transform USE='XFORM0a'/>
          <Transform USE='XFORM0b'/>
          <Transform USE='XFORM0c'/>
          <Transform USE='XFORM0d'/>
        </Transform>
      )


!!! ===================*/

          // create x3d scene
          var parent = d3.select('.riskroom-output');
          
          // first remove everything          
          d3.select('x3d').remove();
          // TODO: Would make a much nicer room if we only once create the floor / walls 
          //       and afterwards use nice transitions to change the scenery
          
          
          var x3d = parent
            .append("x3d")
              .attr("id","the_element")
              .style( "width", parseInt(parent.style("width"))+"px" )
              .style( "height", parseInt(parent.style("height"))+"px" )
              .style( "border", "1" );

          var scene = x3d.append("scene");
          var riskroom = scene.append("transform").attr("class","riskroom");

          
          // create the floor
          function createFloor(riskroom) {

            var scale = d3.scale.linear()
                  .domain([0,1])
                  .range([-(0.9*MDM_EDGE/2),(0.9*MDM_EDGE/2)]);

            var shapeFloor = riskroom.append("transform")
                  .attr("translation", "0 0 0")
                .append("shape");

            var appFloor = shapeFloor.append("appearance")
                .append("material")
                  .attr("emissiveColor", "blue");

            var floor = shapeFloor.append("box")
                  .attr("size", MDM_EDGE+' '+MDM_EDGE/100.0+' '+MDM_EDGE);    // attr("size", "10 0.1 10")

            var newPegs = riskroom.selectAll(".pegs")
                .data(mdm)
                  .enter()
                .append("transform")
                  .attr("class", "pegs")
                  .attr("translation", function(d)  { 
                    t = ''  + scale(d.u) + ' ' + 2 * MDM_EDGE/100 + ' ' + scale(d.v);
                    return t; })
                .append("shape");
//                .attr("DEF",function(d) {return d.country;});

            var appearance = newPegs.append("appearance");
            var material = appearance
                  .append("material")
                  .attr("diffuseColor", "red");
          // This one's for the show !  
            var texture = appearance
                  .append("ImageTexture")
                  .attr("url", function(d) {
                    flagurl = 'img/flags/' + d.country + '.png';
                    return flagurl;
                  }); 

            var cylinder = newPegs.append("cylinder")
                .attr("radius", '' + MDM_EDGE/100)        // attr("radius","0.1")
                .attr("height", '' + 5*MDM_EDGE/100);     // attr("height", "0.5")
                // .attr("onclick", function(d) { alert(d.country + ': ' + d.u + ',' + d.v); });
                // just generates a bunch of useless alerts...
          }        

          // create the walls
          function createWall(riskroom, wallId, riskData, boxPlotData) {

  /* For simplicity of programming:
      Create both the walls as if they were in the x-y plane (disregard the z-dimension)
      Wrap everything with a translation and rotation to move wall into position.        */

            var wallGroup = riskroom.append("transform")
                  .attr("translation", wallId == 'x' ? 
                    '0 '+0.9* MDM_EDGE/2+' '+(-1.1*MDM_EDGE/2): 
                    (-1.1*MDM_EDGE/2)+' ' + 0.9* MDM_EDGE/2+' 0')
                  // attr("translation", wallId=='x'? "0 5 -5.5": "-5.5 5 0")
                  .attr("rotation", wallId == 'x' ? 
                    "0 0 0 0": 
                    "0 1 0 " + Math.PI/2 );                  

            var shapeWall = wallGroup.append("shape");            
            var appWall = shapeWall.append("appearance")
                .append("material")
                  .attr("emissiveColor", "blue");

            // create the wall as an x-y plane
            var wall = shapeWall.append("box")
                  .attr("size", MDM_EDGE+' '+WALL_HEIGHT+' '+MDM_EDGE/100.0);    // attr("size", "10 10 0.1")   


            var scaleY = d3.scale.linear()
                  .domain([0,1])
                  .range([0,(0.7*WALL_HEIGHT)]);
            var scaleX = d3.scale.linear()
                  .domain([-1,boxPlotData.length])
                  .range([-(0.9*MDM_EDGE/2),(0.9*MDM_EDGE/2)]);

            // add the boxplots
            var newParCoords = wallGroup.selectAll("transform")
                .data(boxPlotData)
                  .enter()
                .append("transform")
                  .attr("class",wallId)
                  .attr("translation", function(d,i) {
                     return scaleX(i) + ' 0 0.2';
                  });
                //.append("shape");

            /*
            var lq = newParCoords.append("box")
                .attr("translate",function(d) { return '0 ' + scaleY(d.md - d.lq)/2 + ' 0'; })
                .attr("size", function(d) { return '0.3 ' + scaleY(d.md - d.lq) + ' 0.1'; }); */

          
            var whisker = newParCoords.append("shape");
            whisker.append("cylinder")
                .attr("DEF","whisker")
                .attr("radius", '0.05')        // attr("radius","0.1")
                .attr("height", function(d) { 
                  return '' + scaleY(d.uw - d.lw); });
            whisker.append("appearance")
                .append("material")
                .attr("emissiveColor","red");

            var lq = newParCoords.append("transform")
                  .attr("DEF","lq")
                  .attr("translation",function(d) {return '0 ' +  (-scaleY(d.md - d.lq)/2) + ' 0';})
                .append("shape");
            lq.append("cylinder")
                .attr("radius", '0.2')        // attr("radius","0.1")
                .attr("height", function(d) { 
                  return '' + scaleY(d.md - d.lq); });
            lq.append("appearance")
                .append("material")
                .attr("emissiveColor","green");

            var uq = newParCoords.append("transform")
                  .attr("DEF","uq")
                  .attr("translation",function(d) {return '0 ' +  (scaleY(d.uq - d.md)/2) + ' 0';})
                .append("shape");
            uq.append("cylinder")                
                .attr("radius", '0.2')        // attr("radius","0.1")
                .attr("height", function(d) { 
                  return '' + scaleY(d.uq - d.md); });
            uq.append("appearance")
                .append("material")
                .attr("emissiveColor","blue");                

          }  
          createFloor(riskroom);
          createWall(riskroom, 'x', xRisks, xBoxPlotData);
          createWall(riskroom, 'y', yRisks, yBoxPlotData);
          
          $.getScript('js/x3dom.js');
  
    } //  if (data.mdm != null) 
    
  }
});

Shiny.outputBindings.register(riskroomOutputBinding, 'zurich.riskroombinding');

</script>