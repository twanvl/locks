include <../util.scad>;

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

C = 0.15;

core_diameter = 10;
core_bottom_thickness = 1.2;

pin_diameter = 3;

pin_spacing = roundToLayerHeight(4.3);

keypin_thickness = 3;
ringpin_extra_thickness = roundToLayerHeight(1.2);

spring_type = "coil";
driverpin_extra_thickness = roundToLayerHeight(spring_type == "coil" ? 4 : 7);
spring_thickness = spring_type == "coil" ? 6.5 : 0;

key_thickness = roundToLayerHeight(2);
key_half_thickness = roundToLayerHeight(1.1);

housing_wall = 1.2;
//housing_angle = 8;
housing_angle = 7;

bit_thickness = 0.6;
//max_pin_travel = 3;
max_pin_travel = 4*bit_thickness;

bitting = [3,2,4,0,1];

core_rotation = 45;
ring_rotation = 90;

//-----------------------------------------------------------------------------
// Computed parameters
//-----------------------------------------------------------------------------

max_bits = max_pin_travel / bit_thickness;

ring_diameter_diag = core_diameter + 2*(0 + max_pin_travel + ringpin_extra_thickness);
ring_diameter = diagonal(ring_diameter_diag/2, pin_diameter/2)*2 - 0.3*C;
//ring_diameter = ring_diameter_diag - 0.0*C;
echo(ring_diameter = ring_diameter);

key_circle_diameter = ring_diameter - 3;

key_x0 = -key_circle_diameter/2;
//key_x1 = core_diameter/2 - keypin_thickness;
key_x1 = side_given_diagonal(core_diameter/2,pin_diameter/2) + 0*C - keypin_thickness;

pin0_z = core_bottom_thickness + pin_diameter/2 + 1.0;
function pin_z(i) = i * pin_spacing + pin0_z;
core_back_thickness = roundToLayerHeight(1.5);
core_thickness = len(bitting) * pin_spacing + core_back_thickness;

core_back_z = core_bottom_thickness + core_thickness;
ring_bottom_thickness = roundToLayerHeight(2);
ring_back_z = roundToLayerHeight(core_back_z + ring_bottom_thickness);
ring_limiter_thickness = roundToLayerHeight(2);
ring_limiter_z = ring_back_z - ring_limiter_thickness;

//housing_bottom_thickness = 1.2;
housing_bottom_thickness = roundToLayerHeight(1);
housing_bottom_z = -housing_bottom_thickness;

housing_lid_thickness = roundToLayerHeight(1.2 + layerHeight);
screw_cover_thickness = roundToLayerHeight(1.3);

housing_back_z = ring_back_z + layerHeight;
//housing_back_z = ring_back_z - roundToLayerHeight(0);
housing_end_z  = housing_back_z + housing_lid_thickness + screw_cover_thickness;
housing_thickness = housing_end_z - housing_bottom_z;

screw_diameter = 6;
screw_slot_diameter = 4;
screw_head_thickness = roundToLayerHeight(1.5);
screw_head_diameter = screw_diameter + 2*screw_head_thickness;

screw_y = (screw_diameter/2 + pin_diameter/2 + 1.2);
screw_x = ring_diameter/2 + C + housing_wall + screw_diameter/2 + 2;
//screw_z2 = ring_back_z;
screw_z2 = ring_back_z;
screw_z1 = roundToLayerHeight(screw_z2 - 3);
screw_z0 = max(0, screw_z1 - 10);

module rotate_around(x,a) {
  translate(x) rotate(a) translate(-x) children();
}

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

key_extra_x = 1.6;

module key_profile(base = false, extra_x = 0, bridge_clearance=0) {
  x0 = key_x0;
  x1 = key_x1;
  dl = 0.6;
  dr = 0.7 * (1 + bridge_clearance);
  xla = x0 + 1.5;
  xlb = x0 + 3.5;
  xlc = x1 - max_pin_travel + 1.0;
  xra = xlb-dl + 0.3;
  xrb = xlc - 0.3;
  h = key_thickness;
  y = 0;
  y0 = y-h/2;
  y2 = y+h/2;
  y1r = y2 - key_half_thickness;
  y1l = y1r - bridge_clearance;//y0 + key_half_thickness;
  intersection() {
    //rotate_around([x0,0], -3)
    if (base) {
      polygon([[x0,y2],[x1+extra_x,y2], [x1+extra_x,y0],[x0,y0]]);
    } else {
      polygon([
        [x0,y2],[xra,y2],[xra+dr,y1l],[xrb-dr,y1l],[xrb,y2],[x1+extra_x,y2],
        [x1+extra_x,y1r],[xlc,y1r],[xlc-dl,y0],[xlb,y0],[xlb-dl,y1r],[xla+0,y1r],[xla,y0],[x0,y0]]);
    }
    group() {
      intersection() {
        circle(d = key_circle_diameter);
        negative_x2d();
      }
      circle(r = key_x1 + key_extra_x);
    }
  }
}
*!key_profile(extra_x = key_extra_x);
module key_approx_profile() {
  hull() {
    key_profile(base = true, extra_x=key_extra_x);
  }
}
*!key_approx_profile();

