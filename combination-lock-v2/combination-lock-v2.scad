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
wheel_cover_thickness = roundToLayerHeight(2.7);
wheel_z = roundToLayerHeight(-1.5);
//wheel_z = 0;
// moving parts
encoder_sleeve_thickness = roundToLayerHeight(3);
encoder_mesh_thickness = roundToLayerHeight(2.7);
fixer_sleeve_thickness = roundToLayerHeight(5.5);
// travel
sleeve_z = roundToLayerHeight(0.3);
change_travel = -encoder_mesh_thickness - sleeve_z + roundToLayerHeight(0.5);
false_travel = encoder_mesh_thickness - roundToLayerHeight(0.5);
max_travel = wheel_housing_thickness - encoder_sleeve_thickness - sleeve_z - roundToLayerHeight(1.0);
min_true_travel = roundToLayerHeight(false_travel+1);

//-----------------------------------------------------------------------------
// Profiles
//-----------------------------------------------------------------------------

module wheel_outer_profile() {
  circle(d = wheel_diameter);
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

//function pin_positions = [for (i=[0:num_positions-1])];

//-----------------------------------------------------------------------------
// Sleeve with teeth chamfered in all directions
//-----------------------------------------------------------------------------

function sym_polygon_y_coords3(list) =
  concat(
    list,
    mul_vecs([1,-1,1],reverse(list))
  );
function sym_polygon_yz_coords(list) =
  concat(
    list,
    mul_vecs([1,1,-1],reverse(list)),
    mul_vecs([1,-1,-1],list),
    mul_vecs([1,-1,1],reverse(list))
  );
module sleeve_tooth(h, offset=0, internal=false, dz=1) {
  w = 0.25 * 2*PI * sleeve_diameter / num_positions;
  k = 6;
  x1 = sleeve_diameter/2 * 0.98;
  x2 = sleeve_outer_diameter/2 + 2*offset;
  y1 = internal ? w/2+k : 0.2;
  y2 = w/2 + offset;
  z1 = h/2 + (internal ? k-0.6 : 0);
  z2 = h/2 + (internal ? -0.6 : -(w-2*y1)/2);
  dz1 = internal ? -w/2*dz : 0.1;
  dz2 = internal ? 0 : -w/2*dz;
  translate_z(h/2)
  prism([
    reverse(sym_polygon_yz_coords([[x1,y1,z1+dz1],[x1,y2,z2+dz1]])),
    reverse(sym_polygon_yz_coords([[x2,y1,z1+dz2],[x2,y2,z2+dz2]]))
  ], convexity=2);
}
module sleeve_teeth(h, pins=1, offset=0, internal=false, dz=2/3) {
  intersection() {
    union() for (i=[0:num_positions-1]) {
      if (pins == 2 || pins == 1 && (i!=0 && i!=3 && i!=5 && i!=7)) {
        rotate(90+i*360/num_positions)
        sleeve_tooth(h, offset=offset, internal=internal, dz=dz);
      }
    }
    if (internal) {
      translate_z(-2)
      cylinder(d=sleeve_outer_diameter+4*offset, h=h+4);
    } else {
      cylinder(d=sleeve_outer_diameter+4*offset, h=h);
    }
  }
  if (internal) {
    translate_z(-1)
    cylinder(d=sleeve_outer_diameter+4*offset, h=1);
    cylinder(d1=sleeve_outer_diameter+4*offset, d2=sleeve_diameter+offset, h=dz);
    translate_z(h-dz)
    cylinder(d2=sleeve_outer_diameter+4*offset, d1=sleeve_diameter+offset, h=dz);
    translate_z(h)
    cylinder(d=sleeve_outer_diameter+4*offset, h=1);
  }
}
module sleeve_teeth_hole(h, pins=2, outward=true, dz=0.5) {
  sleeve_teeth(h,pins,offset=C,internal=true,dz=dz);
}
*!sleeve_teeth(h=4);
*!group() {
  sleeve_teeth_hole(h=4, pins=1);
  translate_z(6) color("red") sleeve_teeth(h=4, outward=t);
}
*!sleeve_tooth(h=5);
*!sleeve_tooth(h=4, offset=C, internal=true, dz=0.5);

//-----------------------------------------------------------------------------
// Wheels
//-----------------------------------------------------------------------------

module sleeve_outer_hole_profile(pins=2) {
  offset(C) sleeve_outer_profile(pins, offset_outer=C);
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
    // notches separating numbers
    wheel_notch_depth = 0.5;
    wheel_notch_width = 0.8;
    linear_extrude(lots,center=true) {
      for (i=[0:num_positions-1]) {
        rotate(i*360/num_positions)
        translate([wheel_diameter/2-wheel_notch_depth/2,0]) square([wheel_notch_depth,wheel_notch_width],true);
      }
    }
    // teeth and other internals
    translate_z(wheel_z-eps)
    linear_extrude(lots, convexity=5) {
      sleeve_outer_hole_profile();
    }
    sleeve_chamfer = roundToLayerHeight(1);
    sleeve_teeth_hole(wheel_cover_thickness-0.5, pins=2);
    
