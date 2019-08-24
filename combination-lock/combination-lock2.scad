//=============================================================================
// Combination padlock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

C = 0.125;
layerHeight = 0.15;
function roundToLayerHeight(z) = round(z/layerHeight)*layerHeight;

wheelThickness = roundToLayerHeight(5);
wheelSep = roundToLayerHeight(2.5);
wheelPos = 2;
wheelR = 8;
//innerWheelR = 5.7;
innerWheelR = wheelR-1.2;
innerWheelDR = 1.0;
shaftR = 3;
shaftR2 = shaftR + 1.5;

positions = 10;
wheels = 4;

//-----------------------------------------------------------------------------
// Wheels
//-----------------------------------------------------------------------------

//function pf(x) = cos(x);
//function pf(x) = cos(x)+cos(2*x)/2+cos(3*x)/6+cos(4*x)/24;
//function pf(x) = sign(cos(x)) * pow(abs(cos(x)),0.5);
function pf(x,o=0.0,p=0.25) = sign(-cos(x)+o) * pow(abs(-cos(x)+o),p) - pow(o+1,p);
module gear_profile(C=0) {
  step = 1;
  *polygon([for (i=[0:step:360-1]) polar(i, innerWheelR + C + 0.5*(pf(i*positions)))]);
  union() {
    circle(innerWheelR - innerWheelDR);
    for (i=[0:positions-1]) {
      rotate((i+0.5)*360/positions)
      sym_polygon_y([for (j=[0:10/positions:70/positions]) polar(j,innerWheelR), polar(110/positions,innerWheelR-innerWheelDR)]);
    }
  }
}

module outer_wheel(labels=true, for_inner=true, pos=0) {
  difference() {
    linear_extrude(wheelThickness,convexity=5) {
      difference() {
        circle(wheelR);
        for (i=[0:9]) {
          rotate(360/positions*i)
          translate_x(wheelR*1.06) circle(wheelR * 0.09);
        }
        if ($children) {
          children();
        } else if (for_inner) {
          offset(C) gear_profile(0);
        } else {
          circle(shaftR+C);
        }
      }
    }
    if (labels) {
      labelThickness = wheelR * 0.03;
      for (i=[0:positions-1]) {
        rotate([0,0,360/positions*i])
        translate([0,-wheelR,wheelThickness/2])
        linear_extrude_y(labelThickness) {
          text(str(i),size=4,font="ubuntu",halign="center",valign="center");
          //rotate(-90) text(str(i),size=3,font="Ubuntu",halign="center",valign="center");
        }
      }
    }
    if (!for_inner) {
      rotate(360*pos/positions) inner_wheel_inner();
    }
  }
}

module inner_wheel_inner() {
  shaftR2C = shaftR2 + 2*C;
  translate_z(-eps) {
    // gates
    linear_extrude(wheelThickness+2*eps,convexity=10) {
      shaft_profile(C=C, all_pins=false);
    }
    // false gates
    falseGateDepth = roundToLayerHeight(0.8);
    intersection() {
      linear_extrude(2+2*eps,convexity=10) {
        shaft_profile(C=C, all_pins=true);
      }
      union() {
        cylinder(r=shaftR2C,h=0.3+falseGateDepth+2*eps);
        translate_z(0.3+falseGateDepth) cylinder(r1=shaftR2C,r2=shaftR,h=1+2*eps);
      }
    }
    // free space
    cylinder(r=shaftR2C,h=0.3+2*eps);
    translate_z(0.3) cylinder(r1=shaftR2C,r2=shaftR,h=1+2*eps);
  }
  translate_z(wheelThickness+eps) {
    // free space (top)
    translate_z(-0.3) cylinder(r=shaftR2C,h=0.3+2*eps);
    translate_z(-1.3) cylinder(r2=shaftR2C,r1=shaftR,h=1+2*eps);
  }
}

