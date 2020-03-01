//=============================================================================
// Common utilities for lock models
//=============================================================================

// Resolution defaults

$fs = 0.1;
$fa = 2;

eps = 1e-3;

//-----------------------------------------------------------------------------
// Default printing parameters
//-----------------------------------------------------------------------------

C = 0.125; // clearance
layerHeight = 0.15;
function roundTo(x,y) = round(x / y) * y;
function roundToLayerHeight(z) = roundTo(z,layerHeight);

//-----------------------------------------------------------------------------
// Math
//-----------------------------------------------------------------------------

function polar(a,r) = r == undef ? [cos(a),sin(a)] : [r*cos(a),r*sin(a)];
function rot(a,p) = [cos(a)*p[0]-sin(a)*p[1], cos(a)*p[1]+sin(a)*p[0]];
function diagonal(a,b) = sqrt(a*a+b*b);
function side_given_diagonal(c,b) = sqrt(c*c-b*b);
function on_circle(r,x) = [x,side_given_diagonal(r,x)];
function normalize(v) = v / norm(v);
function lerp(a,b,t) = (1-t) * a + t * b;

//-----------------------------------------------------------------------------
// Extruding
//-----------------------------------------------------------------------------

module linear_extrude_y(height,center=false,scale=1,convexity=4) {
  swap_yz()
  linear_extrude(height=height,center=center,scale=scale,convexity=convexity) children();
}
module linear_extrude_x(height,center=false,scale=1,convexity=4) {
  swap_xyz()
  linear_extrude(height=height,center=center,scale=scale,convexity=convexity) children();
}

module linear_extrude_chamfer(height,chamfer1,chamfer2,center=false,convexity=4,step=0.05) {
  n1 = ceil(chamfer1/step);
  n2 = ceil(chamfer2/step);
  translate_z(center ? -height/2 : 0) {
    if (n1 > 0) for (i=[0:n1-1]) {
      z = i*step;
      translate_z(z)
      linear_extrude(min(chamfer1,z+step) - z, convexity=convexity) {
        offset(z-chamfer1) children();
      }
    }
    translate_z(chamfer1)
    linear_extrude(height-chamfer1-chamfer2, convexity=convexity) {
      children();
    }
    if (n2 > 0) for (i=[0:n2-1]) {
      z = i*step;
      z1 = min(chamfer2,z+step);
      translate_z(height-z1)
      linear_extrude(z1 - z, convexity=convexity) {
        offset(z-chamfer2) children();
      }
    }
  }
}

module linear_extrude_cone_chamfer(height,chamfer1,chamfer2,center=false,convexity=undef, resolution=30) {
  maxChamfer = max(chamfer1,chamfer2);
  translate_z(center ? -height/2 : 0)
  minkowski() {
    linear_extrude(height-chamfer1-chamfer2, convexity=convexity) {
      offset(-maxChamfer) children();
    }
    union() {
      $fn = resolution;
      cylinder(r1=maxChamfer-chamfer1,r2=maxChamfer,h=chamfer1);
      translate_z(chamfer1)
      cylinder(r1=maxChamfer,r2=maxChamfer-chamfer2,h=chamfer2);
    }
  }
}

module linear_extrude_chamfer_hole(height, chamfer1, chamfer2, center=false, convexity=undef, resolution=8) {
  translate_z(center ? -height/2 : 0)
  minkowski() {
    linear_extrude(1e-5, convexity=convexity) {
      children();
    }
    union() {
      $fn = resolution;
      e = 1e-5;
      cylinder(r1=chamfer1,r2=e,h=chamfer1);
      translate_z(chamfer1) cylinder(r1=e,r2=e,h=height-chamfer1-chamfer2);
      translate_z(height-chamfer2) cylinder(r1=e,r2=chamfer2,h=chamfer2);
    }
  }
}

//-----------------------------------------------------------------------------
// Chamfering
//-----------------------------------------------------------------------------

module fillet(r) {
  offset(r=r) offset(delta=-r) children();
}

module chamfer_rect(w,h,r, r_tr=undef,r_tl=undef,r_bl=undef,r_br=undef) {
  r_tr = r_tr==undef ? r : r_tr;
  r_tl = r_tl==undef ? r : r_tl;
  r_bl = r_bl==undef ? r : r_bl;
  r_br = r_br==undef ? r : r_br;
  polygon([
    [-w/2+r_bl,-h/2],
    [-w/2,-h/2+r_bl],
    [-w/2,h/2-r_tl],
    [-w/2+r_tl,h/2],
    [w/2-r_tr,h/2],
    [w/2,h/2-r_tr],
    [w/2,-h/2+r_br],
    [w/2-r_br,-h/2],
  ]);
}

