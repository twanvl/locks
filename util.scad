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
  rotate([0,0,90]) rotate([90,0,0])
  linear_extrude(height=height,center=center,convexity=convexity) children();
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
module positive_x(h=lots) { translate([h,0,0]) cube(2*h,true); }
module positive_y(h=lots) { translate([0,h,0]) cube(2*h,true); }
module positive_z(h=lots) { translate([0,0,h]) cube(2*h,true); }
module negative_x(h=lots) { translate([-h,0,0]) cube(2*h,true); }
module negative_y(h=lots) { translate([0,-h,0]) cube(2*h,true); }
module negative_z(h=lots) { translate([0,0,-h]) cube(2*h,true); }
module everything(h=lots) { cube(2*h,true); }
module not() { difference() { group() {children();} everything(); }  }

// a wedge, starting from the positive x, up to rotation of a counter clockwise
module wedge_space(a, center=false) {
  da = center ? -a/2 : 0;
  rotate(da)
  if (a < 180) {
    difference() {
      positive_y(lots/10);
      rotate(a) positive_y();
    }
  } else {
    union() {
      positive_y(lots/10);
      rotate(a-180) positive_y(lots/10);
    }
  }
}

module wedge(a1=undef, a2=undef, center=false, r=lots) {
  b1 = a2==undef ? (center ? -a1/2 : 0) : a1;
  b2 = a2==undef ? (center ? a1/2 : a1) : a2;
  n = 10;
  points = [for (i=[0:n]) [r*cos(b1+(b2-b1)*i/n),r*sin(b1+(b2-b1)*i/n)]];
  polygon(concat([[0,0]],points));
}

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

module rotated(a) {
  children();
  rotate(a) children();
}

//-----------------------------------------------------------------------------
// Threads
//-----------------------------------------------------------------------------

module m3_thread(length,internal=false) metric_thread(diameter=3,pitch=0.5,length=length,internal=internal);
module m4_thread(length,internal=false) metric_thread(diameter=4,pitch=0.7,length=length,internal=internal);

//-----------------------------------------------------------------------------
// Twisting
//-----------------------------------------------------------------------------
