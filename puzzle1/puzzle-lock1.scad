//=============================================================================
// Puzzle lock 1, "halfway"
//=============================================================================

include <../util.scad>
use <../threads.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

// Clearances

sliding_clearance = 0.2; // free moving parts

// Thing that looks like a lock core

core_face_diameter = 13;
core_lip_radius = 1;
core_thickness = roundToLayerHeight(13);
core_back_thickness = roundToLayerHeight(1); // cosmetic
//core_back_thickness = -1; // debug

core_pin_height = 5;
core_pin_thickness = roundToLayerHeight(3);
core_pin_travel = 3;
core_pin_clearance = 0.5;
core_pin_chamfer = 0.9;
core_pin_diameter = 3;

// wheels

wheel_diameter = 15;
wheel_thickness = roundToLayerHeight(3);
wheel_weight_thickness = roundToLayerHeight(10);
//wheel_weight_diameter = 8;
wheel_shackle_overlap = 2;
wheel_shackle_clearance = 2*C;

wheel_hole_clearance = 0.4;

// y wheel

wheel1_shackle_overlap = 2;
wheel1_core_overlap_x = 3;
wheel1_core_overlap_z = 2;
wheel1_core_clearance = 0.3;

wheel1_angle = -45;

// x wheel

wheel2_shackle_overlap = 2;
wheel2_thickness = roundToLayerHeight(10);
wheel2_overlap_thickness = roundToLayerHeight(2.5);

wheel2_angle = -45;

// Pins holding wheels

pin_diameter = 1.1;
pin_clearance = C;
pin_stickout = 1.5;

pin2_stickout = pin_stickout;
pin1_stickout = pin_stickout;

// Shackle

shackle_diameter = 8;
shackle_length = 10;

shackle_spacing = 4; // space between shackle and core

shackle_travel = 3;

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
core_pin_z = 2*housing_thickness + shackle_travel + core_pin_thickness/2;

// shackle

shackle_x = core_diameter / 2 + shackle_spacing + shackle_diameter / 2;

// wheel 2

wheel2_x = shackle_x - shackle_diameter/2 - wheel_diameter/2 + wheel2_shackle_overlap;
wheel2_y = 0;
wheel2_z = roundToLayerHeight(core_top_z + pin2_stickout + 1.5);
wheel2_pos = [wheel2_x, wheel2_y, wheel2_z];

//pin2_length = wheel2_thickness + 2*pin2_stickout;

//wheel2_shackle_clearance = 2*C;

//wheel2_weight_diameter = wheel_diameter-2*(wheel2_shackle_overlap+wheel2_shackle_clearance);
//wheel2_weight_diameter = 2*(shackle_x - shackle_diameter/2 - wheel2_x - wheel2_shackle_clearance);

// wheel 1

wheel1_x = -wheel2_x;
wheel1_y = 0;
wheel1_z = wheel2_z + wheel_thickness + roundToLayerHeight(0.45);
wheel1_pos = [wheel1_x, wheel1_y, wheel1_z];

//wheel1_thickness = wheel1_shackle_overlap + shackle_spacing + wheel1_core_overlap_x;

//pin1_length = wheel1_thickness + 2*2;

// housing

housing_top_z = max(wheel1_z,wheel2_z) + wheel_weight_thickness + pin_stickout + housing_thickness;

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

core_rotation_limiter_thickness = roundToLayerHeight(1.5);

