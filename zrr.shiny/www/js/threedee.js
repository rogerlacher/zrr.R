
/* CSS Utility Functions
-------------------------------------------------- */

var CssUtils = (function() {	
	var s = document.documentElement.style;
 	var vendorPrefix = 
		(s.WebkitTransform !== undefined && "-webkit-") ||
		(s.MozTransform !== undefined && "-moz-") ||
		(s.msTransform !== undefined && "-ms-");
	
	return {
		translate: function( x, y, z, rx, ry, rz ) {
			return vendorPrefix + "transform:" +
				"translate3d(" + x + "px," + y + "px," + z + "px)" +	
				"rotateX(" + rx + "deg)" +
				"rotateY("  +ry + "deg)" +
				"rotateZ(" + rz + "deg);"
		},
		origin: function( x, y, z ) {
			return vendorPrefix + "transform-origin:" + x + "px " + y + "px " + z + "px;";
		},
		texture: function( colour, rx, ry, rz ) {
			var a = Math.abs(-0.5+ry/180)/1.5;
			if (rz!==0) {
				a/=1.75;
			}
			/* for shading:  return "background:rgb(" + (200-a*255|0) + "," + (200-a*255|0) + "," + (200-a*255|0) + ");" */
			/* dor outline:  return "outline:1px solid #393;"; */
			return "background:"+vendorPrefix +"linear-gradient(rgba(0,0,0," + a + "),rgba(0,0,0," + a + "))," + colour + ";";
		}		
	}
}());


/* Triplet
-------------------------------------------------- */

function Triplet( x, y, z ) {
	this.x = x || 0;
	this.y = y || 0;
	this.z = z || 0;
}

/* Camera
-------------------------------------------------- */

function Camera( cube, x, y, z, rx, ry, rz) {
	this.cube = cube;
	this.position = new Triplet(x, y, z);
	this.rotation = new Triplet(rx, ry, rz);	
	this.fov = 700;
}

Camera.prototype = {
	update: function() {
		if (this.cube) {
			this.cube.node.style.cssText=
				CssUtils.origin( -this.position.x, -this.position.y, -this.position.z) +
				CssUtils.translate( this.position.x, this.position.y, this.fov, this.rotation.x, this.rotation.y, this.rotation.z)
			}
		}
}

/* Cube
-------------------------------------------------- */

function Cube( container ) {
  this.node = document.createElement("div")
	this.node.className = "cube"
	container.node.appendChild(this.node)  
	container.camera.cube = this;
}

Cube.prototype = {
	addPlane: function( plane ) {
		this.node.appendChild(plane.node)    
	}
}

/* Container
-------------------------------------------------- */

function Container( node ) {  
	this.node = document.createElement("div")
	this.node.className = "container"
  this.node.id = "container"
  this.node.width = 600;
  this.node.heigth = 600;
	this.camera = new Camera()
	node.append(this.node)  
}

/* Plane
-------------------------------------------------- */
function Plane(id, className, shinyDivId, w,h, x,y,z, rx,ry,rz) {
  this.node = document.createElement("div");
  this.node.className= className;
  this.node.id = id;
  
	this.width = w;
	this.height = h;
	this.position = new Triplet(x, y, z);
	this.rotation = new Triplet(rx, ry, rz);  
  
  subdiv = document.createElement("div");
  subdiv.id = shinyDivId;
  subdiv.className = "shiny-html-output"
  this.node.appendChild(subdiv);    
  this.update();  
}


Plane.prototype = {
  update: function() {    
    return;
		this.node.style.cssText += 
			"width:" + this.width + "px;" +
			"height:" + this.height + "px;" +
			CssUtils.texture(this.colour, this.rotation.x, this.rotation.y, this.rotation.z) +
			CssUtils.translate( this.position.x, this.position.y, this.position.z, this.rotation.x, this.rotation.y, this.rotation.z)
  }
}