//=============================================================================
// Puzzle lock 1, "halfway"
//=============================================================================

include <../util.scad>
use <../threads.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

// Thing that looks like a lock core

core_face_diameter = 13;
core_lip_radius = 1;
core_thickness = roundToLayerHeight(12);
core_back_thickness = roundToLayerHeight(1); // cosmetic
//core_back_thickness = -1; // debug

core_pin_height = 5;
core_pin_thickness = roundToLayerHeight(3);
core_pin_travel = 3;
core_pin_chamfer = 0.9;

// wheels

wheel_diameter = 15;
wheel_thickness = roundToLayerHeight(3);
wheel_weight_diameter = 8;

wheel_hole_clearance = 0.4;

// x wheel

x_wheel_shackle_overlap = 2;
x_wheel_thickness = roundToLayerHeight(10);
x_wheel_overlap_thickness = roundToLayerHeight(2.5);

x_wheel_angle = -45;

// y wheel

y_wheel_shackle_overlap = 2;
y_wheel_core_overlap_x = 3;
y_wheel_core_overlap_z = 2;
y_wheel_core_clearance = 0.3;

y_wheel_angle = -45;

// Pins holding wheels

pin_diameter = 1.1;
pin_clearance = C;

x_pin_stickout = 2;
y_pin_stickout = 2;

// Shackle

shackle_diameter = 8;
shackle_length = 10;

shackle_spacing = 4; // space between shackle and core

shackle_travel_core_pin = 3;
shackle_travel_y_wheel = 3;

// Housing

housing_thickness = roundToLayerHeight(1.5); // thickness of top and bottom
housing_wall = 1.2; // wall thickness

//-----------------------------------------------------------------------------
// Computed parameters
//-----------------------------------------------------------------------------

// core

core_diameter = core_face_diameter + 2*core_lip_radius;
core_top_z = housing_thickness + core_thickness;

core_pin_width = core_pin_travel + shackle_spacing;
core_pin_z = 2*housing_thickness + shackle_travel_core_pin + core_pin_thickness/2;

// shackle

shackle_x = core_diameter / 2 + shackle_spacing + shackle_diameter / 2;

// x wheel

x_wheel_x = shackle_x - shackle_diameter/2 - wheel_diameter/2 + x_wheel_shackle_overlap;
x_wheel_y = 0;
x_wheel_z = core_top_z + 2 + 2;
x_wheel_pos = [x_wheel_x, x_wheel_y, x_wheel_z];

x_pin_length = x_wheel_thickness + 2*x_pin_stickout;

x_wheel_shackle_clearance = 2*C;

x_wheel_weight_diameter = wheel_diameter-2*(x_wheel_shackle_overlap+x_wheel_shackle_clearance);

// y wheel

y_wheel_x = -shackle_x + shackle_diameter/2 - y_wheel_shackle_overlap;
y_wheel_y = 0;
y_wheel_z = core_top_z - y_wheel_core_overlap_z + wheel_diameter/2;

y_wheel_thickness = y_wheel_shackle_overlap + shackle_spacing + y_wheel_core_overlap_x;

y_pin_length = y_wheel_thickness + 2*2;

// housing

housing_top_z = x_wheel_z + x_wheel_thickness + x_pin_stickout + housing_thickness;

//-----------------------------------------------------------------------------
// 'Core'
//-----------------------------------------------------------------------------

module key_profile(y=0,s=0.5) {
  // s=0 gives a rectangle, s=0.5 gives key profile, in between interpolates
  w=2.0;
  h=core_face_diameter * 0.7;
  l=w*s;
  r=w-w*s;
  rotate(-90)
  intersection() {
    translate([-w/2,-core_face_diameter/2])
    polygon([
      [0,y],[0,1.3],[l,1.5],[l,2.3],[0,3.0],[0,5.0],[l,5.8],[0,h],
      [r,h],[w,6.2],[w,5.2],[r,4.2],[r,3.8],[w,3.2],[w,y]
    ]);
    circle(d=core_face_diameter);
  }
}