module key_rotation_profile() {
  if (1) {
    max_angle = core_rotation+ring_rotation;
    steps = 10;
    fillet(-0.5)
    for (i=[0:steps]) {
      rotate(i*max_angle/steps) key_approx_profile();
    }
  } else {
    circle(d = key_circle_diameter);
  }
}
module key_hole_rotation_profile() {
  offset(C) key_rotation_profile();
}
*!key_hole_rotation_profile();


module key_hole_profile() {
  offset(C) key_profile();
}

module key_cut() {
  translate_x(key_x1 + pin_diameter/2) hull() {
    for (pos = [[0,0,0],[5,0,-5],[5,0,5]]) {
      translate(pos) minkowski() {
        sphere(d = pin_diameter, $fn=30);
        cube([eps,0.5,0.2],center=true);
      }
    }
    *linear_extrude_y(key_thickness+1,center=true, convexity=4) hull() {
      *circle(d = pin_diameter);
      square([eps,pin_diameter], center=true);
      translate_x(3) square([eps,pin_diameter + 2*3], center=true);
    }
  }
}
module key(narrow = true) {
  key_top_z = core_back_z - 1*layerHeight;
  key_chamfer = 1;
  bridge_clearance = 1*layerHeight;
  difference() {
    dz = 4;
    translate_z(-dz)
    linear_extrude(key_top_z + dz, convexity=6) {
      key_profile(bridge_clearance = bridge_clearance);
    }
    for (i=[0:len(bitting)-1]) {
      translate([-bitting[i]*bit_thickness,0,pin_z(i)]) {
        key_cut();
      }
    }
    linear_extrude_y(lots,center=true) {
      y = key_top_z;
      translate_x((key_x0+key_x1)/2 - 0)
      sym_polygon_x([[0,y+2.5],[-100,y-100],[-100,y+100]]);
    }
  }
  // handle
  h1 = 4;
  key_x2 = key_x1 + key_extra_x;
  translate_z(-h1) {
    linear_extrude(h1+eps) {
      key_profile(bridge_clearance = bridge_clearance, extra_x = key_x2 - key_x1);
    }
    intersection() {
      linear_extrude_x(lots, center=true) {
        translate_x(-layerHeight/2) sym_polygon_x([[0,h1],[lots,h1-lots]]);
      }
      linear_extrude(h1+eps) {
        key_approx_profile();
        *translate_x((key_x2+key_x0)/2) intersection() {
          square([key_x2 - key_x0, key_thickness],center=true);
          circle(d = key_x2 - key_x0);
        }
      }
    }
  }
  intersection() {
    linear_extrude_y(key_thickness, center=true) {
      *translate([0, -11]) {
        difference() {
          fillet(2) intersection() {
            circle(d = 20);
            square([-2*key_x0,20],center=true);
          }
          translate_y(-5) circle(d = 5);
        }
      }
      translate([(key_x0+key_x2)/2, -11]) {
        difference() {
          fillet(2) intersection() {
            circle(d = 20);
            if (narrow) square([key_x2-key_x0,20],center=true);
          }
          translate_y(-5) circle(d = 5);
        }
      }
    }
    if (narrow) {
      linear_extrude(lots,center=true) {
        key_approx_profile();
      }
    }
  }
}
*!key();

module export_key() { rotate([-90]) key(); }
module export_key_wide() { rotate([-90]) key(narrow=false); }
*!export_key();

//-----------------------------------------------------------------------------
// Pins
//-----------------------------------------------------------------------------

module pin_profile() {
  circle(d = pin_diameter);
}

