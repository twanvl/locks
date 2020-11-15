include <../../util/util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

magnet_diameter = 3;
magnet_thickness = 1;

key_diameter = 4;

sleeve_diameter = 6;

disc_diameter = 11.5;
disc_thickness = round_to_layer_height(magnet_diameter + 1);

core_diameter = 15;

sidebar_travel = 1.2;
sidebar_false_travel = 0.5;
sidebar_thickness = 3;

bits = 12;
bitting = [10,3,0,8,7,2];
tension_disc = 2; // must have bitting[tension_disc]=0

disc_total_spacing = 2*layer_height;
function disc_position(i) = i * disc_thickness + (i+0.5) * disc_total_spacing / len(bitting);

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key() {
  difference() {
    chamfer_cylinder(d = key_diameter, h = core_thickness, chamfer_top=0.5);
    
    for (i=[0:len(bitting)-1]) {
      translate_z(disc_position(i) + disc_thickness/2) {
        rotate(bitting[i] * 360/bits) {
          // make top of magnet flush with key cylinder
          translate_x(key_diameter/2 - 1*(magnet_thickness+C) - (key_diameter/2 - side_given_diagonal(key_diameter/2, magnet_diameter/2)))
          linear_extrude_x(key_diameter) {
            circle(d = magnet_diameter+2*C);
          }
        }
      }
    }
  }
  handle_length = 3;
  translate_z(-handle_length) {
    cylinder(d = key_diameter, h = handle_length+eps);
  }
  bow_height = 18;
  hole_size = 6;
  bow_thickness = key_diameter;
  translate_z(-handle_length - bow_height*0.85/2) {
    linear_extrude_y_inset(bow_thickness-1, bow_thickness, 1, center=true) {
      difference() {
        truncated_circle(bow_height);
        //chamfer_rect(bow_height,bow_height,bow_height*0.25);
        translate_y(-(bow_height-hole_size)/2*0.85 + 2.5)
          truncated_circle(hole_size);
          //chamfer_rect(hole_size,hole_size,hole_size*0.25);
      }
    }
  }
}
*!key();

module truncated_circle(d) {
  intersection() {
    circle(d = d);
    square([d,d*0.85],true);
  }
}
module linear_extrude_y_inset(a,b,r,center=true) {
  linear_extrude_y(a,center) children();
  linear_extrude_y(b,center) inset(r) children();
}
module inset(r) {
  difference() {
    union() children();
    offset(-r) union() children();
  }
}

module export_key() {
  key();
}

//-----------------------------------------------------------------------------
// Discs
//-----------------------------------------------------------------------------

module disc(bit) {
  difference() {
    linear_extrude(disc_thickness, convexity=2) {
      difference() {
        circle(d=disc_diameter);
        circle(d=sleeve_diameter+2*C);
        true_gate_profile();
        for (i=[0:1.5:bits-1]) {
          rotate(i * 360/bits) {
            false_gate_profile();
          }
        }
      }
    }
    // magnet
    translate_z(disc_thickness/2) {
      rotate(bit * 360/bits) {
        linear_extrude_x(sleeve_diameter/2+C + magnet_thickness+C) {
          circle(d = magnet_diameter+2*C);
        }
      }
    }
  }
}
*!intersection() {
  disc(1);
  translate_z(disc_thickness/2) negative_z();
}

module tension_disc_spacer() {
  linear_extrude(disc_thickness, convexity=2) {
    difference() {
      circle(d=disc_diameter);
      circle(d=sleeve_diameter+2*C);
      true_gate_profile();
      offset(C) tension_disc_puller_profile();
    }
  }
}

module discs_assembly(solved = true) {
  for (i=[0:len(bitting)-1]) {
    rotate(solved ? 0 : -bitting[i]*360/bits) {
      translate_z(disc_position(i)) {
        if (i == tension_disc) {
          color("purple") assembly_cut(i) tension_disc_spacer();
        } else {
          color(i%2 ? "red" : "DarkRed") assembly_cut(i) disc(bitting[i]);
        }
      }
    }
  }
}

module export_discs() {
  for (i=[0:len(bitting)-1]) {
    translate_x(i * core_diameter) {
      if (i == tension_disc) {
        tension_disc_spacer();
      } else {
        disc(bitting[i]);
      }
    }
  }
}
*!export_discs();

//-----------------------------------------------------------------------------
// Sidebar
//-----------------------------------------------------------------------------

module sidebar_extra_profile() {
  w = core_diameter/2;
  //h = magnet_diameter+1;
  h = sidebar_thickness;
  difference() {
    intersection() {
      translate([sleeve_diameter/2, (h-sidebar_thickness)/2 - h/2]) {
        square([core_diameter/2 - sleeve_diameter/2, h]);
      }
      *sym_polygon_y([
        [sleeve_diameter/2, (magnet_diameter+1)/2],
        //[disc_diameter/2, sidebar_thickness/2],
        [core_diameter/2, sidebar_thickness/2]
      ]);
      circle(d = core_diameter);
    }
    circle(d = sleeve_diameter+2*C);
  }
}
module sidebar_profile() {
  intersection() {
    //circle(d=core_diameter);
    sidebar_extra_profile();
    //w = 100;
    group() {
      w = core_diameter - disc_diameter + 1;
      translate_x(w/2 + disc_diameter/2 - sidebar_travel) {
        scale([1,1.2])
        chamfer_rect(w, sidebar_thickness, sidebar_travel);
      }
      *difference() {
        sidebar_extra_profile();
        circle(d = disc_diameter+2*C);
      }
    }
  }
}
*!sidebar_profile();

module true_gate_profile() {
  offset(C) sidebar_profile();
}

module false_gate_profile() {
  offset(C) difference() {
    sidebar_profile();
    circle(d=disc_diameter - sidebar_false_travel);
  }
}

