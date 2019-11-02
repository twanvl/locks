// Lock with sliders and rotating obstructions

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

/* [Key] */

// Key bitting code.  Use values between -1 and 1.
bitting = [-1,0,1,-0.5,1,0.5];

// Use a random bitting instead of the fixed bitting code.
random_bitting = false;
random_bitting_length = 6;

/* [Printing] */

// Layer height.  All heights/thicknesses will be rounded to multiples of this value.
layer_height = 0.15; // [0:0.01:1]

/* [Housing dimensions] */

/* [Core dimensions] */

core_diameter = 15; // [1:0.1:30]

// Thickness of each wafer/slider (will be rounded to layer height)
wafer_thickness = 2; // [0.1:0.1:5]
// Thickness of spacer / rotating wafer (will be rounded to layer height)
spacer_thickness = 2; // [0.1:0.1:5]
wafer_width = 9.5; // [1:0.1:30]

sidebar_thickness = 2.0; // [0.1:0.1:5]
// How far the sidebar moves between locked and unlocked states
sidebar_travel = 0.7;

/* [Key dimensions] */

key_width = 6;
key_height = 2.2;
key_chamfer1 = 0.3;
key_chamfer2 = 0.4;

/* [Computed] */

//-----------------------------------------------------------------------------
// Computed values
//-----------------------------------------------------------------------------

//bitting = [1,-1,-1,0.5];
/*
bitting = random_bitting ? rands(-1,1,random_bitting_length) : bitting_code;
*/

coreR = 15 / 2;
waferWidth = 9.5;
waferThickness = roundToLayerHeight(2);
sepThickness = roundToLayerHeight(2);

keyWidth   = 6;
keyHeight1 = roundToLayerHeight(2.2);
keyHeight2 = roundToLayerHeight(keyHeight1 + 0.3);
keyHeight3 = keyHeight1+0;
//keyHeight2 = keyHeight1;
keyChamfer  = 0.3;
keyChamfer2 = 0.4;
step = keyWidth/2-keyHeight3/2;

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_profile() {
  render() union() {
    // base rectangle (not really needed)
    dw = 0.2;
    chamfer_rect(keyWidth-dw,keyHeight1,keyChamfer, r_bl=keyChamfer2, r_tr=1.5);
    // make room for rotating the bitting prongs at the edges of the key
    // shape traced out by key_bit_profile at -bit*step and bit*step, rotated around (0,0),
    // but shifted so that vertical height remains constant, i.e. by sin(a)*x+dy(a)
    // we use a pairwise convex hull to get the traced shape
    steps = 5;
    for (a=[0:steps:90-steps-eps]) {
    //for (a=[40]) {
      hull() {
        for (bit=[-1,1]) {
          b=a+steps;
          translate_y(-bit*step*sin(a) - dy(a)) rotate(a) key_bit_profile(bit);
          translate_y(-bit*step*sin(b) - dy(b)) rotate(b) key_bit_profile(bit);
        }
      }
    }
  }
}
*!key_profile();

module key_bit_profile(bit=0) {
  $fn = 60;
  translate_x(bit*step) {
    //square([keyHeight1,keyHeight1],true);
    //circle(keyHeight1/2);
    intersection() {
      h = keyHeight1;
      w = keyHeight3;
      chamfer_rect(w,h,keyChamfer,r_bl=keyChamfer2);
      // make sure that the shape can be rotated
      //translate([w/2,-h/2+keyChamfer]) scale([w/h,1]) circle(r=h);
      //translate([w/2-keyChamfer,-h/2]) scale([w/h,1]) circle(r=h);
      translate([-w/2,-h/2+keyChamfer2]) scale([w/h,1]) circle(r=h);
      translate([-w/2+keyChamfer2,-h/2]) scale([w/h,1]) circle(r=h);
    }
  }
}

module key_profile_test_wafer() {
  linear_extrude(waferThickness) {
    difference() {
      intersection() {
        translate_y(step) circle(r = coreR);
        translate_y(-step) circle(r = coreR);
        square([waferWidth,lots],true);
      }
      //translate_y(-(keyHeight2-keyHeight1)*0.5)
      key_profile();
      translate_y(keyHeight2*1.2) key_profile();
    }
  }
}

// point where bottom of keyway touches key at given angle
//function dy(a) = -1*sin(a) * (keyHeight2/2 - keyChamfer);
function dy(a) = min(-keyHeight1/2,min(
  rot(-a, [keyHeight3/2 - keyChamfer2, -keyHeight1/2])[1],
  rot(-a, [keyHeight3/2, -keyHeight1/2 + keyChamfer2])[1]))
  + keyHeight1/2;

module key_profile_test() {
  bit = 1;
  a = 0;
  rotate(a) linear_extrude(sepThickness) key_profile();
  translate_y(bit*step * sin(a)) {
    translate_x(bit*step * cos(a))
    rotate(a) color("green") linear_extrude(10) key_bit_profile();
    //color("yellow") rotate(0) key_profile_test_wafer();
    translate_z(3) color("yellow") translate_y(dy(a)) key_profile_test_wafer();
  }
}
!key_profile_test();

