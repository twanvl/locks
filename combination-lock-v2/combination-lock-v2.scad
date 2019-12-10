//=============================================================================
// Combination padlock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

shaft_diameter = 6.5;
shaft_notch = 0.8;
shaft_minor_diameter = shaft_diameter - 2*shaft_notch;

sleeve_diameter = 9;
sleeve_notch = 0.8;
sleeve_outer_diameter = sleeve_diameter + 2*sleeve_notch;
wheel_diameter = 16;

num_positions = 10;
num_wheels = 3;

z_step = roundTo(1.0,1*layerHeight);
// stationary parts
wheel_thickness = roundToLayerHeight(6);
sep_thickness = roundToLayerHeight(3);
wheel_housing_thickness = wheel_thickness + sep_thickness;
wheel_cover_thickness = roundToLayerHeight(3);
wheel_z = roundToLayerHeight(-1);
//wheel_z = 0;
// moving parts
encoder_sleeve_thickness = roundToLayerHeight(3);
encoder_mesh_thickness = roundToLayerHeight(2);
fixer_sleeve_thickness = roundToLayerHeight(5.5);
// travel
sleeve_z = roundToLayerHeight(0.3);
change_travel = -encoder_mesh_thickness - sleeve_z - 2*layerHeight;
false_travel = encoder_mesh_thickness + roundToLayerHeight(0.5);
max_travel = wheel_housing_thickness - encoder_sleeve_thickness - sleeve_z - roundToLayerHeight(0.5);
min_true_travel = roundToLayerHeight(false_travel+1);

//-----------------------------------------------------------------------------
// Profiles
//-----------------------------------------------------------------------------

module wheel_outer_profile() {
  notch_depth = 0.3;
  notch_width = 0.8;
  difference() {
    circle(d = wheel_diameter);
    for (i=[0:num_positions-1]) {
      rotate(i*360/num_positions)
      translate([wheel_diameter/2-notch_depth/2,0]) square([notch_depth,notch_width],true);
    }
  }
}

wheel_cover_diameter = wheel_diameter-3;
module wheel_cover_profile() {
  circle(d = wheel_cover_diameter);
}

module sleeve_outer_profile(pins, offset_outer=0) {
  // pins=0 = blank shaft
  // pins=1 = only pins in encoding positions
  // pins=2 = all pins
  // pins=3 = free movement of pins
  circle(d=sleeve_diameter);
  if (pins > 0)
  intersection() {
    circle(d=sleeve_outer_diameter+2*offset_outer);
    if (pins < 3) {
      for (i=[0:num_positions-1]) {
        w = 0.25 * 2*PI * sleeve_diameter / num_positions;
        //if (pins == 2 || pins == 1 && (i!=0 && i!=3 && i!=7 && i!=5)) {
        if (pins == 2 || pins == 1 && (i!=0 && i!=3 && i!=5 && i!=7)) {
          //rotate((i+0.5)*360/num_positions)
          rotate(90+i*360/num_positions)
          translate([0,-w/2]) square([lots,w]);
        }
      }
    }
  }
}
*!sleeve_outer_profile(1);


//-----------------------------------------------------------------------------
// Wheels
//-----------------------------------------------------------------------------

module sleeve_outer_hole_profile(pins=2) {
  offset(C) sleeve_outer_profile(pins, offset_outer=C);
}

module wheel_profile() {
  difference() {
    wheel_outer_profile();
    sleeve_outer_hole_profile();
  }
}

module wheel(labels = true) {
  linear_extrude(layerHeight+eps, convexity=2) {
    // glide ring
    difference() {
      //d = (sleeve_outer_diameter+4*C + wheel_diameter)/2;
      d = wheel_z < 0 ? sleeve_outer_diameter+4*C : (sleeve_outer_diameter+4*C + wheel_diameter)/2;
      circle(d=d+2*0.5);
      circle(d=d);
    }
  }
  difference() {
    union() {
      // label background
      translate_z(layerHeight+wheel_z)
      linear_extrude(wheel_thickness - layerHeight, convexity=5) {
        circle(d=wheel_diameter-2*0.3);
      }
      difference() {
        translate_z(layerHeight+wheel_z)
        linear_extrude(wheel_thickness - layerHeight, convexity=5) {
          wheel_outer_profile();
        }
        // labels
        if (labels)
        for (i=[0:num_positions-1]) {
          rotate((i+0.5)*360/num_positions)
          translate_z(wheel_thickness/2+wheel_z)
          linear_extrude_x(lots) {
            //rotate(-90)
            //scale([1.2,0.8])
            text(str(i),size=4,font="ubuntu bold",halign="center",valign="center");
          }
        }
      }
    }
    translate_z(wheel_z-eps)
    linear_extrude(lots, convexity=5) {
      sleeve_outer_hole_profile();
    }
    translate_z(wheel_z-eps)
    linear_extrude(-wheel_z+layerHeight-eps, convexity=5) {
      offset(C) wheel_cover_profile();
    }
    chamfer = 0.6;
    translate_z(min(-chamfer,wheel_z)-eps) {
      cylinder(d1=wheel_diameter-1, d2=wheel_cover_diameter+2*C, h=chamfer);
    }
    translate_z(wheel_cover_thickness-eps)
    linear_extrude(lots, convexity=5) {
      offset(C) wheel_cover_profile();
    }
    sleeve_chamfer = roundToLayerHeight(1);
    translate_z(wheel_cover_thickness-sleeve_chamfer) {
      cylinder(d1=sleeve_diameter+2*C,d2=wheel_cover_diameter+2*C,h=sleeve_chamfer);
    }
    sleeve_bottom_chamfer = roundToLayerHeight(0.8);
    translate_z(-eps) {
      cylinder(d2=sleeve_diameter+2*C,d1=sleeve_outer_diameter+4*C,h=sleeve_bottom_chamfer);
    }
  }
}
*!wheel($fn=30);