module inner_wheel() {
  difference() {
    linear_extrude(wheelThickness,convexity=5) {
      difference() {
        *circle(innerWheelR);
        gear_profile(0);
        *circle(innerWheelR-innerWheelDR);
      }
    }
    inner_wheel_inner();
  }
}
//!inner_wheel();

module export_inner_wheel() { inner_wheel(); }
module export_outer_wheel() { outer_wheel(); }
module export_wheel0() { outer_wheel(for_inner=false,pos=0); }

//!group(){inner_wheel(); outer_wheel(false); }

//-----------------------------------------------------------------------------
// Alternate wheels
//-----------------------------------------------------------------------------

altInnerR1 = shaftR + 1.2;
altInnerR2 = altInnerR1 + 1.2;

module outer_wheel_alt(labels=true) {
  difference() {
    outer_wheel(labels) {
      circle(altInnerR2+2*C);
    }
    translate_z(wheelThickness - roundToLayerHeight(1))  {
      cylinder(r = altInnerR2 + C + 1, h=lots);
    }
  }
}
module inner_wheel_alt() {
  linear_extrude(wheelThickness + wheelSep,convexity=5) {
    difference() {
      circle(altInnerR1);
      circle(shaftR+C/2);
    }
  }
}

module inner_pin_alt_profile(C = 0) {
  shaftR2C = altInnerR2 + 2*C; // note: extra clearance to prevent sideways interaction 
  w = shaftPinW+2*C;
  intersection() {
    circle(shaftR2C);
    translate([-w/2,0]) square([w,shaftR2C]);
  }
  *wedge(360/positions * 0.7,r=shaftR2C);
}
module inner_alt_profile(C = 0, all_pins = false) {
  circle(r=altInnerR+C);
  pins = all_pins ? [0:positions-1] : [0,3,7];
  offset = 1*360/10;
  rotations = [for (i=pins) 360*i/positions + offset];
  rotated(rotations) inner_pin_alt_profile(C);
}

//!group(){outer_wheel_alt(false); inner_wheel_alt(); }

//-----------------------------------------------------------------------------
// Shaft
//-----------------------------------------------------------------------------

shaftPinW = shaftR * 2*PI / positions * 0.9;
module shaft_pin_profile(C = 0) {
  shaftR2C = shaftR2 + 2*C; // note: extra clearance to prevent sideways interaction 
  w = shaftPinW+2*C;
  intersection() {
    circle(shaftR2C);
    translate([-w/2,0]) square([w,shaftR2C]);
  }
  *wedge(360/positions * 0.7,r=shaftR2C);
}
module shaft_profile(C = 0, all_pins = false) {
  circle(r=shaftR+C/2);
  pins = all_pins ? [0:positions-1] : [0,3,7];
  //pins = all_pins ? [0:positions-1] : [0,4,6];
  //pins = all_pins ? [0:positions-1] : [0,4,6];
  //offset = -90;
  //offset = 1*360/10;
  offset = 180;
  rotations = [for (i=pins) 360*i/positions + offset];
  rotated(rotations) shaft_pin_profile(C);
}
//!shaft_profile(all_pins=true);

module actuator_profile() {
  sym_polygon_x([
    [lugX,shaftLength],
    [lugX,lugZ-shaftTravel+lugDepth-lugChamfer2+C],
    [lugX+lugTravel+C,lugZ-shaftTravel+lugDepth-lugChamfer2+lugTravel/1.2+C],
    [lugX+lugTravel+C,lugZ+1.0],
    //[lugX+lugTravel-0.5,lugZ+lugDepth/2],
    [lugX+lugTravel-0.1,actuatorEndZ]]);
}
module actuator_center_profile() {
  sym_polygon_x([
    [1,shaftLength],
    [1,actuatorEndZ]]);
}