module pin_hole_profile() {
  *circle(d = pin_diameter + 2*C);
  semi_teardrop(r = pin_diameter/2 + C, cutoff = 2*layerHeight);
}
module pin_hole(extra = 0) {
  pin_x = key_x1 - max_pin_travel;
  x2 = ring_diameter/2 + driverpin_extra_thickness + max_pin_travel + extra;
  hull() {
    translate_x(pin_x + pin_diameter/2+C)
    sphere(d = pin_diameter + 2*C, $fn = 30);
    translate_x(pin_x + pin_diameter/2+C)
    linear_extrude_x(x2 - (pin_x + pin_diameter/2+C)) {
      pin_hole_profile();
    }
  }
}
module pin_holes(flip = false, extra = 0) {
  for (i=[0:len(bitting)-1]) translate_z(pin_z(i)) {
    rotate(flip ? [180] : 0) pin_hole(extra = extra);
  }
}

// pins for printing

function long_ring_pin(i) = i == len(bitting)-1;

module pin(length) {
  linear_extrude(length) {
    circle(d = pin_diameter);
  }
}
module export_pins() {
  step = pin_diameter + 1.5;
  for (i=[0:len(bitting)-1]) {
    bit = bitting[i];
    long = long_ring_pin(i);
    translate_x(i * step) {
      // wafer pins
      for (j=[0:max_bits-1 - (long?1:0)]) {
        translate_y(j * step)
        pin(bit_thickness);
      }
      // ring pin
      translate_y(max_bits * step)
      pin(ringpin_extra_thickness + bit*bit_thickness + (long?bit_thickness:0));
      // driver pin
      translate_y((max_bits+1) * step)
      pin(driverpin_extra_thickness + (max_bits-bit)*bit_thickness) circle(d = pin_diameter);
    }
  }
}
*!export_pins();

// pins in position

module key_pin(pos = 0, long = false, extra_step=0) {
  pin_x = key_x1 - pos * bit_thickness;
  translate_x(pin_x + pin_diameter/2) {
    sphere(d = pin_diameter, $fn = 30);
  }
  if (pos > 0) translate_x(pin_x + pin_diameter) {
    for (i=[0:(long&&pos==max_bits-1 ? max_bits-2 : pos-1)]) {
      translate_x(i * (bit_thickness + extra_step) + 0.03)
      linear_extrude_x(bit_thickness - 0.03) {
        circle(d = pin_diameter);
      }
    }
  }
}
module ring_pin(pos, bit = 0, long = false, extra_step=0) {
  translate_x(core_diameter/2) {
    if (max_bits - (long?1:0) > pos) for (i=[0:max_bits-pos-1 - (long?1:0)]) {
      translate_x(i * (bit_thickness + extra_step))
      linear_extrude_x(bit_thickness - 0.03) {
        circle(d = pin_diameter);
      }
    }
    translate_x((max_bits-pos) * bit_thickness - (long?bit_thickness:0) + (max_bits-pos - (long?1:0))*extra_step)
    linear_extrude_x(ringpin_extra_thickness + bit*bit_thickness + (long?bit_thickness:0)) {
      circle(d = pin_diameter);
    }
  }
}
module driver_pin(pos, bit = 0) {
  translate_x(ring_diameter/2 + (bit-pos)*bit_thickness) {
    linear_extrude_x(driverpin_extra_thickness + (max_bits-bit)*bit_thickness) {
      circle(d = pin_diameter);
    }
  }
}

//-----------------------------------------------------------------------------
// Core/ring connecting Pin
//-----------------------------------------------------------------------------

//core_ring_pin_angle = 110;
core_ring_pin_angle = -45;
core_ring_pin_height = 3;
core_ring_pin_travel = 1;
core_ring_pin_thickness = 3;
//core_ring_pin_z = (pin_z(0) + pin_z(1)) / 2 - core_ring_pin_thickness/2;
core_ring_pin_z = pin_z(len(bitting)-1.5) - core_ring_pin_thickness/2;
echo(core_ring_pin_z=core_ring_pin_z);

