//=============================================================================
// Common utilities for lock models
//=============================================================================

// Resolution defaults

$fs = 0.1;
$fa = 1;

eps = 1e-3;

//-----------------------------------------------------------------------------
// Extruding
//-----------------------------------------------------------------------------

module linear_extrude_y(height,center=false,convexity=4) {
  translate([0,center?0:height,0])
  rotate([90,0,0])
  linear_extrude(height=height,center=center,convexity=convexity) children();
}
module linear_extrude_x(height,center=false,convexity=4) {
  rotate([0,0,90])
  linear_extrude_y(height=height,center=center,convexity=convexity) children();
}

//-----------------------------------------------------------------------------
// Chamfering
//-----------------------------------------------------------------------------

module fillet(r) {
  offset(r=r) offset(delta=-r) children();
}

module chamfer_rect(w,h,r) {
  polygon([
    [-w/2+r,-h/2],
    [-w/2,-h/2+r],
    [-w/2,h/2-r],
    [-w/2+r,h/2],
    [w/2-r,h/2],
    [w/2,h/2-r],
    [w/2,-h/2+r],
    [w/2-r,-h/2],
  ]);
}

module octahedron(r) {
  union() {
    cylinder(r1=r,r2=0,h=r,$fn=4);
    mirror([0,0,1]) cylinder(r1=r,r2=0,h=r,$fn=4);
  }
}

module chamfer_cube(x,y,z,r) {
  minkowski() {
    cube([x-2*r,y-2*r,z-2*r],center=true);
    octahedron(r,center=true);
  }
}

module minkowski_difference(size=1e12) {
  difference() {
    cube(size*[1.1,1.1,1.1], center=true);
    minkowski(){
      difference(){
        cube(size*[1,1,1], center=true);
        children(0);
      }
      children(1);
    }
  }
}

//-----------------------------------------------------------------------------
// Primitives
//-----------------------------------------------------------------------------

function mul_vec(a,b) = [for (i=[0:len(a)-1]) a[i]*b[i]];
function reverse(list) = [for (i=[0:len(list)-1]) list[len(list)-i-1]];
function mul_vecs(a,list) = [for (x=list) mul_vec(a,x)];
function palindrome(mul, list) = concat(list, mul_vecs(mul,reverse(list)));
module sym_polygon(mul,list) {
  polygon(palindrome(mul,list));
}
// a polygon that is symmetric in the y direction
module sym_polygon_y(list) sym_polygon([1,-1],list);
module sym_polygon_x(list) sym_polygon([-1,1],list);
module sym_polygon_xy(list) {
  polygon(concat(
    list,
    mul_vecs([1,-1],reverse(list)),
    mul_vecs([-1,-1],list),
    mul_vecs([-1,1],reverse(list))
  ));
}
module sym_polygon_180(list) {
  polygon(concat(list,mul_vecs([-1,-1],list)));
}

//-----------------------------------------------------------------------------
// Halfspaces
//-----------------------------------------------------------------------------

lots = 1e3;
module positive_x() { translate([lots,0,0]) cube(2*lots,true); }
module positive_y() { translate([0,lots,0]) cube(2*lots,true); }
module positive_z() { translate([0,0,lots]) cube(2*lots,true); }
module negative_x() { translate([-lots,0,0]) cube(2*lots,true); }
module negative_y() { translate([0,-lots,0]) cube(2*lots,true); }
module negative_z() { translate([0,0,-lots]) cube(2*lots,true); }
module everything() { cube(2*lots,true); }
module not() { difference() { group() {children();} everything(); }  }

//-----------------------------------------------------------------------------
// Other construction utilities
//-----------------------------------------------------------------------------

module translate_x(d) { translate([d,0,0]) children(); }
module translate_y(d) { translate([0,d,0]) children(); }
module translate_z(d) { translate([0,0,d]) children(); }

module translates(ps) {
  for (p=ps) translate(p) children();
}

module mirrored(a) {
  children();
  mirror(a) children();
}

//-----------------------------------------------------------------------------
// Threads
//-----------------------------------------------------------------------------

module m3_thread(length,internal=false) metric_thread(diameter=3,pitch=0.5,length=length,internal=internal);
module m4_thread(length,internal=false) metric_thread(diameter=4,pitch=0.7,length=length,internal=internal);

//-----------------------------------------------------------------------------
// Twisting
//-----------------------------------------------------------------------------