module linear_extrude_z_chamfer_y(height,chamfer) {
  intersect_offset_y(chamfer)
  minkowski() {
    linear_extrude(eps) {
      children();
    }
    translate_z(height/2) linear_extrude_x(eps) {
      chamfer_rect(2*chamfer,height,chamfer);
    }
  }
}
module intersect_offset_y(y=1) {
  intersection() {
    translate_y(-y) children();
    translate_y(y) children();
  }
}

module linear_extrude_chamfer2(height,chamfer1,chamfer2,center=false,convexity=4) {
  translate_z(center ? -height/2 : 0) {
    minkowski() {
      linear_extrude(eps) children();
      c = 0.5;
      cylinder(h=c,r1=c,r2=0,$fn=4);
    }
  }
}

// linear extrude with hacky chamfer based on scaling, works ok for rectangular shapes
module linear_extrude_scale_chamfer(height,xsize,ysize,chamfer1,chamfer2,center=false,slope=1,convexity=4) {
  translate_z(center ? -height/2 : 0) {
    if (chamfer1 > 0) {
      scale([1-2*slope*chamfer1/xsize,1-2*slope*chamfer1/ysize,1])
      linear_extrude(chamfer1+eps, scale=[1/(1-2*slope*chamfer1/xsize),1/(1-2*slope*chamfer1/ysize)]) children();
    }
    translate_z(chamfer1)
    linear_extrude(height-chamfer1-chamfer2) children();
    if (chamfer2 > 0) {
      translate_z(height-chamfer2-eps)
      linear_extrude(chamfer2+eps, scale=[1-2*slope*chamfer2/xsize,1-2*slope*chamfer2/ysize]) children();
    }
  }
}

*!linear_extrude_scale_chamfer(sepThickness,keyWidth*2,keyHeight1,0.31,0.31,slope=1) {
  key_profile();
}
*!linear_extrude_z_chamfer_y(sepThickness,0.3) {
  key_profile();
}


module linear_extrude_cone_chamfer2(height,chamfer1,chamfer2,center=false,convexity=undef,slope=1, resolution=8) {
  maxChamfer = max(chamfer1,chamfer2);
  translate_z(center ? -height/2 : 0)
  difference() {
    linear_extrude(height, convexity=convexity) {
      children();
    }
    if (chamfer1 > 0) translate_z(-eps) minkowski() {
      linear_extrude(chamfer1, convexity=convexity+1) difference() {
        square(lots,true);
        children();
      }
      cylinder(r1=chamfer1,r2=chamfer1*(slope-1),h=chamfer1, $fn=resolution);
    }
    if (chamfer2 > 0) translate_z(height-chamfer2+eps) minkowski() {
      linear_extrude(chamfer2, convexity=convexity+1) difference() {
        square(lots,true);
        children();
      }
      cylinder(r1=chamfer2*(slope-1),r2=chamfer2,h=chamfer2, $fn=resolution);
    }
  }
}

module key() {
  crossC = C/2;
  for (i=[0:len(bitting)-1]) {
    chamfer=0.3;
    translate_z(i*(waferThickness+sepThickness) + (i>0 ? crossC : -2))
    linear_extrude_scale_chamfer(sepThickness - crossC - (i>0 ? crossC : -2) + eps, 2*keyWidth,keyHeight1, chamfer,chamfer) {
    //linear_extrude_cone_chamfer(sepThickness - crossC - (i>0 ? crossC : -2) + eps, chamfer,chamfer) {
    //linear_extrude_cone_chamfer2(sepThickness - crossC - (i>0 ? crossC : -2) + eps, chamfer,chamfer) {
      key_profile();
    }
    translate_z(i*(waferThickness+sepThickness) + sepThickness/2-eps)
    if (i == len(bitting)-1) {
      translate_x(bitting[i]*step)
      linear_extrude_scale_chamfer(waferThickness + sepThickness/2 + eps, keyHeight1,keyHeight1, 0,chamfer)
      translate_x(-bitting[i]*step) {
        key_bit_profile(bitting[i]);
      }
    } else {
      linear_extrude(waferThickness + sepThickness + 2*eps) {
        key_bit_profile(bitting[i]);
      }
    }
  }
  h1 = 3;
  translate_z(-(h1+4)) {
    linear_extrude(h1+4+eps) {
      intersection() {
        circle(r = keyHoleR);
        chamfer_rect(2*keyHoleR,keyHeight1,keyChamfer+0.1);
      }
    }
  }
  translate_z(-h1) key_handle();
}
module key_handle() {
  w = 20; // handle
  r = 2.75; // hole
  translate_z(-w/2)
  rotate([90]) {
    difference() {
      group() {
        cylinder(r=w/2,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=w/2,r2=w/2-keyChamfer,h=keyChamfer);
      }
      translate_y(-w/2+r+r)
      group() {
        cylinder(r=r,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=r,r2=r+keyChamfer,h=keyChamfer+2*eps);
      }
    }
  }
}

*!key();

module export_key() { rotate([90]) key(); }
*!export_key();

//-----------------------------------------------------------------------------
// Wafers
//-----------------------------------------------------------------------------

