//=============================================================================
// Disc detainer lock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

// Bitting code for the key.
// Rules:
//  * first should be a 5 (for spinner disc)
//  * excluding spinner, there should be a 5 near the start and one near the end (for tension discs)
//bittingCode = undef;
//bittingCode = [5,3,5,0,3,2,1,4,3,5];
bittingCode = [4,2,4,0,3,2,1,0,3,0,1,4];

TINY = 1;
SMALLER = 2;
SMALL = 3;
MEDIUM = 4;
LARGE = 5;
ORIGINAL = 6;
size = SMALLER;

C = 0.125; // clearance
keyC = C;
tightC = 0.05;
bridgeC = C+0.5;
coreC = 0.15; // clearance for core hole

eps = 1e-2;

bits = size <= SMALLER ? 4 : 5;
//step = -90/4; // degrees
step = size < ORIGINAL ? 135/bits : 120/bits; // degrees
//step = -100/4; // degrees

discR = size <= TINY ? 7.2 : size <= SMALLER ? 7.4 : size <= SMALL ? 8.5 : 10;
coreWall = size <= TINY ? 1 : size <= SMALLER ? 1.3 : size <= MEDIUM ? 1.6 : 1.7;
coreR = discR + coreWall;
echo("core diameter ",2*coreR);

layerHeight = 0.15;
firstLayerHeight = size == ORIGINAL ? 0.2 : layerHeight;
function roundToLayerHeight(z) = round((z-firstLayerHeight)/layerHeight)*layerHeight + firstLayerHeight;

keyR1 = size <= SMALLER ? 3.75 : size <= SMALL ? 4 : 5;
keyR2 = size <= SMALLER ? 2.7 : size <= SMALL ? 3 : 3.5;
keyWidth = size <= SMALLER ? 2.1 : size <= SMALL ? 2.75 : size <= MEDIUM ? 2.75 : 3;
keyWidthCenter = size <= SMALLER ? 1.3 : keyWidth/2 + 0.08;
keyRot = size <= SMALL ? 0.45*step : size <= MEDIUM ? 0.3*step : 0.5*step;
//keyThickness = 2 * rot(keyRot,on_circle(keyR1+1, keyWidth/2))[0];
keyThickness = 2 * rot(keyRot,on_circle(keyR1, keyWidth/2))[0];
keyProfileFillet = 0.2;
echo("keyThickness", keyThickness);
keywayAngle = 0;

keywayR = size <= SMALLER ? keyR1 + 0.5 : keyR1 + 1;
keywayC = size <= SMALLER ? 0.3 : 0.5;
keywayChamfer = 2;

discThickness = roundToLayerHeight(size <= SMALL ? 1.5 : size <= MEDIUM ? 1.85 : 2.0);
spacerThickness = roundToLayerHeight(size <= MEDIUM ? 0.5 : 0.65);
spinnerThickness = roundToLayerHeight(size <= SMALL ? 1.5 : 2);
spinnerCountersink = roundToLayerHeight(spinnerThickness/2);
builtinSpacerThickness = layerHeight;
builtinSpacerThickness2 = layerHeight;
builtinSpacerR = keyR1 + C + 0.5;

gateHeight = size <= TINY ? 2 : 2.4;
smoothGates = true;
falseHeight = size <= TINY ? 0.5 : size <= SMALLER ? 0.7 : smoothGates ? 0.8 : 1;
sidebarThickness = roundToLayerHeight(1.85);
printSidebarSpring = true;

limiterInside = true;
limiterAngle = 30;

function randomBitting(n,bits=bits) =
  insert_at(n-1, bits,
  insert_at(0, bits,
  insert_at(1, bits, randis(0,bits-1,n-3))));
bitting = bittingCode == undef ? randomBitting(12) : bittingCode;
echo("Bitting: ", bitting);

discs = len(bitting);
coreDepth = (discs-1) * (discThickness + spacerThickness) + spinnerThickness - spinnerCountersink + C;
coreAngle = -90;
coreBack = discThickness;
coreBackChamfer = 1;
coreLimiter = 2;
coreLimiterFirst = true;

discPos = roundToLayerHeight(size <= SMALL ? 6.2 : size <= MEDIUM ? 7 : 8);
corePos = discPos + spinnerThickness - spinnerCountersink;
setScrewPos = (size <= SMALL ? 2 : size <= MEDIUM ? 2 : 3.2) + 4/2;
setScrewLength = size <= SMALLER ? 3 : 3.5; // relative to coreR

shackleDiameter = size <= TINY ? 6 : 8;
shackleChamfer = 1;
shackleSpacing = size <= SMALLER ? 2 : size <= MEDIUM ? 2.5 : 3;
shackleWidth = 2*coreR + shackleDiameter + 2*shackleSpacing;

lugR = size <= SMALL ? coreR-2 : coreR-2;
lugHeight = size <= SMALL ? shackleDiameter+3 : shackleDiameter+4;
lugOverlap = size == SMALLER ? shackleDiameter/2-1 : shackleDiameter/2-0.5;
lugRetainOverlap=1;
lugTravel=lugOverlap+0.5;
lugDepth = roundToLayerHeight(size <= SMALLER ? 5.0 : size <= SMALL ? 5.7 : 6.6);
lugSlope = size <= SMALLER ? 0.75 : 0.8; // about 60deg
lugC = 0.5 + C;
lugPos = corePos + coreDepth + coreBack + lugDepth/2 + lugC + C;

housingSpacingX = size <= TINY ? 2 : size <= SMALLER ? 2.75 : 3;
housingSpacingY = size <= TINY ? 2 : size <= SMALLER ? 2 : size <= MEDIUM ? 2.5 : 3;
housingSpacingY2 = housingSpacingX;
housingHeight = 2*coreR + 2*housingSpacingY;
housingWidth = shackleWidth + shackleDiameter + 2*housingSpacingX;
housingBack = roundToLayerHeight(size <= SMALLER ? 1.5 : 2);
housingDepth = corePos + coreDepth + coreBack + lugDepth + lugC + housingBack + 2*C;

sidebarPos = corePos;
sidebarDepth = (discs-1) * (discThickness + spacerThickness) + spinnerThickness - spinnerCountersink;
sidebarInSpinner = false;

shacklePos = roundToLayerHeight(size <= TINY ? 1.5 : 2);
shackleLength = housingDepth + (size <= TINY ? 5 : 7);
shackleLength1 = shackleLength;
shackleLength2 = shackleLength - coreDepth - corePos + shackleSpacing + shacklePos-2 - (size <= SMALLER ? 0.5 : 0);
//shackleTravel = coreDepth + 3;
shackleTravel = housingBack + lugDepth + 6;