core_thickness = len(bitting) * disc_thickness + disc_total_spacing;

module sidebar() {
  linear_extrude(core_thickness - 2*C, convexity=3) {
    sidebar_profile();
  }
  translate_z(disc_position(tension_disc)) {
    difference() {
      linear_extrude(disc_thickness, convexity=3) {
        tension_disc_puller_profile();
      }
      translate_z(disc_thickness/2) {
        rotate(bitting[tension_disc] * 360/bits)
        linear_extrude_x(sleeve_diameter/2+C + magnet_thickness+C) {
          circle(d = magnet_diameter+2*C);
        }
      }
    }
  }
}
*!sidebar();

module tension_disc_puller_profile() {
  sidebar_extra_profile();
}
*!tension_disc_spacer();

module export_sidebar() {
  translate_z(sidebar_thickness/2) rotate([90]) sidebar();
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

core_back_thickness = round_to_layer_height(1.5);
rotation_limiter_diameter = core_diameter + 2*1.2;

module core() {
  linear_extrude(core_thickness, convexity=2) {
    difference() {
      circle(d = core_diameter);
      circle(d = disc_diameter + 2*C);
      offset(C) hull() {
        sidebar_profile();
        translate_x(sidebar_travel) sidebar_profile();
      }
    }
  }
  translate_z(core_thickness - eps)
  linear_extrude(core_back_thickness+eps, convexity=2) {
    difference() {
      union() {
        circle(d = core_diameter);
        rotate(-45) wedge(180-45,center=true, r=rotation_limiter_diameter/2);
      }
      circle(d = sleeve_diameter+2*C);
    }
  }
}

module export_core() {
  translate_z((core_thickness+core_back_thickness)) rotate([180]) core();
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housing_bottom_thickness = round_to_layer_height(1.5);
housing_diameter = core_diameter + 2*C + 2.4;
housing_chamfer = 0.5;

screw_length = 3;
screw_overlap = 0.45;

module housing_profile() {
  translate_x(sidebar_travel/2) {
    circle(d = housing_diameter + sidebar_travel);
  }
  *hull() {
    circle(d = housing_diameter);
    translate_x(sidebar_travel)
      circle(d = housing_diameter);
  }
}
module housing(threads=true) {
  translate_z(-housing_bottom_thickness)
  difference() {
    linear_extrude_cone_chamfer(housing_bottom_thickness+eps,housing_chamfer,0, convexity=2) {
      housing_profile();
    }
    translate_z(-eps)
    chamfer_cylinder(d = key_diameter + 2*C, h=housing_bottom_thickness+1, chamfer_bottom=-1);
  }
  linear_extrude(core_thickness, convexity=2) {
    difference() {
      housing_profile();
      circle(d = core_diameter + 2*C);
      translate_x(sidebar_travel) offset(C) sidebar_profile();
    }
  }
  // sleeve
  difference() {
    chamfer = 1.1;
    key_chamfer = 0.5;
    group() {
      cylinder(d = sleeve_diameter, h=core_thickness + core_back_thickness + (threads ? -screw_overlap : screw_length));
      // screw
      if (threads) {
        translate_z(core_thickness + core_back_thickness - screw_overlap) {
          standard_thread(d=sleeve_diameter, length=screw_length+screw_overlap);
        }
      }
    }
    chamfer_cylinder(d = key_diameter + 2*C, h=core_thickness + chamfer - key_chamfer, chamfer_top=chamfer);
  }
  *linear_extrude(core_thickness - layer_height, convexity=2) {
    difference() {
      circle(d = sleeve_diameter);
      circle(d = key_diameter + 2*C);
    }
  }
  // rotation limiter
  translate_z(core_thickness - eps)
  linear_extrude(core_back_thickness + layer_height + eps, convexity=2) {
    difference() {
      housing_profile();
      rotate(0) wedge(180-45 + 90,center=true, r=rotation_limiter_diameter/2+C);
      circle(d=core_diameter+2*C);
    }
  }
}

housing_nut_z = core_thickness + core_back_thickness + layer_height;
module housing_nut(threads=true) {
  difference() {
    translate_z(housing_nut_z) {
      group() {
        linear_extrude_cone_chamfer(housing_bottom_thickness+eps,0,housing_chamfer, convexity=2) {
          housing_profile();
        }
        chamfer_cylinder(d=sleeve_diameter+3, h=screw_length-layer_height, chamfer_top=housing_chamfer);
      }
    }
    if (threads) {
      translate_z(core_thickness + core_back_thickness - screw_overlap) {
        standard_thread(d=sleeve_diameter, length=screw_length+screw_overlap+1, internal=true, C=C);
      }
    }
    // window
    rotated([45,-45])
    translate_x(core_diameter/2-0.5) {
      cylinder(d=3, h=lots);
    }
  }
}

module export_housing() {
  translate_z(housing_bottom_thickness) housing();
}
module export_housing_nut() {
  translate_z(-housing_nut_z) housing_nut();
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e,always=false) {
  // Note: translate a tiny bit to prevent rendering artifacts from identical surfaces
  translate([e*eps,e*sqrt(3)*eps,e*sqrt(5)*eps])
  intersection() {
    children();
    //if (always)
    //translate_x(e*eps*10) positive_y();
    //translate_z(3.5*disc_thickness) negative_z();
  }
}

module assembly() {
  rotate(0) {
    color("cyan") assembly_cut(10) key();
    discs_assembly();
    color("pink") assembly_cut(11) core();
    translate_x(1*sidebar_travel) {
      color("green") assembly_cut(12) sidebar();
    }
  }
  color("yellow") assembly_cut(13) housing();
  color("LightYellow") assembly_cut(14) housing_nut();
}
assembly();