    *translate_z(wheel_cover_thickness-sleeve_chamfer) {
      cylinder(d1=sleeve_diameter+2*C,d2=wheel_cover_diameter+2*C,h=sleeve_chamfer);
    }
    translate_z(wheel_cover_thickness-sleeve_chamfer) {
      cylinder(d1=sleeve_diameter+2*C,d2=wheel_cover_diameter+2*C,h=sleeve_chamfer);
    }
    translate_z(wheel_cover_thickness-eps) {
      cylinder(d=wheel_cover_diameter+2*C,h=lots);
    }
    sleeve_bottom_chamfer = roundToLayerHeight(0.8);
    *translate_z(-eps) {
      cylinder(d2=sleeve_diameter+2*C,d1=sleeve_outer_diameter+4*C,h=sleeve_bottom_chamfer);
    }
    translate_z(wheel_z-eps)
    linear_extrude(-wheel_z+layerHeight-eps, convexity=5) {
      offset(C) wheel_cover_profile();
    }
    chamfer = 0.6;
    translate_z(min(-chamfer,wheel_z)-eps) {
      cylinder(d1=wheel_diameter-1, d2=wheel_cover_diameter+2*C, h=chamfer);
    }
    *linear_extrude(lots, convexity=5) {
      offset(C) wheel_cover_profile();
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
      translate_z(0) sleeve_teeth(encoder_mesh_thickness, dz=2/3);
    }
    translate_z(-eps)
    cylinder(d1=shaft_diameter+2*C, d2=shaft_minor_diameter+2*C, h=shaft_notch);
  }
}

module fixing_sleeve(notch=false) {
  translate_z(encoder_sleeve_thickness)
  difference() {
    union() {
      linear_extrude(fixer_sleeve_thickness, convexity=5) {
        sleeve_outer_profile(0);
      }
      //z = encoder_mesh_thickness - roundToLayerHeight(1.0);
      z = roundToLayerHeight(-change_travel - 1 - sleeve_z);
      translate_z(z) sleeve_teeth(fixer_sleeve_thickness - z, dz=2/3);
    }
    translate_z(-eps + (notch ? encoder_sleeve_thickness : 0))
    linear_extrude(fixer_sleeve_thickness+2*eps, convexity=5) {
      circle(d=shaft_diameter+2*C);
      rotate(360*4/10) if (notch) hull() {
        circle(d=shaft_diameter+2*C);
        translate_y(lots) circle(d=shaft_diameter-0*C);
      }
    }
    if (notch) {
      rotate(360*4/10) linear_extrude(lots,center=true) hull() {
        circle(d=shaft_minor_diameter-0*C);
        translate_y(lots) circle(d=shaft_minor_diameter-0*C);
      }
      translate_z(-eps)
      cylinder(d1=shaft_diameter+2*C, d2=shaft_minor_diameter+2*C, h=shaft_notch);
    }
  }
}


*!encoding_sleeve();
*!fixing_sleeve();
*!fixing_sleeve(notch=true);

module export_encoding_sleeve() { encoding_sleeve(); }
module export_fixing_sleeve() { rotate([180]) fixing_sleeve(); }
module export_fixing_sleeve_notch() { rotate([180]) fixing_sleeve_notch(); }