springPinWidth = 5;
module spring_pin_profile() {
  z = lugZ-shaftTravel;
  z2 = shackleZ;
  z3 = min(roundToLayerHeight(z2 - 2));
  z4 = max(shaftLength, roundToLayerHeight(z - 2));
  polygon([
    [lugX,z+1],[lugX+1,z],[shackleX+shackleR-1,z],
    //[shackleX-shackleR-C,z],
    //[shackleX-shackleR-C,z2], [shackleX+C,z2],
    [shackleX+shackleR-1,z3], [shackleX-shackleR-1,z3],
    [shackleX-shackleR-2,z4],[lugX,z4]]);
}
module spring_pin_profile2() {
  z = lugZ-shaftTravel;
  z2 = shackleZ;
  z3 = z2 - 2;
  z4 = max(shaftLength, roundToLayerHeight(z - 2));
  polygon([
    [lugX,z+1],[lugX+1,z],[shackleX-shackleR-0.5,z],[shackleX-shackleR+1.2,z-1.5],
    [shackleX-shackleR+1.2,z3+1],[shackleX-shackleR,z3], [shackleX-shackleR-1,z3],
    [shackleX-shackleR-2,z4],[lugX,z4]]);
}

module shaft() {
  h = shaftLength;
  cylinder(r=shaftR,h=h);
  intersection() {
    linear_extrude(h,convexity=5) {
      shaft_profile(all_pins = false);
    }
    for (i=[0:wheels-1]) {
      pinH = wheelSep+1;
      translate_z(i*(wheelThickness+wheelSep)) {
        translate_z(0) cylinder(r1=shaftR,r2=shaftR2,h=1);
        translate_z(1-eps) cylinder(r=shaftR2,h=pinH-2);
        translate_z(pinH-1) cylinder(r2=shaftR,r1=shaftR2,h=1);
        //translate_z(3) cylinder(r1=shaftR2,r2=shaftR,h=1);
      }
    }
  }
  intersection() {
    group() {
      linear_extrude_y(2*(shaftR+0),true) {
        actuator_profile();
      }
      linear_extrude_y(2*(shaftR+1),true) {
        actuator_center_profile();
      }
    }
    translate_z(shaftLength) cylinder(r1=shaftR,r2=shaftR+40,h=100);
  }
  translate_z(shaftLength) cylinder(r1=shaftR,r2=0,h=shaftR);
  union() {
    difference() {
      linear_extrude_y(springPinWidth,true) {
        spring_pin_profile();
      }
      translate([shackleX,0,shackleZ-C]) cylinder(r1=shackleR+C-0.6,r2=shackleR+C+eps,h=0.6);
      translate([shackleX,0,shackleZ-C+0.6-eps]) cylinder(r=shackleR+C+eps,h=lots);
      translate([shackleX,0,max(lugZ-shaftTravel-1,shackleZ-C+0.6)]) cylinder(r1=shackleR+C+eps,r2=shackleR+1,h=1);
    }
    *translate([shackleX,0,roundToLayerHeight(shackleZ-2)+eps]) cylinder(r=shackleR,h=2-C);
  }
  mirror([1,0,0])
  difference() {
    union() {
      linear_extrude_y(springPinWidth,true) {
        spring_pin_profile2();
      }
    }
  }
}
//!shaft();

shaftTravel = roundToLayerHeight(5);
shaftLength = roundToLayerHeight(wheels*(wheelThickness+wheelSep) + 1.5);
//shaftTravel = 7;

lugDepth = roundToLayerHeight(4.5);
lugChamfer = 1.2;
lugChamfer2 = roundToLayerHeight(1.2);
//lugZ = wheels*(wheelThickness+wheelSep) + max(2, shaftTravel - wheelThickness);
lugZ = roundToLayerHeight(shaftLength + lugDepth + shaftTravel - lugDepth + 2);
lugTravel = 2.5;
lugX = shaftR-1;
//lugX = 0;

actuatorEndZ = roundToLayerHeight(lugZ+lugDepth - 1);

