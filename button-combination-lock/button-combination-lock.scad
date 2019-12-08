//=============================================================================
// Combination lock with binary buttons
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

button_width = 5;
button_height = 4.5;
button_lip = 0.5;
button_travel = 3;
button_thickness = roundToLayerHeight(4);
button_stickout = 1*layerHeight;
button_hole_chamfer = 1.2;

front_thickness = roundToLayerHeight(2);

pin_diameter = 3;
pin_height = 3;
pin_sphere = false;

/*
button_step_x = 16;
button_step_y = 12;
button_count_x0 = 3;
button_count_x1 = 3;
button_count_y = 4;
/*/
/*
button_step_x = 12*2;
button_step_y = 12/2;
button_count_x0 = 2;
button_count_x1 = 1;
button_count_y = 8;
/*/
button_step_x = 12*2;
button_step_y = 12/2;
button_count_x0 = 2;
button_count_x1 = 1;
button_count_y = 6;
//*/
button_count_x = max(button_count_x0,button_count_x1);

function button_pos(i,j) =
  [(i-(button_count_x-1)/2) * button_step_x,
   j * button_step_y];
function button_pos2(i,j) =
  [i * button_step_x,
   j * button_step_y];
//button_coords = [for (i=[0:button_count_x-1]) for (j=[0:button_count_y-1]) button_pos(i,j)];
button_coords = [
  for (j=[0:button_count_y-1])
    //for (i=[0:button_count_x-1-(j%2==0?0:1)]) button_pos(i+(j%2)/2,j)
    //for (i=[0:button_count_x-1]) button_pos(i,j)
    //for (i=[0:button_count_x-1]) button_pos(i,j+(i%2)/2)
    for (i=[0:(j%2 ? button_count_x1 : button_count_x0)-1])
      button_pos2(i-((j%2 ? button_count_x1 : button_count_x0)-1)/2,j)
];
//button_coords = [[0,0]];
bitting = [0,0,1,1,1,0,0,1,0,1,0,1,1,0,0,1,0,0];

//-----------------------------------------------------------------------------
// Button
//-----------------------------------------------------------------------------

module button_top_profile() {
  fillet(1)
  square([button_width-2*button_lip,button_height-2*button_lip],true);
}
module lock_profile(h=0) {
  w1 = pin_diameter+button_travel;
  w2 = w1 - pin_diameter;
  lockH = 4*layerHeight+h;
  difference() {
    intersection() {
      translate([-w1/2,0]) square([w1,lockH]);
      hull() {
        $fn = 30;
        translate([-button_travel/2,0]) pin_profile();
        translate([button_travel/2,0]) pin_profile();
      }
    }
    translate([-w2/2,-lots/2]) square([w2,lots]);
  }
}

// teardrop shape for making printable round holes
module teardrop(r) {
  union() {
    circle(r=r);
    translate([0,r*sqrt(2)/2]) rotate(45) square(r,true);
  }
}
module semi_teardrop(r,cutoff=3*layerHeight) {
  intersection() {
    teardrop(r);
    translate_y(r+cutoff) negative_y2d();
  }
}

slider_width = button_width+2*button_travel;
slider_hole_width = slider_width+button_travel;
module button() {
  translate_z(button_thickness)
  linear_extrude(front_thickness+button_stickout) {
    button_top_profile();
  }
  difference() {
    linear_extrude_y(button_height,true) {
      w = slider_width;
      difference() {
        translate([-w/2,0]) square([w,button_thickness]);
        translated([[-button_travel/2,0],[button_travel/2,0]]) {
          offset(C) lock_profile(h=1*layerHeight);
        }
        translate([button_travel/2,0]) offset(C) lock_profile();
        hull() {
          semi_teardrop(r=pin_diameter/2+C);
          *offset(C) pin_profile();
          *translate_y(layerHeight) offset(C) pin_profile();
        }
      }
    }
    *translate_y(pin_y-C)
    linear_extrude_y(lots) {
      hull() {
        offset(C) pin_profile();
        //translate_y(layerHeight) offset(C) pin_profile();
      }
    }
  }
}
*!button();

alt_button_depth = roundToLayerHeight(1);
module alt_button() {
  translate_z(button_thickness)
  linear_extrude(front_thickness+layerHeight) {
    button_top_profile();
  }
  translate_z(-alt_button_depth)
  linear_extrude_y(button_height,true) {
    w = slider_width;
    difference() {
      translate([-w/2,0]) square([w,button_thickness+alt_button_depth]);
      translate([-button_travel/2,0]) offset(C) lock_profile();
      translate([button_travel/2,0]) offset(C) lock_profile();
    }
  }
}
*!group() {
  translate_x(-button_travel/2) alt_button();
  translate_y(5) translate_x(button_travel/2) alt_button();
}

