//=============================================================================
// Puzzle lock 3
//=============================================================================

include <../util.scad>
use <../threads.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

core_face_diameter = 11;
core_diameter = core_face_diameter + 2*0.8;
core_thickness = roundToLayerHeight(19);

ball_diameter = 3;

sleeve_diameter = core_diameter + 2*(1.2+C);
sleeve_thickness = core_thickness + roundToLayerHeight(1.2);

bottom_thickness = roundToLayerHeight(1.2);
top_thickness = bottom_thickness;

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

key_height = core_face_diameter*0.68;
module key_profile(y=0,s=0.5) {
  // s=0 gives a rectangle, s=0.5 gives key profile, in between interpolates
  w=2.0;
  h=key_height;
  l=w*s;
  r=w-w*s;
  m=l*0.3;
  rotate(-90)
  intersection() {
    translate([-w/2,-core_face_diameter/2])
    polygon([
      [0,0],[0,1.0],[l,1.1],[l,2.1],[0,2.7],[0,5.0],[l,5.7],[m,h],
      [r+m,h],[w,6.0],[w,4.9],[r,4.1],[r,3.6],[w,3.0],[w,0]
    ]);
    circle(d=core_face_diameter);
  }
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module core() {
  difference() {
    group() {
      cylinder(d=core_face_diameter, h=bottom_thickness+eps);
      translate_z(bottom_thickness)
      cylinder(d=core_diameter, h=core_thickness);
    }
    // keyway
    translate_z(-2*eps) {
      linear_extrude(lots, convexity=5) {
        offset(C) key_profile();
      }
      h = 2.75;
      translate_x(-core_face_diameter/2+h+0.6) cylinder(r1=h,r2=0,h=h*0.8);
    }
    //
    ball_hole_core();
  }
}
*!core($fn=60);

module core_hole() {
  translate_z(-eps)
  cylinder(d=core_face_diameter+2*C, h=bottom_thickness+2*eps);
  translate_z(bottom_thickness-eps)
  cylinder(d=core_diameter+2*C, h=core_thickness+layerHeight);
}

module export_core() { rotate([180]) core(); }

//-----------------------------------------------------------------------------
// Sleeve
//-----------------------------------------------------------------------------

module sleeve() {
  difference() {
    translate_z(bottom_thickness) {
      cylinder(d=sleeve_diameter, h=sleeve_thickness);
    }
    core_hole();
    ball_hole_sleeve();
    // marking (for debuging)
    translate([-sleeve_diameter/2+2,0,sleeve_thickness+bottom_thickness+1.5-0.6]) {
      sphere(d=3,$fn=30);
    }
  }
}

module sleeve_hole() {
  translate_z(bottom_thickness-eps)
  cylinder(d=sleeve_diameter+2*C, h=sleeve_thickness+layerHeight);
}

module export_sleeve() { rotate([180]) sleeve(); }

//-----------------------------------------------------------------------------
// Balls
//-----------------------------------------------------------------------------

ball_x = -(core_diameter/2 + ball_diameter/2 - 0.6);
ball_z1 = 9;
ball_z2 = ball_z1 + 0.7*ball_diameter;
//ball_z_sleeve = (ball_z1+ball_z2)/2;
ball_z_sleeve = ball_z2;
//ball_angles = [0,120,240];
//ball_and_false_angles = ball_angles;
//ball_angles = [0,120,240];
ball_angles = range_to_list([45:90:360]);
ball_and_false_angles = [0,90,270];

module ball_hole(offset=0,up=true) {
  $fn=40;
  d = ball_diameter+2*C+2*offset;
  hull() {
    sphere(d=d);
    // for printability of holes
    rotate([up?0:180])
    cylinder(d=d*sqrt(2)/4,h=d/2+layerHeight);
  }
}
*!ball_hole();

module ball_hole_base(up=true,sy=0) {
  s = [1,1+sy,1];
  rotated(ball_angles) hull() {
    translate([ball_x,0,ball_z1]) scale(s) ball_hole(up=up);
    translate([ball_x,0,ball_z2]) scale(s) ball_hole(up=up);
    translate([ball_x+1,0,ball_z1]) scale(s) ball_hole(up=up);
    translate([ball_x+1,0,ball_z2]) scale(s) ball_hole(up=up);
  }
}
module ball_hole_housing(up=true,sy=0) {
  ball_hole_base(up=up);
  // for lock of sleeve to core
  rotate_extrude() {
    translate([ball_x2_lock,ball_z2_lock]) circle(d=ball_diameter+2*C);
  }
  rotate(0) {
    hull() {
      translate([ball_x,0,ball_z1_lock]) ball_hole(0,up=up);
      translate([ball_x2_lock,0,ball_z2_lock]) ball_hole(0,up=up);
    }
  }
  // for debuging
  rotated(ball_angles) hull() {
    d=1;
    ball_z1d = ball_z1-1;
    ball_z2d = ball_z2+1;
    translate([ball_x-5,0,ball_z1d]) sphere(d=d,$fn=15);
    translate([ball_x-5,0,ball_z2d]) sphere(d=d,$fn=15);
    translate([ball_x+1,0,ball_z1d]) sphere(d=d,$fn=15);
    translate([ball_x+1,0,ball_z2d]) sphere(d=d,$fn=15);
  }
}

module ball_hole_sleeve(up=false) {
  ball_hole_base(up=up);
  *rotated(ball_angles) {
    translate_z(ball_z_sleeve) hull() {
      translate_x(ball_x) ball_hole(up=up);
      translate_x(0) ball_hole(up=up);
    }
    translated([[0,0,ball_z1],[0,0,ball_z2]]) hull() {
      translate_x(ball_x) ball_hole(up=up);
      translate_x(ball_x+C) ball_hole(up=up);
    }
  }
  // hole for engaging with core
  *rotated([180]) {
    translate_z(ball_z_sleeve)
    translate_x(-core_diameter/2) ball_hole(up=up);
  }
  // for lock to core
  rotate(0) {
    hull() {
      translate([ball_x,0,ball_z1_lock]) ball_hole(0,up=up);
      translate([ball_x2_lock-0.5,0,ball_z2_lock]) ball_hole(0,up=up);
      translate([ball_x+1,0,ball_z1_lock]) ball_hole(0,up=up);
      translate([ball_x2_lock+1,0,ball_z2_lock]) ball_hole(0,up=up);
      //translate([ball_x+2,0,ball_z1_lock]) ball_hole(0,up=up);
      //translate([ball_x,0,ball_z2_lock]) ball_hole(0,up=up);
      //translate([ball_x+2,0,ball_z2_lock]) ball_hole(0,up=up);
    }
  }
}

num_balls = 3;
ball_z1_core = bottom_thickness + ball_diameter/2;
ball_z2_core = max(ball_z_sleeve-2, ball_z1_core + (num_balls-2)*(ball_diameter+2*C));
//ball_x_core = -core_diameter/2 + ball_diameter + C;
ball_x1_core = -core_diameter/2 * 0.4 + ball_diameter/2;
//ball_x2_core = -core_diameter/2 + ball_diameter + C;
ball_x2_core = ball_x1_core;

ball_z2_lock = core_thickness - 2*C;
ball_z1_lock = ball_z2_lock - ball_diameter*1.2;
ball_x2_lock = -(sleeve_diameter/2 - ball_diameter/2);
//ball_x2_lock = ball_x;
//ball_x2_lock = -(sleeve_diameter/2 - ball_diameter/2) - 2*C;

module ball_hole_core(up=false) {
  rotate(180) {
    s=[1,1.2,1];
    hull() {
      translate([ball_x1_core,0,ball_z1_core]) ball_hole(C,up=up);
      translate([ball_x2_core,0,ball_z2_core]) ball_hole(C,up=up);
    }
    hull() {
      translate([ball_x+2.5,  0,ball_z_sleeve]) ball_hole(C,up=up);
      translate([ball_x2_core,0,ball_z_sleeve-2]) ball_hole(C,up=up);
    }
    hull() {
      //translate([ball_x2_core,0,ball_z_sleeve]) ball_hole(C,up=up);
      //translate([ball_x2_core,0,ball_z_sleeve-0.3]) ball_hole(C,up=up);
      translate([ball_x,      0,ball_z_sleeve]) scale(s) ball_hole(C,up=up);
      translate([ball_x+2.5,  0,ball_z_sleeve]) ball_hole(C,up=up);
    }
    hull() {
      translate([ball_x+1,0,ball_z_sleeve]) scale(s) ball_hole(C,up=up);
      translate([ball_x,0,ball_z1]) scale(s) ball_hole(0,up=up);
    }
    rotated(ball_and_false_angles) hull() {
      translate([ball_x,0,ball_z2]) scale(s) ball_hole(C,up=up);
      translate([ball_x,0,ball_z1]) scale(s) ball_hole(0,up=up);
    }
  }
  *rotated(ball_angles) hull() {
    translate([ball_x,0,ball_z1]) ball_hole(C,up=up);
  }
  rotate_extrude() {
    translate([ball_x,ball_z1]) circle(d=ball_diameter+2*C);
  }
  // for lock to sleeve
  rotate_extrude() {
    translate([ball_x,ball_z1_lock]) circle(d=ball_diameter+2*C);
  }
  rotated(range_to_list([0:45:360-1])) {
    hull() {
      translate([ball_x,0,ball_z1_lock]) ball_hole(0,up=up);
      translate([ball_x2_lock,0,ball_z2_lock]) ball_hole(0,up=up);
      translate([ball_x2_lock,0,sleeve_thickness+ball_diameter]) ball_hole(0,up=up);
    }
  }
}

*!sleeve($fn=30);
*!core($fn=30);
*!housing($fn=30);
*!housing_outer($fn=30);

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housing_thickness = sleeve_thickness + layerHeight + bottom_thickness + top_thickness;
//housing_width = sleeve_diameter + 2*1.5;
housing_width = sleeve_diameter + 2*2.5;

module housing_outer_profile() {
  *fillet(1) square(housing_width,true);
  circle(d=housing_width,$fn=8);
}

module housing(logo=false) {
  difference() {
    union() {
      linear_extrude(housing_thickness) {
        housing_outer_profile();
      }
      translate_x(-housing_width/2+1) hull() {
        translate_z(5) sphere(d=3,$fn=30);
        translate_z(15) sphere(d=3,$fn=30);
      }
    }
    core_hole();
    sleeve_hole();
    ball_hole_housing();
  }
}
module housing_lid_profile() {
  z1 = housing_thickness - top_thickness;
  z2 = housing_thickness;
  x1 = sleeve_diameter/2 + 0.7;
  x2 = sleeve_diameter/2;
  sym_polygon_x([[x1,z1],[x1,z1+0.3],[x2,z2-0.3],[x2,z2]]);
}
module offset_x(offset) {
  minkowski() {
    children();
    square([2*offset,eps],true);
  }
}
module housing_outer(logo=false) {
  difference() {
    housing();
    rotate(180/8) intersection() {
      linear_extrude_y(lots,true) offset_x(C) housing_lid_profile();
      rotated([360/8]) union() {
        linear_extrude_y(lots,true) offset_x(C) housing_lid_profile();
        positive_x();
      }
      rotated([2*360/8]) union() {
        linear_extrude_y(lots,true) offset_x(C) housing_lid_profile();
        positive_x();
      }
      rotated([3*360/8]) union() {
        linear_extrude_y(lots,true) offset_x(C) housing_lid_profile();
        positive_x();
      }
      not() {
        w=18;h=2;
        translate([-w/2,housing_width/2-h,housing_thickness - top_thickness]) {
          cube([w,h,layerHeight]);
        }
      }
    }
  }
}
module housing_lid(logo=false) {
  intersection() {
    *housing();
    linear_extrude(housing_thickness) {
      housing_outer_profile();
    }
    rotate(180/8) linear_extrude_y(lots,true) housing_lid_profile();
    rotated([360/8]) union() {
      rotate(180/8) linear_extrude_y(lots,true) housing_lid_profile();
      positive_x();
    }
    rotated([2*360/8]) union() {
      rotate(180/8) linear_extrude_y(lots,true) housing_lid_profile();
      positive_x();
    }
    rotated([3*360/8]) union() {
      rotate(180/8) linear_extrude_y(lots,true) housing_lid_profile();
      positive_x();
    }
    rotate(180/8) not() {
        w=18+2*C;h=2+C;
        translate([-w/2,housing_width/2-h,housing_thickness - top_thickness -eps]) {
          cube([w,h,layerHeight]);
        }
      }
  }
}
!housing_lid();
!group(){housing_outer(); housing_lid();}

module export_housing_outer() { housing_outer(); }
module export_housing_lid() { housing_lid(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e,always=false) {
  // Note: translate a tiny bit to prevent rendering artifacts from identical surfaces
  translate([e*eps,e*sqrt(3)*eps,e*sqrt(5)*eps])
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
    if (always||true)
      translate_y(e*eps*10) positive_y();
    *translate_y(e*eps*10) negative_y();
    *translate_y(e*eps*1) cube([lots,1,lots],true);
  }
}

module assembly() {
  $fn = 30;
  threads = false;
  core_angle = 0;
  ha = 45;

  group() {
    color("pink") assembly_cut(1) rotate(core_angle) core();
    color("green") assembly_cut(5,true) rotate(ha) translate_z(0.3*layerHeight) sleeve();
    
    *color("pink") assembly_cut(12) translate_z(shackle_pos) {
      shackle(threads=threads);
    }
  }
  group() {
    color("yellow") assembly_cut(11,true) rotate(ha) housing(logo=false);
    *color("yellow") assembly_cut(11,true) rotate(ha) housing_outer(logo=false);
    *color("lightYellow") assembly_cut(10,true) rotate(ha) housing_lid();
    *color("Khaki") assembly_cut(9,true) housing_inner2();
  }
  
}
assembly();