module core_ring_pin_profile(pos = 0, hole = false) {
  x1 = core_diameter/2 // side_given_diagonal(core_diameter/2, core_ring_pin_height/2)
     - (hole ? core_ring_pin_travel : pos*core_ring_pin_travel);
  x2 = ring_diameter/2 + 0.1 //side_given_diagonal(ring_diameter/2, core_ring_pin_height/2 - 1)
     + (hole ? core_ring_pin_travel : (1-pos)*core_ring_pin_travel);
  rotate(core_ring_pin_angle)
  translate_x((x2+x1)/2)
  chamfer_rect(x2-x1, core_ring_pin_height, 1);
}
module core_ring_pin_hole_profile() {
  offset(delta=C) core_ring_pin_profile(hole = true);
}
module core_ring_pin(pos=1) {
  translate_z(core_ring_pin_z)
  linear_extrude(core_ring_pin_thickness) {
    core_ring_pin_profile(pos=pos);
  }
}

module core_ring_pin_hole(flip = false, large = false) {
  larger = large ? 0.6 : 0;
  translate_z(core_ring_pin_z - layerHeight - (flip ? layerHeight : 0) - larger/2)
  linear_extrude(core_ring_pin_thickness + 3*layerHeight + larger) {
    core_ring_pin_hole_profile();
  }
}

module export_core_ring_pin() { core_ring_pin(); }

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

core_key_width = key_thickness + 2*2;
module core_profile(holes = true) {
  difference() {
    group() {
      circle(d = core_diameter);
      intersection() {
        circle(d = ring_diameter);
        translate_x(-lots/2) square([lots,core_key_width],true);
      }
      *rotate(180) wedge(60, r=ring_diameter/2, center=true);
    }
    if (holes) key_hole_profile();
  }
}

module core_hole_profile(rotation = core_rotation) {
  if (0) {
    offset(C) {
      steps = 3;
      for (i=[0:steps]) {
        rotate(rotation*i/steps) core_profile(holes = false);
      }
    }
  } else {
    circle(d = core_diameter + 2*C);
    offset(core_key_width/2 + 0.1*C)
    rotate(180) wedge(rotation, r=ring_diameter/2, center=false);
  }
}

module core() {
  difference() {
    group() {
      linear_extrude(core_bottom_thickness, convexity=3) {
        difference() {
          intersection() {
            ring_profile(holes = false);
            rotate(-core_rotation) ring_profile(holes = false);
          }
          key_hole_profile();
        }
      }
      translate_z(core_bottom_thickness - eps)
      linear_extrude(core_thickness + eps, convexity=3) {
        core_profile();
      }
    }
    pin_holes();
    rotate(-core_rotation) core_ring_pin_hole(large=true);
  }
}
*!core();

module ring_hole_profile() {
  if (ring_limiter_inside) {
    circle(d = ring_diameter - 2*ring_limiter_width + 2*C);
    rotate(ring_limiter_rot + ring_rotation)
    wedge(r = ring_diameter / 2 + C, a1 = ring_limiter_angle, a2 = 360);
  } else {
    circle(d = ring_diameter + 2*C);
  }
}
module ring_hole() {
  linear_extrude(ring_back_z + layerHeight) {
    ring_hole_profile();
  }
  if (!ring_limiter_inside)
  translate_z(ring_limiter_z)
  linear_extrude(ring_limiter_thickness + layerHeight, convexity=2) {
    difference() {
      rotate(ring_limiter_rot2)
      wedge(r = ring_diameter/2 + ring_limiter_width2 + C, ring_limiter_angle2 + ring_rotation, center = true);
      circle(d = ring_diameter);
    }
  }
}

ring_limiter_angle = 20;
ring_limiter_rot = 20;
ring_limiter_width = 1;
ring_limiter_inside = false;
module ring_profile(holes = true) {
  difference() {
    group() {
      if (ring_limiter_inside) {
        circle(d = ring_diameter - 2*ring_limiter_width);
        rotate(ring_limiter_rot)
        wedge(r = ring_diameter / 2, a1 =  ring_limiter_angle + ring_rotation, a2 = 360);
      } else {
        circle(d = ring_diameter);
      }
    }
    if (holes) core_hole_profile();
  }
}
*!ring_profile();

//ring_limiter_thickness = 1.2;
ring_limiter_angle2 = 30;
ring_limiter_width2 = 1.2;
ring_limiter_rot2 = housing_angle;
module ring() {
  difference() {
    group() {
      translate_z(core_bottom_thickness)
      linear_extrude(core_thickness + ring_bottom_thickness, convexity=3) {
        ring_profile();
      }
      translate_z(core_back_z)
      linear_extrude(ring_bottom_thickness) {
        difference() {
          circle(d = ring_diameter);
          *circle(d = core_diameter + 1);
        }
      }
      if (!ring_limiter_inside)
      translate_z(ring_limiter_z)
      linear_extrude(ring_limiter_thickness) {
        difference() {
          rotate(-ring_rotation/2 + ring_limiter_rot2)
          wedge(r = ring_diameter/2 + ring_limiter_width2, ring_limiter_angle2, center = true);
          circle(d = ring_diameter);
        }
      }
    }
    pin_holes(flip = true);
    core_ring_pin_hole(flip = true);
    translate_z(eps) screw_cover_hole();
  }
}
*!ring();