module rounded_rect(w,h,r) {
  offset(r) square([w-2*r,h-2*r],true);
}

module double_cone(r,h=undef) {
  hh = h == undef ? r : h;
  union() {
    cylinder(r1=r,r2=0,h=hh);
    mirror([0,0,1]) cylinder(r1=r,r2=0,h=hh);
  }
}

module octahedron(r) {
  double_cone(r,r,$fn=4);
}

module chamfer_cube(x,y,z, r=1,rx=undef,ry=undef,rz=undef) {
  rxx = rx == undef ? r : max(eps,rx);
  ryy = ry == undef ? r : max(eps,ry);
  rzz = rz == undef ? r : max(eps,rz);
  minkowski() {
    cube([x-2*rxx,y-2*ryy,z-2*rzz],center=true);
    scale([rxx,ryy,rzz]) octahedron(1);
  }
}

module chamfer_cylinder(r,h, chamfer_bottom=0,chamfer_top=0, d=undef, chamfer_slope=1) {
  the_r = r == undef ? d/2 : r;
  union() {
    if (chamfer_bottom != 0) {
      cylinder(r1=the_r-chamfer_bottom, r2=the_r, h=abs(chamfer_bottom)*chamfer_slope);
    }
    if (h-abs(chamfer_bottom)*chamfer_slope-abs(chamfer_top)*chamfer_slope >= eps/2) {
      translate_z(abs(chamfer_bottom)*chamfer_slope-eps)
      cylinder(r=the_r, h=h-abs(chamfer_bottom)*chamfer_slope-abs(chamfer_top)*chamfer_slope+2*eps);
    }
    if (chamfer_top != 0) {
      translate_z(h-abs(chamfer_top)*chamfer_slope)
      cylinder(r1=the_r, r2=the_r-chamfer_top, h=abs(chamfer_top)*chamfer_slope);
    }
  }
}

