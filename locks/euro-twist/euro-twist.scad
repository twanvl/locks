//=============================================================================
// Eurocylinder with a twist
// by Twan van Laarhoven
//=============================================================================

include <../../util/util.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

// Clearance for holes
C = 0.15;
// Layer height, used as clearance in z direction
layer_height = 0.15;

/* [Housing and core] */
housing_diameter = 17;
core_diameter = 13;
bible_width = 10;
bible_height = 33 - housing_diameter/2;
face_diameter = core_diameter + 2*0.75;
// thickness of face extending from the lock
face_chamfer = 0.8;
// thickness of face extending from the lock
face_thickness = 1;
// thickness of face countersunk into the housing
face_countersink = 1;

/* [Pins] */
pins = 5;
pin_diameter = 3.1;
// Distance between pin centers
pin_sep = 4;
// Position of first pin
first_pin_sep = 3 + 3/2;
last_pin_sep = 2 - 3/2;
housing_depth = first_pin_sep + pins*pin_sep + last_pin_sep;

/* [Back of the lock] */
clip_thickness = 1.2;
clip_diameter = core_diameter - 2;
tail_depth = 2;

/* [Key] */
key_width = 2;
keyHeight = 8.4;
keyBowR = 12;
keyBowHoleR = 3;
keyBowHoleSep = 3;
keyC = 0.2;

/* [Bitting] */
bittingOffset = -1.5;
bitting = [3,1,5,4,2];
// Difference between pin length for one bitting step
step = 0.55;

/* [Do the twist!] */
// twist per mm in z direction
// Note: rotate is in opposite direction of twist!
twist = -4;
// resolution of twist
res = 1;
bible_extend = abs(twist) > 2 ? abs(twist) : 0; // extend bible to account for twisting

//-----------------------------------------------------------------------------
// Computed parameters
//-----------------------------------------------------------------------------


function pin_pos(i) = first_pin_sep + i*pin_sep;

//-----------------------------------------------------------------------------
// lock profile
//-----------------------------------------------------------------------------

module housing_profile() {
  step = $fn == undef || $fn == 0 ? 1 : 360/$fn;
  difference() {
    union() {
      circle(d=housing_diameter);
      if (bible_extend == 0) {
        translate([-bible_width/2,0]) square([bible_width,bible_height-bible_width/2], center=false);
        translate([0,bible_height-bible_width/2]) circle(r=bible_width/2);
      } else {
        sym_polygon_x(concat(
          [[0,0],
           rot(bible_extend,[-bible_width/2,0]),
           rot(bible_extend,[-bible_width/2,bible_height-bible_width/2])],
          [for (a=[0:step:90]) rot(bible_extend,[0,bible_height-bible_width/2] + bible_width/2*polar(180-a)) ],
          [for (a=[-bible_extend:step:0]) rot(-a,[0,bible_height]) ]
        ));
      }
    }
    circle(d=core_diameter + 2*C);
  }
}

module housing(threads = true) {
  difference() {
    linear_extrude(housing_depth, convexity=10, twist=twist*housing_depth) { 
      housing_profile();
    }
    translate([0,0,-eps]) cylinder(d=face_diameter+2*C, h=face_countersink+layer_height);
    for (i=[0:pins-1]) {
      translate([0,0,pin_pos(i)]) rotate(-twist*pin_pos(i)) {
        rotate([-90]) cylinder(d=pin_diameter,h=bible_height+1);
        if (threads) {
          screwHeight = 4;
          translate([0,bible_height-screwHeight,0]) rotate([-90])
          //cylinder(d=4,h=screwHeight);
          m4_thread(screwHeight,C=C,internal=true);
        }
      }
    }
  }
}
//!housing();

module grub_screw() {
  rotate([180])
  difference() {
    m4_thread(3.5, leadin=1); 
    // 2mm hex key
    translate_z(-eps) cylinder(d=2/cos(180/6)+C,$fn=6,h=1.5);
  }
}

//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