module export_wheel() { rotate([180]) wheel(); }

//-----------------------------------------------------------------------------
// Sleeves
//-----------------------------------------------------------------------------

module encoding_sleeve_profile(pins=1) {
  difference() {
    sleeve_outer_profile(pins);
    circle(d=shaft_minor_diameter+2*C);
    hull() {
      circle(d=shaft_minor_diameter-0*C);
      translate_y(lots) circle(d=shaft_minor_diameter-0*C);
    }
  }
}

module encoding_sleeve() {
  difference() {
    union() {
      linear_extrude(encoder_sleeve_thickness, convexity=5) {
        encoding_sleeve_profile(pins=0);
      }
      linear_extrude(encoder_mesh_thickness, convexity=5) {
        encoding_sleeve_profile();
      }
      *linear_extrude(0.5+eps, convexity=5) {
        encoding_sleeve_profile(pins=0);
      }
    }
    translate_z(-eps)
    cylinder(d1=shaft_diameter+2*C, d2=shaft_minor_diameter+2*C, h=shaft_notch);
  }
}

module fixing_sleeve() {
  translate_z(encoder_sleeve_thickness)
  difference() {
    union() {
      linear_extrude(fixer_sleeve_thickness, convexity=5) {
        sleeve_outer_profile(0);
      }
      intersection() {
        z = encoder_mesh_thickness - roundToLayerHeight(0.5);
        translate_z(z)
        linear_extrude(fixer_sleeve_thickness - z, convexity=5) {
          sleeve_outer_profile(1);
        }
        cylinder(d1=sleeve_diameter+3*fixer_sleeve_thickness, d2=sleeve_diameter, h=fixer_sleeve_thickness);
        // ?
        translate_z(z)
        cylinder(d1=sleeve_diameter, d2=sleeve_diameter+3*fixer_sleeve_thickness, h=fixer_sleeve_thickness);
      }
    }
    translate_z(-eps)
    linear_extrude(fixer_sleeve_thickness+2*eps, convexity=5) {
      circle(d=shaft_diameter+2*C);
    }
  }
}

module export_encoding_sleeve() { encoding_sleeve(); }
module export_fixing_sleeve() { rotate([180]) fixing_sleeve(); }

//-----------------------------------------------------------------------------
// Shaft
//-----------------------------------------------------------------------------

shaft_bottom_z = roundToLayerHeight(-1);
module shaft(num_wheels = num_wheels) {
  height = (num_wheels+1) * wheel_housing_thickness + top_housing_thickness;
  length = roundToLayerHeight(12);
  difference() {
    union() {
      translate_z(shaft_bottom_z)
      linear_extrude(height-shaft_bottom_z + eps) {
        circle(d=shaft_diameter);
      }
      translate_z(height-min_true_travel) {
        linear_extrude(min_true_travel) {
          offset(C) shaft_top_pin_profile();
        }
      }
    }
    for (i=[0:num_wheels-1]) {
      translate_z(i*wheel_housing_thickness + sleeve_z - layerHeight) {
        difference() {
          cylinder(d=shaft_diameter+1,h=encoder_sleeve_thickness+layerHeight);
          translate_z(-eps)
          cylinder(d1=shaft_diameter,d2=shaft_minor_diameter,h=shaft_notch);
          translate_z(shaft_notch)
          cylinder(d=shaft_minor_diameter,h=encoder_sleeve_thickness+layerHeight);
        }
      }
    }
  }
  // shackle
  shackle_diameter = shaft_diameter;
  translate_z(height)
  linear_extrude(length) {
    circle(d=shackle_diameter);
  }
  translate_x(screw_x) {
    translate_z(height-min_true_travel)
    linear_extrude(min_true_travel+1) {
      circle(d=4);
    }
    translate_z(height)
    linear_extrude(length) {
      circle(d=shackle_diameter);
    }
  }
  translate_z(height+length-roundToLayerHeight(1.5)) {
    //linear_extrude(roundToLayerHeight(4)) {
    linear_extrude_cone_chamfer(roundToLayerHeight(6), housing_chamfer,housing_chamfer) {
      *housing_profile(screw_hole=false);
      hull() {
        circle(d=shackle_diameter);
        translate_x(screw_x) circle(d=shackle_diameter);
      }
    }
  }
}
module export_shaft() { rotate([180]) shaft(); }