//-----------------------------------------------------------------------------
// Shaft
//-----------------------------------------------------------------------------

shaft_bottom_z = encoder_sleeve_thickness + roundToLayerHeight(-0.5);

//shackle_diameter = shaft_diameter+2;
shackle_diameter = 10;
shackle_length = roundToLayerHeight(18);
shackle_depth = min_true_travel;

module shaft_notch() {
  difference() {
    cylinder(d=shaft_diameter+1,h=encoder_sleeve_thickness+layerHeight);
    translate_z(-eps)
    cylinder(d1=shaft_diameter,d2=shaft_minor_diameter,h=shaft_notch);
    translate_z(shaft_notch)
    cylinder(d=shaft_minor_diameter,h=encoder_sleeve_thickness+layerHeight);
  }
}
module shaft(num_wheels = num_wheels) {
  height = (num_wheels+1) * wheel_housing_thickness + top_housing_thickness;
  difference() {
    union() {
      translate_z(shaft_bottom_z)
      linear_extrude(height-shaft_bottom_z + eps) {
        circle(d=shaft_diameter);
      }
      *translate_z(height-min_true_travel) {
        linear_extrude(min_true_travel) {
          shaft_top_pin_profile();
        }
      }
    }
    translate_z(sleeve_z + encoder_sleeve_thickness - layerHeight) {
      shaft_notch();
    }
    for (i=[1:num_wheels]) {
      translate_z(i*wheel_housing_thickness + sleeve_z - layerHeight) {
        shaft_notch();
      }
    }
  }
  shackle(num_wheels);
}
module shackle(num_wheels = num_wheels, offset=0) {
  height = (num_wheels+1) * wheel_housing_thickness + top_housing_thickness;
  // attached to shaft
  translate_z(height - shackle_depth)
  intersection() {
    shackle_shaft_with_chamfer(offset=offset);
    translate_x(-shaft_diameter/2-offset) positive_x();
    rotate(180)
    translate_x(-shaft_diameter/2-offset) positive_x();
  }
  //translate_z(height - shackle_depth - change_travel) intersection() {
  translate_z(height - shackle_depth + min_true_travel) intersection() {
    shackle_shaft_with_chamfer(offset=offset);
    translate_x(-shaft_diameter/2-offset+eps) positive_x();
  }
  translate_z(height - shackle_depth + min_true_travel - change_travel) {
    shackle_shaft_with_chamfer(offset=offset);
  }
  // over screw
  translate_x(screw_x) {
    chamfer = 3*layerHeight;
    translate_z(height - shackle_depth + chamfer )
    cylinder(d=shackle_diameter+2*offset, h = shackle_length + shackle_depth);
    translate_z(height - shackle_depth)
    cylinder(d1=shackle_diameter-2*chamfer+2*offset , d2=shackle_diameter+2*offset, h=chamfer+eps);
  }
  // top
  translate_z(height+shackle_length-roundToLayerHeight(1.5)) {
    linear_extrude_cone_chamfer(roundToLayerHeight(8), housing_chamfer,housing_chamfer) {
      hull() {
        circle(d=shackle_diameter+2*offset);
        translate_x(screw_x) circle(d=shackle_diameter+2*offset);
      }
    }
  }
}
module shackle_shaft_with_chamfer(offset=0) {
  chamfer = (shackle_diameter - shaft_diameter)/3;
  union() {
    cylinder(d=shackle_diameter+2*offset, h=shackle_length + shackle_depth);
    translate_z(-chamfer+eps)
    cylinder(d1=shaft_diameter+2*offset, d2=shackle_diameter+2*offset, h=chamfer);
  }
}
*!shaft();
*!shackle();

module export_shaft() { rotate([180]) shaft(); }

//-----------------------------------------------------------------------------
// Screw
//-----------------------------------------------------------------------------

bottom_thickness = roundToLayerHeight(1.5);
bottom_housing_thickness = bottom_thickness + wheel_housing_thickness - (shaft_bottom_z + change_travel) + layerHeight;
top_housing_thickness = roundToLayerHeight(6.5);
housing_chamfer = 1;