module export_core() { core(); }
module export_ring() { rotate([180]) ring(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housing_diameter = ring_diameter + 2*C + 2*housing_wall;

housing_max_x = ring_diameter/2 + driverpin_extra_thickness + max_pin_travel + spring_thickness + 0*housing_wall;
housing_width = (housing_max_x+2) / cos(housing_angle) + housing_diameter/2;

module housing_outer_profile() {
  *circle(d = housing_diameter);
  //fillet(-1) fillet(1) { fillet(2 + 4)
  fillet(6) {
    //hull() {
    group() {
      circle(d = housing_diameter);
      *rotate(ring_limiter_rot) translate_x(1) circle(d = housing_diameter);
      *rotate(core_ring_pin_angle) translate_x(1) circle(d = housing_diameter);
      
      *rotate(-25) translate_x(10) circle(d = housing_diameter);
      
      *rotate(0) {
        translate_y(1) circle(d = housing_diameter);
        translate([21,1/2]) square([1,housing_diameter+1],true);
      }
      rotate(housing_angle) {
        *translate_y(1) circle(d = housing_diameter);
        *translate([25,1/2]) square([1,housing_diameter+1],true);
        *translate([(housing_max_x+2) / cos(housing_angle),1/2]) square([eps,housing_diameter],true);
        translate([-housing_diameter/2, -housing_diameter/2])
          square([housing_width, housing_diameter]);
      }
      *translate([ring_diameter/2 + 9/2, 5]) circle(d = 9);
      offset(housing_wall+C) {
        core_ring_pin_hole_profile();
      }
    }
    *hull() {
      translated([[0,0], [housing_max_x - 2,0]])
      circle(d = pin_diameter+2*housing_wall);
    }
    *if (spring_type == "coil")
    translated([[0,0], [housing_max_x + 0.5,0]])
    scale([1,1]) {
      *circle(d = pin_diameter+2*housing_wall);
      square([3, pin_diameter+2*housing_wall + 2], center=true);
    }
  }
}

module spring_hole_profile() {
  h = 15;
  x = ring_diameter/2 + driverpin_extra_thickness - 0.0;
  spring_thickness = 2*layerHeight;
  if (0) {
    offset(C)
    translate_x(x) {
      square([spring_thickness,h], center=true);
      hull() {
        square([eps,h-2], center=true);
        translate_x(max_pin_travel) circle(d=pin_diameter+2*spring_thickness);
      }
    }
  } else if (0) {
    // printed cantilever springs
    l = 13;
    offset(C)
    translate([x, -pin_diameter/2]) {
      square([spring_thickness,l]);
    }
  } else {
    // coil springs
  }
}
spring_width = 2;
module spring_holes() {
  #linear_extrude(housing_thickness,center=true) {
    spring_hole_profile();
  }
}

module housing(threads=true, deep_screw=false, pins_extra=0) {
  housing_chamfer = roundToLayerHeight(1);
  difference() {
    translate_z(-housing_bottom_thickness)
    //linear_extrude(housing_thickness, convexity=10) {
    linear_extrude_cone_chamfer(housing_thickness, housing_chamfer, housing_chamfer, convexity=2) {
      housing_outer_profile();
    }
    holes_in_housing(threads=threads, deep_screw=deep_screw, pins_extra=pins_extra);
  }
}
*!housing(threads=false);

module holes_in_housing(threads=true, deep_screw=false, pins_extra=0) {
  pin_holes(extra = spring_thickness + pins_extra);
  ring_hole();
  spring_holes();
  screw_holes(deep=deep_screw, threads=threads);
  screw_access_hole();
  screw_cover_hole();
  core_ring_pin_hole(large = true);
  translate_z(-housing_bottom_thickness-eps)
  linear_extrude(housing_bottom_thickness + 2*eps) {
    key_hole_rotation_profile();
  }
}
*!holes_in_housing(threads=false);

module housing_cover_mask_profile() {
  x1 = ring_diameter/2 + driverpin_extra_thickness + max_pin_travel + spring_thickness;
  x2 = x1 + 0.6;
  l = 0.85;
  y1 = (pin_diameter/2 + 1 + abs(x1 * sin(housing_angle)));
  y2 = y1 - l;
  rotate(housing_angle) {
    sym_polygon_y([[x1,y1],[x2,y1],[x2+l,y2],[x1+lots,y2]]);
  }
}
module housing_cover_mask(offset) {
  translate_z(roundToLayerHeight(pin_z(0)-pin_diameter/2-1))
  linear_extrude(lots, convexity=2) {
    offset(offset) housing_cover_mask_profile();
  }
}
module housing_back_mask(offset, simple=false) {
  *translate([screw_x, screw_y, screw_z1]) linear_extrude(lots) {
    circle(d = screw_diameter + 2*(screw_head_thickness + 1.5 + C));
  }
  difference() {
    group() {
      translate_z(housing_back_z) positive_z();
      translate_z(screw_z1) linear_extrude(lots, convexity=2) {
        offset(offset)
        rotate(housing_angle) {
          //h = housing_diameter - 2.2;
          h = housing_diameter - 2*1.2;
          fillet(-2) difference() {
            //translate_x(ring_diameter/2) positive_x2d();
            translate_x(housing_width/2-ring_diameter/2) positive_x2d();
            square([2*(screw_x-screw_diameter/2-screw_head_thickness/2-C), housing_diameter-2*(1.4+C)],center=true);
            *circle(d=ring_diameter + 7);
          }
          //translate_x(ring_diameter/2 + 2) positive_x2d();
          *translate_x(screw_x) positive_x2d();
          //translate([ring_diameter/2 + 1.3,-h/2]) square([lots,h]);
          *translate([screw_x - 1,-h/2]) square([lots,h]);
        }
      }
      // registration pins
      *if (!simple)
      translate_z(screw_z2 - 1.5) linear_extrude(lots, convexity=2) {
        offset(offset) {
          rotate(housing_angle) {
            w = 1.5;
            difference() {
              translate_x(housing_width/2-ring_diameter/2 + w/2) square([w, lots],true);
              square([lots, housing_diameter-2*(1.2+C)-2],center=true);
            }
          }
        }
      }
    }
    // registration pins
    if (!simple)
    translate_z(screw_z1-eps) linear_extrude(roundToLayerHeight(1), convexity=2) {
      offset(-offset) {
        translate([screw_x+1,-screw_y+1.1]) circle(d=3.5);
      }
    }
    // registration pins
    if (!simple)
    translate_z(housing_back_z-eps) linear_extrude(roundToLayerHeight(1), convexity=2) {
      offset(-offset) fillet(0.8) difference() {
        offset(-1.2) housing_outer_profile();
        circle(d=ring_diameter);
        positive_x2d();
      }
    }
    // clearance for driver pins
    if (!simple)
    intersection() {
      translate_z(pin_z(len(bitting)-1)) linear_extrude_x(housing_width-ring_diameter/2) {
        *circle(d = pin_diameter + 2*(C+1.5) - 2*offset);
        semi_teardrop(r = pin_diameter/2 + 1.3 - offset);
      }
      linear_extrude(lots) {
        offset(-1.5-offset) housing_outer_profile();
      }
    }
  }
}

module housing_main(threads=true) {
  difference() {
    housing(threads=threads, deep_screw=true, pins_extra=1);
    housing_cover_mask(offset=C);
    translate_z(-eps) housing_back_mask(offset=C);
  }
}
module housing_cover() {
  // cover for pins
  intersection() {
    difference() {
      linear_extrude(lots) housing_outer_profile();
      housing_back_mask(offset=C, simple=true);
    }
    housing_cover_mask(offset=0);
  }
}
*!housing_cover();
module housing_back() {
  intersection() {
    difference() {
      housing(threads=false);
      translate_z(roundToLayerHeight(0.5)) minkowski(convexity=3) {
        screw_holes(threads=false);
        //rotate(housing_angle)
        w = 7;
        rotate(housing_angle + 15)
        //rotate(45)
        translate_x(-w/2) cube([w,eps,eps],true);
      }
    }
    translate_z(eps) housing_back_mask(offset=0);
  }
}
*!housing_back($fn=30);

module export_housing() { housing_main(); }
module export_housing_cover() { rotate([0,-90]) rotate(-housing_angle) housing_cover(); }
module export_housing_back() { rotate([0,180]) housing_back(); }
*!export_housing_back();
*!export_housing_cover();

/*module housing_lid() {
  translate_z(screw_z2) {
    linear_extrude(housing_lid_thickness) {
      housing_outer_profile();
    }
  }
}*/

//-----------------------------------------------------------------------------
// Screw cover
//-----------------------------------------------------------------------------

cover_top_z = screw_z2 + screw_cover_thickness;

screw_cover_pin_thickness = 1.2;
screw_cover_pin_diameter = 5;
//screw_cover_diameter = screw_head_diameter - 2;
screw_cover_diameter = 7;
//screw_cover_travel = screw_cover_diameter;
screw_cover_travel = screw_cover_diameter/2 + screw_head_diameter/2 + C;
// screw cover travels by t=screw_cover_travel when rotating ring by ring_rotation
cover_pin_radius = screw_cover_travel / (2 * cos(ring_rotation/2));
cover_pin_dist = side_given_diagonal(cover_pin_radius, screw_cover_travel/2);
cover_pin_d_angle = atan2(norm([screw_x,screw_y]), cover_pin_dist) - ring_rotation/2;
cover_pin_pos = rot(cover_pin_d_angle, cover_pin_radius * normalize([screw_x,screw_y]));
    
module screw_cover_profile(pos=0) {
  h = (cos((pos-0.5)*ring_rotation) - cos(ring_rotation/2)) * cover_pin_radius;
  l = side_given_diagonal(norm([screw_x,screw_y]), cover_pin_dist) - screw_cover_travel/2;
  a = acos(h/l);
  