module export_button() { button(); }

//-----------------------------------------------------------------------------
// Pins
//-----------------------------------------------------------------------------

pin_y = button_height/2-pin_height-C;

module pin_profile() {
  circle(r=pin_diameter/2);
}
module pin() {
  if (pin_sphere) {
    translate_y(pin_y + pin_diameter/2)
    sphere(d=pin_diameter);
  } else {
    translate_y(pin_y)
    linear_extrude_y(pin_height) {
      pin_profile();
    }
  }
}

module export_pin() { linear_extrude(pin_height) pin_profile(); }

//-----------------------------------------------------------------------------
// Bolt
//-----------------------------------------------------------------------------

bolt_travel = 6.5;
bolt_direction = -1;

//bolt_width = button_count_x * button_step_x;
bolt_width = (button_count_x-1) * button_step_x + slider_hole_width;
//bolt_height = (button_count_y-1) * button_step_y + button_height+bolt_travel + 2;
bolt_height = (button_count_y-1) * button_step_y + button_height + bolt_travel + bolt_travel + 2;
bolt_y = bolt_direction > 0 ? -button_height/2-bolt_travel
                            : -button_height/2-2;

bolt_thickness = roundToLayerHeight(2+1);
lock_height = bolt_travel-C;
//lock_height = 3;
lock_y = -button_height/2 - C - lock_height;

module bolt_profile() {
  difference() {
    translate([0, bolt_y+bolt_height/2])
      chamfer_rect(bolt_width,bolt_height,1);
    // shackle
    mirrored([1,0,0])
    translate([shackle_x - shackle_diameter/2 - 1.5 - C, shackle_y - 2]) {
      square([lots,lots]);
    }
    // lug holes
    minkowski() {
      lug_holes_profile(false);
      square([eps,lots]);
    }
    //translate_y(false_travel) lug_holes_profile(false);
    translate_y(bolt_travel) lug_holes_profile(true);
    // top of lock profile
    translate_y(shackle_y+shackle_height) {
      circle(r=shackle_x-shackle_diameter/2+housing_wall);
    }
    // screw hole
    for (pos=screw_coords) {
      translate(pos) {
        translate_y(-bolt_direction*bolt_travel) circle(d=screw_diameter+2*C);
        intersection() {
          hull() {
            circle(d=screw_diameter+2*C);
            translate_y(-bolt_direction*bolt_travel) circle(d=screw_diameter+2*C);
          }
          translate_x((pos[0] > 0 ? 1 : -1) * 2/2)
          square([3,lots],true);
        }
      }
    }
  }
}
module bolt_deep_profile() {
  intersection() {
    bolt_profile();
    mirrored([1,0,0])
    translate([shackle_x - shackle_diameter/2 - lug_diameter - C, lug_y-lug_diameter/2 + 2.0])
    square([lots,lots]);
  }
}

module bolt_pin_slot() {
  if (pin_sphere) {
    translate_y(pin_y+pin_diameter/2) {
      group() {
        translate([-button_travel/2,0]) sphere(r=pin_diameter/2+C);
        translate([button_travel/2,0]) sphere(r=pin_diameter/2+C);
      }
      bump = 1*layerHeight;
      s = (pin_diameter/2+C-bump) / (pin_diameter/2+C);
      scale([1,1,s])
      hull() {
        translate([-button_travel/2,0]) sphere(r=pin_diameter/2+C);
        translate([button_travel/2,0]) sphere(r=pin_diameter/2+C);
      }
    }
  } else {
    translate_y(pin_y-C)
    linear_extrude_y(pin_height+2*C) {
      group() {
        translate([-button_travel/2,0]) circle(r=pin_diameter/2+C);
        translate([button_travel/2,0]) circle(r=pin_diameter/2+C);
      }
      hull() {
        bump = 1*layerHeight;
        translate([-button_travel/2,0]) circle(r=pin_diameter/2+C-bump);
        translate([button_travel/2,0]) circle(r=pin_diameter/2+C-bump);
      }
    }
  }
}