module core() {
  difference() {
    group() {
      translate_z(layerHeight)
      linear_extrude(housing_thickness) {
        circle(d = core_face_diameter);
      }
      translate_z(housing_thickness-eps)
      linear_extrude(core_thickness+eps) {
        circle(d = core_diameter);
      }
    }
    // (cosmetic) keyway
    translate_z(-eps)
    linear_extrude(core_top_z-core_back_thickness, convexity=5) {
      offset(C) key_profile();
    }
    h = 3;
    translate_z(-eps) translate_x(-core_face_diameter/2+h+0.6) cylinder(r1=h,r2=0,h=h*0.8);
    // y wheel
    rotate(-90)
    y_wheel_pos() {
      cylinder(d=wheel_diameter+2*y_wheel_core_clearance, h=y_wheel_thickness+y_wheel_core_clearance);
    }
    // pin
    core_pin_hole();
  }
}

module core_hole() {
  translate_z(-eps)
  cylinder(d=core_face_diameter+2*C, h=housing_thickness+2*eps);
  translate_z(housing_thickness)
  cylinder(d=core_diameter+2*C, h=core_thickness+layerHeight);
}

//-----------------------------------------------------------------------------
// Pin locking core rotation
//-----------------------------------------------------------------------------

module core_pin_profile() {
  chamfer_rect(core_pin_height, core_pin_thickness, core_pin_thickness/3);
}
module core_pin() {
  *translate([core_diameter/2,0,core_pin_z])
  linear_extrude_y(core_pin_height,center=true) {
    chamfer_rect(core_pin_width, core_pin_thickness, 0.5);
  }
  *translate([core_diameter/2,0,core_pin_z])
  linear_extrude_x(core_pin_width) {
    core_pin_profile();
  }
  translate([core_diameter/2 + core_pin_width/2,0,core_pin_z])
  chamfer_cube(core_pin_width, core_pin_height, core_pin_thickness, core_pin_chamfer);
}

*!core_pin();

module core_pin_hole() {
  *translate([core_diameter/2 - core_pin_travel,0,core_pin_z])
  linear_extrude_x(core_pin_width + core_pin_travel) {
    //offset(C) core_pin_profile();
    l = 2* layerHeight;
    chamfer_rect(core_pin_height + 4*C, core_pin_thickness + 2*layerHeight + 2*l, core_pin_chamfer + C/sqrt(2) + l);
  }
  w = core_pin_width + core_pin_travel + 2*C;
  l = 2* layerHeight;
  translate([core_diameter/2 + w/2 - core_pin_travel,0,core_pin_z])
  chamfer_cube(w, core_pin_height + 2*C, core_pin_thickness + 2*layerHeight + 2*l, core_pin_chamfer + C + l);
}
*!core_pin_hole();

//-----------------------------------------------------------------------------
// Gravity wheels: rotate around x axis: blocks pull
//-----------------------------------------------------------------------------


module x_wheel_pos() {
  translate(x_wheel_pos) children();
}

module x_wheel(angle=0) {
  x_wheel_pos() rotate(angle) {
    difference() {
      group() {
        cylinder(d=wheel_diameter, h=x_wheel_overlap_thickness);
        cylinder(d=x_wheel_weight_diameter, h=x_wheel_thickness);
      }
      // pin
      pin_hole(x_wheel_thickness);
      // weight distribution
      translate_z(x_wheel_overlap_thickness)
      linear_extrude(lots, convexity=2) {
        rotate(x_wheel_angle) wheel_weight_hole_profile();
      }
      // gates
      linear_extrude(lots,center=true,convexity=4) {
        translate(-x_wheel_pos) translate_x(shackle_x) circle(d=shackle_diameter+2*x_wheel_shackle_clearance);
        for (i=[0:45:360]) {
          h = 1.2;
          rotate(i) translate(-x_wheel_pos) x_wheel_false_gate(offset=x_wheel_shackle_clearance);
        }
      }
    }
  }
}
*!intersection() {
  x_wheel();
  positive_y();
}

module x_wheel_false_gate(offset=0) {
  translate_x(shackle_x) {
    //translate_x(-1)
    //circle(d=shackle_diameter-3+2*x_wheel_shackle_clearance);
    *translate_x(x_wheel_shackle_overlap-shackle_diameter/2)
    circle(d=2.5+2*x_wheel_shackle_clearance);
    translate_x(-1)
    circle(d=shackle_diameter-4+2*offset);
    *offset(x_wheel_shackle_clearance)
    intersection() {
      circle(d=shackle_diameter-2);
      square([lots,2],true);
    }
  }
}

