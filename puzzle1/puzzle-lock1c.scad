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
core_lip_radius = 0.8;
core_thickness = roundToLayerHeight(18);
core_back_thickness = roundToLayerHeight(1); // cosmetic
//core_back_thickness = -1; // debug

// wheels

wheel_diameter = 15.5;
wheel_thickness = roundToLayerHeight(3);
wheel_weight_thickness = roundToLayerHeight(12);
//wheel_weight_diameter = 8;
wheel_shackle_overlap = 2;
wheel_shackle_clearance = 2*C;

wheel_hole_clearance = 0.5;

// y wheel

wheel1_shackle_overlap = 2;
wheel1_core_overlap_x = 3;
wheel1_core_overlap_z = 2;
wheel1_core_clearance = 0.3;

wheel1_angle = -45-90;

// x wheel

wheel2_shackle_overlap = 2;
wheel2_thickness = roundToLayerHeight(10);
wheel2_overlap_thickness = roundToLayerHeight(2.5);

wheel2_angle = -45;

wheel_stagger = true;

// Pins holding wheels

pin_diameter = 1.1;
pin_clearance = C;
pin_stickout = 1.5;

pin2_stickout = pin_stickout;
pin1_stickout = pin_stickout;

// Shackle

shackle_diameter = 8;
shackle_length = 10;

//shackle_spacing = 4; // space between shackle and core
//shackle_spacing = 4.8; // space between shackle and core
shackle_spacing = 5.4; // space between shackle and core

shackle_travel_down = roundToLayerHeight(3.5);
shackle_travel_up   = roundToLayerHeight(3.5);
shackle_travel_open = roundToLayerHeight(4.0);

// Housing

housing_thickness = roundToLayerHeight(1.5); // thickness of top and bottom
housing_wall = 1.2; // wall thickness

//-----------------------------------------------------------------------------
// Computed parameters
//-----------------------------------------------------------------------------

// core

core_diameter = core_face_diameter + 2*core_lip_radius;
core_top_z = housing_thickness + core_thickness;

// shackle

shackle_x = core_diameter / 2 + shackle_spacing + shackle_diameter / 2;

// wheel 2

//wheel2_x = shackle_x - shackle_diameter/2 - wheel_diameter/2 + wheel2_shackle_overlap;
wheel2_x = shackle_x - shackle_diameter/2 - wheel_diameter/2 + wheel2_shackle_overlap - 2;
wheel2_y = 0;
wheel2_z = roundToLayerHeight(core_top_z + pin2_stickout + 1.5);
wheel2_pos = [wheel2_x, wheel2_y, wheel2_z];

//pin2_length = wheel2_thickness + 2*pin2_stickout;

wheel2_base_z = 0;
//wheel2_base_z = wheel_weight_thickness - wheel_thickness - wheel_thickness - 4*layerHeight;
wheel2_wheel_z = wheel2_z + wheel2_base_z;

//wheel2_shackle_clearance = 2*C;

//wheel2_weight_diameter = wheel_diameter-2*(wheel2_shackle_overlap+wheel2_shackle_clearance);
//wheel2_weight_diameter = 2*(shackle_x - shackle_diameter/2 - wheel2_x - wheel2_shackle_clearance);

wheel_weight_diameter = wheel_diameter - 2*wheel_shackle_overlap - 2*wheel_shackle_clearance;
  
// wheel 1

//wheel1_x = -wheel2_x;
wheel1_x = -(shackle_x - shackle_diameter/2 - wheel_diameter/2 + wheel2_shackle_overlap);
wheel1_y = 0;
wheel1_z = wheel2_z + (wheel_stagger ? wheel_thickness + roundToLayerHeight(0.45) : 0);
wheel1_pos = [wheel1_x, wheel1_y, wheel1_z];

wheel1_base_z = wheel_weight_thickness - wheel_thickness;
wheel1_wheel_z = wheel1_z + wheel1_base_z;
//wheel1_wheel_z = wheel1_z;