module chamfer(r) {
  minkowski() {
    offset(delta=-r) children();
    octahedron(r,center=true);
  }
}
module chamfer2d(r) {
  minkowski() {
    offset(delta=-r) children();
    circle(r,$fn=2);
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
function randi(min,max) = floor(rands(min,max+1-1e-10,1)[0]);
function randis(min,max,n) = [for (i=rands(0,max-min+1-1e-10,n)) min + floor(i)];
function drop(n,xs,i=0) = [for (i=[n:len(xs)-1]) xs[i]];
function insert_at(pos,x,xs) = [for (i=[0:len(xs)]) i < pos ? xs[i] : i == pos ? x : xs[i-1]];
function cumsum(list,x) = [for (s=x,i=0; i<=len(list); s=s+list[i],i=i+1) s];

module sym_polygon(mul,list) {
  polygon(palindrome(mul,list));
}
// a polygon that is symmetric in the y direction
module sym_polygon_y(list) sym_polygon([1,-1],list);
module sym_polygon_x(list) sym_polygon([-1,1],list);
function sym_polygon_xy_coords(list) =
  concat(
    list,
    mul_vecs([1,-1],reverse(list)),
    mul_vecs([-1,-1],list),
    mul_vecs([-1,1],reverse(list))
  );
module sym_polygon_xy(list) {
  polygon(sym_polygon_xy_coords(list));
}
module sym_polygon_180(list) {
  polygon(concat(list,mul_vecs([-1,-1],list)));
}

module line(points,r) {
  n = len(points);
  angles = [for (i=[0:n-2]) normalize(points[i+1] - points[i])];
  angles2 = [for (i=[0:n-1]) i==0 ? angles[0] : i==n-1 ? angles[n-2] : (angles[i-1]+angles[i])/2 ];
  outline = [
    for (i=[0:n-1])    points[i]+eps/2*rot(-90,angles2[i]),
    for (i=[n-1:-1:0]) points[i]+eps/2*rot(90,angles2[i])
  ];
  offset(r/2)
  polygon(outline);
}

function range_to_list(xs) = [for (x=xs) x];

module prism(polygons,zs,convexity=undef) {
  n = len(polygons);
  k = len(polygons[0]);
  zs2 = zs != undef && !is_num(zs) ? range_to_list(zs) : // convert range to list
        is_num(zs) ? [for (i=[0:n-2]) zs] : zs; // constant step
  zs3 = zs2 != undef && !is_num(zs2) && len(zs2) == n-1 ? cumsum(zs2) : zs2;
  points =
    len(polygons[0][0]) == 3 ?
      [for (i=[0:n-1]) each polygons[i] ] :
      [for (i=[0:n-1]) for (j=[0:k-1]) concat(polygons[i][j],[zs3[i]]) ];
  sideFaces = [for (i=[0:n-2]) for (j=[0:k-1]) [(i+1)*k+j, (i+1)*k+((j+1)%k), (i)*k+((j+1)%k), (i)*k+j]];
  topFace = [for (j=[0:k-1]) n*k-1-j];
  bottomFace = [for (j=[0:k-1]) j];
  polyhedron(points=points, faces=concat([topFace,bottomFace],sideFaces), convexity=convexity);
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
module not() { difference() { everything(); children(); }  }

module positive_x2d(h=lots) { translate([h,0]) square(2*h,true); }
module positive_y2d(h=lots) { translate([0,h]) square(2*h,true); }
module negative_x2d(h=lots) { translate([-h,0]) square(2*h,true); }
module negative_y2d(h=lots) { translate([0,-h]) square(2*h,true); }
module everything2d(h=lots) { square(2*h,true); }
module not2d() { difference() { everything2d(); children(); }  }

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

module wedge(a1=undef, a2=undef, center=false, r=lots, max_steps=360) {
  b1 = a2==undef ? (center ? -a1/2 : 0) : a1;
  b2 = a2==undef ? (center ? a1/2 : a1) : a2;
  n = min(max_steps,max(1,ceil(abs(b1-b2))));
  points = [for (i=[0:n]) polar(lerp(b1,b2,i/n), r)];
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

module translated(a) {
  if (is_list(a)) {
    for (x=a) translate(x) children();
  } else {
    children();
    translate(a) children();
  }
}

module rotated(a) {
  if (is_list(a)) {
    for (x=a) rotate(x) children();
  } else {
    children();
    rotate(a) children();
  }
}

module swap_yz() {
  multmatrix([[1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]]) children();
}
module swap_xz() {
  multmatrix([[0,0,1,0],[0,1,0,0],[1,0,0,0],[0,0,0,1]]) children();
}
module swap_xyz() {
  multmatrix([[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) children();
}

//-----------------------------------------------------------------------------
// Threads
//-----------------------------------------------------------------------------

use <threads.scad>

function coarse_pitch(d) =
  d == 1 ? 0.25 :
  d == 2 ? 0.4 :
  d == 3 ? 0.5 :
  d == 4 ? 0.7 :
  d == 5 ? 0.8 :
  d == 6 ? 1.0 :
  d == 7 ? 1.0 :
  d == 8 ? 1.25 :
  d == 9 ? 1.25 :
  d == 10 ? 1.5 :
  d == 20 ? 2.5 :
  "unknown pitch for thread " + str(d);

module standard_thread(d,length,C=0,internal=false,leadin=0) {
  metric_thread(diameter=d+2*C,pitch=coarse_pitch(d),length=length,internal=internal,leadin=leadin);
}
module m3_thread(length,C=0,internal=false) {
  standard_thread(3,length=length,internal=internal,leadin=leadin);
}
module m4_thread(length,C=0,internal=false,leadin=0) {
  standard_thread(4,length=length,internal=internal,leadin=leadin);
}
module m5_thread(length,C=0,internal=false,leadin=0) {
  standard_thread(5,length=length,internal=internal,leadin=leadin);
}

module thread_with_stop(diameter, C = 0, pitch, length, stop, internal = false, angle=30) {
  d = diameter + 2*C * 1.5;
  stopl = (stop == undef) ? pitch - C*pitch/d/3.14 : stop;
  h = pitch / (2 * tan(angle));
  inner_r = d/2 - h*(internal ? 0.625 : 5.3/8);
  step = 10;
  difference() {
    metric_thread(diameter=d, pitch=pitch, length=length, internal = internal, angle=angle);
    rotate(-90+360*(length-stopl) / pitch)
    for(i=[0:step:360-step]) {
      translate_z(i/360*pitch + length - stopl)
      linear_extrude(pitch,center=false) {
        difference() {
          wedge(i-step/2,i+step/2+0.1);
          circle(r=inner_r);
        }
      }
    }
  }
}

//-----------------------------------------------------------------------------
// Screws
//-----------------------------------------------------------------------------

// Make a screw that runs from z1 to z3,
// with an unthreaded shaft from z2 to z3
// with a triangular head at the top (z3) and a hex slot
module make_screw(
  diameter, z1, z2, z3,
  slot_diameter=undef, slot_depth=undef, slot_type="hex",
  head_thickness = roundToLayerHeight(1.5), head_straight_thickness=roundToLayerHeight(0.5),
  point_chamfer = 1, point_clearance = roundToLayerHeight(1),
  threads=true, internal=false
) {
  c = internal ? C : 0;
  z2_ = internal ? z2 : z2 + 2*layerHeight;
  difference() {
    intersection() {
      union() {
        // threads
        translate_z(z1-(internal?eps:0)) if(threads) {
          standard_thread(d=screw_diameter,length=z2_-z1+eps+(internal?eps:0),internal=internal,C=c);
        } else {
          cylinder(d=screw_diameter+2*c,h=z2_-z1+eps+(internal?eps:0));
        }
        // shaft
        translate_z(z2_) {
          cylinder(d=screw_diameter+2*c,h=z3-z2_-eps);
        }
        // head
        h1 = head_thickness;
        h2 = head_straight_thickness;
        translate_z(z3-h1-h2) cylinder(d1=screw_diameter+2*c,d2=screw_diameter+2*c+2*h1,h=h1);
        translate_z(z3-h2-eps) cylinder(d=screw_diameter+2*c+2*h1,h=h2+eps+(internal?eps:0));
      }
      // chamfer the point, add some clearance to the bottom
      if (!internal) {
        translate_z(z1+point_clearance)
        cylinder(d1=screw_diameter-2*point_chamfer,d2=screw_diameter+2*lots,h=lots,$fn=90);
      }
    }
    // slot
    if (!internal) {
      if (slot_type == "hex") {
        d = (slot_diameter+2*C)*2/sqrt(3);
        translate_z(z3-slot_depth) {
          cylinder(d=d, h=lots, $fn=6);
        }
        translate_z(z3-slot_depth-slot_diameter/2) {
          cylinder(d1=0, d2=d, h=slot_diameter/2+eps, $fn=6);
        }
        translate_z(z3-1) {
          cylinder(d1=d-2,d2=d+2, h=2);
        }
      }
    }
  }
}

//-----------------------------------------------------------------------------
// Sliding
//-----------------------------------------------------------------------------

// Printable slot profile.
// Shape:
//    _______________
//    |             |
//   /               \
//  |_________________|
//
// The large width is w, the small width is w-2*dx
module simple_slot_profile(w, dx, h, slope = 1.2, center=0.5) {
  dz = dx/slope; // height of sloped part
  z1 = roundToLayerHeight((h - dz) * center);
  z2 = roundToLayerHeight((h - dz) * center + dz);
  sym_polygon_x([[w/2,0],[w/2,z1],[w/2-dx,z2],[w/2-dx,h]]);
}

//-----------------------------------------------------------------------------
// Springs
//-----------------------------------------------------------------------------

// Generate a 2d spring that can be compressed in the x direction.
// A spring(w,h) fits exactly into a square([w,h]) if angle=0
// Parameters
//   w: width
//   h: height
//   turns: number of 180 degree turns the spring makes
//   line_width: (Default 0.5)
//   angle: extend/compress the spring. Positive angle extends
//   left_flat: make left side flat even if angle!=0
//   right_flat: make right side flat even if angle!=0
//   center: center around [0,0]? Can be a vector of 2 booleans
module spring_profile(w, h, turns = 4, line_width=0.5, angle = 0, left_flat = true, right_flat = true, center = false, curved = false) {
  nx = turns;
  r = line_width;
  width_per_turn = (w - line_width) / turns;
  gon = 80; // approximate circular turn as an n-gon
  translate([line_width/2 + (is_bool(center) && center || center[0] ? -w/2 : 0),line_width/2 + (is_bool(center) && center || center[1] ? -h/2 : 0)])
  line(cumsum([for (i=[0:turns])
      each [polar( i == 0 && left_flat || i == turns && right_flat
                    ? (i % 2 == 1 ? -90 : 90)
                 : i % 2 == 1 ? -90+angle : 90-angle
                 , curved
                    ? h - width_per_turn - line_width + (i == 0 || i == turns ? width_per_turn/2 : 0)
                    : h - line_width)
           ,if (i<turns && curved)
              for (j=[-90:360/gon:90])
                polar((i % 2 == 1 ? j : -j) * (180-2*angle)/180, width_per_turn*sin(180/gon))
           ,if (i<turns && !curved)
              polar(0, width_per_turn)
           ]
    ],[0,0]), r);
}

//-----------------------------------------------------------------------------
// Twisting
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Logo
//-----------------------------------------------------------------------------

module logo(r=10, logo=true, local=false) {
  h1 = r*0.3;
  h2 = r*0.15;
  difference() {
    cylinder(r1=r,r2=r+h1,h=h1);
    if (logo)
    for (step=[0:0.05:h2]) {
      pos = min(1, (step+0.025)/h2);
      e = 0.5*(1-pos) + 1.7*((sqrt(1-pos*pos)) - 1);
      translate_z(step) linear_extrude(0.05, convexity=10) {
        offset(0.1*r*e)
        scale(0.015*r) import(local ? "flinder.dxf" : "../flinder.dxf");
      }
    }
  }
}

module logo_test() {
  difference() {
    cylinder(r=15,h=3);
    translate_z(1+eps) logo(local=true);
  }
}