screw_diameter = 8;
screw_head_diameter = shackle_diameter;
screw_x = -wheel_diameter - 5;

module screw(num_wheels = num_wheels, threads=true, internal=false) {
  screw_top_z = bottom_housing_thickness + num_wheels * wheel_housing_thickness + top_housing_thickness - min_true_travel;
  dh = internal ? lots : 0;
  translate_z(wheel_housing_thickness-bottom_housing_thickness)
  translate_x(screw_x) {
    make_screw(screw_diameter, bottom_thickness,bottom_housing_thickness,dh+screw_top_z, slot_diameter=4, slot_depth=3,
      head_straight_thickness = roundToLayerHeight(3.0)+dh,
      head_thickness=(screw_head_diameter-screw_diameter)/2,
      threads=threads, internal=internal);
  }
}
module export_screw() { rotate([180]) screw(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module housing_profile(screw_hole=true) {
  difference() {
    hull() {
      circle(d = wheel_diameter-1);
      translate_x(screw_x)
      //translate_x(-wheel_diameter)
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
    translate_x(-wheel_diameter/2-3) positive_x2d();
  }
}
tight_C = C/2;
module housing_connector() {
  translate_z(-4*layerHeight)
  linear_extrude(4*layerHeight, convexity=5) housing_connector_profile();
}
module housing_connector_hole() {
  translate_z(-7*layerHeight) {
    linear_extrude(lots, convexity=5) offset(tight_C) housing_connector_profile();
  }
}

module wheel_housing(last = false) {
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
      dh = wheel_z < 0 && !last ? layerHeight : 0;
      translate_z(wheel_z+wheel_thickness+layerHeight+eps)
      linear_extrude(wheel_housing_thickness-(wheel_thickness+layerHeight+(last?wheel_z:0))-dh, convexity=5) {
        housing_profile();
      }
      housing_connector();
    }
    // holes through
    translate_z(-eps) linear_extrude(lots, convexity=5) {
      sleeve_outer_hole_profile(pins=1);
    }
    z = wheel_cover_thickness-0.3;
    // chamfer tops
    if (!last) intersection() {
      translate_z(z) sleeve_teeth_hole(wheel_housing_thickness-z, pins=1);
      translate_z(false_travel+encoder_mesh_thickness+sleeve_z-1.5) positive_z();
    }
    // holes up to false travel
    intersection() {
      translate_z(z) sleeve_teeth_hole(wheel_housing_thickness-z, pins=2, dz=0);
      translate_z(false_travel+encoder_mesh_thickness+sleeve_z-1.5) negative_z();
    }
    translate_z(z) sleeve_teeth(false_travel+encoder_mesh_thickness+sleeve_z-z, pins=2, offset=C);
    // chamfer top
    if (!last) {
      *sleeve_hole_chamfer(wheel_housing_thickness);
      translate_z(wheel_housing_thickness) housing_connector_hole();
    }
  }
}
module sleeve_hole_chamfer(z) {
  translate_z(z-2)
  cylinder(d1=sleeve_outer_diameter+2*C-3*2, d2=sleeve_outer_diameter+2*C+2*C, h=2+eps);
}
*!wheel_housing($fn=30);

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


module top_housing() {
  difference() {
    union() {
      wheel_housing(last=true);
      //linear_extrude(top_thickness, convexity=5) {
      translate_z(wheel_housing_thickness) {
        linear_extrude_cone_chamfer(top_housing_thickness,0,housing_chamfer,convexity=4) {
          housing_profile(screw_hole=false);
        }
        housing_connector();
        *translate_z(-3*layerHeight) {
          linear_extrude(3*layerHeight+eps,convexity=5) {
            sleeve_outer_profile(1);
          }
        }
        z_stop = encoder_sleeve_thickness + sleeve_z + max_travel + layerHeight;
        translate_z(-wheel_housing_thickness + z_stop) {
          cylinder(d=sleeve_outer_diameter+8*C, h = 1 + wheel_housing_thickness - z_stop);
        }
      }
    }
    // shaft
    translate_z(-lots/2-eps)
    linear_extrude(lots) {
      circle(d=shaft_diameter+2*C);
    }
    // shackle
    *translate_z(top_housing_thickness-min_true_travel-2*layerHeight) {
      linear_extrude(lots) {
        offset(C) shaft_top_pin_profile();
      }
    }
    *translate_z(top_housing_thickness-min_true_travel-2*layerHeight+change_travel) {
      linear_extrude(lots) {
        rotate(180) offset(C) shaft_top_pin_profile();
      }
    }
    *translate_z(top_housing_thickness - min_true_travel + change_travel) {
      intersection() {
        cylinder(d=shackle_diameter+2*C,h=lots);
        cube([shackle_diameter-2+2*C,lots,lots],true);
      }
    }
    shackle(num_wheels=0, offset=C);
    rotate(180) translate_z(change_travel) {
      shackle(num_wheels=0, offset=C);
    }
    // screw
    screw(num_wheels=0, threads=false, internal=true);
  }
}
module shaft_top_pin_profile() {
  w = shackle_diameter/2 + 0.0;
  h = 2;
  intersection() {
    hull() {
      circle(d=h);
      translate_x(-w) circle(d=h);
    }
    *sleeve_outer_profile(2);
  }
  *translate([-w,-h/2]) square([w,h]);
}
/*module shackle_countersink_profile() {
  intersection() {
    circle(d=shackle_diameter);
  }
}*/

module top_wheel_housing() {
  //wheel_housing(last=true);
  translate_z(wheel_housing_thickness) top_housing();
}
!group() {
  intersection() {
    top_housing($fn=30);
    positive_y();
  }
  translate_z(false_travel)
  //translate_z(min_true_travel)
  //translate_z(change_travel) rotate(180)
  color("red")shaft(num_wheels=0);
}

module export_wheel_housing() { rotate([180]) wheel_housing(); }
module export_bottom_housing() { bottom_housing(); }
module export_top_housing() { rotate([180]) top_housing(); }
module export_top_wheel_housing() { rotate([180]) top_wheel_housing(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e,d=0) {
  intersection() {
    translate_y(e*0.01) children();
    //rotate(d*10)
    //rotate(36)
    translate_y(e*0.01 + d*0.0) positive_y();
    //translate_z(4.5*wheel_housing_thickness) negative_z();
  }
}
module assembly_cut_x(e) {
  intersection() {
    translate_x(e*0.01) children();
    translate_x(e*0.01) positive_x();
  }
}

module assembly() {
  $fn = 30;
  travel = 0*change_travel + 0*false_travel + 0*min_true_travel + 0*max_travel;
  //travel = 1.5;
  //travel = 1*max_travel;
  // -2.5 = change
  // 0.5 = neutral
  // 2.5 = false gate
  // 6 = max travel
  