module pin_hole(height, pin_surface=1.2) {
  translate_z(-eps)
  cylinder(d=pin_diameter+2*pin_clearance, h=height+2*eps);
  translate_z(pin_surface)
  chamfer_cylinder(d=pin_diameter+2*pin_clearance+1, chamfer_bottom=0.5, chamfer_top=0.5, h=height-2*pin_surface);
}

module x_pin() {
  x_wheel_pos()
  translate_z(-x_pin_stickout)
  cylinder(d=pin_diameter, h=x_pin_length);
}

module x_wheel_hole() {
  x_wheel_pos() {
    cylinder(d=wheel_diameter+2*wheel_hole_clearance, h=x_wheel_overlap_thickness+2*layerHeight);
    cylinder(d=x_wheel_weight_diameter+2*wheel_hole_clearance, h=x_wheel_thickness+layerHeight);
    translate_z(-x_pin_stickout)
    cylinder(d=pin_diameter+2*C, h=x_pin_length);
    // minimize contact between wheel and housing
    translate_z(-layerHeight) linear_extrude(layerHeight+eps,convexity=3) difference() {
      circle(d=wheel_diameter+2*wheel_hole_clearance);
      circle(d=pin_diameter+3);
    }
    translate_z(x_wheel_thickness+layerHeight-eps) linear_extrude(layerHeight+eps,convexity=3) difference() {
      circle(d=x_wheel_weight_diameter+2*wheel_hole_clearance);
      circle(d=pin_diameter+3);
    }
  }
}

//-----------------------------------------------------------------------------
// Gravity wheels: rotate around y axis: blocks push
//-----------------------------------------------------------------------------

module wheel_weight_hole_profile(spokes=false,windows=false) {
  difference() {
    union() {
      circle(d=wheel_diameter-2*1.2);
      if (windows) {
        rotate(45/2)
        for (i=[0:45:360]) {
          h = 4;
          rotate(i) translate_y(-h/2) square([lots,h]);
        }
      }
    }
    circle(d=pin_diameter+2*1.2);
    negative_y2d();
    if (spokes) {
      for (i=[0:45:360]) {
        h = 1.2;
        rotate(i) translate_y(-h/2) square([lots,h]);
      }
    }
  }
}
*!y_wheel_pos()wheel_weight_hole_profile(spokes=true);

y_wheel_pos = [y_wheel_x, y_wheel_y, y_wheel_z] + [2,0,0];
module y_wheel_pos() {
  translate(y_wheel_pos)
  rotate([0,-20,0])
  swap_xyz()
  children();
}
module y_wheel_pos_inv() {
  swap_xyz() swap_xyz()
  rotate([0,20,0])
  translate(-y_wheel_pos)
  children();
}

module y_wheel(angle=0) {
  y_wheel_pos() rotate(angle) {
    difference() {
      //weight_thickness = 12;
      weight_thickness = y_wheel_thickness;
      group() {
        cylinder(d=wheel_diameter, h=y_wheel_thickness);
        *cylinder(d=wheel_weight_diameter, h=weight_thickness);
      }
      // pin
      pin_hole(height=weight_thickness);
      // weight distribution
      translate_z(roundToLayerHeight(2))
      intersection() {
        rotate(-y_wheel_angle) 
        group() {
          linear_extrude(lots, convexity=2) {
            wheel_weight_hole_profile();
          }
          *linear_extrude(y_wheel_thickness-roundToLayerHeight(2)-roundToLayerHeight(1), convexity=2) {
            wheel_weight_hole_profile();
          }
          *linear_extrude(lots, convexity=5) {
            wheel_weight_hole_profile(spokes=true);
          }
          *translate_z(y_wheel_thickness-roundToLayerHeight(2)-eps)
          linear_extrude(lots, convexity=2) {
            wheel_weight_hole_profile();
          }
        }
        cylinder(d1 = wheel_diameter-3*3, d2=3*lots, h=lots);
      }
      // core
      y_wheel_pos_inv() {
        cylinder(d=core_diameter+y_wheel_core_clearance, h=housing_thickness + core_thickness + y_wheel_core_clearance);
      }
      // gates
      false_gate_depth = 0.5;
      rotated(range_to_list([0:45:360-1])) {
        y_wheel_pos_inv() translate_z(-false_gate_depth) y_wheel_gate();
      }
      y_wheel_pos_inv() translate_z(-3) y_wheel_gate();
    }
  }
}
*!intersection() {
  y_wheel();
  positive_y();
}