//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

module key_profile(r=keyR1) {
  //x=3.5/2;y=keyR1;
  //square([3.5,10],true);
  keyWidth2 = keyWidth - 0.0;
  fillet(keyProfileFillet)
  intersection() {
    union() {
      rotate(0) square([keyWidth,r],true);
      rotate(-keyRot) square([keyWidth2,2*r],true);
      rotate(keyRot) square([keyWidth2,2*r],true);
      circle(keyWidthCenter);
    }
    circle(r);
  }
}
module keyway_profile() {
  render() {
    fillet(keyProfileFillet)
    intersection() {key_profile();circle(keyR1);}
    fillet(keyProfileFillet)
    rotate(-2*step) intersection() {key_profile();circle(keyR2);}
  }
}

//-----------------------------------------------------------------------------
// discs
//-----------------------------------------------------------------------------

discLimiterR = size <= MEDIUM ? discR - 1 + C : discR - 2;

module rotation_limiter() {
  intersection() {
    difference() {
      circle(coreR);
      circle(discLimiterR);
    }
    a = limiterInside ? 270 : 270-bits*step/2;
    rotate(a) wedge(limiterAngle,center=true);
  }
}
module rotation_limiter_slot(fixed = false) {
  C1 = C * 0.33;
  offset(delta=C1)
  intersection() {
    difference() {
      circle(coreR+1);
      circle(discLimiterR-(C-C1));
    }
    a = limiterInside || fixed ? 270 : 270-bits*step/2;
    rotate(a) wedge(-limiterAngle/2,(fixed ? 0 : bits*step)+limiterAngle/2,center=true);
  }
}

module sidebar_slot(deep,C=C,chamfer=true) {
  w = sidebarThickness+1*C;
  h = deep ? gateHeight+C : falseHeight;
  chamferX = chamfer && smoothGates ? falseHeight*1.1 : 0.3;
  chamferY = chamfer && smoothGates ? falseHeight : 0.4;
  translate([0,discR]) {
    //sym_polygon_x([[-w/2,0],[-w/2,-h]]);
    sym_polygon_x([[-w/2-chamferX,0],[-w/2,-chamferY],[-w/2,-h]]);
    //sym_polygon_x([[-w/2-0.1,0],[-w/2,-0.2],[-w/2-0.1,-1],[-w/2,-h]]);
  }
}
module sidebar_slot_wiggle(deep, chamfer=true) {
  Ca  = smoothGates ? 1.8 : size <= SMALLER ? 1.5 : 1.3;
  rotate(-Ca) sidebar_slot(deep,chamfer=chamfer);
  rotate(0) sidebar_slot(deep,chamfer=chamfer);
  rotate(Ca) sidebar_slot(deep,chamfer=chamfer);
}

module disc_profile(keyway = true, fixed = false) {
  difference() {
    circle(discR);
    if (keyway) rotate(keywayAngle) offset(keyC) keyway_profile();
    if (limiterInside) rotation_limiter_slot(fixed);
  }
  if (!limiterInside) rotate(-bits*step) rotation_limiter();
}

module builtin_spacer() {
  linear_extrude(builtinSpacerThickness, convexity=10) difference() {
    circle(builtinSpacerR);
    circle(keyR1+C);
  }
}
module disc(bit=0) {
  linear_extrude(discThickness - builtinSpacerThickness, convexity=10) {
    difference() {
      disc_profile();
      // slots
      for (i=[0:bits]) {
        rotate(i*step) sidebar_slot_wiggle(i == bit);
      }
    }
  }
  translate_z(discThickness - builtinSpacerThickness) builtin_spacer();
}
module spacer_disc() {
  linear_extrude(spacerThickness - builtinSpacerThickness2, convexity=10) {
    difference() {
      disc_profile(false,true);
      circle(keyR1+keyC);
      sidebar_slot_wiggle(true,chamfer=false);
    }
  }
  translate_z(spacerThickness - builtinSpacerThickness) builtin_spacer();
}
module spacer_disc_for_spinner() {
  spacer_disc();
  translate_z(spacerThickness - builtinSpacerThickness2) linear_extrude(spinnerThickness + builtinSpacerThickness2 - spinnerCountersink - C) {
    difference() {
      disc_profile(false,true);
      circle(discLimiterR);
      sidebar_slot_wiggle(true);
    }
  }
}
module tension_disc() {
  linear_extrude(discThickness - builtinSpacerThickness, convexity=10) {
    difference() {
      disc_profile();
      if (false) {
        // gates?
        for (i=[0:bits-2]) {
          rotate(i*step) sidebar_slot_wiggle(false);
        }
      }
      rotate(bits*step) {
        //sidebar_slot_wiggle(true);
        w = sidebarThickness+1*C;
        h = gateHeight+C;
        a = step;
        b = 0.6;
        chamferY = smoothGates ? falseHeight : 0.4;
        Ca = smoothGates ? 1.8 : size <= SMALLER ? 1.5 : 1.3;
        //translate([0,discR]) polygon([[-w/2,0],[-w/2,-h],[w/2,-h],[w*4/2,0]]);
        polygon([
          rot(-1.3,[-w/2,discR+10]),
          rot(-1.3,[-w/2,discR-h]),
          [w/2,discR-h],
          for (i=[0:0.2:1]) rot(a*i,[w/2,discR-h*(1-i*(1+b-b*i))])
          //for (i=[0:0.2:1]) rot(a*i,[w/2,discR-h*(1-pow(i,0.7))])
          //rot((step-Ca)/2,[0,discR-h/2-chamferY/2]), rot(step-Ca,[-w/2,discR-chamferY]), rot(step+Ca,[w/2,discR])
          ]);
      }
    }
  }
  translate_z(discThickness - builtinSpacerThickness) builtin_spacer();
}
module spinner_disc() {
  difference() {
    cylinder(r=limiterInside ? discLimiterR-C : discR, h=spinnerThickness);
    translate([0,0,-C]) linear_extrude(3+2*C) {
      rotate(keywayAngle) offset(keyC) key_profile();
    }
    translate([0,0,-C]) linear_extrude(3+2*C)
    if (sidebarInSpinner) {
      rotated(180)
      rotate(bits*step) {
        w = sidebarThickness+1*C;
        w2 = 5*w;
        h = gateHeight+C;
        polygon([[-w2/2,discR],[-w/2,discR-h],[w/2,discR-h],[w2/2,discR]]);
      }
    }
  }
}
module spacer_disc1() {
  linear_extrude(spacerThickness, convexity=10) {
    difference() {
      disc_profile(false);
      circle(keyR1+keyC);
      sidebar_slot_wiggle(true);
    }
  }
}