module export_shaft() { rotate([180]) shaft(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housingFloor   = roundToLayerHeight(1.0);
housingCeiling = roundToLayerHeight(1.5);
housingWall    = 2*0.4+2*C;
housingWall2   = 1.8;
housingChamfer = 1;
housingInteriorHeight = actuatorEndZ + shaftTravel;
housingHeight  = housingInteriorHeight + housingFloor + housingCeiling;

module housing_profile(wall=1,C=0) {
  hull() {
    mirrored([1,0,0]) translate([shackleX,0]) circle(r=shackleR+C+wall*housingWall2);
    circle(r=wheelR+2*C+wall*housingWall);
  }
}
module housing_interior_profile() {
  housing_profile(0,C=C);
}

module housing() {
  wall = housingWall;
  floor   = housingFloor;
  ceiling = housingCeiling;
  h = housingHeight;
  chamfer = housingChamfer;
  difference() {
    //translate_z(h/2-2) {
    translate_z(-floor) {
      *difference() {
        chamfer_cube(2*(shackleX+shackleR+2),2*(shackleR+2),h,1);
        chamfer_cube(2*(shackleX+shackleR+2*C),2*(shackleR+2*C),h+2*C-4,1);
      }
      minkowski() {
        translate_z(chamfer) linear_extrude(h-2*chamfer) {
          offset(-chamfer) housing_profile();
        }
        double_cone(chamfer);
      }
    }
    // wheels
    for (i=[0:wheels-1]) {
      translate_z(i*(wheelThickness+wheelSep) + wheelSep) {
        cylinder(r=wheelR + 2*C,h=wheelThickness);
      }
      *translate([-(wheelR+2*C),-lots/2,i*(wheelThickness+wheelSep) + wheelSep]) {
        cube([2*(wheelR+2*C),lots,wheelThickness+C]);
      }
    }
    windowA = 30;
    windowA2 = 50;
    windowZ = 0.5;
    windowZ2 = 2.0;
    windowCutout = reverse([polar(90-windowA2,wheelR*2),for (i=[-windowA:5:windowA]) polar(i+90,wheelR-0.5),polar(90+windowA2,wheelR*2)]);
    //windowCutout2 = reverse([polar(90-windowA2,wheelR*2+2),for (i=[-windowA:5:windowA]) polar(i+90,wheelR+1.2),polar(90+windowA2,wheelR*2+2)]);
    windowCutout2 = mul_vecs([1.2,1.2],windowCutout);
    prism([windowCutout2,windowCutout,windowCutout,windowCutout2],
      [roundToLayerHeight(wheelSep-windowZ2),roundToLayerHeight(wheelSep-windowZ), roundToLayerHeight(wheels * (wheelThickness+wheelSep)+windowZ), roundToLayerHeight(wheels * (wheelThickness+wheelSep)+windowZ2)], convexity=5);
    *translate_z(wheelSep-1) {
      linear_extrude(wheels * (wheelThickness+wheelSep) - wheelSep + 2) {
        polygon(windowCutout);
      }
    }
    // shackle holes
    translate([shackleX, 0,roundToLayerHeight(shackleZ)-layerHeight]) cylinder(r=shackleR+C,h=lots);
    translate([-shackleX,0,shackleZ2-C]) cylinder(r=shackleR+C,h=lots);
    //translate([shackleX,0,0]) cylinder(r=shackleR-1+C,h=30);
    translate([shackleX,0,0]) linear_extrude(shackleZ-2+C) square(2*(shackleR-1.2+C),true);
    *shackle_retaining_pin(C=C+2*eps);
    // shaft hole
    *color("pink") minkowski() {
      shaft();
      translate([-C,-C,0]) cube([2*C,2*C,shaftTravel+layerHeight + 1]);
    }
    color("pink") linear_extrude(lugZ+lugDepth+C,convexity=5) shaft_profile(C);
    linear_extrude_y(2*(shaftR+C),true) {
      minkowski() {
        actuator_profile();
        translate([-C,0]) square([2*C,shaftTravel+layerHeight]);
      }
    }
    linear_extrude_y(2*(shaftR+1+C),true) {
      minkowski() {
        actuator_center_profile();
        translate([-C,0]) square([2*C,shaftTravel+layerHeight]);
      }
    }
    linear_extrude_y(springPinWidth+2*C,true) {
      minkowski() {
        union() {
          spring_pin_profile();
          mirror([1,0,0]) spring_pin_profile2();
        }
        translate([-C,0]) square([2*C,shaftTravel+layerHeight + 1]);
      }
      //translate_y(shaftTravel) offset(C) sym_polygon_x(actuatorShape);
    }
    // lug holes
    mirrored([1,0,0]) color("lightgreen") group() {
      lug(C);
      translate_x(-lugTravel) lug(C);
      //translate_x(-lugTravel*3) lug(C);
      // holes to get lugs in
      *linear_extrude_y(lugW+2*C,true) {
        sym_polygon_x([[lugX+2,lugZ-C],[lugX+2,lugZ+lugDepth+C],[lugDepth/2+C+2,lugZ+lugDepth+C],[lugDepth/2+0.5+C,lugZ+lugDepth+2+C],[lugDepth/2+0.5+C,h]]);
      }
    }
    // cap
    if (0) {
      capR = shackleR + 1 + C;
      z1 = h-ceiling-floor+C - eps;
      translate_x(-shackleX+shackleR+2) linear_extrude_x(shackleX*2 + eps) {
        sym_polygon_x([[capR+1,z1],[capR+1,z1+0.3],[capR,z1+1.2],[capR,h]]);
      }
      linear_extrude_y(lots,true) {
        polygon([[shackleX,z1],[shackleX,h],[lots,h],[lots,z1]]);
      }
    }
    // wheel holes
    *translate_z(wheelSep) {
      cylinder(r=wheelR + C,h=lots);
    }
  }
}
//!intersection(){housing(); positive_y();}

module housing_interior_mask() {
  linear_extrude(housingInteriorHeight) {
    housing_interior_profile();
  }
}
tightC = 0.05;
module housing_connector_profile() {
  intersection() {
    housing_interior_profile();
    union() {
      //square([2*(innerMaskX-1), lugW+2*C],true);
      *chamfer_rect(2*(wheelR+2*C+0.8), lugW+2*C,2.6);
      chamfer_rect(2*(wheelR+2*C+0.8), lugW+2*C-3,1.0);
      difference() {
        *square([2*innerMaskX, lugW+2*C],true);
        *chamfer_rect(2*(wheelR+2*C+1.5), lugW+2*C-2,2.6);
        chamfer_rect(2*(wheelR+2*C+1.5), lugW+2*C-3,1.0);
        square([lots, 2],true);
      }
      intersection() {
        square([2*(wheelR+2*C+1.5), lugW+2*C-3],true);
        positive_x2d();
        translate_y(2) positive_y2d();
      }
    }
  }
}
module housing_wheel_mask(extraC = 0) {
  translate_z(wheelSep+wheelThickness-eps)
  //linear_extrude(shaftLength-wheelSep+eps) {
  linear_extrude(lots,convexity=4) {
    circle(r=wheelR+2*C-2*eps-tightC+extraC);
    offset(extraC) housing_connector_profile();
  }
}
capTravel = 2.5;
housingCapHeight = roundToLayerHeight(1);
module housing_cap_mask() {
  h = housingCapHeight;
  w0 = lugW+0.5-0+2*C;
  w1 = w0-2;
  w2 = lugW-2+2*C;
  translate_z(housingInteriorHeight-h) positive_z();
  difference() {
    translate_z(lugZ+lugDepth+C-eps) {
      linear_extrude(lots,convexity=5) {
        *translate([-shackleX,-w1/2]) {
          square([2*shackleX - capTravel - shackleR,w1]);
        }
        translate([-wheelR,-w0/2]) {
          square([wheelR*2 - capTravel - 0.2,w0]);
        }
        translate([-shackleX+shackleR-1,-w1/2]) {
          square([2*shackleX - capTravel - 2*(shackleR-1),w1]);
        }
        translate([0,-w2/2]) {
          square([shackleX - capTravel,w2]);
        }
      }
    }
    *linear_extrude_y(lots,true) {
      polygon([[-shackleX-eps,housingInteriorHeight-h], [-shackleX-eps + 1.5,housingInteriorHeight-h], [-shackleX-eps + 1.5,housingInteriorHeight-h - 0.5], [-shackleX-eps,housingInteriorHeight-h - 2]]);
    }
  }
  //*for (x=[-0.6*shackleX-capTravel,-capTravel/2,0.6*shackleX-capTravel]) {
  for (x=[-shackleX+shackleR-1, shackleX-shackleR+1-2*capTravel-C+1]) {
  //for (x=[-shackleX+shackleR-1, wheelR+2*C+1.5 - 2.0]) {
    translate([x,0,lugZ+lugDepth+C-eps]) linear_extrude_x(x<0?capTravel:2,convexity=5) {
      simple_slot_profile(w1+2,2/2,3);
    }
  }
  translate([-capTravel,0,lugZ+lugDepth+C]) linear_extrude_x(capTravel) {
    simple_slot_profile(w0+2,2/2,3);
  }
}
module housing_cap_mask_negative() {
  minkowski(convexity=4) {
    housing_cap_mask();
    group() {
      translate([0,-tightC]) cube([capTravel,2*tightC,eps]);
      translate([capTravel,-tightC]) cube([2*tightC,2*tightC,lots]);
    }
  }
}
module housing_outer() {
  difference() {
    housing();
    color("pink") housing_wheel_mask(tightC);
    color("lightyellow") housing_cap_mask_negative();
  }
}
module housing_inner() {
  intersection() {
    difference() {
      housing();
      housing_cap_mask_negative();
    }
    housing_wheel_mask();
  }
}
module housing_inner_part(i) {
  intersection() {
    housing_inner();
    translate_z((wheelSep+wheelThickness)*(i+1)) positive_z();
    if (i < wheels-1)
    translate_z((wheelSep+wheelThickness)*(i+2)-eps) negative_z();
  }
}
module housing_cap() {
  difference() {
    intersection() {
      housing();
      housing_cap_mask();
    }
    // room to slide cap
    linear_extrude_y(2*(shaftR+C),true) {
      minkowski() {
        actuator_profile();
        translate([-C-capTravel,0]) square([capTravel+2*C,shaftTravel+layerHeight]);
      }
    }
    linear_extrude_y(2*(shaftR+1+C),true) {
      minkowski() {
        actuator_center_profile();
        translate([-C-capTravel,0]) square([capTravel+2*C,shaftTravel+layerHeight]);
      }
    }
  }
}
*!intersection(){
  group() {
    housing_outer();
    *housing_inner();
    *housing_inner_part(3);
    translate_x(35) housing_inner();
    translate_z(5) housing_cap();
  }
  translate_y(-1)positive_y();
  *translate_z(housingHeight-4) negative_z();
}


module export_housing_test() {
  intersection() {
    housing();
    translate_z(-2) cylinder(r=wheelR+2.2,h=20);
  }
}
//!export_housing_test();

module export_housing_outer() { housing_outer(); }
module export_housing_cap() { rotate([180]) housing_cap(); }
module export_housing_inner() {
  for (i=[0:wheels-1]) {
    translate([i*(wheelR*2+10),0,-(wheelSep+wheelThickness)*(i+1)]) {
      housing_inner_part(i);
    }
  }
}

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

shackleX = 15;
shackleR = 4;

shackleWiggle = 2.8;

shackleZ = lugZ-6.0;
shackleTravel = shaftTravel + shackleWiggle + lugDepth + 6 + 1;
shackleZ2 = wheels*(wheelThickness+wheelSep) - wheelThickness - shackleTravel - 1;
shackleLimiterZ = wheels*(wheelThickness+wheelSep) - wheelThickness/2-1;

shackleBendZ = housingInteriorHeight + housingCeiling + roundToLayerHeight(10);

module shackle_retaining_pin(depth=0,C=0) {
  z1 = shackleLimiterZ-depth-C;
  z2 = shackleLimiterZ+2+C;
  x1 = -shackleX+shackleR-1-C;
  x2 = -wheelR;
  linear_extrude_y(4+2*C,true) {
    polygon([[x1,z1+0.8],[x1+1,z1],[x2,z1],[x2,z2],[x1+1,z2],[x1,z2-0.8]]);
  }
}

module shackle(shackleLabel = true) {
  difference() {
    group() {
      shackleLength  = shackleBendZ-shackleZ;
      shackleLength2 = shackleBendZ-shackleZ2;
      translate_x(shackleX) {
        translate_z(shackleZ+1) cylinder(r=shackleR,h=shackleLength-1);
        translate_z(shackleZ)   cylinder(r1=shackleR-1,r2=shackleR,h=1);
      }
      translate_x(-shackleX) {
        translate_z(shackleZ2+1) cylinder(r=shackleR,h=shackleLength2-1);
        translate_z(shackleZ2)   cylinder(r1=shackleR-1,r2=shackleR,h=1);
      }
      *translate_x(-shackleX) {
        h = shackleTravel-shaftTravel+2;
        translate_z(shackleZ+1)   cylinder(r=shackleR,h=shackleLength-1);
        translate_z(shackleZ-0.35)cylinder(r1=shackleR-1.35,r2=shackleR,h=1.35);
        translate_z(shackleZ-h)   cylinder(r=shackleR-1.35,h=h);
        translate_z(shackleZ-h)   cylinder(r2=shackleR-1.35,r1=shackleR,h=1);
        translate_z(shackleZ2+1)  cylinder(r=shackleR,h=shackleZ-shackleZ2-h-1);
        translate_z(shackleZ2)    cylinder(r1=shackleR-1,r2=shackleR,h=1);
      }
      translate_z(shackleBendZ) intersection() {
        rotate([90,0,0]) rotate_extrude() {
          translate([shackleX,0]) circle(r=shackleR);
        }
        positive_z();
      }
    }
    mirrored([1,0,0]) {
      translate_z(-shackleWiggle) lug(C,5,shackleWiggle);
    }
    // shackle limiter pin hole
    if (0) {
      shackle_retaining_pin(depth=shackleTravel,C=C);
      z2 = shackleLimiterZ-shackleTravel-C;
      translate_x(-shackleX) {
        difference() {
          group() {
            translate_z(z2) cylinder(r=shackleR+1,h=2);
          }
          translate_z(z2) cylinder(r1=shackleR+eps,r2=shackleR-1,h=0.8);
          translate_z(z2+0.8) cylinder(r=shackleR-1,h=0.4);
          translate_z(z2+1.2) cylinder(r1=shackleR-1,r2=shackleR+eps,h=0.8);
        }
      }
    } else {
      h = shackleTravel-shaftTravel;
      linear_extrude_y(springPinWidth+2*C,true) {
        minkowski() {
          union() {
            mirror([1,0,0]) spring_pin_profile2();
          }
          translate([-C,-h-C]) square([2*C,h+2*layerHeight]);
        }
      }
      h2 = h - 3;
      translate_x(-shackleX) rotate(180) translate_x(shackleX)
      linear_extrude_y(springPinWidth+2*C,true) {
        minkowski() {
          union() {
            mirror([1,0,0]) spring_pin_profile2();
          }
          translate([-C,-h-C]) square([2*C,h2+2*layerHeight]);
        }
      }
      z2 = shackleZ-h-2.2;
      translate_x(-shackleX) {
        difference() {
          group() {
            translate_z(z2) cylinder(r=shackleR+1,h=2.9);
          }
          translate_z(z2) cylinder(r1=shackleR+eps,r2=shackleR-1.3,h=1.1);
          translate_z(z2+1.1) cylinder(r=shackleR-1.3,h=0.7);
          translate_z(z2+1.8) cylinder(r1=shackleR-1.3,r2=shackleR+eps,h=1.1);
        }
      }
    }
  }
}


module shackle_with_support() {
  offset = 1*layerHeight;
  f = sqrt(2)/2;
  h = f * (shackleX + shackleR);
  shackleTop = shackleBendZ+shackleX+shackleR;
  wall = 0.8;
  rotate([0,180,0])
  translate_z(-shackleTop) 
  group() {
    shackle();
    color("red")
    difference() {
      translate_z(shackleBendZ+h) linear_extrude(shackleTop - (shackleBendZ+h) + 2*layerHeight) {
        square([2*(f*(shackleR+shackleX)+wall),2*(f*shackleR+wall)],true);
      }
      translate_z(shackleBendZ) rotate([90,0,0]) rotate_extrude() {
        translate([shackleX,0]) circle(r=shackleR + offset);
        translate([0,-10]) square([shackleX+shackleR*f,20]);
      }
    }
  }
}
*!shackle_with_support();

module export_shackle_with_support(){shackle_with_support();}

//-----------------------------------------------------------------------------
// Locking lugs
//-----------------------------------------------------------------------------

lugW = 2*(shackleR+1);

module lug(CC=0,extraChamfer=0,dz=0) {
  chamfer = lugChamfer;
  slope = 1.1;
  x1 = lugX+lugTravel+C;
  x2 = shackleX - max(0,shackleR - (lugTravel-0.2));
  linear_extrude_y(lugW+2*CC,true) {
    offset(CC)
    //polygon([[shaftR+lugTravel+C,lugZ], [shaftR+lugTravel+C,lugZ+lugDepth], [shackleX-C,lugZ+lugDepth], [shackleX-C,lugZ]]);
    polygon([
      [x1+slope*chamfer,lugZ-extraChamfer], [x1,lugZ+chamfer-extraChamfer], [x1,lugZ+lugDepth+dz-lugChamfer2], [x1+slope*lugChamfer2,lugZ+lugDepth+dz],
      [x2-slope*chamfer-extraChamfer,lugZ+lugDepth+dz+extraChamfer], [x2,lugZ+lugDepth+dz-chamfer], [x2,lugZ+chamfer], [x2-slope*chamfer-extraChamfer,lugZ-extraChamfer]]);
  }
}

module export_lug() { lug(); }

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly(cut = false) {
  $fn = 20;
  labels = false;
  showWheels = true;
  d=10;
  //shaftPos = 0;
  lugPos = -max(0,min(lugTravel,0.0 * lugTravel + d - shackleWiggle));
  shackleDPos = min(shackleTravel, 0*shackleTravel + 0*shackleWiggle + d);
  shaftPos = min(shaftTravel, shackleDPos);
  shackleA = 180;
  
  yClip = cut ? 0 : -100;
  
  if (showWheels) color("lightsalmon") intersection() {
    for (i=[0:wheels-1]) {
    //for (i=[0:0]) {
      translate_z(i*(wheelThickness+wheelSep) + wheelSep + layerHeight/2) {
        rotate(i*360/positions) {
          //outer_wheel(labels);
          //inner_wheel();
          outer_wheel(labels,false);
        }
      }
    }
    translate_y(yClip-4*eps) positive_y();
  }
  color("red") intersection() {
    translate_z(shaftPos) shaft();
    translate_y(yClip-10) positive_y();
  }

  color("lightblue") intersection() {
    translate_x(-shackleX) rotate(shackleA) translate_x(shackleX)
    translate_z(shackleDPos) shackle();
    translate_y(yClip-0) positive_y();
  }
  
  color("lightgreen")  intersection() {
    mirrored([1,0,0]) translate_x(lugPos) lug();
    translate_y(yClip-2*eps) positive_y();
  }
  
  color("lightyellow") intersection() {
    housing();
    translate_y(yClip+2*eps) positive_y();
  }
}

module test() {
  if (1) {
    assembly(true);
  } else {
    intersection() {
      assembly(false);
      *positive_y();
      translate_z(wheelPos+10) negative_z();
    }
  }
}
test();