//wheel1_thickness = wheel1_shackle_overlap + shackle_spacing + wheel1_core_overlap_x;

//pin1_length = wheel1_thickness + 2*2;

// pins
pin_length = wheel_weight_thickness + 2*pin_stickout;
echo("pin length = ", pin_length);

// housing

housing_top_thickness = roundToLayerHeight(shackle_travel_open - 1);
housing_top_z = max(wheel1_z,wheel2_z) + wheel_weight_thickness + housing_top_thickness;

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

module core(simple=$preview) {
  difference() {
    group() {
      translate_z(0)
      linear_extrude(housing_thickness) {
        circle(d = core_face_diameter);
      }
      *translate_z(housing_thickness-eps)
      linear_extrude(core_rotation_limiter_thickness+eps,convexity=2) {
        circle(d = core_face_diameter);
        wedge(r=core_diameter/2, a1=20, a2=270-20);
      }
      *translate_z(housing_thickness+core_rotation_limiter_thickness-eps)
      linear_extrude(core_thickness-core_rotation_limiter_thickness+eps) {
        circle(d = core_diameter);
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
    // slot for core-lock
    h1 = shackle_travel_down + shackle_travel_up;
    h1b = h1+1*layerHeight;
    h2 = h1 + shackle_travel_open + 1;
    a0 = 0;
    a1 = 90;
    a2 = 135;
    core_lock_pin_slot(a0,a0,0,h1b, simple=simple);
    core_lock_pin_slot(a0,a1,h1,h1, simple=simple);
    core_lock_pin_slot(a1,a1,0,h1b, simple=simple);
    core_lock_pin_slot(a1,a2,0,0, simple=simple);
    core_lock_pin_slot(a2,a2,0,h2, simple=simple);
  }
}
*!core(simple=true,$fn=30);

module core_hole() {
  translate_z(-eps)
  chamfer_cylinder(d=core_face_diameter+2*C, h=housing_thickness+2*eps, chamfer_bottom=-0.6);
  translate_z(housing_thickness)
  *linear_extrude(core_rotation_limiter_thickness,convexity=2) {
    circle(d = core_face_diameter+2*C);
    wedge(r=core_diameter/2+C, a1=20, a2=360-20);
  }
  *translate_z(housing_thickness+core_rotation_limiter_thickness)
  cylinder(d=core_diameter+2*C, h=core_thickness-core_rotation_limiter_thickness+layerHeight);
  translate_z(housing_thickness)
  cylinder(d=core_diameter+2*C, h=core_thickness+layerHeight);
}
*!core_hole();

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

key_d = 18;
key_height = core_thickness*2.5;

module key() {
  h = key_height - key_d;
  translate_z(key_d) {
    intersection() {
      translate_z(-5)
      linear_extrude(h+5) {
        translate_x(core_face_diameter*0.3)
        key_profile();
      }
      linear_extrude_y(lots,true) {
        //translate_x(-core_face_diameter*0.3)
        difference() {
          sym_polygon_x([[1,h],[1+h+10,-10]]);
          bitting=[5,2,4,6];
          for (i=[0:len(bitting)-1]) {
            translate([core_face_diameter*0.5-bitting[i]*0.5,4+i*4]) {
              sym_polygon_y([[0,0.5],[10,0.5+10]]);
            }
          }
        }
      }
    }
    hole_d = 6;
    linear_extrude_y(2,true) {
      translate_y(-key_d/2) {
        difference() {
          circle(d=key_d);
          translate_y(-(key_d-hole_d)/2+1.2) circle(d=hole_d);
        }
        translate([-core_face_diameter*0.2,0])
        square(core_face_diameter*0.7);
      }
    }
  }
}
toy_key_thickness = 1.5;
toy_key_height = (core_thickness+1+(wheel_stagger?wheel_thickness:0));
toy_key_scale = toy_key_height/key_height;
toy_key_x = ((-shackle_x+shackle_diameter/2) + -(core_diameter/2)) / 2;
module toy_key() {
  translate([toy_key_x,0,housing_thickness+toy_key_height])
  rotate(90)
  rotate([180])
  scale([toy_key_scale,toy_key_thickness/2,toy_key_scale]) key();
}
module toy_key_hole() {
  translate([toy_key_x,0,housing_thickness])
  linear_extrude(toy_key_height+3*layerHeight) {
    square([toy_key_thickness+2*C, toy_key_scale*key_d+2*C],true);
  }
}
module toy_key_removal_hole() {
  translate([toy_key_x,0,housing_thickness+toy_key_height]) {
    linear_extrude_x(-toy_key_x) {
      hull() {
        circle(d=toy_key_scale*key_d+2*C);
        translate_y(-4)
        circle(d=toy_key_scale*key_d+2*C);
      }
    }
  }
}
*!group() {
  translate_x(1)
  color("green") toy_key_hole();
  toy_key();
}
*!key();

//-----------------------------------------------------------------------------
// Gravity wheels: generic stuff
//-----------------------------------------------------------------------------

module wheel(weight_angle, base_diameter=wheel_diameter, base_thickness=wheel_thickness, total_thickness=wheel_weight_thickness, shackle_overlap=wheel_shackle_overlap, base_z=0) {
  weight_diameter = base_diameter - 2*shackle_overlap - 2*wheel_shackle_clearance;
  difference() {
    group() {
      // base wheel with gates
      translate_z(base_z)
      linear_extrude(base_thickness, convexity=2) difference() {
        circle(d=base_diameter);
        // weight clearance
        difference() {
          circle(d=base_diameter-2*3.2);
          circle(d=pin_diameter+2*1.2);
        }
        // true gate
        // has some clearance for incorrect rotation
        true_gate_clearance = 4;
        shackle_dx = base_diameter/2+shackle_diameter/2-shackle_overlap;
        rotated([-true_gate_clearance,true_gate_clearance])
        translate_x(shackle_dx) circle(d=shackle_diameter+2*wheel_shackle_clearance);
        difference() {
          wedge(r=base_diameter/2,a1=-true_gate_clearance,a2=true_gate_clearance);
          circle(d=base_diameter-2*shackle_overlap - 2*wheel_shackle_clearance);
        }
        // false gates
        for (i=[0:45:360]) {
          rotate(i) translate_x(shackle_dx) wheel_false_gate_profile(offset=wheel_shackle_clearance);
        }
      }
      // weight
      linear_extrude(total_thickness, convexity=2) {
        circle(d=pin_diameter+2*1.2);
        *rotate(weight_angle) intersection() {
          circle(d=weight_diameter);
          negative_y2d();
        }
        wedge_angle=120;
        rotate(weight_angle-90) wedge(r=weight_diameter/2,a1=-wedge_angle/2,a2=wedge_angle/2);
      }
    }
    // pin hole
    pin_hole(total_thickness);
    // hole for extra metal weight
    if (1) {
      d = 3;
      //translate_z(layerHeight)
      translate_z(-eps)
      rotate(weight_angle)
      translate_y(-(weight_diameter/2-d/2-0.5))
      cylinder(d=d,h=lots,total_thickness+2*eps);
    }
  }
}
*!wheel(-45);
*!intersection() { wheel(0); positive_x(); }

module pin_hole(height, pin_contact_surface=1.5) {
  translate_z(-eps)
  //cylinder(d=pin_diameter+2*pin_clearance, h=height+2*eps);
  chamfer_cylinder(d=pin_diameter+2*pin_clearance, h=height+2*eps, chamfer_bottom=-0.4, chamfer_top=-0.4);
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

module wheel_hole(base_diameter=wheel_diameter, base_thickness=wheel_thickness, total_thickness=wheel_weight_thickness, shackle_overlap=wheel_shackle_overlap, pin_stickout=pin_stickout, base_z=0) {
  pin_length = total_thickness + 2*pin_stickout;
  weight_diameter = base_diameter - 2*shackle_overlap - 2*wheel_shackle_clearance;
  bottom = base_z==0;
  top = base_z+base_thickness+eps>=total_thickness;
  
  cylinder(d=weight_diameter+2*wheel_hole_clearance, h=total_thickness+2*layerHeight);
  translate_z(base_z - (bottom ? 0 : top ? 2 : 1)*layerHeight)
  cylinder(d=base_diameter+2*wheel_hole_clearance, h=base_thickness+4*layerHeight);
  translate_z(-pin2_stickout)
  cylinder(d=pin_diameter+2*C, h=pin_length);
  // minimize contact between wheel and housing
  //contact_diameter = pin_diameter+2*C+2*0.5;
  contact_diameter = pin_diameter+2*1.2;
  translate_z(-layerHeight) linear_extrude(layerHeight+eps,convexity=3) difference() {
    circle(d=(bottom?base_diameter:weight_diameter)+2*wheel_hole_clearance);
    circle(d=contact_diameter);
  }
  translate_z(total_thickness+2*layerHeight-eps) linear_extrude(layerHeight+eps,convexity=3) difference() {
    circle(d=(top?base_diameter:weight_diameter)+2*wheel_hole_clearance);
    circle(d=contact_diameter);
  }
}
*!wheel_hole(base_z=1);
*!wheel_hole(base_z=wheel_weight_thickness-wheel_thickness);


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
  wheel(weight_angle=wheel1_angle, base_z=wheel1_base_z);
}

module pin1() {
  translate(wheel1_pos) pin();
}

module wheel1_hole() {
  translate(wheel1_pos) {
    wheel_hole(base_z=wheel1_base_z);
  }
}

//-----------------------------------------------------------------------------
// Gravity wheels: rotate around z axis: blocks pull
//-----------------------------------------------------------------------------

wheel2_diameter = wheel_diameter - 1;

module wheel2(angle=0) {
  translate(wheel2_pos)
  rotate(angle)
  wheel(weight_angle=wheel2_angle, base_z=wheel2_base_z, base_diameter=wheel2_diameter, shackle_overlap=1);
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
    wheel_hole(base_z=wheel2_base_z);
  }
}

//-----------------------------------------------------------------------------
// Core-shackle lock
//-----------------------------------------------------------------------------

shackle_travel_total = shackle_travel_down + shackle_travel_up + shackle_travel_open;

core_lock_down_z = housing_thickness + roundToLayerHeight(2.0);
core_lock_thickness = core_thickness + housing_thickness - core_lock_down_z - shackle_travel_total;
//core_lock_thickness = 3;

core_lock_angle = 25;
core_lock_d = core_face_diameter-1;

//core_lock_pin_width = 3;
core_lock_pin_width = sin(core_lock_angle) * core_diameter/2;

//core_lock_top_z = wheel2_wheel_z;
core_lock_top_z = wheel2_z + shackle_travel_total - 4*layerHeight;

module core_lock_profile() {
  difference() {
    h = core_lock_pin_width;// + 2*1.2;
    group() {
      hull() {
        translate_x(core_diameter/2) square(h,true);
        translate_x(shackle_x) square(h,true);
      }
      translate_x(shackle_x) circle(d=shackle_diameter+2*1.2);
    }
    circle(d=core_diameter+2*C);
  }
  offset(-C)
  difference() {
    wedge(r=core_diameter/2+3*C, a1=-core_lock_angle/2, a2=+core_lock_angle/2);
    circle(d=core_lock_d);
  }
}
*!core_lock_profile();

module core_lock_pin_slot(a1,a2,h1,h2, simple=false) {
  d = core_face_diameter-1;
  translate_z(core_lock_down_z + h1) {
    difference() {
      linear_extrude(h2-h1 + core_lock_thickness, convexity=2) {
        difference() {
          wedge(r=core_diameter, a1=a1-core_lock_angle/2, a2=a2+core_lock_angle/2, max_steps=4);
          circle(d=core_lock_d);
        }
      }
      if (!simple) {
        cylinder(d1=core_diameter+eps, d2=core_lock_d, h=1);
      }
    }
  }
}

module core_lock(simple=$preview) {
  difference() {
    translate_z(core_lock_down_z + shackle_travel_down)
    difference() {
      group() {
        //linear_extrude() {
        linear_extrude(core_lock_thickness, convexity=3) {
          core_lock_profile();
        }
        translate_x(shackle_x) {
          cylinder(d=shackle_diameter+2*1.2, h=core_lock_top_z - core_lock_down_z - shackle_travel_total);
        }
      }
      if (!simple) {
        translate_z(-eps)
        cylinder(d1=core_diameter+2*C,d2=core_lock_d+2*C,h=1);
      }
    }
    // spring hole
    spring_hole();
    translate_z(core_lock_down_z + shackle_travel_down - eps) {
      translate_x(shackle_x) {
        cylinder(d1=spring_diameter+2*0.6,d2=spring_diameter,h=0.6);
      }
    }
    // screw
  }
}
*!core_lock();

module core_lock_hole() {
  translate_z(core_lock_down_z) {
    linear_extrude(core_lock_thickness + shackle_travel_total + layerHeight) {
      offset(C) core_lock_profile();
    }
    translate_x(shackle_x) {
      cylinder(d=shackle_diameter+2*1.2+2*C, h=wheel2_wheel_z - core_lock_down_z + layerHeight);
    }
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

shackle_left_z  = wheel1_wheel_z; // + wheel_weight_thickness - shackle_travel_up;
//shackle_right_z = housing_thickness + shackle_travel;
//shackle_right_z = wheel2_wheel_z - shackle_travel_up - shackle_travel_open;

shackle_screw_length = roundToLayerHeight(7);
shackle_right_z = core_lock_top_z - shackle_travel_up - shackle_travel_open;

module shackle(threads=false) {
  translate_z(housing_top_z)
  shackle_extrude_z(shackle_x, shackle_length) {
    circle(d = shackle_diameter);
  }
  // cut outs for wheels
  wheel_shackle_hole_clearance = wheel_hole_clearance + C; // clearance for free spinning wheel
  // left
  group() {
    z2 = wheel1_wheel_z + wheel_thickness + 2*layerHeight;
    chamfer = 1;
    difference() {
      translate([-shackle_x,0,shackle_left_z])
        chamfer_cylinder(d = shackle_diameter, h=housing_top_z-shackle_left_z+eps, chamfer_bottom=1);
      // cut-out for wheel1
      translate([wheel1_x,wheel1_y,0])
        cylinder(d = wheel_diameter+2*wheel_shackle_hole_clearance, h=z2+chamfer);
    }
    // chamfer
    translate([-shackle_x,0,z2]) {
      *cylinder(d1=shackle_diameter-2*wheel_shackle_overlap, d2=shackle_diameter, h=chamfer);
      hull() {
        //d = shackle_diameter-2*wheel_shackle_overlap;
        d = 2;
        translate_x((shackle_diameter-d)/2-1) cylinder(d=d,h=eps);
        translate_z(chamfer) cylinder(d=shackle_diameter,h=eps);
      }
    }
  }
  // right
  group() {
    difference() {
      translate([shackle_x,0,shackle_right_z])
        chamfer_cylinder(d = shackle_diameter, h=housing_top_z-shackle_right_z+eps, chamfer_bottom=0);
      chamfer = 3;
      slope = 0.6;
      *translate([wheel2_x,wheel2_y,wheel2_wheel_z - chamfer*slope]) {
        chamfer_cylinder(d = wheel_diameter+2*wheel_shackle_hole_clearance, h=wheel_thickness+3*layerHeight + shackle_travel_down + chamfer*slope, chamfer_bottom=chamfer, chamfer_slope=slope);
      }
    }
    extra = 2;
    h = wheel_thickness - 2*layerHeight;
    translate([shackle_x,0,wheel2_wheel_z-extra]) {
      linear_extrude_cone_chamfer(h+extra, 0,1) {
        wheel_false_gate_profile();
      }
    }
    // screw
    translate([shackle_x,0,shackle_right_z-shackle_screw_length+eps])
    intersection() {
      if(threads) {
        standard_thread(d=shackle_diameter,length=shackle_screw_length);
      } else {
        cylinder(d=shackle_diameter,h=shackle_screw_length);
      }
      chamfer = 1;
      cylinder(d1=shackle_diameter-2*chamfer,d2=shackle_diameter-2*chamfer+lots,h=lots/2);
    }
    // connection to core-lock
    screwdriver_length = 1.5;
    translate([shackle_x,0,shackle_right_z-shackle_screw_length-screwdriver_length+eps])
    linear_extrude(screwdriver_length) {
      screw_slot_profile();
    }
  }
}
*!shackle($fn=30);

module shackle_hole() {
  z1 = shackle_left_z-shackle_travel_down-eps;
  z2 = shackle_right_z-shackle_travel_down;
  translate([-shackle_x,0,z1])
    chamfer_cylinder(d=shackle_diameter+2*C, h=housing_top_z-z1+eps,chamfer_bottom=0,chamfer_top=-0.6);
  translate([shackle_x,0,z2])
    chamfer_cylinder(d=shackle_diameter+2*C, h=housing_top_z-z2+eps,chamfer_bottom=1,chamfer_top=-0.6);
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
// Screw
//-----------------------------------------------------------------------------

module screw_slot_profile() {
  h = 1.5;
  o = 0.25;
  offset(o) {
    *circle(d=1.5,$fn=3);
    rotated([0,120,240]) {
      translate_y(-(h-2*o)/2)
      square([shackle_diameter/2-1.2-o,h-2*o]);
    }
  }
}
*!group() {
  color("pink") cylinder(d=shackle_diameter, h=1);
  translate_z(1) screw_slot_profile();
}

screw_diameter = 6;
module screw(threads=true, internal=false) {
  z1 = housing_thickness;
  z2 = core_top_z - 4*layerHeight;
  z3 = shackle_left_z - shackle_travel_down;
  ht = (shackle_diameter-screw_diameter) / 2;
  
  slot_thickness = 2;
  translate_x(-shackle_x)
  difference() {
    make_screw(screw_diameter, z1, z2, z3, slot_type="none", head_thickness=ht, head_straight_thickness=3, threads=threads, internal=internal);
    if (!internal)
    translate_z(z3-slot_thickness)
    linear_extrude_chamfer_hole(slot_thickness+2*eps,0,0.3,convexity=2) {
      offset(C) screw_slot_profile();
    }
  }
}
*!screw(threads=false);

module screw_hole(threads) {
  screw(threads=threads,internal=true);
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housing_width  = 2*(shackle_x + shackle_diameter/2 + housing_wall);
housing_height = max(shackle_diameter,wheel_diameter,core_diameter) + 2*housing_wall;

housing_chamfer = 1;
echo("housing size = ", housing_width,housing_height,housing_top_z);

module housing_profile() {
  *square([housing_width,housing_height],true);
  d = max(shackle_diameter,wheel_diameter,core_diameter);
  *hull() mirrored([1,0,0]) {
    translate_x(shackle_x) circle(d=d+2*housing_wall);
  }
  hull() {
    //circle(d=core_diameter+2*(2*housing_wall+2*C));
    mirrored([1,0,0]) {
      translate_x(shackle_x) circle(d=shackle_diameter+2*housing_wall);
      dx = housing_wall+C;
      translate_x(shackle_x - (wheel_diameter - shackle_diameter)/2 + dx) circle(d=wheel_diameter+2*housing_wall+2*C);
    }
  }
}

module wheel_shared_hole() {
  translate_z(wheel1_z - 1*layerHeight) {
    /*
    linear_extrude(wheel_weight_thickness - wheel_thickness + 3*layerHeight, convexity=2) {
      difference() {
        hull() {
          //d = wheel_weight_diameter+2*wheel_hole_clearance;
          d = wheel_weight_diameter-1.2;
          translate([wheel1_x,wheel1_y]) circle(d=d);
          translate([wheel2_x,wheel2_y]) circle(d=d);
        }
        d2 = wheel_weight_diameter;
        translate([wheel1_x,wheel1_y]) circle(d=d2);
        translate([wheel2_x,wheel2_y]) circle(d=d2);
      }
    }
    */
    linear_extrude(wheel_weight_thickness + 4*layerHeight, convexity=2) {
      square([wheel_diameter*0.5,wheel_diameter*0.6],true);
    }
  }
}

spring_diameter = 4.5;
spring_length = 10;
module spring_hole() {
  translate_x(shackle_x)
  translate_z(housing_thickness)
  cylinder(d=spring_diameter+2*C, h=spring_length+shackle_travel_down);
}
module spring(dz=0) {
  d = spring_diameter * sqrt(spring_length/(spring_length+dz));
  translate_x(shackle_x)
  translate_z(housing_thickness)
  cylinder(d=d, h=spring_length+shackle_travel_down+dz);
}

module housing(threads) {
  difference() {
    linear_extrude_cone_chamfer(housing_top_z, housing_chamfer, housing_chamfer) {
      housing_profile();
    }
    core_hole();
    core_lock_hole();
    wheel2_hole();
    wheel1_hole();
    wheel_shared_hole();
    shackle_hole();
    screw_hole(threads=threads);
    toy_key_hole();
    spring_hole();
  }
}

module housing_inner_mask(offset=0) {
  housing_split_z = wheel1_wheel_z-2*layerHeight;
  translate_z(-eps)
  linear_extrude(housing_inner_split_z+eps, convexity=2) {
    offset(offset-C) {
      dx = housing_wall+C;
      hull() {
        translate([wheel1_x,wheel1_y]) circle(d=wheel_diameter+2*wheel_hole_clearance);
        translate([wheel2_x,wheel2_y]) circle(d=wheel_diameter+2*wheel_hole_clearance);
        translate_x(-shackle_x+(wheel_diameter+2*wheel_hole_clearance - (shackle_diameter+2*housing_wall+2*C))/2) circle(d=wheel_diameter+2*wheel_hole_clearance);
        
        *translate_x(-(shackle_x - (wheel_diameter - shackle_diameter - dx)/2)) circle(d=wheel_diameter+2*housing_wall+2*C);
        //translate_x(shackle_x-wheel_diameter/2-shackle_diameter/2-1.2) circle(d=wheel_diameter+2*housing_wall+2*C);
        *translate_x(shackle_x-wheel_diameter/2-spring_diameter/2) circle(d=wheel_diameter+2*housing_wall+2*C);
      }
    }
  }
  translate_z(housing_inner_split_z-eps) {
    linear_extrude(housing_split_z-housing_inner_split_z+2*eps, convexity=2) {
      offset(offset-C) {
        square([wheel_diameter*0.2,wheel_diameter*0.7+2*housing_wall],true);
        *translate([wheel1_x,wheel1_y]) circle(d=wheel_diameter+2*wheel_hole_clearance);
        *translate([wheel2_x,wheel2_y]) circle(d=wheel_diameter+2*wheel_hole_clearance);
        fillet(3) {
          translate([wheel1_x,wheel1_y]) square([wheel_weight_diameter+2*wheel_hole_clearance,wheel_diameter+2*wheel_hole_clearance],true);
          *translate([wheel2_x,wheel2_y]) square([wheel_weight_diameter+2*wheel_hole_clearance,wheel_diameter+2*wheel_hole_clearance],true);
        }
      }
    }
    linear_extrude(wheel2_wheel_z-1*layerHeight-housing_inner_split_z+2*eps, convexity=2) {
      offset(offset-C) {
        fillet(3) {
          translate([wheel2_x,wheel2_y]) square([wheel_weight_diameter+2*wheel_hole_clearance,wheel_diameter+2*wheel_hole_clearance],true);
        }
      }
    }
  }
  translate_z(housing_inner_split_z-eps)
  linear_extrude(wheel1_z-housing_inner_split_z+2*eps, convexity=2) {
    hull() {
      translate_x(-shackle_x)
        circle(d=shackle_diameter+2*housing_wall+2*offset);
      translate([wheel1_x,wheel1_y])
        circle(d=shackle_diameter+2*housing_wall+2*offset);
    }
  }
}

housing_inner_split_z = core_top_z+layerHeight;

module housing_outer() {
  difference() {
    housing(threads=false);
    housing_inner_mask(offset=C);
  }
}
*!housing_inner1($fn=30);
*!housing_inner2($fn=30);

module housing_inner1(threads) {
  intersection() {
    difference() {
      housing(threads=threads);
      toy_key_removal_hole();
    }
    housing_inner_mask();
    translate_z(housing_inner_split_z-eps) negative_z();
  }
}

module housing_inner2() {
  intersection() {
    housing(threads=false);
    housing_inner_mask();
    translate_z(housing_inner_split_z+eps) positive_z();
  }
}

//-----------------------------------------------------------------------------
// Test
//-----------------------------------------------------------------------------

module test_housing_profile() {
  difference() {
    translate([-0.5+2,3.5])
    square([wheel_diameter+6+6,12],true);
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
  translate_z(wheel_thickness+4*layerHeight) positive_z();
  translate_z(wheel_thickness+4*layerHeight - 0.9) linear_extrude(0.9+eps, convexity=5) {
    difference() {
      offset(0.3+offset) {
        offset(-1.2-0.3) difference() {
          test_housing_profile();
          circle(d=wheel_diameter+2*C);
        }
        *translate_x(8) positive_x2d();
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
  
  *color("yellow") assembly_cut(11) test_housing1();
  color("lightyellow") assembly_cut(12) test_housing2();
}
*!test_assembly();

module export_test_housing1() { rotate([180]) test_housing1(); }
module export_test_housing2() { test_housing2(); }
module export_test_wheel() { wheel(); }
module export_test_shackle() { rotate([180]) test_shackle(); }

module export_shackle_screw_test1() {
  cylinder(d=shackle_diameter,h=8);
  thread_diameter = shackle_diameter-3;
  translate_z(8)
  intersection() {
    l=4;
    standard_thread(d=thread_diameter,length=l,internal=false,C=0);
    cylinder(d1=thread_diameter-2+2*3,d2=thread_diameter-2,h=l);
  }
}
module export_shackle_screw_test2() {
  thread_diameter = shackle_diameter-3;
  translate_z(8) difference() {
    cylinder(d=shackle_diameter,h=8);
    standard_thread(d=thread_diameter,length=5,internal=true,C=C);
  }
}

*!group() {
  color("red") assembly_cut(1,true) export_shackle_screw_test1();
  color("blue") assembly_cut(2,true) export_shackle_screw_test2();
}

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
  threads = false;
  //shackle_pos = -shackle_travel_down;
  //shackle_pos = 0;
  //shackle_pos = shackle_travel_up;
  shackle_pos = shackle_travel_up + shackle_travel_open;
  /**/
  color("red") assembly_cut(1) core();
  
  color("purple") assembly_cut(5) translate_z(0.5*layerHeight) wheel1(angle=45/2);
  color("violet") assembly_cut(6) pin1();
  color("blue") assembly_cut(3) translate_z(0.5*layerHeight) wheel2(angle=0);
  color("violet") assembly_cut(4) pin2();
    
  color("green") assembly_cut(7,true) translate_z(shackle_pos) core_lock();

  color("pink") assembly_cut(12) translate_z(shackle_pos) shackle(threads=threads);
  
  
  color("yellow") assembly_cut(11,true) housing_outer();
  color("lightYellow") assembly_cut(10,true) housing_inner1(threads=threads);
  color("Khaki") assembly_cut(9,true) housing_inner2();
  
  color("teal") assembly_cut(13) screw(threads=threads);
  
  color("orange") assembly_cut(15) toy_key();
  color("cyan") assembly_cut(16) spring(shackle_pos);
}
assembly();
