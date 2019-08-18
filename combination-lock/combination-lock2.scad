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
wheelSep = roundToLayerHeight(3);
wheelPos = 2;
wheelR = 7;
//innerWheelR = 5.7;
innerWheelR = wheelR-0.6;
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
  polygon([for (i=[0:step:360-1]) polar(i, innerWheelR + C + 0.5*(pf(i*positions)))]);
  *union() {
    circle(innerWheelR - 0.3);
    for (i=[0:9]) {
      rotate(360/positions*(i+0.5))
      translate_x(innerWheelR-0.8) circle(1.3);
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
        if (for_inner) {
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
    falseGateDepth = 0.5;
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
        gear_profile(0);
        *circle(shaftR+C);
      }
    }
    inner_wheel_inner();
  }
}
//!inner_wheel();

//module export_inner_wheel() { inner_wheel(); }
//module export_outer_wheel() { outer_wheel(); }
module export_wheel0() { outer_wheel(for_inner=false,pos=0); }

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
  circle(r=shaftR+C);
  pins = all_pins ? [0:positions-1] : [0,3,7];
  //pins = all_pins ? [0:positions-1] : [0,4,6];
  rotations = [for (i=pins) 360*i/positions + -90];
  rotated(rotations) shaft_pin_profile(C);
}
//!shaft_profile(all_pins=true);

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
    linear_extrude_y(2*(shaftR+0),true) {
      sym_polygon_x(actuatorShape);
    }
    translate_z(shaftLength) cylinder(r1=shaftR,r2=shaftR+100,h=100);
  }
  linear_extrude_y(4,true) {
    sym_polygon_x([[wheelR+1,h], [wheelR+1,h+1]]);
  }
}
//!shaft();

shaftTravel = 5.0;
//shaftTravel = 7;

lugDepth = 4;
lugChamfer = 1.2;
//lugZ = wheels*(wheelThickness+wheelSep) + max(2, shaftTravel - wheelThickness);
lugZ = wheels*(wheelThickness+wheelSep) + lugDepth + shaftTravel - lugDepth + lugChamfer + 2;
lugTravel = 2.5;
lugX = shaftR-0;
//lugX = 0;

shaftLength = wheels*(wheelThickness+wheelSep) + 1;
actuatorShape = [[lugX,shaftLength], [lugX,lugZ+lugDepth-1-shaftTravel], [lugX+lugTravel+C,lugZ-0.0], [lugX+lugTravel+C,lugZ+0.5], [lugX+lugTravel-0.5,lugZ+lugDepth/2], [lugX+lugTravel-0.5,lugZ+lugDepth]];