//-----------------------------------------------------------------------------
// Screw
//-----------------------------------------------------------------------------

module screw(num_wheels = num_wheels, threads=true, internal=false) {
  height = bottom_housing_thickness + num_wheels * wheel_housing_thickness + top_housing_thickness;
  translate_z(wheel_housing_thickness-bottom_housing_thickness)
  translate_x(screw_x) {
    make_screw(screw_diameter, bottom_thickness,bottom_housing_thickness,height, slot_diameter=4, slot_depth=min_true_travel+1,
      head_straight_thickness=roundToLayerHeight(1.0),
      threads=threads, internal=internal);
  }
}
module export_screw() { rotate([180]) screw(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

screw_diameter = 8;
//screw_x = -wheel_diameter/2 - screw_diameter/2 - 2.5;
screw_x = -wheel_diameter;
module housing_profile(screw_hole=true) {
  difference() {
    hull() {
      circle(d = wheel_diameter-1);
      translate_x(-wheel_diameter)
      //translate_x(-2*wheel_diameter)
      circle(d = wheel_diameter-1);
    }
    if (screw_hole)
    translate_x(screw_x) circle(d=screw_diameter+2*C);
  }
}
module wheel_housing_profile(screw_hole=true) {
  fillet(1)
  difference() {
    housing_profile(screw_hole);
    circle(d = wheel_diameter+4*C);
  }
}
module housing_connector_profile() {
  *translate_x(screw_x) {
    rotated([0,90,180,270]) {
      translate([screw_diameter/2,screw_diameter/2]) square(2);
    }
  }
  difference() {
    offset(-1-C) wheel_housing_profile(screw_hole=false);
    offset(-2-C) wheel_housing_profile(screw_hole=false);
    translate_x(screw_x+screw_diameter/2) positive_x2d();
  }
}
tight_C = C/2;
module housing_connector() {
  translate_z(-3*layerHeight)
  linear_extrude(3*layerHeight, convexity=5) housing_connector_profile();
}
module housing_connector_hole() {
  translate_z(-5*layerHeight) {
    linear_extrude(lots, convexity=5) offset(tight_C) housing_connector_profile();
  }
}

module wheel_housing() {
  difference() {
    union() {
      linear_extrude(wheel_housing_thickness, convexity=5) {
        wheel_housing_profile();
      }
      chamfer = roundToLayerHeight(0.6);
      translate_z(wheel_cover_thickness-chamfer+layerHeight+eps)
      intersection() {
        linear_extrude(wheel_housing_thickness-(wheel_cover_thickness-chamfer+layerHeight)+eps, convexity=5) {
          wheel_cover_profile();
        }
        union() {
          cylinder(d1=sleeve_diameter+1+2*C,d2=wheel_cover_diameter,h=chamfer);
          translate_z(chamfer-eps) cylinder(d=wheel_cover_diameter,h=lots);
        }
      }
      intersection() {
        translate_z(wheel_z+wheel_thickness+layerHeight+eps)
        linear_extrude(wheel_housing_thickness-(wheel_thickness+layerHeight)-wheel_z+eps, convexity=5) {
          housing_profile();
        }
        translate_z(wheel_housing_thickness-lots-0.6)
          cylinder(d1=wheel_cover_diameter+3*lots,d2=wheel_cover_diameter,h=lots);
      }
      dh = wheel_z < 0 ? layerHeight : 0;
      translate_z(wheel_z+wheel_thickness+layerHeight+eps)
      linear_extrude(wheel_housing_thickness-(wheel_thickness+layerHeight)-dh, convexity=5) {
        housing_profile();
      }
      housing_connector();
    }
    translate_z(-eps)
    linear_extrude(lots, convexity=5) {
      sleeve_outer_hole_profile(pins=1);
    }
    linear_extrude(false_travel+encoder_mesh_thickness+sleeve_z, convexity=5) {
      sleeve_outer_hole_profile(pins=2);
    }
    sleeve_hole_chamfer(wheel_housing_thickness);
    translate_z(wheel_housing_thickness) housing_connector_hole();
  }
}
module sleeve_hole_chamfer(z) {
  translate_z(z-2)
  cylinder(d1=sleeve_outer_diameter+2*C-3*2, d2=sleeve_outer_diameter+2*C+2*C, h=2+eps);
}
*!wheel_housing();

bottom_thickness = roundToLayerHeight(1.5);
bottom_housing_thickness = bottom_thickness + wheel_housing_thickness - (shaft_bottom_z + change_travel) + layerHeight;
housing_chamfer = 1;
module bottom_housing(threads=true) {
  translate_z(wheel_housing_thickness-bottom_housing_thickness)
  difference() {
    union() {
      //linear_extrude(bottom_housing_thickness, convexity=5) {
      linear_extrude_cone_chamfer(bottom_housing_thickness,housing_chamfer,0,convexity=4) {
        housing_profile(screw_hole=false);
      }
    }
    // screw hole
    translate_x(screw_x) {
      make_screw(screw_diameter, bottom_thickness,bottom_housing_thickness,lots, threads=threads, internal=true);
    }
    // shaft
    translate_z(bottom_thickness)
    linear_extrude(lots, convexity=5) {
      sleeve_outer_hole_profile(pins=1);
    }
    sleeve_hole_chamfer(bottom_housing_thickness);
    // connector
    translate_z(bottom_housing_thickness) housing_connector_hole();
  }
}


top_housing_thickness = roundToLayerHeight(6);
module top_housing() {
  difference() {
    union() {
      //linear_extrude(top_thickness, convexity=5) {
      linear_extrude_cone_chamfer(top_housing_thickness,0,housing_chamfer,convexity=4) {
        housing_profile(screw_hole=false);
      }
      housing_connector();
      translate_z(-3*layerHeight) {
        linear_extrude(3*layerHeight+eps,convexity=5) {
          sleeve_outer_profile(1);
        }
      }
    }
    // shackle
    translate_z(-lots/2-eps)
    linear_extrude(lots) {
      circle(d=shaft_diameter+2*C);
    }
    translate_z(top_housing_thickness-min_true_travel-2*layerHeight) {
      linear_extrude(lots) {
        offset(C) shaft_top_pin_profile();
      }
    }
    translate_z(top_housing_thickness-min_true_travel-2*layerHeight+change_travel) {
      linear_extrude(lots) {
        rotate(180) offset(C) shaft_top_pin_profile();
      }
    }
    // screw
    translate_z(-wheel_housing_thickness)
    screw(0, threads=false, internal=true);
  }
}
module shaft_top_pin_profile() {
  w = shaft_diameter/2 + 0.5;
  h = 2;
  intersection() {
    hull() {
      circle(d=h);
      translate_x(-w) circle(d=h);
    }
    sleeve_outer_profile(2);
  }
  *translate([-w,-h/2]) square([w,h]);
}

module export_wheel_housing() { rotate([180]) wheel_housing(); }
module export_bottom_housing() { bottom_housing(); }
module export_top_housing() { rotate([180]) top_housing(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e,d=0) {
  intersection() {
    translate_y(e*0.01) children();
    //rotate(d*10)
    //rotate(36)
    translate_y(e*0.01 + d*0.0) positive_y();
  }
}

module assembly() {
  $fn = 30;
  //travel = 0*change_travel + 0*false_travel + 0*max_travel;
  //travel = 1.5;
  travel = 0;
  // -2.5 = change
  // 0.5 = neutral
  // 2.5 = false gate
  // 6 = max travel
  
  color("red") assembly_cut(0) translate_z(travel + 0.5*layerHeight) {
    shaft();
  }
  color("blue") assembly_cut(1,1) translate_z(0.5*layerHeight) {
    for (i=[1:num_wheels]) {
      translate_z(i*wheel_housing_thickness) wheel(labels=false);
    }
  }
  color("green") assembly_cut(2) translate_z(travel) translate_z(sleeve_z) {
    encoding_sleeve();
    for (i=[1:num_wheels]) {
      translate_z(i*wheel_housing_thickness) encoding_sleeve();
    }
  }
  color("teal") assembly_cut(3) translate_z(0.5*layerHeight) translate_z(travel) translate_z(sleeve_z) {
    for (i=[0:num_wheels-1]) {
      translate_z(i*wheel_housing_thickness) fixing_sleeve();
    }
  }
  color("lightyellow") assembly_cut(4,2) bottom_housing();
  for (i=[1:num_wheels]) {
    color(i%2 ? "yellow" : "orange")
    assembly_cut(10+i,2) translate_z(i*wheel_housing_thickness) wheel_housing();
  }
  color("salmon") assembly_cut(7,2) translate_z((num_wheels+1)*wheel_housing_thickness) top_housing();
  color("pink") assembly_cut(18,0) screw();
}
assembly();