  angle = -pos*ring_rotation + a-90;
  
  rotate(pos * ring_rotation)
  rotate_around(cover_pin_pos, angle)
  group() {
    hull() {
      translate([screw_x,screw_y]) circle(d=screw_cover_diameter);
      translate(cover_pin_pos) circle(d=screw_cover_pin_diameter);
    }
  }
}
module screw_cover_hole_profile() {
  offset(C) hull() {
    for (i=[0:0.05:1+eps]) {
      screw_cover_profile(pos=i);
    }
  }
}

module screw_cover(pos=1) {
  translate_z(screw_z2)
  linear_extrude(screw_cover_thickness) {
    screw_cover_profile(pos=pos);
  }
  translate_z(screw_z2 - screw_cover_pin_thickness)
  linear_extrude(screw_cover_pin_thickness+eps) {
    rotate(pos * ring_rotation)
    translate(cover_pin_pos) circle(d=screw_cover_pin_diameter);
  }
}

module screw_cover_hole() {
  translate_z(screw_z2)
  linear_extrude(screw_cover_thickness + layerHeight) {
    screw_cover_hole_profile();
  }
  translate_z(screw_z2 - screw_cover_pin_thickness - 3*layerHeight)
  linear_extrude(screw_cover_pin_thickness+eps+3*layerHeight) {
    offset(C)
    translate(cover_pin_pos) circle(d=screw_cover_pin_diameter);
  }
}

module export_screw_cover() { rotate([0,180]) screw_cover(); }

*!group() {
  color("red") screw_cover(pos=0);
  translate_z(1.5/2) color("purple") screw_cover(pos=0.5);
  translate_z(1.5) color("green") screw_cover(pos=1);
  *translate_z(screw_z2-0) color("yellow") linear_extrude(1) screw_cover_hole_profile();
  color("blue") screw(threads=false);
  color("lightgreen") ring();
}

//-----------------------------------------------------------------------------
// Screws
//-----------------------------------------------------------------------------

//housing_screw_locations = [[housing_screw_x, housing_screw_y], [housing_screw_x, -housing_screw_y]];

module screw(threads=true, hole=false, deep=false) {
  translate([screw_x, screw_y])
  make_screw(screw_diameter, screw_z0,screw_z1,screw_z2, slot_diameter=screw_slot_diameter,slot_depth=2, head_thickness=screw_head_thickness, head_straight_thickness=roundToLayerHeight(deep?1:0.5), threads=threads, internal=hole);
}
module screw_holes(deep=false, threads=true) {
  screw(hole=true, deep=deep, threads=threads);
}
module screw_access_hole() {
  translate([screw_x, screw_y, screw_z1]) linear_extrude(lots) {
    circle(d = screw_slot_diameter/cos(180/6) + 2*C);
  }
}

module export_screw() { rotate([0,180]) screw(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(i, always=false) {
  translate([1e-3*i,2e-3*i,3e-3*i]) intersection() {
    children();
    *positive_y();
    *positive_x();
    *rotate(housing_angle+10) positive_y();
    *translate_y(-1.6) positive_y();
    *cube([lots,1,lots],true);
    *translate_z(ring_back_z) negative_z();
    *translate_z(pin_z(4)-1) negative_z();
    *translate_z(core_ring_pin_z+3) negative_z();
    *translate_z(pin_z(0)) cube([lots,lots,0.1],true);
    *if (always) translate_z(pin_z(len(bitting)-1)) negative_z();
    *if (always) positive_y();
    *if (always) translate_y(-5) positive_y();
  }
}

module assembly() {
  $fn = 30;
  //ra = 1*core_rotation;
  ra = 30;
  rb = 0.0*ring_rotation;
  //rb = 20;
  //bitting = [4,0,1];
  //pos = [4,4,4,4,4];
  pos = bitting;
  //pos = -0*bitting;
  threads = false;

  rotate(ra+rb) {
    color("pink") assembly_cut(1) core();
    color("blue") assembly_cut(2) for (i=[0:len(bitting)-1]) {
      translate_z(pin_z(i)) key_pin(pos[i], long=long_ring_pin(i));
    }
    color("green") key();
  }
  group() {
    color("lightgreen") assembly_cut(3) rotate(rb) ring();
    color("teal") assembly_cut(4) rotate(rb) for (i=[0:len(bitting)-1]) {
      translate_z(pin_z(i)) ring_pin(pos[i], bitting[i], long=long_ring_pin(i));
    }
    color("orange") assembly_cut(8) rotate(rb) core_ring_pin(pos = ra >= core_rotation ? 1 : 0);
  }
  color("purple") assembly_cut(6) for (i=[0:len(bitting)-1]) {
    translate_z(pin_z(i)) driver_pin(pos[i], bitting[i]);
  }
  color("yellow") assembly_cut(10,true) housing_main(threads=threads);
  *color("lightyellow") assembly_cut(11) housing_cover();
  *color("orange") assembly_cut(14) housing_back();
  color("blue") assembly_cut(12) screw(threads=threads);
  color("salmon") assembly_cut(13) screw_cover(pos = rb/ring_rotation);
  *#holes_in_housing();
}
assembly();

module exploded_assembly() {
  $fn = 30;
  //ra = 1*core_rotation;
  ra = 0;
  rb = 0.0*ring_rotation;
  //rb = 20;
  //bitting = [4,0,1];
  //pos = [4,4,4,4,4];
  pos = bitting;
  //pos = -0*bitting;
  threads = false;
  step = 1;

  translate_z(step*-60)
  rotate(ra+rb) {
    color("pink") assembly_cut(1) core();
    color("blue") assembly_cut(2) for (i=[0:len(bitting)-1]) {
      translate_x(step*6)
      translate_z(pin_z(i)) key_pin(pos[i], long=long_ring_pin(i), extra_step=step*1);
    }
    translate_z(step*-30)
    color("green") key();
  }
  translate_z(step*-30)
  group() {
    color("lightgreen") assembly_cut(3) rotate(rb) ring();
    color("teal") assembly_cut(4) rotate(rb) for (i=[0:len(bitting)-1]) {
      translate_x(step*6)
      translate_z(pin_z(i)) ring_pin(pos[i], bitting[i], long=long_ring_pin(i), extra_step=step*1);
    }
    color("orange") assembly_cut(8) rotate(rb) {
      translate(step*[4,-4])
      core_ring_pin(pos = ra >= core_rotation ? 1 : 0);
    }
  }
  translate_z(step*5) {
    color("purple") assembly_cut(6) for (i=[0:len(bitting)-1]) {
      translate_x(step*15)
      translate_z(pin_z(i)) driver_pin(pos[i], bitting[i]);
    }
    color("yellow") assembly_cut(10,true) housing(threads=false);
    *color("yellow") assembly_cut(10,true) housing_main(threads=threads);
    *color("lightyellow") assembly_cut(11) housing_cover();
    *color("orange") assembly_cut(14) housing_back();
    *color("blue") assembly_cut(12) screw(threads=threads);
    *color("salmon") assembly_cut(13) screw_cover(pos = rb/ring_rotation);
  }
}
!rotate([0,-90]) exploded_assembly();