  color("red") assembly_cut(0) translate_z(travel + 0.5*layerHeight) {
    shaft();
  }
  *color("blue") assembly_cut(1,1) translate_z(0.5*layerHeight) {
    for (i=[1:num_wheels]) {
      translate_z(i*wheel_housing_thickness) wheel(labels=false);
    }
  }
  *color("green") assembly_cut(2) assembly_cut_x(2) translate_z(travel) translate_z(sleeve_z) {
    for (i=[1:num_wheels]) {
      translate_z(i*wheel_housing_thickness) encoding_sleeve();
    }
  }
  *color("teal") assembly_cut(3) assembly_cut_x(3) translate_z(0.5*layerHeight) translate_z(travel) translate_z(sleeve_z) {
    for (i=[0:num_wheels-1]) {
      translate_z(i*wheel_housing_thickness) fixing_sleeve();
    }
  }
  *color("lightyellow") assembly_cut(4,2) bottom_housing();
  for (i=[1:num_wheels]) {
    color(i%2 ? "yellow" : "orange")
    assembly_cut(10+i,2) translate_z(i*wheel_housing_thickness) {
      if (i==num_wheels) {
        top_wheel_housing();
      } else {
        wheel_housing();
      }
    }
  }
  color("pink") assembly_cut(18,0) screw();
}
assembly();