module bolt() {
  difference() {
    union() {
      translate_z(-bolt_thickness)
      linear_extrude(bolt_thickness) {
        bolt_profile();
      }
      translate_z(-bolt_thickness)
      linear_extrude(bolt_thickness+button_thickness,convexity=2) {
        bolt_deep_profile();
      }
      intersection() {
        for (i=[0:len(button_coords)-1]) {
          translate(button_coords[i])
          in_bolt_direction() translate_y(lock_y)
          linear_extrude_y(lock_height, convexity=2) {
            lock_profile();
          }
        }
        linear_extrude(lots) bolt_profile();
      }
    }
    for (i=[0:len(button_coords)-1]) {
      translate(button_coords[i])
        in_bolt_direction() bolt_pin_slot();
    }
    // retainging pin things
    *translate_y(shackle_y-4) {
      linear_extrude_y(lots) {
        mirrored([1,0,0])
        translate([shackle_x,0]) {
          square([shackle_diameter+3+2*C,lots],true);
        }
      }
    }
    // button connection
    translate_z(-bolt_thickness-eps)
    linear_extrude(roundToLayerHeight(0.6)+3*layerHeight) {
      offset(delta=C/2) bolt_button_join_hole_profile();
    }
  }
}
module in_bolt_direction() {
  if (bolt_direction > 0) {
    children();
  } else {
    mirror([0,1,0]) children();
  }
}

*!bolt();

screw_diameter = 5;
//screw_coords = [for (i=[0.5,button_count_x-1.5]) for (j=[0.5,button_count_y-1.5]) button_pos(i,j)];
//screw_coords = [for (i=[-0.5,button_count_x-1.5]) for (j=[-0.5,button_count_y-1.5]) button_pos(i,j)];
//screw_coords = [for (x=[-1,1]) [x*bolt_width/2, 1*button_step_y], [4,-bolt_travel+2]];
//screw_coords = [for (x=[-1,1]) [x*(bolt_width/2-0.5), 1*button_step_y]];
screw_coords = [];

module export_bolt() { translate_z(-bolt_thickness) bolt(); }

//-----------------------------------------------------------------------------
// Bolt button
//-----------------------------------------------------------------------------

bolt_button_width = 15;
bolt_button_height = 13;
module bolt_button_profile() {
  translate_y(button_step_y*(button_count_y-1)/2)
  fillet(2)
  square([bolt_button_width,bolt_button_height],true);
}

module bolt_button_join_hole_profile() {
  y = button_step_y*(button_count_y-1)/2;
  r = 4.5;
  dx = (bolt_button_width-r-1)/2;
  dy = (bolt_button_height-r-1)/2;
  translated([for (x2=[-dx,dx]) for (y2=[y-dy,y+dy]) [x2,y2]]) {
    chamfer_rect(r,r,1.2);
  }
}

module bolt_button() {
  translate_z(-bolt_thickness-front_thickness)
  linear_extrude(front_thickness+eps) {
    bolt_button_profile();
  }
  translate_z(-bolt_thickness-eps)
  linear_extrude(roundToLayerHeight(0.6)) {
    bolt_button_join_hole_profile();
  }
}
*!bolt_button();