//gateC = C/2;
gateC = 0;
gateCHousing = C/2;
falseGate = 0.5;

module keyway(height) {
  chamfer = roundToLayerHeight(0.4);
  translate_z(-eps)
  //linear_extrude_scale_chamfer(height+2*eps, 2*keyWidth,keyHeight1, chamfer,chamfer, slope=-1) {
  linear_extrude_chamfer_hole(height+2*eps, chamfer,chamfer, convexity=4) {
    offset(delta=C) key_profile();
  }
}

module wafer(bit) {
  difference() {
    linear_extrude(waferThickness, convexity=2) {
      difference() {
        intersection() {
          translate_y(step) circle(r = coreR);
          translate_y(-step) circle(r = coreR);
          square([waferWidth,lots],true);
        }
        // gate
        translate_y(-bit*step) offset(delta=gateC) sidebar_profile();
        for (i=[-1:0.5:1]) {
          if (abs(i-bit)>=1)
          translate_y(-i*step) offset(delta=gateC) sidebar_profile(1 - falseGate);
        }
        if (springTravel>0) {
          offset(delta=C) spring_gate_profile(chamfered=false);
        }
      }
    }
    keyway(waferThickness);
  }
}
*!wafer(-1);

spacerR = waferWidth/2 + 0.15;
limiterThickness = roundToLayerHeight(sepThickness/2);
module spacer() {
  intersection() {
    difference() {
      //for (limiter = [0,1]) {
      limiter = 1;{
        //translate_z(limiter ? sepThickness-limiterThickness : 0)
        //linear_extrude(limiter ? limiterThickness : sepThickness, convexity=2) {
        linear_extrude(sepThickness, convexity=4) {
          difference() {
            union() {
              circle(r = spacerR);
              if (limiter) spacer_limiter_profile();
            }
            *translate_y(-(keyHeight3-keyHeight1)*0.5)
              offset(delta=C) key_profile();
            rotate(-90) offset(delta=C) sidebar_profile();
            if (springTravel>0) {
              offset(delta=C) spring_gate_profile();
            }
          }
        }
      }
      keyway(sepThickness);
    }
    union() {
      z2 = sepThickness - 3*layerHeight;
      *translate_z(-eps) cylinder(r=spacerLimiterR,h=z1+2*eps);
      *translate_z(z1) cylinder(r1=spacerLimiterR,r2=spacerR,h=z2-z1+eps);
      cylinder(r=spacerR,h=sepThickness+2*eps);
      difference() {
        translate_z(3*layerHeight-eps) cylinder(r=spacerLimiterR,h=sepThickness-3*layerHeight+2*eps);
        core_spacer_holders(C=0);
        rotate(90) core_spacer_holders(C=0);
      }
    }
  }
}
spacerLimiterR = sqrt(2)*spacerR - 0.5;
module spacer_limiter_profile() {
  intersection() {
    circle(r = spacerLimiterR);
    square(waferWidth,true);
    //square(spacerR);
    rotate(-45) square([2,lots],true);
  }
}
*!spacer();