module export_shaft() { rotate([180]) shaft(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module housing() {
  wall = 2;
  floor   = roundToLayerHeight(1.0);
  ceiling = roundToLayerHeight(1.5);
  h = lugZ + lugDepth + shaftTravel + floor + ceiling;
  chamfer = 1;
  difference() {
    //translate_z(h/2-2) {
    translate_z(-floor) {
      *difference() {
        chamfer_cube(2*(shackleX+shackleR+2),2*(shackleR+2),h,1);
        chamfer_cube(2*(shackleX+shackleR+2*C),2*(shackleR+2*C),h+2*C-4,1);
      }
      minkowski() {
        linear_extrude(h) {
          hull() {
            mirrored([1,0,0]) translate([shackleX,0]) circle(r=shackleR+wall-chamfer);
            //circle(r=wheelR+0*wall-chamfer);
            circle(r=wheelR+-1-chamfer);
          }
        }
        double_cone(chamfer);
      }
    }
    // wheels
    for (i=[0:wheels-1]) {
      translate_z(i*(wheelThickness+wheelSep) + wheelSep) {
        cylinder(r=wheelR + 2*C,h=wheelThickness+C);
      }
      translate([-wheelR-C,0,i*(wheelThickness+wheelSep) + wheelSep]) {
        cube([wheelR*2+2*C,lots,wheelThickness+C]);
      }
    }
    *translate_z(wheelSep-1) {
      linear_extrude(wheels * (wheelThickness+wheelSep) - wheelSep + 2) {
        sym_polygon_x([[wheelR+2.2,wheelR+wall],for (i=[60:5:90]) polar(i,wheelR-0.5)]);
      }
    }
    // shackle holes
    translate([shackleX, 0,shackleZ -C]) cylinder(r=shackleR+C,h=lots);
    translate([-shackleX,0,shackleZ2-C]) cylinder(r=shackleR+C,h=lots);
    //translate([shackleX,0,0]) cylinder(r=shackleR-1+C,h=30);
    translate([shackleX,0,0]) linear_extrude(shackleZ) square(2*(shackleR-1+C),true);
    shackle_retaining_pin(C=C+2*eps);
    // shaft hole
    color("pink") linear_extrude(h-floor-ceiling+C,convexity=5) shaft_profile(C);
    linear_extrude_y(2*(shaftR+C),true) {
      minkowski() {
        sym_polygon_x(actuatorShape);
        translate_y(-C) square([eps,shaftTravel+10+2*C]);
      }
      //translate_y(shaftTravel) offset(C) sym_polygon_x(actuatorShape);
    }
    // lug holes
    mirrored([1,0,0]) color("lightgreen") group() {
      lug(C);
      translate_x(-lugTravel) lug(C);
      //translate_x(-lugTravel*3) lug(C);
      linear_extrude_y(lugW+2*C,true) {
        sym_polygon_x([[lugX+2,lugZ-C],[lugX+2,lugZ+lugDepth+C],[lugDepth/2+C+2,lugZ+lugDepth+C],[lugDepth/2+0.5+C,lugZ+lugDepth+2+C],[lugDepth/2+0.5+C,h]]);
      }
    }
    // cap
    capR = shackleR + 1 + C;
    z1 = h-ceiling-floor+C - eps;
    translate_x(-shackleX+shackleR+2) linear_extrude_x(shackleX*2 + eps) {
      sym_polygon_x([[capR+1,z1],[capR+1,z1+0.3],[capR,z1+1.2],[capR,h]]);
    }
    linear_extrude_y(lots,true) {
      polygon([[shackleX,z1],[shackleX,h],[lots,h],[lots,z1]]);
    }
  }
}
//!intersection(){housing(); positive_y();}

module export_housing_test() {
  intersection() {
    housing();
    translate_z(-2) cylinder(r=wheelR+2.2,h=20);
  }
}
!export_housing_test();

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

shackleX = 15;
shackleR = 4;

shackleTravel = shaftTravel + 14;
shackleZ = lugZ-7.5;
shackleZ2 = wheels*(wheelThickness+wheelSep) - wheelThickness - shackleTravel - 1;
shackleLimiterZ = wheels*(wheelThickness+wheelSep) - wheelThickness/2-1;

shackleWiggle = 4;
shackleLength = 30;

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
      translate([shackleX,0,shackleZ+1]) cylinder(r=shackleR,h=shackleLength-1);
      translate([shackleX,0,shackleZ])   cylinder(r1=shackleR-1,r2=shackleR,h=1);
      shackleLength2 = shackleLength+shackleZ-shackleZ2;
      translate([-shackleX,0,shackleZ2+1]) cylinder(r=shackleR,h=shackleLength2-1);
      translate([-shackleX,0,shackleZ2])   cylinder(r1=shackleR-1,r2=shackleR,h=1);
      translate_z(shackleZ+shackleLength) intersection() {
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
    z2 = shackleLimiterZ-shackleTravel-C;
    shackle_retaining_pin(depth=shackleTravel,C=C);
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
  }
}

//-----------------------------------------------------------------------------
// Locking lugs
//-----------------------------------------------------------------------------

lugW = 2*(shackleR+1);

module lug(CC=0,extraChamfer=0,dz=0) {
  chamfer = lugChamfer;
  x1 = lugX+lugTravel+C;
  x2 = shackleX - C - max(0,shackleR - (lugTravel-0.2));
  linear_extrude_y(lugW+2*CC,true) {
    offset(CC)
    //polygon([[shaftR+lugTravel+C,lugZ], [shaftR+lugTravel+C,lugZ+lugDepth], [shackleX-C,lugZ+lugDepth], [shackleX-C,lugZ]]);
    polygon([
      [x1+chamfer,lugZ-extraChamfer], [x1,lugZ+chamfer-extraChamfer], [x1,lugZ+lugDepth+dz-chamfer], [x1+chamfer,lugZ+lugDepth+dz],
      [x2-chamfer-extraChamfer,lugZ+lugDepth+dz+extraChamfer], [x2,lugZ+lugDepth+dz-chamfer], [x2,lugZ+chamfer], [x2-chamfer-extraChamfer,lugZ-extraChamfer]]);
  }
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly(cut = false) {
  labels = false;
  shaftPos = 1 * shaftTravel;
  //shaftPos = 0;
  lugPos = -0 * lugTravel;
  shackleDPos = 0*shackleTravel;
  
  yClip = cut ? 0 : -100;
  
  color("lightsalmon") intersection() {
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
    translate_y(yClip) positive_y();
  }

  color("lightblue") intersection() {
    translate_z(shackleDPos) shackle();
    translate_y(yClip-10) positive_y();
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
  intersection() {
    assembly(true);
    *positive_y();
  }
}
test();