module export_bolt_button() { translate_z(-bolt_thickness-front_thickness) bolt_button(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

false_travel = pin_height+0.1;

module button_hole() {
  translate_z(-eps)
  linear_extrude_y(button_height+2*C,true) {
    w = slider_hole_width+2*C;
    translate([-w/2,0-eps]) square([w,button_thickness+2*eps]);
  }
  translate_z(button_thickness-eps)
  linear_extrude_chamfer_hole(front_thickness+2*eps,0,button_hole_chamfer,resolution=12) {
    offset(C) hull() {
      translate_x(-button_travel/2) button_top_profile();
      translate_x(button_travel/2) button_top_profile();
    }
  }
}
module pin_hole(bit) {
  for (b=[0,1]) {
    x = (b-0.5)*button_travel;
    translate([x,button_height/2,0])
    if (pin_sphere) {
      hull() {
        sphere(r=pin_diameter/2+C);
        translate_y((bit == b ? bolt_travel : false_travel) - pin_diameter/2)
        sphere(r=pin_diameter/2+C);
      }
    } else {
      rotate(-2*(b-0.5))
      linear_extrude_y(bit == b ? bolt_travel : false_travel) {
        circle(r=pin_diameter/2+C);
      }
    }
  }
}
module lock_hole() {
  translate_y(lock_y-C)
  linear_extrude_y(bolt_travel + bolt_travel + 2*C) {
    offset(C) lock_profile();
  }
}

module bolt_button_hole() {
  translate_z(-bolt_thickness-front_thickness-eps)
  linear_extrude_chamfer_hole(front_thickness+2*eps,button_hole_chamfer,0,resolution=12) {
    offset(C) hull() {
      bolt_button_profile();
      translate_y(-bolt_travel) bolt_button_profile();
    }
  }
}

retain_pin_diameter = roundToLayerHeight(2);
retain_pin_x = bolt_width/2 + C + retain_pin_diameter/2 + 1;

housing_wall = 2;
housing_width = bolt_width + 2*C + 2*housing_wall + 2*(retain_pin_diameter+1);
//housing_height = button_count_y * button_step_y + 2*2;
housing_height = bolt_height + bolt_travel + 2*housing_wall + 3;
//housing_thickness = front_thickness+button_thickness;
housing_y = bolt_y-2 - bolt_travel;
center_z = (button_thickness-bolt_thickness)/2;

housing_chamfer = 3;

module housing() {
  difference() {
    translate_z((button_thickness-bolt_thickness)/2)
    translate_y(housing_y+housing_height/2)
    chamfer_cube(housing_width, housing_height, 2*front_thickness+button_thickness+bolt_thickness, housing_chamfer);
    
    // bolt hole
    translate_z(-bolt_thickness-layerHeight)
    linear_extrude(bolt_thickness+1*layerHeight) {
      minkowski() {
        bolt_profile();
        translate([-C,-bolt_travel-C]) square([2*C,bolt_travel+2*C]);
      }
    }
    // bolt part that interacts with lugs
    translate_z(shackle_z)
    linear_extrude(shackle_diameter+2*C,center=true) {
      minkowski() {
        bolt_deep_profile();
        translate([-C,-bolt_travel-C]) square([2*C,bolt_travel+2*C]);
      }
    }
    // button holes
    intersection() {
      group() for (i=[0:len(button_coords)-1]) {
        translate(button_coords[i]) in_bolt_direction() {
          button_hole();
          pin_hole(bit = bitting[i]);
          lock_hole();
        }
      }
      linear_extrude(lots,center=true,convexity=2) {
        minkowski() {
          bolt_profile();
          translate([-C,-bolt_travel-C]) square([2*C,bolt_travel+2*C]);
        }
      }
    }
    // bolt actuator button hole
    bolt_button_hole();
    // screw hole
    for (pos=screw_coords) {
      translate(pos)
      translate_z(-lots)
      linear_extrude(button_thickness+lots+lots) {
        circle(d=screw_diameter+2*C);
      }
    }
    // shackle holes
    translate_z(shackle_z)
    translate_y(shackle_y-C)
    shackle_extrude_y(shackle_x,shackle_height,1,1-1*2/shackle_diameter) {
      octagon(shackle_diameter+2*C);
    }
    // top curve
    translate_y(shackle_y+shackle_height) {
      dr = 0;
      dr2 = 2;
      r = shackle_x-shackle_diameter/2+C-dr;
      cylinder(h=lots, r=r, center=true);
      translate_z(shackle_z)
      mirrored([0,0,1]) translate_z((shackle_diameter/2+dr2) / (sqrt(2)+1))
      cylinder(h=100, r1=r, r2=r+100);
    }
    translate_y(shackle_y+shackle_height - (shackle_x-shackle_diameter/2)*0.45) {
      positive_y();
    }
    *translate_y(shackle_y+shackle_height-5) {
      linear_extrude(lots,center=true) {
        x = shackle_x;
        translate_x(-x) square([2*x,lots]);
      }
    }
    // locking lugs
    lug_holes();
    // retaining pin holes
    translate_y(bolt_y-bolt_travel+2)
    linear_extrude_y(lots) {
      mirrored([1,0,0]) minkowski() {
        retain_pin_profile();
        square([3*C,2*layerHeight],true);
      }
    }
    *translate_y(shackle_y-4) {
      linear_extrude_y(5) {
        mirrored([1,0,0])
        translate([shackle_x,0]) circle(d=shackle_diameter+2*C);
      }
    }
    // holes to push out retaining pins
    linear_extrude_y(lots,true) {
      mirrored([1,0,0])
      translate([retain_pin_x,shackle_z+1.2])
      circle(d=1.5+2*C);
    }
  }
}

module housing_outer_profile() {
  difference() {
    translate_y(housing_y+housing_height/2) {
      chamfer_rect(housing_width, housing_height, housing_chamfer);
    }
    translate_y(shackle_y+shackle_height) {
      circle(r=shackle_x-shackle_diameter/2);
    }
    translate_y(shackle_y+shackle_height - (shackle_x-shackle_diameter/2)*0.45) {
      positive_y2d();
    }
  }
}

lip_thickness = roundToLayerHeight(bolt_thickness/2);
module housing_lip_profile(hole=false) {
  offset(-1-(hole?C/2:-C/2)) housing_outer_profile();
}

module housing_tab_profile() {
  mirrored([1,0,0])
  union() {
    offset(1) retain_pin_profile();
    t = roundToLayerHeight((retain_pin_thickness+2)/2);
    w = (retain_pin_diameter/2+1);
    translate([retain_pin_x-w,shackle_z-t]) {
      square([w,2*t]);
    }
  }
}
module housing_shackle_tab_profile() {
  mirrored([1,0,0])
  translate([shackle_x,shackle_z])
  difference() {
    intersection() {
      octagon(shackle_diameter+2+C);
      square([lots,shackle_diameter+1],true);
    }
    square([shackle_diameter*0.45,lots],true);
  }
}
module x_clearance() {
  minkowski() {
    children();
    square([2*C,eps],true);
  }
}

module housing_top() {
  difference() {
    intersection() {
      housing();
      //translate_z(-bolt_thickness + 1) positive_z();
      union() {
        translate_z(center_z) positive_z();
        translate_z(center_z-lip_thickness) {
          linear_extrude(lots) {
            housing_lip_profile(hole=false);
          }
        }
        // tabs to join top and bottom
        for (j=[0:2:button_count_y-1]) {
          translate_y(j*button_step_y)
          linear_extrude_y(button_step_y-C) {
            housing_tab_profile();
          }
        }
        translate_y(lug_y+lug_diameter/2+C) {
          linear_extrude_y(4)
          housing_shackle_tab_profile();
        }
      }
    }
    // tabs to join top and bottom
    for (j=[-1:2:button_count_y-2]) {
      translate_y(j*button_step_y-C)
      linear_extrude_y(button_step_y+C) {
        x_clearance() housing_tab_profile();
      }
    }
    translate_y(lug_y+lug_diameter/2+4+C) {
      linear_extrude_y(4+2*C)
      x_clearance() housing_shackle_tab_profile();
    }
  }
}

module housing_bottom() {
  difference() {
    intersection() {
      housing();
      union() {
        difference() {
          translate_z(center_z) negative_z();
          translate_z(center_z-lip_thickness) {
            linear_extrude(lots,convexity=2) {
              housing_lip_profile(hole=true);
            }
          }
        }
        // tabs to join top and bottom
        for (j=[-1:2:button_count_y-2]) {
          translate_y(j*button_step_y)
          linear_extrude_y(button_step_y-C,convexity=2) {
            housing_tab_profile();
          }
        }
        translate_y(lug_y+lug_diameter/2+C+4) {
          linear_extrude_y(4)
          housing_shackle_tab_profile();
        }
      }
    }
    // tabs to join top and bottom
    for (j=[0:2:button_count_y-1]) {
      translate_y(j*button_step_y-C)
      linear_extrude_y(button_step_y+C) {
        x_clearance() housing_tab_profile();
      }
    }
    translate_y(lug_y+lug_diameter/2) {
      linear_extrude_y(4+2*C)
      x_clearance() housing_shackle_tab_profile();
    }
  }
}

*!housing();
*!group() {
  $fn=20;
  intersection() {
    group() {
      color("red") housing_top();
      *color("yellow") translate([eps,eps,-1]) housing_bottom();
    }
    *translate_y(0*button_step_y) positive_y();
  }
}

module export_housing_top() { rotate([0,180,0]) translate_z(-front_thickness-button_thickness) housing_top(); }
module export_housing_bottom() { housing_bottom(); }

//-----------------------------------------------------------------------------
// Housing retaining/connecting pin
//-----------------------------------------------------------------------------

retain_pin_thickness = roundTo(4.8,layerHeight*2);
module retain_pin_profile() {
  translate([retain_pin_x,shackle_z])
  chamfer_rect(retain_pin_diameter,retain_pin_thickness,retain_pin_diameter/2);
}
module retain_pin() {
  y1 = bolt_y-bolt_travel+2;
  y2 = shackle_y-C;
  linear_extrude_y(y2-y1) retain_pin_profile();
}

module export_retain_pin() { rotate([0,90,0]) translate_x(-retain_pin_x) retain_pin(); }

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

lug_overlap = 2.5; // how far locking lugs overlap the shackle
lug_diameter = 6;
lug_y = (button_count_y-2) * button_step_y + button_height/2 + lug_diameter/2 + bolt_travel;

//shackle_x = bolt_width/2;
//shackle_y = bolt_y + bolt_height - (bolt_direction<0?bolt_travel:0) - 0.5;
//shackle_y = bolt_y + bolt_height - bolt_travel - (bolt_direction<0?bolt_travel:0) + 1.5;
shackle_y = lug_y - lug_diameter/2 - 2;
shackle_height = 24;
//shackle_diameter = 8;
shackle_z = center_z;
shackle_diameter = button_thickness+bolt_thickness;
shackle_x = housing_width/2 - 2 - shackle_diameter/2;

//retain_pin_x = shackle_x + (shackle_diameter-retain_pin_diameter)/2;

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
  rotate([90]) shackle_extrude_y(x,height) children();
}
*!shackle_extrude_z(10,20) square(5,true);

module octagon(w) {
  intersection() {
    square(w,true);
    rotate(45) square(w,true);
  }
}

module shackle() {
  difference() {
    translate_z(shackle_z)
    translate_y(shackle_y)
    shackle_extrude_y(shackle_x,shackle_height,1,1-1*2/shackle_diameter) {
      octagon(shackle_diameter);
    }
    lug_holes();
  }
}

module export_shackle() { shackle(); }

//-----------------------------------------------------------------------------
// Locking lugs
//-----------------------------------------------------------------------------

module lug_holes_profile(retracted = true) {
  mirrored([1,0,0])
  translate([shackle_x-shackle_diameter/2-lug_diameter/2+lug_overlap, lug_y]) {
    hull() {
      circle(d=lug_diameter+2*C);
      if (retracted) translate_x(-lug_overlap) circle(d=lug_diameter+2*C);
    }
  }
}
module lug_holes(retracted = true) {
  translate_z(shackle_z)
  linear_extrude(shackle_diameter+2*C,center=true) {
    lug_holes_profile(retracted);
  }
}

module lug() {
  cylinder(d=lug_diameter, h=shackle_diameter);
}

module export_lug() { lug(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e) {
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
    cut_y = 0;
    *translate_y(e*0.01+cut_y) positive_y();
    *translate_y(e*0.01+cut_y+2) negative_y();
  }
}
module assembly_cut_x(e) {
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
  }
}
module assembly_cut_x2(e) {
  intersection() {
    children();
    *translate_x(e*eps) negative_x();
  }
}
module assembly_cut_z(e) {
  intersection() {
    children();
    *translate_z(e*eps+shackle_z) positive_z();
  }
}