module export_spacer() { rotate([180]) spacer(); }
module export_wafers() {
  for (i=[0:len(bitting)-1]) {
    translate_x(i * (waferWidth + 5)) {
      rotate([180]) wafer(bitting[i]);
      translate_y(2*coreR+5) rotate([180]) spacer();
    }
  }
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module core_profile() {
  difference() {
    circle(r=coreR);
    square([waferWidth+2*C,lots],true);
    circle(r=spacerR+C);
    translate_x(-lots/2) square([lots,sidebarThickness+C],true);
    if (springTravel > 0) {
      translate_x(lots/2) square([lots,springThickness+2*C],true);
    }
  }
}

stackThickness = len(bitting)*(waferThickness+sepThickness);
coreThickness = stackThickness + layerHeight;
coreBackThickness = roundToLayerHeight(2.5);

module core(back = true) {
  linear_extrude(coreThickness, convexity=4) {
      core_profile();
  }
  for (i=[0:len(bitting)-1]) {
    translate_z(i*(waferThickness+sepThickness)) {
      difference() {
        core_spacer_holders();
        translate_z(-eps) cylinder(r=spacerR+C,h=sepThickness+2*eps);
      }
    }
  }
  if (back) {
    rotate(-coreAngle)
    difference() {
      translate_z(coreThickness) linear_extrude(coreBackThickness, convexity=2) {
        circle(r=coreR);
        // rotation limiter
        rotate(180-45) wedge(180-45,center=true,r=housingR);
      }
      // locking lug pin holes
      rotated(180) translate(lugPinPos) {
        translate_z(lugZ-lugPinThickness-3*layerHeight) cylinder(r=lugPinR+C,h=lots);
        translate_z(coreThickness+coreBackThickness-0.5) cylinder(r1=lugPinR+C,r2=lugPinR+C+0.5,h=0.5+eps);
      }
    }
  }
}

module core_spacer_holders(C=C) {
  z1 = sepThickness - 2*layerHeight;
  z2 = 3*layerHeight;
  z3 = 1*layerHeight-(C>0?0:2*layerHeight);
  h = 2*side_given_diagonal(coreR,waferWidth/2+C);
  linear_extrude_y(h,true) {
    x1 = waferWidth/2+C+eps;
    x2 = x1 - (z1-z2) * 1.2;
    mirrored([1,0,0]) polygon([[x1,z1],[x2,z2],[x2,z3],[x1,z3]]);
  }
}
*!core();

module export_core() { rotate([180]) translate_z(-(coreThickness+coreBackThickness)) core(); }

//-----------------------------------------------------------------------------
// Sidebar
//-----------------------------------------------------------------------------

sidebarThickness = roundToLayerHeight(2.0);
sidebarChamfer = sidebarThickness/2;//0.8;
sidebarChamfer2 = 0.6;
sidebarChamfer3 = 0.3;
sidebarTravel = 0.7;

module sidebar_profile(pos = 0, extraY = 0, lessChamfer=0) {
  rotate(coreAngle) {
    x = coreR;
    w = x - spacerR + sidebarTravel;
    translate_x(-pos*sidebarTravel) intersection() {
      circle(r=coreR);
      translate_x(w/2 - x)
        chamfer_rect(w, sidebarThickness + 2*extraY, sidebarChamfer+extraY-lessChamfer, r_tl=sidebarChamfer3+extraY, r_bl=sidebarChamfer2+extraY);
    }
  }
}

module sidebar(pos = 0) {
  linear_extrude(stackThickness) {
    sidebar_profile(pos,lessChamfer=layerHeight/2);
  }
}

*!sidebar();

module export_sidebar() { rotate([90]) sidebar(); }

//-----------------------------------------------------------------------------
// Side spring
//-----------------------------------------------------------------------------

springTravel = 0.5;
springThickness = roundToLayerHeight(1);

module spring_gate_profile(pos = 0, chamfered = true) {
  rotate(coreAngle) {
    chamfer = chamfered ? springTravel : 0;
    extraW  = chamfered ? springTravel-0.1 : 0.1;
    translate([(coreR+spacerR)/2 - (1-pos)*springTravel, 0]) {
      chamfer_rect(coreR-spacerR, springThickness + 2*extraW, chamfer);
    }
  }
}

module spring(pos = 0, extra = 0.0, angle = 0) {
  h = stackThickness;
  baseW = side_given_diagonal(coreR, springThickness/2) - spacerR;
  barW = baseW - 0.2;
  w = baseW + (1-pos) * springTravel + extra;
  barLW = springTravel + 0.2;
  bar = 1.5;
  sep = 0.5;
  