module disc_sanding_tool() {
  h = 15;
  depth = 2*layerHeight;
  difference() {
    intersection() {
      cylinder(r=discR+3,h=h);
      linear_extrude_y(2*discR+10,true) {
        sym_polygon_x([[5,0],[5,5],[discR+3,h-2],[discR+3,h]]);
      }
    }
    translate_z(h-depth) linear_extrude(depth+eps) {
      difference() {
        offset(C) disc_profile(false,true);
        rotate(keywayAngle) key_profile();
      }
    }
  }
}

module disc_test() {
  disc(0);
  translate([2*coreR,0,0]) disc(1);
  translate([0,2*coreR,0]) spacer_disc();
  translate([2*coreR,2*coreR,0]) tension_disc();
  translate([2*coreR,2*coreR,-2]) color("blue") disc(bits-1);
  translate([2*coreR,2*coreR,-2]) rotate((bits-0.9)*step-90) translate_x(-discR-4.5) color("green") sidebar();
  translate([4*coreR,2*coreR,0]) spinner_disc();
  translate([6*coreR,2*coreR,0]) spacer_disc_for_spinner();
  translate([4*coreR,0*coreR,0]) intersection() {
    core();
    //translate_z(10) negative_z();
  }
  //translate([7*coreR,0*coreR,0]) disc_sanding_tool();
  translate([7*coreR,0*coreR,0]) keyway_test();
}
//!tension_disc();
//!disc_test();

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_bit_profile(bit) {
  intersection() {
    key_profile();
    rotate((bits-bit)*step) keyway_profile();
    if (bits-bit >= 2) intersection() {
      rotate((bits-bit-2)*step) key_profile();
      if (bits-bit > 2) rotate((bits-bit-2.5)*step) key_profile();
      if (bits-bit > 3) rotate((bits-bit-3)*step) key_profile();
      if (bits-bit > 3) rotate((bits-bit-3.5)*step) key_profile();
      if (bits-bit > 3) rotate((bits-bit-3.5)*step) key_profile();
      if (bits-bit > 4) rotate((bits-bit-4)*step) key_profile();
      if (bits-bit > 4) rotate((bits-bit-4.5)*step) key_profile();
      circle(keyR2);
    }
  }
}

module inset(r) {
  difference() {
    union() children();
    offset(-r) union() children();
  }
}
module linear_extrude_x_inset(a,b,r,center=true) {
  linear_extrude_x(a,center) children();
  linear_extrude_x(b,center) inset(r) children();
}

module key_bitting(bitting = bitting) {
  transition = spacerThickness*2;
  transition2 = spacerThickness;
  translate_z(discPos) group() {
    for (i=[0:len(bitting)-1]) {
      mirror([1,0,0])
      translate_z(i*(discThickness+spacerThickness)) {
        if (i+1 < len(bitting)) {
          linear_extrude(discThickness+spacerThickness-transition) {
            key_bit_profile(bitting[i]);
          }
          translate_z(discThickness+spacerThickness-transition)
          linear_extrude(transition) {
            key_bit_profile(min(bitting[i],bitting[i+1]));
          }
          translate_z(discThickness+spacerThickness-transition)
          linear_extrude(transition2, scale=0.5) {
            key_bit_profile(bitting[i]);
          }
          translate_z(discThickness+spacerThickness)
          mirror([0,0,1]) linear_extrude(transition2, scale=0.5) {
            key_bit_profile(bitting[i+1]);
          }
        } else {
          linear_extrude(discThickness) {
            key_bit_profile(bitting[i]);
          }
          translate_z(discThickness)
          linear_extrude(discThickness, scale = 0.25) {
            render() key_bit_profile(bitting[i]);
          }
        }
      }
    }
  }
}

keyHandleSizeX = size <= SMALLER ? 9.5 : 11;
keyHandleSizeY = size <= SMALLER ? 8.5 : 9.5;
module key(bitting = bitting) {
  intersection() {
    linear_extrude(discPos) key_profile(keywayR);
    cube([keyThickness,lots,lots],true);
  }
  intersection() {
    cylinder(r=keywayR,h=discPos);
    linear_extrude_y(lots,true) {
      sym_polygon_x([[-keyThickness/2,0],[-keyWidth/2,discPos]]);
    }
  }
  translate_z(-keyHandleSizeY) group() {
    linear_extrude_x_inset(keyThickness-1,keyThickness,1,true) {
      difference() {
        intersection() {
          circle(keyHandleSizeX);
          square([lots,2*keyHandleSizeY],true);
        }
        translate_y(-keyHandleSizeY+(size <= SMALLER ? 4.5 : 5.5)) intersection() {
          circle(3);
          square([lots,5],true);
        }
      }
    }
  }
  key_bitting(bitting);
}

module shell(r=0.5,h=0.15*2) {
  intersection() {
    children();
    minkowski() {
      not() children();
      cylinder(r=r,h=2*h,center=true);
    }
  }
}

module key_with_brim(support = true, brim = true) {
  translate_z(2*9.5) group() {
    union() key();
    if (support) {
      difference() {
        translate_z(discPos) {
          linear_extrude(len(bitting)*(discThickness+spacerThickness) - spacerThickness)
            key_profile();
        }
        minkowski() {
          key_bitting();
          translate_z(-2*layerHeight) cylinder(r=2*C,h=4*layerHeight);
        }
        transition = spacerThickness;
        *for (i=[0:len(bitting)-1]) {
          if (i+1 < len(bitting) && bitting[i] > bitting[i+1]) {
            translate_z(discPos + i*(discThickness+spacerThickness) + discThickness + (bitting[i] > bitting[i+1] ? 0 : transition-layerHeight)) {
              cylinder(r=keyR1,h=layerHeight);
            }
          }
        }
      }
    }
  }
  if (brim) translate([-15/2,-10/2,0]) cube([15,10,0.15]);
}
//!key_with_brim(support=true);
//!keyway_test();

//-----------------------------------------------------------------------------
// Locking mechanism
//-----------------------------------------------------------------------------

lugTravel1=lugOverlap-lugRetainOverlap+C;
lugTravel2=lugOverlap+0.5;
lugR1 = lugR + lugTravel - lugTravel1;
lugR2 = lugR + lugTravel - lugTravel2;

