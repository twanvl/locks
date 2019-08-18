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

module outer_wheel(labels=true, for_inner=true) {
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
        linear_extrude_y(labelThickness)
          text(str(i),size=4,font="ubuntu",halign="center",valign="center");
      }
    }
    if (!for_inner) {
      inner_wheel_inner();
    }
  }
}

//function gateDepth(i) = i == 0 ? wheelThickness : 2;
function gateDepth(i) = i == 0 || i == 3 || i == 7 ? wheelThickness : 1.5;

module inner_wheel_inner() {
  shaftR2C = shaftR2 + 2*C; // note: extra clearance to prevent sideways interaction with pin
  intersection() {
    for (i=[0:positions-1]) {
      rotate(180/positions)
      rotate([0,0,360/positions*i])
      //translate_y(-shaftR)
      //cube([2+2*C, 2*shaftR, i == 0 ? lots : 2*2],true);
      linear_extrude_y(shaftR2C) {
        w = 0.9;
        sym_polygon_x([[w+C+1,-eps],[w+C+1,0.6],[w+C,1.2],[w+C,gateDepth(i)+eps]]);
      }
    }
    translate_z(-eps) cylinder(r=shaftR2C,h=wheelThickness+2*eps);
  }
  translate_z(-eps) cylinder(r=shaftR2C,h=1+2*eps);
  translate_z(-eps) cylinder(r=shaftR+0.5+C,h=1.3+2*eps);
}

module inner_wheel() {
  difference() {
    linear_extrude(wheelThickness,convexity=5) {
      difference() {
        gear_profile(0);
        circle(shaftR+C);
      }
    }
    inner_wheel_inner();
  }
}

module shaft_profile() {
}

module shaft() {
  h = shaftLength;
  difference() {
    group() {
      //translate_z(-4) cylinder(r=shaftR,h=h);
      cylinder(r=shaftR,h=h);
      for (i=[0:wheels-1]) {
        translate_z(i*(wheelThickness+wheelSep)) {
          intersection() {
            rotate(180/positions)
            rotated([0,360*3/positions,360*7/positions])
            linear_extrude_y(shaftR2+C) {
              w = 1;
              sym_polygon_x([[w,0],[w,6]]);
            }
            union() {
              translate_z(0.5) cylinder(r1=shaftR,r2=shaftR2,h=1);
              translate_z(1.5-eps) cylinder(r=shaftR2,h=wheelSep-1.5+0.5);
              //translate_z(3) cylinder(r1=shaftR2,r2=shaftR,h=1);
            }
          }
        }
      }
    }
    //translate_z(-eps) cylinder(r=3.5/2,h=10);
  }
  /*
  translate_z(wheels*(wheelThickness+wheelSep)+C + 5/2)
  //cylinder(r=shaftR+5,h=5);
  cube([shaftR*2,shaftR*2,5],true);
  translate_z(wheels*(wheelThickness+wheelSep)+wheelSep + 5/2)
  //cylinder(r=shaftR+5,h=5);
  cube([shaftR*2+10,shaftR*2,5],true);
  */
  difference() {
    //actuatorShape = [[shaftR,h],[shaftR,h+4],[shaftR+4,h+8],[shaftR+4,h+10]];
    //actuatorShape = [[shaftR,h],[shaftR,h+1],[shaftR+lugTravel,h+4],[shaftR+lugTravel,h+8]];
    //actuatorShape = [[shaftR,h],[shaftR+lugTravel,lugZ],[shaftR+lugTravel,lugZ+lugDepth]];
    //actuatorShape = [[shaftR,h], [shaftR+lugTravel+0.1,lugZ-0.5], [shaftR+lugTravel-0.5,lugZ+lugDepth/2], [shaftR+lugTravel-0.5,lugZ+lugDepth]];
    //actuatorShape = [[shaftR,h],[shaftR+lugTravel,lugZ-2],[shaftR+lugTravel,lugZ-1],[shaftR+lugTravel-1,lugZ],[shaftR+lugTravel-1,h+shaftTravel]];
    //actuatorShape = [[lugX,lugZ-shaftTravel], [lugX,lugZ+lugDepth-1-shaftTravel], [lugX+lugTravel+C,lugZ-0.5], [lugX+lugTravel+C,lugZ], [lugX+lugTravel-0.5,lugZ+lugDepth/2], [lugX+lugTravel-0.5,lugZ+lugDepth]];
    
    linear_extrude_y(2*(shaftR+0),true) {
      sym_polygon_x(actuatorShape);
    }
  }
  linear_extrude_y(4,true) {
    sym_polygon_x([[wheelR+1,h], [wheelR+1,h+1]]);
  }
}

shacklePos = 15;
shackleR = 4;

shaftTravel = 5.0;
//shaftTravel = 7;