  translate_x(spacerR - (1-pos)*springTravel) {
    linear_extrude_y(springThickness,true) {
      translate([barLW-0.5,bar+sep])
      spring_profile(w-barLW+0.5,h-2*bar-2*sep,turns=2,curved=false,angle=angle,right_flat=true);
      square([barLW,h]);
      square([barW,bar]);
      translate_y(h-bar) square([barW,bar]);
    }
  }
}

*!spring();
*!group() {
  translate_y(6) spring(angle=4);
  translate_y(4) spring(extra=0.5,angle=2);
  translate_y(2) spring(extra=0.5);
  spring();
  translate_y(-2) spring(pos=1);
  translate_y(-4) translate_x(springTravel) spring(extra=0.5, angle=-4);
  translate_y(-6) translate_x(springTravel) spring(extra=0.0, angle=-3);
}

module export_spring() { rotate([90]) spring(angle=4); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

keyHoleR = diagonal(keyWidth/2,keyHeight1/2-keyChamfer) + 0.1;
housingWall = 0.8;
housingR = coreR+C+housingWall;
frontThickness = roundToLayerHeight(1.5);
backThickness = roundToLayerHeight(1.5);
housingOnly = false;

coreAngle = 0;

module housing_profile(connector=1, coreHole=false, sidebar=true) {
  chamfer = 3;
  difference() {
    group() {
      if (connector == 3 && !housingOnly) {
        hull() {
          circle(r=housingR);
          translate_x(-shackleX) circle(r=shackleR);
        }
      } else if (connector && !housingOnly) {
        offset(-chamfer) {
          circle(r=housingR+chamfer);
          translate_x(-shackleX) circle(r=shackleR+chamfer);
          h = shackleR+chamfer-0;
          translate([-shackleX,-h]) square([shackleX,2*h]);
          if (sidebar) offset(gateCHousing+housingWall+chamfer) sidebar_profile(1);
        }
      } else {
        offset(-chamfer)offset(chamfer) {
          circle(r=housingR);
          if (sidebar) offset(gateCHousing+housingWall) sidebar_profile(1);
        }
      }
    }
    if (coreHole) {
      circle(r=coreR+C);
      if (sidebar) offset(gateCHousing) sidebar_profile(1, extraY=C);
    }
  }
}

module housing(threads = true) {
  group() {
    difference() {
      group() {
        translate_z(-frontThickness)
        linear_extrude(frontThickness+eps, convexity=2) {
          difference() {
            housing_profile(2,false);
            circle(r=keyHoleR+C);
          }
        }
        linear_extrude(housingThickness1+eps, convexity=2) {
          housing_profile(1,true);
        }
        translate_z(housingThickness1)
        linear_extrude(housingThickness-housingThickness1, convexity=2) {
          housing_profile(0,true);
        }
        // rotation limiter
        translate_z(coreThickness) linear_extrude(coreBackThickness, convexity=2) {
          difference() {
            wedge(180-45,center=true,r=housingR);
            circle(r=coreR+C);
          }
        }
      }
      // chamfer for key hole
      chamfer = roundToLayerHeight(0.4);
      translate_z(-frontThickness-eps)
      cylinder(r1=keyHoleR+C+chamfer,r2=keyHoleR+C,h=chamfer);
      // screw hole
      screwZ2 = max(0,screwZ-2*coarse_pitch(screwDiameter));
      h = housingThickness1-screwZ2+2*eps;
      screwC = 0.2;
      translate([-shackleX,0,screwZ2])
      if (threads) {
        standard_thread(screwDiameter,h,C=screwC,internal=true);
      } else {
        cylinder(d=screwDiameter+screwC,h);
      }
    }
  }
}

*!housing();

module export_housing() { housing(); }

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

lugZ = coreThickness + coreBackThickness + layerHeight;
lugThickness = roundToLayerHeight(2.5);

bodyThickness = frontThickness + lugZ + lugThickness + backThickness;

shackleR = 8/2;
shackleSep = 2.5;
shackleX = coreR + shackleR + 2*C + shackleSep;
shackleZ = roundToLayerHeight(lugZ - 3.5);
shackleClearance = roundToLayerHeight(2);
shackleTravel = bodyThickness - frontThickness - shackleZ + shackleClearance;
//shackleZ2 = shackleZ - shackleTravel - roundToLayerHeight(4);
shackleZ2 = 0;
shackleBaseLength = 10; // length of shackle above body
shackleBendZ = roundToLayerHeight(shackleBaseLength + bodyThickness - frontThickness);
shackleLength1 = shackleBendZ - shackleZ;
shackleLength2 = shackleBendZ - shackleZ2;

module shackle() {
  difference() {
    group() {
      translate([-shackleX,0,shackleZ])   cylinder(r1=shackleR-1,r2=shackleR,h=1+eps);
      translate([-shackleX,0,shackleZ+1]) cylinder(r=shackleR,h=shackleLength1-1+eps);
      translate([shackleX,0,shackleZ2])   cylinder(r1=shackleR-1,r2=shackleR,h=1+eps);
      translate([shackleX,0,shackleZ2+1]) cylinder(r=shackleR,h=shackleLength2-1+eps);
      translate_z(shackleBendZ) intersection() {
        rotate([90,0,0]) rotate_extrude() {
          translate([shackleX,0]) circle(r=shackleR);
        }
        positive_z();
      }
    }
    lug_holes();
    // hole for shackle retaining pin
    shackle_retaining_pin(C=C, h=shackleTravel);
    translate([shackleX,0,shackleRetainPinZ-shackleTravel-C])
    difference() {
      cylinder(r=shackleR+eps,h=shackleRetainPinThickness+3*C);
      cylinder(r=shackleR-shackleRetainPinOverlap-C,h=shackleRetainPinThickness+3*C);
    }
    /*
    // hole for shackle spring
    shackleSpringWidth = 2;
    translate([shackleX,0,shackleZ2-eps])
    linear_extrude(lugZ-lugTravel-2) {
      square([shackleSpringWidth,2*shackleR+1],true);
    }
    */
  }
}

shackleRetainPinZ = roundToLayerHeight(shackleZ2 + shackleTravel + 3);
shackleRetainPinThickness = roundToLayerHeight(2);
shackleRetainPinOverlap = 1;
module shackle_retaining_pin(C=0, h=0) {
  pinH = 4;
  translate_z(shackleRetainPinZ-h)
  linear_extrude(shackleRetainPinThickness+h+roundToLayerHeight(C)) {
    difference() {
      translate([0,-pinH/2]) offset(C) square([shackleX-shackleR+shackleRetainPinOverlap,pinH]);
      circle(r=housingR+tightC-eps);
    }
  }
}

module shackle_with_support() {
  offset = 1*layerHeight;
  f = sqrt(2)/2;
  h = f * (shackleX + shackleR);
  shackleTop = shackleBendZ+shackleX+shackleR;
  wall = 0.8;
  base = 3 * layerHeight;
  rotate([0,180,0])
  translate_z(-(shackleTop+base)) 
  group() {
    shackle();
    // support holes
    color("blue")
    translate_z(lugZ-layerHeight) linear_extrude(lugThickness-layerHeight) {
      w = 0.8;
      translate_x(-(shackleX-shackleR+w/2)) square([w,2*shackleR*0.8],true);
    }
    // support bottom
    color("red")
    difference() {
      translate_z(shackleBendZ+h) linear_extrude(shackleTop - (shackleBendZ+h) + base) {
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

module export_shackle_retaining_pin(){shackle_retaining_pin();}
module export_shackle_with_support(){shackle_with_support();}

//-----------------------------------------------------------------------------
// Locking lugs
//-----------------------------------------------------------------------------

lugTravel = 3.5;
lugOverlap = lugTravel - 0.6;
lugPinR = lugTravel - 0.8;
lugPinA = 0;
// rotation from lugPinA to lugPinA+90 should result in a horizontal travel of lugTravel
// travel = lugPinP*(cos(lugPinA)-cos(lugPinA+90))
//lugPinP = lugTravel / (cos(lugPinA)-cos(lugPinA+90));
lugPinP = lugTravel / (cos(lugPinA)-cos(lugPinA+90));
lugPinPos = polar(lugPinA,lugPinP);
lugPinThickness = roundToLayerHeight(2);
lugOverlapMax = lugOverlap + lugPinP * (1 - cos(lugPinA));
module lug_profile() {
  w = shackleX-shackleR+lugOverlap;
  daMax = asin(lugPinP*(sin(lugPinA+90)-sin(lugPinA)) / (w-lugPinP));
  fillet(0.5)
  difference() {
    hull() {
      lugPinPos2 = lugPinPos;//polar(max(0,lugPinA),lugPinP);
      translate(lugPinPos2) circle(lugPinR);
      translate([lugPinR+C/2,0]) circle(lugPinR);
      translate(lugPinPos2+[0,-lugPinR]) square([w-lugPinPos2[0],2*lugPinR]);
      x = housingR;
      translate([x,-shackleR]) square([w-x,2*shackleR]);
    }
    *translate([lugTravel,0]) 
    rotate(90+daMax)
    translate([-2*lugTravel,0]) circle(lugPinR+C);
  }
}
module lug(pos = 0, test = false) {
  displayX = -(1-cos(90*pos)) * lugTravel;
  
  a = 90*pos;
  w = shackleX-shackleR+lugOverlap;
  
  // when rotated by a=90*pos, the pivot point is moved by [p*cos(a),p*sin(a)]
  // we want the point orginally at [w,0] to be at [w',0]
  // rotate by da around the pivot puts this point at
  //  polar(a,p) + rotate(da,[w,0]) = [_, p*sin(a) + w*sin(da)]
  // solving for da gives
  //  da = asin(p*sin(a)/(w-p))
  
  da = -a - 1*asin(lugPinP*(sin(lugPinA+a)-sin(lugPinA)) / (w-lugPinP));
  daMax = asin(lugPinP*(sin(lugPinA+90)-sin(lugPinA)) / (w-lugPinP));
  
  //displayY = -(1-cos(90*pos)) * lugTravel;
  //translate_x(displayX)
  //translate_y(displayY)
  rotate(a)
  translate(lugPinPos)
  rotate(da)
  translate(-lugPinPos)
  translate_z(lugZ) {
    linear_extrude(lugThickness) lug_profile();
    translate_z(-lugPinThickness)
    translate(lugPinPos) cylinder(r=lugPinR, h=lugThickness+lugPinThickness+(test?1:0));
  }
}
module lugs(pos, test=false) {
  rotated([0,180]) lug(pos,test=test);
}
module lugs_hole_profile() {
  rotated([0,180]) union() for (pos=[0:0.05:1+eps]) {
    a = 90*pos;
    w = shackleX-shackleR+lugOverlap;
    da = -a - 1*asin(lugPinP*(sin(lugPinA+a)-sin(lugPinA)) / (w-lugPinP));
    rotate(a) translate(lugPinPos) rotate(da) translate(-lugPinPos)
    offset(C) lug_profile();
  }
}
module lug_holes() {
  // lug holes
  clearance = 2*layerHeight;
  translate_z(lugZ-clearance)
  linear_extrude(lugThickness+clearance, convexity=2) {
    lugs_hole_profile();
    square([2*(shackleX-shackleR+lugOverlap+C),2*shackleR],true);
  }
}

module lugTest() {
  for (i=[0:2]) {
    translate_y(3*coreR*(i+1)) {
      translate_z(coreThickness) color("lightsalmon") cylinder(r=housingR,h=1);
      translate_z(coreThickness) translate_x(shackleX) color("lightsalmon") cylinder(r=shackleR,h=1);
      color("green") lugs(i/2,test=true);
       translate_z(coreThickness) color("blue") linear_extrude(lugThickness) difference() {
        translate_z(lugZ) circle(r=shackleX);
        lugs_hole_profile();
      }
    }
  }
  
  translate_z(coreThickness) color("lightsalmon") cylinder(r=coreR,h=1);
  color("green") lugs(0);
  translate_z(2.05) color("yellow") lugs(0.5);
  translate_z(4.1) color("blue") lugs(1);
}
*!lugTest();

module export_lug() { rotate([180]) translate_z(-(lugZ+lugThickness)) lug(); }

//-----------------------------------------------------------------------------
// Core retaining screw
//-----------------------------------------------------------------------------

use <../threads.scad>

screwDiameter = 5;

screwShankThickness = roundToLayerHeight(2);
screwHeadThickness1 = shackleR - screwDiameter/2;
screwHeadThickness2 = roundToLayerHeight(2);
screwHeadThickness = screwHeadThickness1 + screwHeadThickness2;
screwThreadLength = roundToLayerHeight(8);

housingThickness = coreThickness;
//housingThickness1 = roundToLayerHeight(coreThickness / 2);
screwTopZ = shackleZ - 2*layerHeight;
housingThickness1 = roundToLayerHeight(screwTopZ - screwShankThickness - screwHeadThickness);
screwZ = roundToLayerHeight(housingThickness1 - screwThreadLength);

module screw(threads = true) {
  translate_x(-shackleX) {
    // note: a bit extra screw height at the top (over shank)
    // a bit less screw height at the bottom
    h = screwThreadLength + 2*layerHeight + eps;
    translate_z(screwZ) 
    intersection() {
      if (threads) {
        standard_thread(screwDiameter,h,internal=false,leadin=true);
      } else {
        cylinder(d=screwDiameter,h);
      }
      translate_z(layerHeight)
      cylinder(r1=screwDiameter/2-0.7,r2=screwDiameter/2-0.7+100,100);
    }
    translate_z(housingThickness1 + 2*layerHeight) {
      h1 = screwShankThickness - 2*layerHeight;
      h2 = screwHeadThickness1;
      h3 = screwHeadThickness2;
      slotDepth = roundToLayerHeight(screwHeadThickness1 + 1);
      slotD = 4;
      difference() {
        union() {
          translate_z(-eps)  cylinder(d=screwDiameter,h1+2*eps);
          translate_z(h1)    cylinder(r1=screwDiameter/2,r2=shackleR,h2);
          translate_z(h1+h2) cylinder(r=shackleR,h3);
        }
        translate_z(h1+h2+h3 - slotDepth) cylinder(d=slotD*2/sqrt(3)+C, slotDepth+eps, $fn=6);
        //cylinder(d=screwDiameter+2*C,h);
      }
    }
  }
}
*!screw();

module export_screw() { rotate([180]) translate_z(-screwTopZ) screw(); }

//-----------------------------------------------------------------------------
// Lock body
//-----------------------------------------------------------------------------

tightC = 0.08;
bodyWall = 1.2;
bodyWall2 = 1.6;
bodyShape = "smooth";
bodyChamfer = 2*layerHeight;

module lock_body_profile() {
  r1 = housingR+tightC+bodyWall;
  r2 = shackleR+tightC+bodyWall2;
  if (bodyShape == "hull") {
    hull() {
      circle(r = r1);
      translate_x(shackleX) circle(r=r2);
      translate_x(-shackleX) circle(r=r2);
    }
  } else if (bodyShape == "minimal") {
    chamfer = 2;
    offset(-chamfer) {
      circle(r = r1+chamfer);
      translate_x(shackleX) circle(r=r2+chamfer);
      translate_x(-shackleX) circle(r=r2+chamfer);
      square([2*shackleX,2*(r2+chamfer)],true);
    }
  } else if (bodyShape == "smooth") {
    // smooth transition between radius r1 in the middle and r2 at shackleX
    power = 1.5;
    ps = [for (a=[-1:0.02:1+eps])
      [a*shackleX, pow(sqrt(1-a*a+eps),power) * (r1-r2)]
    ];
    offset(r2) sym_polygon_y(ps);
  }
}
*!lock_body_profile();

module lock_body() {
  difference() {
    translate_z(-frontThickness)
    linear_extrude_cone_chamfer(bodyThickness,bodyChamfer,bodyChamfer,resolution=30) {
      lock_body_profile();
    }
    // hole for housing
    translate_z(-frontThickness-eps)
    linear_extrude(frontThickness+2*eps) {
      offset(tightC) housing_profile(2);
    }
    linear_extrude(housingThickness1+eps,convexity=2) {
      offset(tightC) housing_profile(1);
    }
    translate_z(housingThickness1)
    linear_extrude(housingThickness+eps-housingThickness1,convexity=2) {
      offset(tightC) housing_profile(0);
    }
    translate_z(housingThickness)
    linear_extrude(lugZ+eps-housingThickness,convexity=2) {
      offset(tightC) housing_profile(0,sidebar=false);
    }
    // shackle/screw holes
    group() {
      translate_x(-shackleX) cylinder(r=screwDiameter/2+C, h=lots);
      z1 = housingThickness1 + screwShankThickness;
      h1 = screwHeadThickness1 + C;
      translate([-shackleX,0,z1])     cylinder(r1=screwDiameter/2, r2=shackleR+C, h=h1);
      translate([-shackleX,0,z1+h1])  cylinder(r=shackleR+C, h=lots);
      translate([shackleX,0,shackleZ2])   cylinder(r1=shackleR-1+C, r2=shackleR+C, h=1);
      translate([shackleX,0,shackleZ2+1]) cylinder(r=shackleR+C, h=lots);
      // chamfer
      chamfer = 2*layerHeight;
      translate([-shackleX,0,bodyThickness-frontThickness-chamfer]) cylinder(r1=shackleR+C,r2=shackleR+C+chamfer+eps, h=chamfer+eps);
      translate([shackleX,0,bodyThickness-frontThickness-chamfer]) cylinder(r1=shackleR+C,r2=shackleR+C+chamfer+eps, h=chamfer+eps);
    }
    // shackle retaining pin
    shackle_retaining_pin(C=tightC);
    // lug holes
    group() {
      lug_holes();
      // printing overhang for lug holes
      chamfer = 1.5;
      z1 = lugZ - 2*layerHeight;
      z2 = z1 - chamfer*0.8;
      render() intersection() {
        rotated(180)
        group() {
          prism([
            [[shackleX-shackleR-C,shackleR+C+0.8], [shackleX-shackleR-C,-(shackleR+C)], [shackleX,-(shackleR+C)], [shackleX,shackleR+C]],
            [[shackleX-shackleR-C+chamfer,shackleR+C-chamfer], [shackleX-shackleR-C+chamfer,-(shackleR+C-chamfer)], [shackleX,-(shackleR+C-chamfer)], [shackleX,shackleR+C-chamfer]]],
            [z1+eps,z2]
          );
          prism([
            [[housingR+C,shackleR+C+4], [housingR+C,-(shackleR+C)], [housingR-4,-(shackleR+C)], [housingR-4,shackleR+C+4]],
            [[housingR+C-chamfer,shackleR+C-chamfer+4], [housingR+C-chamfer,-(shackleR+C-chamfer)], [housingR-4,-(shackleR+C-chamfer)], [housingR-4,shackleR+C-chamfer+4]]],
            [z1+eps,z2]
          );
        }
        linear_extrude(lots,convexity=2) lugs_hole_profile();
      }
    }
  }
}
*!lock_body();

module export_lock_body() { rotate([180]) translate_z(-(bodyThickness-frontThickness)) lock_body(); }

//-----------------------------------------------------------------------------
// Test
//-----------------------------------------------------------------------------

module back_test() {
  rotate([180]) translate_z(-(bodyThickness-frontThickness)) intersection() {
    lock_body();
    translate_z(coreThickness) positive_z();
  }
  translate_y(3*housingR)
  rotate([180]) translate_z(-(coreThickness+coreBackThickness)) intersection() {
    core();
    translate_z(coreThickness+eps) positive_z();
  }
  h = bodyThickness-frontThickness + roundToLayerHeight(2);
  translate_y(6*housingR)
  rotate([180]) translate_z(-h) intersection() {
    shackle();
    translate_z(coreThickness) positive_z();
    translate_z(h) negative_z();
    positive_x();
  }
  translate([8,-3*housingR]) export_lug();
  translate([-8,-3*housingR]) rotate(180) export_lug();
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

colors = [
  "lightgreen", "lightblue", "Aquamarine", "Orchid", "lightsalmon", "lightyellow",
  "pink", "MediumSlateBlue", "DarkOrchid"
];

module visualize_cutout(colors, min_x = undef, min_y = undef, min_z = undef, max_x = undef, max_y = undef, max_z = undef) {
  for (i = [0:$children-1]) {
    color(colors[i]) {
      intersection() {
        group() {cube(0);children(i);}
        if (min_x != undef) translate_x(min_x + i * 2e-3) positive_x();
        if (min_y != undef) translate_y(min_y + i * 2e-3) positive_y();
        if (min_z != undef) translate_z(min_z + i * 2e-3) positive_z();
        if (max_x != undef) translate_x(max_x - i * 2e-3) negative_x();
        if (max_y != undef) translate_y(max_y - i * 2e-3) negative_y();
        if (max_z != undef) translate_z(max_z - i * 2e-3) negative_z();
      }
    }
  }
}

module assembly() {
  anim = 180;
  angle = min(90,anim);
  coreExtraAngle = max(0,anim-90);
  sidebarPos = 1 - min(1,max(0,anim-80)/10);
  springPos = min(1,anim/7);
  lugPos = coreExtraAngle/90;
  shacklePos = 0*shackleTravel;
  
  body = true;
  housing = true;
  shackle = true;
  shacklePin = true;
  screw = true;
  lugs = false;
  core = true;
  wafers = false;
  spacers = wafers;

  threads = true;
  
  min_y = 0;
  max_z = undef;//is_undef(min_y) ? coreThickness/2 : undef;
  //max_z = lugZ+2;
  
  visualize_cutout(colors,min_y=min_y,max_z=max_z) {
    if (body) lock_body();
    if (housing) translate_z(-layerHeight/3) housing(threads=threads);
    if (shackle) translate_z(shacklePos) shackle();
    if (shacklePin) shackle_retaining_pin();
    if (screw) screw(threads=threads);
    if (lugs) lugs(lugPos);
    if (core) rotate(coreAngle+coreExtraAngle) core();
    if (wafers) rotate(coreAngle+coreExtraAngle) {
      for (i=[0:len(bitting)-1]) {
        translate_z(i*(waferThickness+sepThickness)+sepThickness)
        translate_y(dy(angle) + bitting[i] * step * sin(angle))
        wafer(bitting[i]);
      }
    }
    if (spacers) rotate(coreAngle+coreExtraAngle) {
      for (i=[0:len(bitting)-1]) {
        translate_z(i*(waferThickness+sepThickness))
        rotate(angle)
        spacer();
      }
    }
  }
}

!assembly();