module actuator_profile(offset=0) {
  o = size <= SMALLER ? 1.5 : 4;
  intersection() {
    offset(r=o+offset) offset(r=-o)
    difference() {
      circle(lugR);
      translate([-lugR,0]) scale([lugTravel1*2,lugHeight]) circle(d=1,$fn=80);
      translate([lugR,0]) scale([lugTravel2*2,lugHeight]) circle(d=1,$fn=80);
    }
    circle(coreR);
  }
}

module lug_hole(dx,dz1,dz2,dy=0,hole=false) {
  x = coreR-lugR-lugTravel+shackleSpacing+lugOverlap + dx;
  chamferX1 = lugOverlap;
  chamferZ1 = lugOverlap*lugSlope;
  chamferX2 = lugOverlap;
  chamferZ2 = lugOverlap*lugSlope;
  intersection() {
    group() {
      linear_extrude_y(lugHeight+dy,true) {//sym_polygon_y([[0,-lugDepth/2+dz],[x-chamferX,-lugDepth/2+dz],[x,-lugDepth/2+dz+chamferZ]]);
        polygon([
          [0,-lugDepth/2-dz1], [x-chamferX1,-lugDepth/2-dz1], [x,-lugDepth/2-dz1+chamferZ1],
          [x,lugDepth/2+dz2-chamferZ2], [x-chamferX2,lugDepth/2+dz2], [0,lugDepth/2+dz2]]);
      }
      difference() {
        translate([0,-(lugHeight+dy)/2,-lugDepth/2-dz1])
          cube([x,lugHeight+dy,lugDepth+dz1+dz2]);
        if (!hole) {
          translate_x(coreR-lugR-lugTravel+shackleSpacing+shackleDiameter/2)
            cylinder(d=shackleDiameter+4*C,h=lugDepth*2,center=true);
        }
      }
    }
  }
}
module lug(clear_limiter = coreLimiterFirst || size <= SMALL) {
  intersection() {
    group() {
      difference() {
        linear_extrude(lugDepth,center=true) {
          intersection() {
            scale([lugTravel*2-2*C,lugHeight]) circle(d=1,$fn=20);
            translate_x(-lots) square(2*lots,true);
          }
        }
        // clearance around core rotation limiter
        if (!coreLimiterFirst && clear_limiter) {
          translate([-coreLimiterR-lugTravel+2.2, 0, (lugDepth-(coreLimiter+bridgeC))/2])
          cylinder(r1=coreLimiterR-2.2, r2=coreLimiterR, h=coreLimiter+bridgeC+eps, center=true);
        }
        if (coreLimiterFirst && clear_limiter) {
          translate_x(-(lugR + lugTravel))
          translate_z(-lugDepth/2)
          group() {
            cylinder(r=coreR+coreC+0.5,h=coreLimiter+C+eps);
            linear_extrude(coreLimiter+C+eps) {
              translate_x(lugTravel+2*C) {
                rotate(90) wedge(-10,-10-45,r=coreR+5);
                polygon([[lugTravel+coreR-lugR-1,0],polar(90-10,coreR),polar(90-10-45,coreR)]);
                polygon([[lugTravel+coreR-lugR-0.2,-2],polar(90-10,coreR),polar(90-10-45,coreR)]);
              }
            }
          }
        }
      }
      lug_hole(0,0,0);
    }
    linear_extrude_x(lots,true) {
      chamfer = 1; // chamfer at bottom side for printability
      sym_polygon_x([
        [lugHeight/2, lugDepth/2],
        [lugHeight/2, -lugDepth/2+chamfer*0.8],
        [lugHeight/2-chamfer, -lugDepth/2]
      ]);
    }
  }
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

coreLimiterR = size <= SMALLER ? lugR - lugTravel + 1 : lugR - lugTravel;

module core() {
  rotate(coreAngle) group() {
    difference() {
      union() {
        cylinder(r=coreR,h=coreDepth+coreBack-coreBackChamfer);
        translate_z(coreDepth+coreBack-coreBackChamfer)
          cylinder(r1=coreR,r2=max(lugR,coreR-coreBackChamfer/0.8),h=coreBackChamfer);
      }
      translate_z(-eps) cylinder(r=discR+C,h=coreDepth+eps);
      // sidebar slot
      sidebarC = C/2;
      translate([0,discR+2/2]) cube([sidebarThickness+2*sidebarC,2+2*gateHeight,coreDepth*2],true);
      // key end
      translate([0,0,coreDepth-2*eps]) cylinder(r1=keyR1+keyC,r2=keyR1*0.25+keyC,h=discThickness+0.5);
      if (!limiterInside) {
        translate_z(-eps) linear_extrude(coreDepth,convexity=10) rotation_limiter_slot();
      }
    }
    if (limiterInside) {
      linear_extrude(coreDepth,convexity=10) rotation_limiter();
    }
  }
  // rotation limiter
  if (coreLimiterFirst) {
    translate_z(coreDepth)
    linear_extrude(coreLimiter+coreBack,convexity=10) {
      difference() {
        union() {
          rotated(180) wedge(-10,-10-45,r=coreR);
        }
        circle(lugR);
      }
      union() {
        //rotated(180) wedge(-10,-10-45,r=lugR,center=true);
        rotated(180) polygon([polar(-10,lugR),polar(-10-45/2,coreR),polar(-10-45,lugR),polar(-10-45/2,lugR*0.75)]);
      }
    }
  }
  rotate(-90)
  translate_z(coreDepth+coreBack) {
    difference() {
      linear_extrude(lugDepth+lugC,convexity=10) {
        actuator_profile();
      }
      if (!coreLimiterFirst) {
        translate_z(lugDepth+lugC-coreLimiter-bridgeC)
          core_limiter_slot();
      }
    }
  }
}
//!core();
module core_limiter_slot() {
  linearC = 0;
  linear_extrude(coreLimiter+bridgeC+eps) {
    offset(linearC) difference() {
      circle(r=coreLimiterR+C-linearC);
      wedge(90+90/2,center=true);
    }
    circle(r=0.25);
  }
}

//-----------------------------------------------------------------------------
// Shackle
//-----------------------------------------------------------------------------

function layout_text(text,sz) =
  text == "SOFTENED" ? [sz*-3.5,sz*-2.47,sz*-1.45,sz*-0.5,sz*0.35,sz*1.45,sz*2.45,sz*3.5] : // manual kerning
  text == "PLASTIC" ? [sz*-3,sz*-2,sz*-0.8,sz*0.35,sz*1.35,sz*2.15,sz*3] // manual kerning
  : [for (i=[0:len(text)-1]) (i - (len(text)-1)/2) * sz];

module shackle(shackleLabel = true) {
  // legs
  difference() {
    lugZ = lugPos - shacklePos - C;
    lugC = 0;
    group() {
      translate([-shackleWidth/2,0,shackleLength-shackleLength1]) {
        cylinder(d1=shackleDiameter-2*shackleChamfer,d2=shackleDiameter,h=shackleChamfer);
        //translate_z(2) cylinder(d=shackleDiameter,h=shackleLength1-2);
        shackleLimiterZ = lugDepth-2*lugOverlap*lugSlope;
        shackleLimiterX = lugRetainOverlap * lugSlope;
        translate_z(lugZ-shackleTravel+shackleLimiterZ/2+shackleLimiterX)
          cylinder(d=shackleDiameter, h=shackleLength-(lugZ-shackleTravel+shackleLimiterZ/2+shackleLimiterX));
        translate_z(lugZ-shackleTravel+shackleLimiterZ/2)
          cylinder(d2=shackleDiameter,d1=shackleDiameter-2*lugRetainOverlap-2*lugC, h=shackleLimiterX);
        translate_z(lugZ-shackleTravel-shackleLimiterZ/2)
          cylinder(d=shackleDiameter-2*lugRetainOverlap-2*lugC,h=shackleLimiterZ);
        translate_z(lugZ-shackleTravel-shackleLimiterZ/2-shackleLimiterX)
          cylinder(d1=shackleDiameter,d2=shackleDiameter-2*lugRetainOverlap-2*lugC, h=shackleLimiterX);
        translate_z(shackleChamfer)
          cylinder(d=shackleDiameter,h=(lugZ-shackleTravel-shackleLimiterZ/2-shackleLimiterX)-shackleChamfer);
      }
      translate([shackleWidth/2,0,shackleLength-shackleLength2]) {
        cylinder(d1=shackleDiameter-2*shackleChamfer,d2=shackleDiameter,h=shackleChamfer);
        translate_z(shackleChamfer) cylinder(d=shackleDiameter,h=shackleLength2-shackleChamfer);
      }
    }
    mirrored([1,0,0]) {
      translate([lugR+lugTravel,0,lugZ]) lug_hole(C,C,C);
    }
    x = -shackleWidth/2+shackleDiameter/2 - lugRetainOverlap - lugC;
    translate([x, -shackleDiameter/2, lugZ-shackleTravel]) cube([10,shackleDiameter,shackleTravel]);
  }
  // top part
  translate([0,0,shackleLength]) group() {
    // background for text
    color("red") intersection() {
      rotate([90,0,0]) rotate_extrude() {
        translate([shackleWidth/2,0]) circle(d=shackleDiameter-2*0.4);
      }
      positive_z();
    }
    difference() {
      intersection() {
        rotate([90,0,0]) rotate_extrude() {
          translate([shackleWidth/2,0]) circle(d=shackleDiameter);
        }
        positive_z();
      }
      if (shackleLabel)
      rotate([90,0,0])
      linear_extrude(6,convexity=10) {
        text = "PLASTIC";
        textSize = size <= SMALLER ? 4.1 : 4.3;
        sz = size <= SMALLER ? -13.5 : -12;
        pos = layout_text(text,sz);
        for (i=[0:len(text)-1]) {
          rotate(pos[i])
          translate([0,shackleWidth/2])
          text(text[i],size=textSize,font="Ubuntu:style=Bold",halign="center",valign="center");
        }
      }
    }
  }
}


module shackle_with_support() {
  offset = 1*layerHeight;
  base = 0.35;
  rotate([0,180,0])
  group() {
    shackle();
    color("red")
    translate_z(shackleLength) 
    difference() {
      cube([(shackleWidth+shackleDiameter+2*offset)*sqrt(2)/2+1, shackleDiameter/sqrt(2)+1, (shackleWidth+shackleDiameter+2*offset)+2*base],true);
      rotate([90,0,0]) rotate_extrude() {
        union() {
          translate([shackleWidth/2,0]) circle(d=shackleDiameter+2*offset);
          //translate([0,-(shackleDiameter+offset)/2]) square([shackleWidth/2,shackleDiameter+offset]);
          translate([0,-(shackleDiameter+2*offset+10)/2])
            square([shackleWidth/2+(shackleDiameter+2*offset)*sqrt(2)/4,shackleDiameter+2*offset+10]);
        }
      }
      //translate_z((shackleWidth+shackleDiameter)*(0.5-sqrt(2)/2)) negative_z();
      translate_z((shackleWidth+shackleDiameter+2*offset)*(sqrt(2)/4)) negative_z();
    }
  }
}
//!shackle_with_support();

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

include <../threads.scad>

module housing(threads=true, logo=true, shackleHoles=true, lugHoles=true, simple=false) {
  difference() {
    housingChamfer = 0.45;
    //linear_extrude(housingDepth, convexity=10) {
    if (simple) {
      translate_z(housingDepth/2)
      chamfer_cube(housingWidth,housingHeight,housingDepth,housingChamfer);
    } else {
      linear_extrude_chamfer(housingDepth, housingChamfer,housingChamfer, convexity=10) {
        //chamfer_rect(housingWidth,housingHeight,5);
        //offset(4) offset(-4)
        mirrored([0,1])
        union() {
          h1 = shackleDiameter+2*(housingSpacingY2-1);
          chamfer_rect(housingWidth,h1,housingChamfer);
          difference() {
            intersection() {
              // use an ellipse for the sides
              translate_y(lots/2) square([housingWidth,lots],true);
              r1 = housingWidth*1;
              yForEdge = sqrt(r1*r1-(housingWidth/2)*(housingWidth/2));
              r2 = (housingHeight/2 - h1/2) / (1 - yForEdge/r1);
              y = r2/r1 * yForEdge;
              // want: h1/2-y + r2 = housingHeight/2
              //   = h1/2 - r2/r1 * sqrt.. + r2 = housingHeight/2
              //  => r2 * (1 - sqrt../r1) =  housingHeight/2 - h1/2
              translate_y(h1/2-y)  scale([1,r2/r1]) circle(r1);
            }
            // chamfer
            mirrored([1,0])
            translate([housingWidth/2+housingChamfer,h1/2+housingChamfer]) scale([0.7,1]) circle(r=3*housingChamfer,$fn=4);
          }
        }
      }
    }
    // core slot
    translate_z(-eps) cylinder(r=coreR+coreC,h=corePos+coreDepth+coreBack+lugC+2*C);
    translate_z(corePos+coreDepth+coreBack+lugC+C) cylinder(r=lugR+coreC,h=lugDepth+C);
    // sidebar slot
    // Note: chamfered to still accept sidebar if core is rotated too far closed
    sidebarPosY = sidebarThickness/2+C;
    translate([coreR-1, 0, sidebarPos-bridgeC])
    linear_extrude(sidebarDepth+C+bridgeC) {
      polygon([
        [0,sidebarPosY], [gateHeight+1+C,sidebarPosY],
        [gateHeight+1+C,sidebarPosY-sidebarThickness-2*C],
        [2,sidebarPosY-sidebarThickness-2*C],
        [0,sidebarPosY-sidebarThickness-2*C-1.5]]);
    }
    if (printSidebarSpring) {
      h = sidebarSpringDepth + 2*C + 1;
      translate([coreR-1, sidebarPosY-(sidebarSpringThickness+2*C), sidebarPos + (sidebarDepth-h)/2]) {
        cube([sidebarSpringWidth+1,sidebarSpringThickness+2*C,h]);
      }
    } else {
      translate_z(sidebarPos) {
        translate([coreR-1,0,4]) rotate([0,90,0]) cylinder(d=3.3,h=14);
        translate([coreR-1,0,sidebarDepth/2]) rotate([0,90,0]) cylinder(d=3.3,h=14);
        translate([coreR-1,0,sidebarDepth-4]) rotate([0,90,0]) cylinder(d=3.3,h=14);
      }
    }
    // shackle holes
    if (shackleHoles) {
      translates([[-shackleWidth/2,0,shackleLength-shackleLength1],
                  [shackleWidth/2,0,shackleLength-shackleLength2]]) {
        translate([0,0,shacklePos-bridgeC]) cylinder(r1=shackleDiameter/2+C-(shackleChamfer+bridgeC), r2=shackleDiameter/2+C, h=shackleChamfer+bridgeC);
        translate([0,0,shacklePos+shackleChamfer]) cylinder(r=shackleDiameter/2+C, h=housingDepth);
      }
    }
    // lugs
    if (lugHoles) {
      group() {
        linear_extrude_x(2*(coreR+shackleSpacing+lugOverlap+C),true) {
          chamfer1 = 1; // chamfer at bottom side for printability
          chamfer2 = 0.8; // chamfer at bottom side for printability
          sym_polygon_x([
            [lugHeight/2+C, lugPos+lugDepth/2+C],
            [lugHeight/2+C, lugPos-lugDepth/2-C+chamfer1*0.8],
            [lugHeight/2-chamfer1-chamfer2, lugPos-lugDepth/2-C-chamfer2*0.8]
          ]);
        }
        intersection() {
          cylinder(r=coreR+C,h=lots);
          translate_z(lugPos) cube([lots,lugHeight+2*C,lugDepth+2*C],true);
        }
        render() intersection() {
          chamfer1 = 1; chamfer2 = 0.8;
          d=0.5;
          translate_z(lugPos-lugDepth/2-(chamfer2+d)*0.8)
            cylinder(r1=coreR+C,r2=coreR+C+d,h=d*0.8);
          cube([100,lugHeight+2*C-2*(chamfer1+chamfer2),100],true);
        }
      }
    }
    // plug hole
    if (threads) {
      rotate(-120)
      thread_with_stop(diameter=coreR*2+2,C=C,pitch=2,length=corePos,angle=30);
    } else {
      cylinder(r=coreR+1+C,h=corePos-1+tightC);
    }
    cylinder(d=coreR*2+2+2*C,h=1.5+C);
    // set screw
    dx = shackleDiameter/2 + shackleSpacing;
    translate([-(coreR+dx),0,setScrewPos]) rotate([0,-90,0]) cylinder(d=4+2*C,h=lots);
    if (threads) {
      translate([-(coreR+dx),0,setScrewPos]) rotate([0,90,0]) m4_thread(setScrewLength+dx,C=C,internal=true);
    } else {
      translate([-(coreR+dx),0,setScrewPos]) rotate([0,90,0]) cylinder(d=4,h=setScrewLength+dx);
    }
    // logo
    if (logo) {
      if (size <= SMALLER) {
        logoSize = 6;
        logoPos = logoSize+3;
        translate([housingWidth/2-logoPos,-(shackleDiameter/2+housingSpacingY2+housingHeight/2)/2+logoSize*0.100,logoPos])
        rotate([0,0,17.5])
        rotate([90])
        color("red")
        logo(r=logoSize,logo=true);
      } else {
        logoSize = 6;
        logoPos = logoSize+3;
        translate([housingWidth/2-logoPos,-(shackleDiameter/2+housingSpacingY2+housingHeight/2)/2+logoSize*0.12,logoPos])
        rotate([0,0,23])
        rotate([90])
        logo(r=logoSize,logo=logo);
      }
    }
    if (coreLimiterFirst) {
      translate_z(corePos+coreDepth+coreBack+lugC+2*C-2*eps)
      linear_extrude(coreLimiter+2*eps) {
        rotated(180) difference() {
          wedge(-10+90,-10-45,r=coreR+coreC);
          circle(min(1,lugR),$fn=4); // fix manifold issues
        }
      }
    }
  }
  // rotation limiter for core
  if (!coreLimiterFirst) {
    translate_z(housingDepth-housingBack-coreLimiter) {
      intersection() {
        core_limiter();
        // leave room for lugs
        linear_extrude_y(lots,true) {
          sym_polygon_x([[coreLimiterR,coreLimiter+eps],[coreLimiterR-coreLimiter*0.8,0]]);
        }
      }
    }
  }
}
module core_limiter() {
  linear_extrude(coreLimiter) {
    intersection() {
      difference() {
        circle(coreLimiterR);
        circle(0.5);
      }
      rotate(-90 - 180+45) wedge(90+45,center=true);
    }
  }
}
//!housing(threads=false, logo=true);

module plug(threads=true) {
  difference() {
    union() {
      cylinder(r=coreR,h=corePos);
      cylinder(d=coreR*2+2,h=1.5);
      if (threads) {
        rotate(-120)
        thread_with_stop(diameter=coreR*2+2,pitch=2,length=corePos,angle=30);
      } else {
        cylinder(r=coreR+1,h=corePos-1);
      }
    }
    translate([0,0,-eps]) cylinder(r=keywayR+keywayC,h=lots);
    translate([0,0,-eps]) cylinder(r1=keywayR+keywayC+keywayChamfer,r2=keywayR+keywayC,h=keywayChamfer+eps);
    //translate([0,0,-1-eps]) cylinder(r1=keyR1+2,r2=keyR1+1,h=1+eps);
    dx = shackleDiameter/2 + shackleSpacing;
    if (threads) {
      translate([-(coreR+dx),0,setScrewPos]) rotate([0,90,0]) m4_thread(setScrewLength+dx,C=C,internal=true);
    } else {
      translate([-(coreR+dx),0,setScrewPos]) rotate([0,90,0]) cylinder(d=4,h=setScrewLength+dx); 
    }
    translate_z(discPos) cylinder(r=discLimiterR,h=spinnerCountersink+eps);
    // unscrewing screw slot
    translate_z(size <= SMALLER ? -5.2 : -6) rotate([90,0,90]) {
      cylinder(r=keyHandleSizeX, h=keyThickness+2*C, center=true);
    }
  }
}
//!plug();

module set_screw() {
  difference() {
    m4_thread(setScrewLength+shackleSpacing, leadin=1); 
    //translate([-1/2,-lots/2,0]) cube([1,lots,1]);
    //translate([-1/2,-lots/2,0]) cube([1,lots,1]);
    // 2mm hex key
    translate_z(-eps) cylinder(d=2/cos(180/6)+C,$fn=6,h=1.5);
  }
}
//!rotate([180]) set_screw();

//-----------------------------------------------------------------------------
// Sidebar
//-----------------------------------------------------------------------------

module sidebar() {
  sidebarChamfer = 0.4;
  difference() {
    translate([(gateHeight+coreWall)/2,0,(sidebarDepth-C)/2])
    chamfer_cube(gateHeight+coreWall,sidebarThickness,sidebarDepth-C,sidebarChamfer,rz=0);
    if (!sidebarInSpinner) {
     translate([-lots+gateHeight-discR+discLimiterR+C,-lots/2,C-spinnerCountersink])
      //translate([(gateHeight+coreWall)-(coreR-discLimiterR)-lots,-lots/2,-spinnerCountersink])
      cube([lots,lots,discThickness]);
    }
  }
}

sidebarSpringWidth = shackleDiameter+shackleSpacing+housingSpacingX-2;
sidebarSpringPrintWidth = sidebarSpringWidth + 1;
sidebarSpringDepth = sidebarDepth - 6;
sidebarSpringThickness = sidebarThickness + 2;

module wiggle(w,h,r) {
  a = atan2(h,w/2);
  rx = r/sin(a);
  ry = r/cos(a);
  //polygon([[0,0],[0,ry],[w/2-rx/2,h],[w/2+rx/2,h],[w,ry],[w,0],[w/2,h-ry]]);
  polygon([[rx/2,0],[0,0],[0,ry],[w/2-rx/2,h],[w/2+rx/2,h],[w,ry],[w,0],[w-rx/2,0],[w/2,h-ry]]);
}
module sidebar_spring(angle = 0, nub=true) {
  h = sidebarSpringDepth;
  nx = 6;
  r = 0.5;
  w = (sidebarSpringPrintWidth-r)/nx;
  h2 = h*cos(angle);
  w2 = w + h*sin(angle);
  linear_extrude_y(sidebarSpringThickness,center=true) {
    square([r,sidebarSpringDepth]);
    for (i=[0:nx-1]) {
      translate([i*w2+r/2,i%2 ? h2-r : 0]) square([w,r]);
      translate([i*w2+r/2+ (i%2==0 ? w : w2), 0])
        rotate(i%2==0 ? -angle : angle)
        translate([-r/2,0])
        square([r,sidebarSpringDepth]);
    }
  }
  // pusher for sidebar
  if (nub) {
    p = r;
    translate_y((sidebarSpringThickness-sidebarThickness)/2)
    linear_extrude(sidebarSpringDepth) {
      sym_polygon_y([[0,sidebarThickness/2],[-p,sidebarThickness/2-1.5*p]]);
    }
  }
}

module sidebar_test() {
  sidebar();
  translate_x(gateHeight+coreWall + 2) sidebar_spring(5);
}
//!sidebar_test();

//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

//translate([0,20,0]) disc_test();

module keyway_test() {
  translate([0,0]) keyway_profile();
  for (i=[0:bits]) {
    translate([10+i*10,0]) {
      color("blue") render() key_bit_profile(bits-i);
      rotate(i*step) {
        translate([0,0,-1]) color("yellow") keyway_profile();
        translate([0,0,-2]) color("pink") rotate(2) offset(C) keyway_profile();
      }
    }
    translate([10+i*10,-10]) {
      color("blue") render() key_bit_profile(bits-i);
      rotate(0) {
        translate([0,0,-1]) color("yellow") keyway_profile();
        translate([0,0,-2]) color("pink") rotate(-2) offset(C) keyway_profile();
      }
    }
  }
}

module core_limiter_test1() {
  translate_z(-3*layerHeight) linear_extrude(3*layerHeight) square(2*coreR,true);
  linear_extrude(25*layerHeight) {
    difference() {
      square(2*coreR,true);
      circle(lugR+coreC);
    }
  }
  core_limiter();
  translate_z(25*layerHeight) linear_extrude(layerHeight) {
    difference() {
      union() {
        square([0.5,2*coreR],true);
        square([2*coreR,0.5],true);
      }
      circle(lugR+coreC);
    }
  }
}
module core_limiter_test2() {
  translate_z(C) {
    difference() {
      cylinder(r=lugR,h=25*layerHeight);
      translate_z(-eps) core_limiter_slot();
    }
    translate_z(25*layerHeight) linear_extrude(layerHeight) {
      intersection() {
        union() {
          translate_y(coreR) square([0.5,2*coreR],true);
          translate_y(-coreR) square([0.5,coreR*0.8],true);
          translate_x(coreR) square([coreR*0.8,0.5],true);
          translate_x(-coreR) square([coreR*0.8,0.5],true);
        }
        circle(lugR);
      }
    }
  }
}
module core_limiter_test() {
  intersection() {
    group() {
      core_limiter_test1();
      color("red") core_limiter_test2();
    }
    //positive_x();
  }
}
//!core_limiter_test();

module housing_sidebar_test() {
  $fn=40;
  intersection() {
    group() {
      export_housing_sidebar_test();
      *rotate(0.5)
      color("red") translate([0,0,corePos + C]) core();
    }
    //translate_z(corePos+coreDepth+coreBack+lugDepth+lugC) negative_z();
  }
  *translate_x(housingWidth)
    export_housing_sidebar_test();
  *translate_x(2*housingWidth)
    color("red") translate([0,0,corePos + C]) core();
}
//!housing_sidebar_test();

module test() {
  $fs = 1; $fa = 8;
  threads = false;
  logo = false;
  housing = true;
  key = true;
  discs = false;
  core = true;
  cut = false;
  lugs = true;
  shackle = true;
  sidebar = core;
  cutHousing = undef;
  cutCore = cutHousing;
  cutShackle = undef;//cutHousing;
  ts = 4;
  unlocked = max(0,min(1,ts*$t));
  open = max(0,min(1,ts*$t-1));
  //open=1.6;
  //open=0;
  lugOpen = pow(open,3);
  shacklePosT = shacklePos + C + shackleTravel*max(0,min(1,ts*$t-2));
  sidebarSpringPos = sidebarPos+(sidebarDepth-sidebarSpringDepth)/2;