module key_profile(y=0,top=0,s=0.5) {
  // s=0 gives a rectangle, s=0.5 gives key profile, in between interpolates
  w=key_width;
  h=keyHeight + top;
  l=w*s;
  r=w-w*s;
  intersection() {
    translate([-w/2,-core_diameter/2])
    polygon([
      [0,y],[0,1.3],[l,1.5],[l,2.3],[0,3.0],[0,5.0],[l,5.8],[0,h],
      [r,h],[w,6.2],[w,5.2],[r,4.2],[r,3.8],[w,3.2],[w,y]
    ]);
    circle(core_diameter/2-y);
  }
}
//!key_profile();

module test_key_profile() {
  C=0.2;
  translate_z(-1) color("lightgreen") linear_extrude(1) circle(core_diameter/2);
  translate_z(1) linear_extrude(1) key_profile(0,0,0.5);
  color("red") linear_extrude(1) offset(r=C) {key_profile(-2);}
}
//!test_key_profile();

//-----------------------------------------------------------------------------
// core
//-----------------------------------------------------------------------------

core_depth = housing_depth + clip_thickness + layer_height + tail_depth;

module core() {
  difference() {
    union() {
      translate([0,0,-face_thickness]) cylinder(d1=face_diameter-2*face_chamfer, d2=face_diameter, h=face_chamfer+eps);
      translate([0,0,-face_thickness+face_chamfer]) cylinder(d=face_diameter, h=face_thickness-face_chamfer+face_countersink+eps);
      cylinder(d=core_diameter, h=housing_depth+eps);
      translate([0,0,housing_depth]) cylinder(d=clip_diameter-2*C, h=clip_thickness+layer_height+eps);
      translate([0,0,housing_depth+clip_thickness+layer_height]) chamfer_cylinder(d=core_diameter, h=tail_depth+eps, chamfer_bottom=(core_diameter-clip_diameter+2*C)/2, chamfer_slope=0.8);
    }
    // clip
    // actuator
    translate([0,0,housing_depth-1]) cylinder(r=4,h=100);
    rotate(-twist*(housing_depth-1))
      translate([0,0,housing_depth-1]) 
        linear_extrude(10,twist=twist*10,convexity=10, slices=res*10*abs(twist))
          square([3,core_diameter/2*2+1],true);
    // keyway
    h = face_thickness + core_depth+2*eps;
    translate([0,0,-face_thickness-eps])
    rotate(-twist*(-face_thickness-eps))
    linear_extrude(h,convexity=10, twist=twist*h, slices=res*h*abs(twist)) {
      offset(r=keyC) {key_profile(-2);}
    }
    // pins
    for (i=[0:pins-1]) {
      rotate(-twist*pin_pos(i))
      translate([0,-1.5,pin_pos(i)])
        rotate([-90])
          cylinder(d=pin_diameter,h=bible_height+1);
    }
  }
}
//!core();

module rotate_test() {
  linear_extrude(10,twist=90) {
    square([10,2]);
  }
  for (z=[1:10]) {
    rotate(-z/10*90)
    translate([10,0,z]) color("red") cube([1,1,1],true);
  }
}
//!rotate_test();

//-----------------------------------------------------------------------------
// key
//-----------------------------------------------------------------------------

module twisted(z1,z2, twist=twist) {
  if (twist == 0) {
    children();
  } else {
    step = 0.05;
    for (z=[z1:step:z2-eps]) {
      rotate(-twist*z)
      intersection() {
        group() children();
        translate([-lots/2,-lots/2,z]) cube([lots,lots,min(step,z2-z)]);
      }
    }
  }
}