module core() {
  difference() {
    group() {
      translate_z(layerHeight)
      linear_extrude(housing_thickness) {
        circle(d = core_face_diameter);
      }
      translate_z(housing_thickness-eps)
      linear_extrude(core_rotation_limiter_thickness+eps,convexity=2) {
        circle(d = core_face_diameter);
        wedge(r=core_diameter/2, a1=20, a2=270-20);
      }
      translate_z(housing_thickness+core_rotation_limiter_thickness-eps)
      linear_extrude(core_thickness-core_rotation_limiter_thickness+eps) {
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
    // core rotation pin
    rotated([0,-90]) {
      core_pin_hole(wide=true, print_angle=180);
    }
    // core-wheel pin
    rotate(-90)
    core_wheel_pin_hole(wide=true);
  }
}
*!core();

module core_hole() {
  translate_z(-eps)
  cylinder(d=core_face_diameter+2*C, h=housing_thickness+2*eps);
  translate_z(housing_thickness)
  linear_extrude(core_rotation_limiter_thickness,convexity=2) {
    circle(d = core_face_diameter+2*C);
    wedge(r=core_diameter/2+C, a1=20, a2=360-20);
  }
  translate_z(housing_thickness+core_rotation_limiter_thickness)
  cylinder(d=core_diameter+2*C, h=core_thickness-core_rotation_limiter_thickness+layerHeight);
}
*!core_hole();

//-----------------------------------------------------------------------------
// Pin locking core rotation
//-----------------------------------------------------------------------------

/*
module core_pin_profile() {
  chamfer_rect(core_pin_height, core_pin_thickness, core_pin_thickness/3);
}*/
module core_pin() {
  /*
  *translate([core_diameter/2,0,core_pin_z])
  linear_extrude_y(core_pin_height,center=true) {
    chamfer_rect(core_pin_width, core_pin_thickness, 0.5);
  }
  *translate([core_diameter/2,0,core_pin_z])
  linear_extrude_x(core_pin_width) {
    core_pin_profile();
  }
  *translate([core_diameter/2 + core_pin_width/2,0,core_pin_z])
    chamfer_cube(core_pin_width, core_pin_height, core_pin_thickness, core_pin_chamfer);
  */
  translate([core_diameter/2,0,core_pin_z])
  linear_extrude_x(core_pin_width)
    circle(d=core_pin_diameter);
}

// cut-off teardrop shape for printing "round" holes
module teardrop(r=undef,d=undef,bridge=3*layerHeight) {
  the_r = r==undef ? d/2 : r;
  union() {
    circle(r=the_r);
    intersection() {
      rotate(45) square(the_r);
      if (bridge != undef) square(2*(the_r+bridge),true);
    }
  }
}
*!teardrop(10);

*!core_pin();

module core_pin_hole(wide=false,print_angle=0) {
  /*
  *translate([core_diameter/2 - core_pin_travel,0,core_pin_z])
  linear_extrude_x(core_pin_width + core_pin_travel) {
    //offset(C) core_pin_profile();
    l = 2* layerHeight;
    chamfer_rect(core_pin_height + 4*C, core_pin_thickness + 2*layerHeight + 2*l, core_pin_chamfer + C/sqrt(2) + l);
  }
  w = core_pin_width + core_pin_travel + 2*C;
  l = 2* layerHeight;
  *translate([core_diameter/2 + w/2 - core_pin_travel,0,core_pin_z])
  chamfer_cube(w, core_pin_height + 2*C, core_pin_thickness + 2*layerHeight + 2*l, core_pin_chamfer + C + l);
  */
  translate([core_diameter/2-core_pin_travel-core_pin_clearance,0,core_pin_z])
  linear_extrude_x(core_pin_width+core_pin_travel+2*core_pin_clearance)
  rotate(-print_angle)
  teardrop(d=core_pin_diameter+(wide?4:2)*sliding_clearance);
}
*!core_pin_hole();

//-----------------------------------------------------------------------------
// Pin locking core to wheels
//-----------------------------------------------------------------------------

core_wheel_pin_travel = roundToLayerHeight(wheel_thickness + 0.8);
core_wheel_pin_length = wheel_thickness + wheel2_z-core_top_z;

module rotate_around(center,angle) {
  translate(center) rotate(angle) translate(-center) children();
}

module core_wheel_pin_profile() {
  *translate([0,core_diameter/2-3/2]) {
    circle(d=3);
  }
  intersection() {
    circle(d=core_diameter);
    //rotate_around(wheel2_pos,90)
    rotate_around(wheel2_pos,90+45)
    translate_x(shackle_x)
    circle(d=shackle_diameter);
    translate_x(-1) positive_x2d();
    translate_y(core_face_diameter*0.2+1.5) positive_y2d(); // clear keyway
  }
}
module core_wheel_pin() {
  translate_z(core_top_z) linear_extrude(core_wheel_pin_length) {
    core_wheel_pin_profile();
  }
}
module core_wheel_pin_hole(wide=false) {
  translate_z(core_top_z - core_wheel_pin_travel - C)
  linear_extrude(core_wheel_pin_length + core_wheel_pin_travel + 3*C) {
    offset(sliding_clearance*(wide?2:1)) core_wheel_pin_profile();
  }
}

//-----------------------------------------------------------------------------
// Gravity wheels: generic stuff
//-----------------------------------------------------------------------------

module wheel(weight_angle, base_diameter=wheel_diameter, base_thickness=wheel_thickness, total_thickness=wheel_weight_thickness, shackle_overlap=wheel_shackle_overlap) {
  weight_diameter = base_diameter - 2*shackle_overlap - 2*wheel_shackle_clearance;
  difference() {
    group() {
      // base wheel with gates
      linear_extrude(base_thickness, convexity=2) difference() {
        circle(d=base_diameter);
        // true gate
        shackle_dx = base_diameter/2+shackle_diameter/2-shackle_overlap;
        translate_x(shackle_dx) circle(d=shackle_diameter+2*wheel_shackle_clearance);
        // false gates
        for (i=[0:45:360]) {
          rotate(i) translate_x(shackle_dx) wheel_false_gate_profile(offset=wheel_shackle_clearance);
        }
      }
      // weight
      linear_extrude(total_thickness, convexity=2) {
        circle(d=pin_diameter+2*1.2);
        rotate(weight_angle) intersection() {
          circle(d=weight_diameter);
          negative_y2d();
        }
      }
    }
    // pin hole
    pin_hole(total_thickness);
  }
}
*!wheel();

module pin_hole(height, pin_contact_surface=1.2) {
  translate_z(-eps)
  cylinder(d=pin_diameter+2*pin_clearance, h=height+2*eps);
  translate_z(pin_contact_surface)
  chamfer_cylinder(d=pin_diameter+2*pin_clearance+1, chamfer_bottom=0.5, chamfer_top=0.5, h=height-2*pin_contact_surface);
}

module wheel_false_gate_profile(offset=0) {
  *translate_x(-1)
  circle(d=shackle_diameter-4+2*offset);
  hull() {
    d = 2.5;
    circle(d=d+2*offset);
    translate_x(-(shackle_diameter/2 - d/2) + wheel_shackle_overlap/2)
    circle(d=d+2*offset);
  }
}

module wheel_hole(base_diameter=wheel_diameter, base_thickness=wheel_thickness, total_thickness=wheel_weight_thickness, shackle_overlap=wheel_shackle_overlap, pin_stickout=pin_stickout) {
  pin_length = total_thickness + 2*pin_stickout;
  weight_diameter = base_diameter - 2*shackle_overlap - 2*wheel_shackle_clearance;
  
  cylinder(d=weight_diameter+2*wheel_hole_clearance, h=total_thickness+layerHeight);
  cylinder(d=base_diameter+2*wheel_hole_clearance, h=base_thickness+2*layerHeight);
  translate_z(-pin2_stickout)
  cylinder(d=pin_diameter+2*C, h=pin_length);
  // minimize contact between wheel and housing
  contact_diameter = pin_diameter+2*C+2*0.5;
  translate_z(-layerHeight) linear_extrude(layerHeight+eps,convexity=3) difference() {
    circle(d=base_diameter+2*wheel_hole_clearance);
    circle(d=contact_diameter);
  }
  translate_z(total_thickness+layerHeight-eps) linear_extrude(layerHeight+eps,convexity=3) difference() {
    circle(d=weight_diameter+2*wheel_hole_clearance);
    circle(d=contact_diameter);
  }
}
*!wheel_hole();


module pin(total_thickness=wheel_weight_thickness, pin_stickout=pin_stickout) {
  pin_length = total_thickness + 2*pin_stickout;
  translate_z(-pin_stickout)
  cylinder(d=pin_diameter, h=pin_length);
}

//-----------------------------------------------------------------------------
// Gravity wheels: rotate around z axis: blocks push
//-----------------------------------------------------------------------------

module wheel1(angle=0) {
  translate(wheel1_pos)
  rotate(angle)
  rotate(180)
  mirror_wheel()
  wheel(weight_angle = wheel2_angle);
}

module pin1() {
  translate(wheel1_pos) pin();
}

module wheel1_hole() {
  translate(wheel1_pos) {
    mirror_wheel() wheel_hole();
  }
}
module mirror_wheel(thickness=wheel2_thickness) {
  translate_z(thickness) mirror([0,0,1]) children();
}

//-----------------------------------------------------------------------------
// Gravity wheels: rotate around z axis: blocks pull
//-----------------------------------------------------------------------------

module wheel2(angle=0) {
  translate(wheel2_pos)
  rotate(angle)
  wheel(weight_angle = wheel2_angle);
}
*!intersection() {
  wheel2();
  positive_y();
}

module pin2() {
  translate(wheel2_pos) pin();
}

module wheel2_hole() {
  translate(wheel2_pos) {
    wheel_hole();
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

shackle_left_z  = wheel1_z;
shackle_right_z = housing_thickness + shackle_travel;

module shackle() {
  translate_z(housing_top_z)
  shackle_extrude_z(shackle_x, shackle_length) {
    circle(d = shackle_diameter);
  }
  // left
  difference() {
    translate([-shackle_x,0,shackle_left_z])
      chamfer_cylinder(d = shackle_diameter, h=housing_top_z-shackle_left_z+eps, chamfer_bottom=1);
    z2 = wheel1_z + wheel_weight_thickness + 2*layerHeight;
    translate([wheel1_x,wheel1_y, 0])
      cylinder(d = wheel_diameter+2*wheel_shackle_clearance, h=z2);
  }
  // right
  difference() {
    translate([shackle_x,0,shackle_right_z])
      chamfer_cylinder(d = shackle_diameter, h=housing_top_z-shackle_right_z+eps, chamfer_bottom=1);
    translate_z(shackle_travel) {
      minkowski() {
        core_pin_hole(print_angle=180);
        cube([eps,eps,0.6]);
      }
    }
    shackle_max_travel = roundToLayerHeight(shackle_travel + 0.6);
    chamfer = 3;
    slope = 0.6;
    translate([wheel2_x,wheel2_y,wheel2_z - chamfer*slope]) {
      chamfer_cylinder(d = wheel_diameter+2*wheel_shackle_clearance, h=wheel_thickness+2*layerHeight + shackle_max_travel + chamfer*slope, chamfer_bottom=chamfer, chamfer_slope=slope);
    }
  }
  extra = 2;
  h = wheel_thickness - 2*layerHeight;
  translate([shackle_x,0,wheel2_z-extra]) {
    linear_extrude_cone_chamfer(h+extra, 0,1) {
      wheel_false_gate_profile();
    }
  }
}
*!shackle($fn=30);

module shackle_hole() {
  translate([-shackle_x,0,shackle_left_z-shackle_travel])
    chamfer_cylinder(d=shackle_diameter+2*C, h=housing_top_z-shackle_left_z+shackle_travel+eps,chamfer_bottom=1,chamfer_top=-0.6);
  translate([shackle_x,0,shackle_right_z-shackle_travel])
    chamfer_cylinder(d=shackle_diameter+2*C, h=housing_top_z-shackle_right_z+shackle_travel+eps,chamfer_bottom=1,chamfer_top=-0.6);
  // chamfer tops
  *mirrored([1,0,0]) {
    translate_x(shackle_x) {
      chamfer = 0.6;
      translate_z(housing_top_z-chamfer) cylinder(d1=shackle_diameter+2*C, d2=shackle_diameter+2*C+2*chamfer, h=chamfer+eps);
    }
  }
}
*!shackle_hole();

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
    wheel2_hole();
    wheel1_hole();
    shackle_hole();
  }
}

module housing_inner() {
  cube(0.01);
}

//-----------------------------------------------------------------------------
// Test
//-----------------------------------------------------------------------------

module test_housing_profile() {
  difference() {
    translate([-0.5,2])
    square([wheel_diameter+6,8],true);
    translate_x(wheel_diameter/2-wheel_shackle_overlap+shackle_diameter/2) circle(d=shackle_diameter+2*C);
  }
}
module test_housing() {
  difference() {
    h = roundToLayerHeight(2);
    translate_z(-h) {
      linear_extrude(wheel_weight_thickness+2*h,convexity=5) {
        test_housing_profile();
      }
    }
    wheel_hole();
  }
}
module test_housing_cut(offset=0) {
  translate_z(wheel_thickness+2*layerHeight) positive_z();
  translate_z(wheel_thickness+2*layerHeight - 0.9) linear_extrude(0.9+eps) {
    difference() {
      offset(0.3) offset(-0.9-0.3-offset) difference() {
        test_housing_profile();
        circle(d=wheel_diameter+2*C);
      }
    }
  }
}
module test_housing1() {
  intersection() {
    test_housing();
    test_housing_cut();
  }
}
module test_housing2() {
  difference() {
    test_housing();
    test_housing_cut(offset=C);
  }
}
module test_shackle() {
  h = roundToLayerHeight(2);
  *translate_x(wheel_diameter/2-wheel_shackle_overlap+shackle_diameter/2) {
    translate_z(-h)
    cylinder(d=shackle_diameter,h=wheel_weight_thickness+2*h);
  }
  intersection() {
    translate([(wheel_diameter/2-wheel_shackle_overlap+shackle_diameter/2)-shackle_x,0,-wheel2_z])
    shackle();
    translate_z(-h) {
      linear_extrude(wheel_weight_thickness+2*h + shackle_travel) {
        positive_x2d();
      }
    }
  }
}
module test_assembly() {
  $fn = 30;
  shackle_pos = -shackle_travel;
  
  color("purple") assembly_cut(5) translate_z(0.5*layerHeight) wheel(weight_angle=45);
  color("violet") assembly_cut(6) pin();
  color("pink") assembly_cut(12) test_shackle();
  
  color("yellow") assembly_cut(11) test_housing1();
  color("lightyellow") assembly_cut(11) test_housing2();
}
!test_assembly();

module export_test_housing1() { test_housing1(); }
module export_test_housing2() { rotate([180]) test_housing2(); }
module export_test_wheel() { wheel(); }
module export_test_shackle() { rotate([180]) test_shackle(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e,always=false) {
  // Note: translate a tiny bit to prevent rendering artifacts from identical surfaces
  translate([e*eps,e*sqrt(3)*eps,e*sqrt(5)*eps])
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
    if (always)
      translate_y(e*eps*10) positive_y();
    *translate_y(e*eps*10) negative_y();
    *translate_y(e*eps*1) cube([lots,1,lots],true);
  }
}

module assembly() {
  $fn = 30;
  shackle_pos = -shackle_travel;
  
  color("red") assembly_cut(1) core();
  color("green") assembly_cut(2) core_pin();
  
  color("purple") assembly_cut(5) translate_z(-0.5*layerHeight) wheel1();
  color("violet") assembly_cut(6) pin1();
  color("blue") assembly_cut(3) translate_z(0.5*layerHeight) wheel2(angle=135);
  color("violet") assembly_cut(4) pin2();
  
  color("green") assembly_cut(7) core_wheel_pin();

  color("pink") assembly_cut(12) translate_z(shackle_pos) shackle();
  color("lightYellow") assembly_cut(10) housing_inner();
  *color("yellow") assembly_cut(11,true) housing();
}
assembly();