  group() {
    intersection() {
      group() {
        if (housing) intersection() {
          translate_z(0) housing(threads,logo);
          if (cutHousing!=undef) translate_y(cutHousing) positive_y();
          //translate_z(corePos-1.9) negative_z();
        }
        //translate([0.08,-0.08])
        //rotate(-2) // simulate slop in core movement
        rotate(open*90)
        group() {
          if (core) intersection() {
            translate([0,0,corePos + C]) color("lightgreen") core();
            if (cutCore!=undef) translate_y(cutCore) positive_y();
          }
          if (discs) translate_z(discPos + C/2) {
            //translate_z(0) color("lightyellow") rotate(coreAngle) spinner_disc();
            for (i=[0:len(bitting)-1]) {
              translate_z(i*(discThickness+spacerThickness))
              rotate(coreAngle + unlocked * bitting[i]*step)
              mirror([1,0,0]) if (i==0) {
                color("lightgreen") spinner_disc();
              } else if (bitting[i] == bits) {
                color("lightblue") tension_disc();
              } else {
                color("lightyellow") disc(bitting[i]);
              }
              *if (i < len(bitting)-1)
              translate_z(i*(discThickness+spacerThickness)+discThickness) color("lightyellow") rotate(coreAngle) spacer_disc();
            }
          }
          if (key) translate_z(0) color("magenta") rotate(coreAngle + keywayAngle + unlocked*bits*step) key();
          if (sidebar) color("green") translate([discR-unlocked*gateHeight+C/2,0,sidebarPos+C/2]) sidebar();
        }
        color("blue") translate([discR-unlocked*gateHeight+C/2+gateHeight+coreWall,(sidebarThickness-sidebarSpringThickness)/2, sidebarSpringPos+C/2])
          scale([(sidebarSpringWidth-(1-unlocked)*gateHeight)/sidebarSpringPrintWidth,1,1]) sidebar_spring();
        if (shackle) intersection() {
          translate([0,0,shacklePosT]) shackle();
          if (cutShackle!=undef) translate_y(cutShackle) positive_y();
        }
        intersection() {
          color("pink") translate([0,0,0]) plug(threads);
          if (cutHousing!=undef) translate_y(cutHousing) positive_y();
        }
        if (lugs) {
          color("pink") translate([-lugR1-(1-lugOpen)*lugTravel1,0,lugPos]) rotate(180) lug();
          color("pink") translate([lugR2+(1-lugOpen)*lugTravel2,0,lugPos]) lug();
        }
        if (threads) color("darkgrey") translate([-(coreR+3),0,setScrewPos]) rotate([0,90]) set_screw();
      }
      if (cut) positive_y();
      //translate([0,-5,0]) rotate([-15]) positive_y();
      translate_z(8) positive_z();
      //translate_z(housingDepth-housingBack-eps) negative_z();
      //translate_z(housingDepth-housingBack-lugDepth) positive_z();
      //translate_z(corePos+1) positive_z();
    }
    //rotate(-70) color("lightblue") translate([0,coreR+4.5]) cube([3,9,coreDepth*2],true);
    //translate([coreR-3,0,corePos-3.5/2-1.5]) rotate([0,90,0]) cylinder(d=4,h=6);
  }
}
//!disc_test();
!test();

//-----------------------------------------------------------------------------
// Exported parts
//-----------------------------------------------------------------------------

module export_discs() {
  translate([-1*coreR*2,0]) spinner_disc();
  for (i=[0:5]) {
    translate([i*coreR*2,0]) if (i==5) tension_disc(); else disc(i);
    translate([i*coreR*2,coreR*2]) spacer_disc();
  }
}
module export_needed_discs() {
  for (i=[0:discs-1]) {
    translate([i*coreR*2,0])
    if (i == 0) {
      spinner_disc();
    } else if (bitting[i]==bits) {
      tension_disc();
    } else {
      disc(bitting[i]);
    }
    if (i == 1) {
      translate([(i-0.5)*coreR*2,coreR*2]) spacer_disc_for_spinner();
    } else if (i > 0) {
      translate([(i-0.5)*coreR*2,coreR*2]) spacer_disc();
    }
  }
}
module export_core() {
  rotate([180]) core();
}
module export_sidebar() {
  rotate([90]) sidebar();
}
module export_sidebar_spring() rotate([90]) sidebar_spring();
module export_sidebar_spring5() rotate([90]) sidebar_spring(5);
module export_sidebar_spring10() rotate([90]) sidebar_spring(10);
module export_shackle() {
  rotate([-90]) shackle();
}
module export_shackle_with_support() shackle_with_support();
module export_housing() {
  rotate([180]) housing();
}
module export_plug() plug();
module export_lug() rotate([180]) lug();
module export_set_screw() rotate([180]) set_screw();
module export_key() key_with_brim(brim=false,support=false);
module export_key_with_brim() key_with_brim();
module export_key_with_support() key_with_brim(brim=false,support=true);
module export_disc_sanding_tool() disc_sanding_tool();
module export_housing_plug_test() {
  rotate([180]) intersection() {
    housing(logo=false);
    cylinder(r=coreR+3,h=corePos+1);
  }
}
module export_housing_lug_test() {
  rotate([180]) intersection() {
    housing(threads=false, logo=false);
    negative_x();
    translate_z(lugPos-lugDepth/2-3) positive_z();
  }
}
module export_housing_sidebar_test() {
  //rotate([180])
  intersection() {
    housing(threads=false, logo=false, shackleHoles=true, lugHoles=true, simple=true);
    //negative_x();
    union() {
      translate_z(corePos+coreDepth) cylinder(r=coreR+2,lots);
      translate([coreR-2,-5,corePos-2]) cube([sidebarSpringDepth-8,8,lots]);
      translate([coreR-2,-5,corePos+15]) cube([sidebarSpringDepth-2.5,8,lots]);
      mirrored([1,0,0])
      translate([coreR-2,-6,corePos+coreDepth]) cube([9,12,lots]);
      //translate_z(lugPos-lugDepth/2-3) positive_z();
    }
  }
}
export_discs();
export_core();
export_sidebar();