module key(twist_bow=true) {
  h=housing_depth;
  difference() {
    z = 0;
    rotate(-twist*z)
    translate([0,0,z])
    linear_extrude(h-z, convexity=10, twist=twist*(h-z), slices=res*(h-z)*abs(twist)) {
      key_profile();
    }
    for (i=[0:pins-1]) {
      w = 0.5; // halfwidth of pin flat
      rotate(-twist*pin_pos(i))
      translate([0,bittingOffset+bitting[i]*step,pin_pos(i)]) {
        linear_extrude_x(4,true) {
          sym_polygon_y([[10,-10-w],[0,-w]]);
        }
      }
    }
    w=0.5;
    h=housing_depth+1;
    rotate(-twist*h)
    translate([0,-3.5,h]) {
      linear_extrude_x(4,true) {
        sym_polygon_x([[10,10],[10,-10+w],[w,0]]);
      }
    }
  }
  flatSize = 3 + face_thickness;
  steps = flatSize/0.05;
  for (i=[1:steps]) {
    z = i*flatSize/steps;
    h = flatSize/steps;
    rotate(-twist*-z)
    translate([0,0,-z])
    linear_extrude(h, convexity=10, twist=twist*h, slices=res*h*abs(twist)) {
      //translate([-key_width/2,-core_diameter/2]) square([key_width,keyHeight+3]);
      if (z-h>=face_thickness+C) translate([-key_width/2,keyHeight-core_diameter/2]) square([key_width,2]);
      key_profile(s=0.5-0.5*i/steps);
    }
  }
  // bow
  x = -core_diameter/2+(keyHeight+2)/2;
  y = -keyBowR*1.7/2 - flatSize;
  rotate(twist_bow ? 0 : twist*flatSize)
  twisted(y-keyBowR*1.7/2, y+keyBowR*1.7/2, twist_bow ? twist : 0) {
    linear_extrude_x(key_width,true) {
      difference() {
        translate([x,y]) chamfer_rect(keyBowR*1.7,keyBowR*1.7,4);
        translate([x-keyHeight/2,-3]) square(keyHeight);
        translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR);
      }
    }
    color("darkgrey")
    linear_extrude_x(key_width+0.4,true) {
      difference() {
        translate([x,y]) chamfer_rect(keyBowR*1.7,keyBowR*1.7,4);
        translate([x,y]) chamfer_rect(keyBowR*1.7-2,keyBowR*1.7-2,4-1);
      }
      difference() {
        translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR+1);
        translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR);
      }
    }
    color("darkgrey")
    translate([0,x,0])
    group() {
      rotated([0,0,180])
      linear_extrude_x((key_width+0.4)/2,false) {
        translate([0,y+4])
        text("twist",5,font="Ubuntu",halign="center",valign="center");
      }
    }
  }
}
//!key();

module key_with_brim() {
  flatSize = 3 + face_thickness;
  bow = keyBowR*1.7;
  x = -core_diameter/2+(keyHeight+2)/2;
  translate_z(bow+flatSize) key();
  translate_y(x) scale([1,1.2,1]) cylinder(r=10,h=0.12);
}
//!key_with_brim();

//-----------------------------------------------------------------------------
// clip
//-----------------------------------------------------------------------------

module clip() {
  r1 = clip_diameter/2;
  r2 = clip_diameter/2+2;
  gap = 65;
  rotate(90)
  difference() {
    linear_extrude(clip_thickness + 1, convexity=3) {
      difference() {
        circle(r2);
        circle(r1);
        wedge(gap,center=true);
        *translate_x(-r1+1) circle(1.5);
      }
      translate(polar(gap/2,(r1+r2)/2)) circle((r2-r1)/2);
      translate(polar(-gap/2,(r1+r2)/2)) circle((r2-r1)/2);
    }
    translate_z(clip_thickness) cylinder(d1=clip_diameter,d2=clip_diameter+2*10,h=10*0.8);
  }
}
//!clip();

//-----------------------------------------------------------------------------
// testing
//-----------------------------------------------------------------------------

module test_parts() {
  housing();
  translate([20,0,0]) color("pink") core();
  translate([40,0,0]) color("lightgreen") key();
}

module test_together() {
  $fn=20;
  intersection() {
    group() {
      housing(threads = false);
      color("pink") core();
      color("lightgreen") key(twist_bow=false);
      translate_z(housing_depth+layer_height/2) rotate(-twist*housing_depth) color("blue") clip();
    }
    //positive_x();
    //translate_z(1)positive_z();
  }
}
test_together();
//test_parts();

//-----------------------------------------------------------------------------
// Export
//-----------------------------------------------------------------------------

module export_key() { key(); }
module export_key_with_brim() { key_with_brim(); }
module export_housing() { housing(); }
module export_core() { core(); }
module export_clip() { clip(); }
module export_grub_screw() { grub_screw(); }