module y_wheel_gate() {
  translate([-shackle_x,0,y_wheel_z + wheel_diameter/2]) {
    chamfer_cylinder(d=shackle_diameter+2*C + 2*0.4, h=lots, chamfer_bottom=1+0.4);
    *cylinder(d1=shackle_diameter+2*C, d2=shackle_diameter+2*C+1*lots , h=lots);
  }
}

module y_pin() {
  y_wheel_pos() {
    translate_z(-y_pin_stickout)
    cylinder(d=pin_diameter, h=y_pin_length);
  }
}

module y_wheel_hole() {
  y_wheel_pos() {
    translate_z(-C)
    cylinder(d=wheel_diameter+2*wheel_hole_clearance, h=y_wheel_thickness+2*C);
  }
}

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

module shackle_extrude_y(x,height,leadin=0,leadin_scale) {
  translate_x(-x) linear_extrude_y(leadin,scale=leadin_scale) children();
  translate_x(x)  linear_extrude_y(leadin,scale=leadin_scale) children();
  translate_y(leadin)
  linear_extrude_y(height-leadin,convexity=2) {
    translate_x(-x) children();
    translate_x(x) children();
  }
  translate_y(height)
  rotate_extrude(angle=180) {
    translate_x(x) children();
  }
}
module shackle_extrude_z(x,height) {
  swap_yz() shackle_extrude_y(x,height) children();
}

module shackle() {
  translate_z(housing_top_z)
  shackle_extrude_z(shackle_x, shackle_length) {
    circle(d = shackle_diameter);
  }
}

module shackle_hole() {
  mirrored([1,0,0]) {
    translate_x(shackle_x) {
      *chamfer_cylinder(d=shackle_diameter+2*C, h=housing_top_z-housing_thickness+eps, chamfer_top=-0.6);
      translate_z(housing_thickness)
      cylinder(d=shackle_diameter+2*C, h=lots);
      chamfer = 0.6;
      translate_z(housing_top_z-chamfer) cylinder(d1=shackle_diameter+2*C, d2=shackle_diameter+2*C+2*chamfer, h=chamfer+eps);
    }
  }
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housing_width  = 2*(shackle_x + shackle_diameter/2 + housing_wall);
housing_height = max(shackle_diameter,wheel_diameter,core_diameter) + 2*housing_wall;

housing_chamfer = 1;
echo(housing_width,housing_height,housing_top_z);

module housing_profile() {
  *square([housing_width,housing_height],true);
  d = max(shackle_diameter,wheel_diameter,core_diameter);
  *hull() mirrored([1,0,0]) {
    translate_x(shackle_x) circle(d=d+2*housing_wall);
  }
  hull() mirrored([1,0,0]) {
    translate_x(shackle_x) circle(d=shackle_diameter+2*housing_wall);
    dx = housing_wall+C;
    translate_x(shackle_x - (wheel_diameter - shackle_diameter)/2 + dx) circle(d=wheel_diameter+2*housing_wall+2*C);
  }
}

module housing() {
  difference() {
    linear_extrude_cone_chamfer(housing_top_z, housing_chamfer, housing_chamfer) {
      housing_profile();
    }
    core_hole();
    core_pin_hole();
    x_wheel_hole();
    y_wheel_hole();
    shackle_hole();
  }
}

module housing_inner() {
  cube(0.01);
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e) {
  // Note: translate a tiny bit to prevent rendering artifacts from identical surfaces
  translate([e*eps,e*sqrt(3)*eps,e*sqrt(5)*eps])
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
    translate_y(e*eps*10) positive_y();
    *translate_y(e*eps*1) cube([lots,1,lots],true);
  }
}

module assembly() {
  $fn = 30;
  
  color("red") assembly_cut(1) core();
  color("green") assembly_cut(2) core_pin();
  
  color("blue") assembly_cut(3) x_wheel();
  color("violet") assembly_cut(4) x_pin();
  color("purple") assembly_cut(5) y_wheel();
  color("violet") assembly_cut(6) y_pin();
  
  color("pink") assembly_cut(12) shackle();
  color("lightYellow") assembly_cut(10) housing_inner();
  *color("yellow") assembly_cut(11) housing();
}
assembly();