module assembly() {
  //travel = ;
  travel = 1*bolt_direction*false_travel + 0*bolt_direction*bolt_travel;
  $fn =30;
  
  color("lightblue") assembly_cut(1) translate_z(0.7*layerHeight) {
    /*translate_x(button_travel/2) button();
    translate_x(-button_travel/2)
    translate_x(16) button();
    translate_y(12) button();
    */
    for (i=[0:len(button_coords)-1]) {
      translate_x((bitting[i]-0.5) * button_travel)
      translate(button_coords[i]) in_bolt_direction() button();
    }
  }
  color("pink") assembly_cut(2) translate_z(0.5*layerHeight) {
    translate_y(travel)
    for (i=[0:len(button_coords)-1]) {
      translate_x((bitting[i]-0.5) * button_travel)
      translate(button_coords[i]) 
      in_bolt_direction() pin();
    }
  }
  *color("green") assembly_cut(3) assembly_cut_x(3) {
    translate_y(travel)
    bolt();
  }
  *color("lightgreen") assembly_cut(4) assembly_cut_x(4) translate_z(0.3*layerHeight) {
    translate_y(travel)
    bolt_button();
  }
  color("lightyellow") assembly_cut(8) assembly_cut_x2(8) translate_z(1*layerHeight) {
    housing_top();
  }
  *color("yellow") assembly_cut(9) assembly_cut_x2(9) translate_z(0*layerHeight) {
    housing_bottom();
  }
  color("blue") assembly_cut(12) translate_z(0.5*layerHeight) {
    mirrored([1,0,0]) retain_pin();
  }
  *translate_x(-housing_width)
  color("yellow") assembly_cut(9) translate_z(0*layerHeight) {
    rotate([0,180]) housing_bottom();
  }
  color("pink") shackle();
}

assembly();