lugDepth = 4;
lugChamfer = 1.2;
//lugZ = wheels*(wheelThickness+wheelSep) + max(2, shaftTravel - wheelThickness);
lugZ = wheels*(wheelThickness+wheelSep) + lugDepth + shaftTravel - lugDepth + lugChamfer + 2;
lugW = 2*(shackleR+1);
lugTravel = 2.5;
lugX = shaftR-0;
//lugX = 0;

shaftLength = wheels*(wheelThickness+wheelSep) + 1;
actuatorShape = [[lugX,shaftLength], [lugX,lugZ+lugDepth-1-shaftTravel], [lugX+lugTravel+C,lugZ-0.0], [lugX+lugTravel+C,lugZ+0.5], [lugX+lugTravel-0.5,lugZ+lugDepth/2], [lugX+lugTravel-0.5,lugZ+lugDepth]];

module lug(CC=0,extraChamfer=0,dz=0) {
  chamfer = lugChamfer;
  x1 = lugX+lugTravel+C;
  x2 = shacklePos - C - max(0,shackleR - (lugTravel-0.2));
  linear_extrude_y(lugW+2*CC,true) {
    offset(CC)
    //polygon([[shaftR+lugTravel+C,lugZ], [shaftR+lugTravel+C,lugZ+lugDepth], [shacklePos-C,lugZ+lugDepth], [shacklePos-C,lugZ]]);
    polygon([
      [x1+chamfer,lugZ-extraChamfer], [x1,lugZ+chamfer-extraChamfer], [x1,lugZ+lugDepth+dz-chamfer], [x1+chamfer,lugZ+lugDepth+dz],
      [x2-chamfer-extraChamfer,lugZ+lugDepth+dz+extraChamfer], [x2,lugZ+lugDepth+dz-chamfer], [x2,lugZ+chamfer], [x2-chamfer-extraChamfer,lugZ-extraChamfer]]);
  }
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module housing() {
  wall = 2;
  floor   = roundToLayerHeight(1.5);
  ceiling = roundToLayerHeight(1.5);
  h = lugZ + lugDepth + shaftTravel + floor + ceiling;
  chamfer = 1;
  difference() {
    //translate_z(h/2-2) {
    translate_z(-floor) {
      *difference() {
        chamfer_cube(2*(shacklePos+shackleR+2),2*(shackleR+2),h,1);
        chamfer_cube(2*(shacklePos+shackleR+2*C),2*(shackleR+2*C),h+2*C-4,1);
      }
      minkowski() {
        linear_extrude(h) {
          hull() {
            mirrored([1,0,0]) translate([shacklePos,0]) circle(r=shackleR+wall-chamfer);
            circle(r=wheelR+wall-chamfer);
          }
        }
        double_cone(chamfer);
      }
    }
    // wheels
    for (i=[0:wheels-1]) {
      translate_z(i*(wheelThickness+wheelSep) + wheelSep) {
        cylinder(r=wheelR + C + 1,h=wheelThickness+C);
      }
    }
    // shackle holes
    mirrored([1,0,0])
    translate([shacklePos,0,lugZ-7-C]) cylinder(r=shackleR+C,h=30);
    // shaft hole
    color("pink") translate([0,0,0]) cylinder(r=shaftR+C,h=h-floor-ceiling);
    linear_extrude_y(2*(shaftR+C),true) {
      minkowski() {
        sym_polygon_x(actuatorShape);
        translate_y(-C) square([eps,shaftTravel+2*C]);
      }
      //translate_y(shaftTravel) offset(C) sym_polygon_x(actuatorShape);
    }
    // lug holes
    mirrored([1,0,0]) color("lightgreen") group() {
      lug(C);
      translate_x(-lugTravel) lug(C);
    }
  }
}
//!intersection(){housing(); positive_y();}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

shackleTravel = 14;

module assembly() {
  labels = false;
  shaftPos = 0 * shaftTravel;
  //shaftPos = 0;
  lugPos = -0 * lugTravel;
  shackleDPos = shaftPos + 0*shackleTravel;
  *for (i=[0:wheels-1]) {
  //for (i=[0:0]) {
    translate_z(i*(wheelThickness+wheelSep) + wheelSep) {
      rotate(i*360/positions) {
        //outer_wheel(labels);
        //inner_wheel();
        outer_wheel(labels,false);
      }
    }
  }
  *translate_z(shaftPos) color("red") shaft();

  color("lightblue")
  translate_z(shackleDPos) {
    difference() {
      translate([shacklePos,0,lugZ-7]) cylinder(r=shackleR,h=30);
      translate_z(-4)lug(C,5,4);
    }
    rotate(180) difference() {
      translate([shacklePos,0,lugZ-7-shackleTravel]) cylinder(r=shackleR,h=30+shackleTravel);
      translate_z(-4)lug(C,5,4);
    }
  }
  
  rotated(180) translate_x(lugPos) color("lightgreen") lug();
  
  color("lightyellow") housing();
}

module test() {
  intersection() {
    assembly();
    positive_y();
  }
}
test();
