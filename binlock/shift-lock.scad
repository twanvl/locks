//=============================================================================
// Binary shift lock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//=============================================================================
// Parameters
//=============================================================================

// Note about names:
//  x = width
//  y = height
//  z = thickness

waferThickness = roundToLayerHeight(0.9);
wafers = 2;

pinWidth = 4;
pinHeight = 8;

keyWidth = 30;
keyHeight = 4*5.5 + 10 + 7;
keyHandleHeight = 20;
keyThickness = roundToLayerHeight(waferThickness * 2.0);

core1Width = keyWidth + 2;
core1Thickness = roundToLayerHeight(wafers * waferThickness + 1.5);
core1Travel = 5.5;
core1Y = 1.2;

core2Thickness = wafers * waferThickness + 0;
core2Travel = 5;

keyTravel = core1Travel + core2Travel; // in y direction

// pin positions
//pinPositions = [[0,35],[8,32],[-8,32], [0,18], [0,35-8]];
//pinPositions = [[0,35],[7,35],[-8,32], [3.5,35-6], [0,35-2*6]];
//pinPositions = [[0,35],[7,35],[-7,32], [0,35-2*core1Travel]];
firstPinY = keyTravel + 3.5;
pinRows = 4;
pinCols = 5;
pinPositions = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) [(j-(pinCols-1)/2)*6, firstPinY+i*core1Travel]];
pinParity = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) (i%2)];

bitting = [0,1,2,2,1,2,0,0,1,0,1,2];

//=============================================================================
// Derived parameters
//=============================================================================

pinTravel = wafers * waferThickness; // in z direction

//=============================================================================
// Pins
//=============================================================================

waferZ = keyThickness + core1Thickness - wafers*waferThickness;
module key_pin_limiter_profile(C=0,i=0) {
  //rotate(45/2)
  //square(2*(2.5+C),true);
  //rotate(45)
  rotate(i*90) rotated(180) square((2.5+C));
  *intersection() {
    rotate(45+90*i) square([7+2*C,2+2*C],true);
    square(2*(3+C),true);
  }
  circle(2.5+C);
}
module key_pin(C=0,i=0) {
  z0 = keyThickness-wafers*waferThickness;
  z1 = wafers*waferThickness + z0;
  z2 = keyThickness + roundToLayerHeight(0.6);
  z3 = waferZ;
  r2 = 2.5;
  translate_z(z0) cylinder(r1=0.8+C,r2=2.5+C,h=z1-z0+eps);
  translate_z(z1) cylinder(r=r2+C,h=z2-z1);
  translate_z(z2) linear_extrude(z3-z2,convexity=2) key_pin_limiter_profile(C,i);
}
module key_pin_hole(i=0) {
  z2 = keyThickness + roundToLayerHeight(0.6);
  linear_extrude(z2+eps) rotate(45) circle((2.5+C));
  translate_z(z2) linear_extrude(lots,convexity=2) key_pin_limiter_profile(C,i);
}

module wafer() {
  cylinder(r=2.5,h=waferThickness);
}
module wafer_hole() {
  cylinder(r=3, h=lots);
}
module mid_pin(bit) {
  cylinder(r=2.5,h=core2Thickness - bit*waferThickness);
}
module top_pin(bit) {
  //cylinder(r=2.5,h=2+bit*waferThickness);
  linear_extrude(bit*waferThickness + roundToLayerHeight(2)) {
    rotate(25) square(2.5*2,true);
  }
}
module top_pin_hole() {
  linear_extrude(lots) {
    rotate(25) square(2*(2.5+C),true);
  }
}

//=============================================================================
// Key
//=============================================================================

module key_profile() {
  chamfer = roundToLayerHeight(1.2);
  polygon([[-keyWidth/2,0], [keyWidth/2,0], [keyWidth/2,keyThickness-chamfer], [keyWidth/2-chamfer,keyThickness], [-keyWidth/2,keyThickness]]);
}
module key() {
  difference() {
    translate_y(-(keyHandleHeight+keyTravel))
    intersection() {
      linear_extrude_y(keyHeight + keyTravel + keyHandleHeight) {
        key_profile();
      }
      linear_extrude(lots) {
        fillet(5) translate_x(-keyWidth/2) {
          square([keyWidth,keyHeight + keyTravel + keyHandleHeight]);
        }
      }
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        translate_z(bitting[i] * waferThickness) key_pin(C);
      }
    }
  }
}

//!key();

//=============================================================================
// Core
//=============================================================================

module core1() {
  difference() {
    group() {
      translate([-core1Width/2,0,keyThickness])
        cube([core1Width,keyHeight+C,core1Thickness]);
      translate([-core1Width/2,0,keyThickness])
        cube([core1Width,core1Y,core1Thickness+core2Thickness]);
      translate([-keyWidth/2,keyHeight+C,0])
        cube([keyWidth,1.2,keyThickness + core1Thickness + core2Thickness]);
    }
    // pins
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        //wafer_hole();
        key_pin_hole(pinParity[i]);
      }
    }
    // limiter
    translate([0,-core1Travel,-coreLimitPinHeight]) minkowski() {
      core_limit_pin();
      //cube([2*C,2*C,eps],true);
      linear_extrude_x(2*C,eps) {
        polygon([[-C,0],[0,0],[coreLimitPinHeight,coreLimitPinHeight]]);
      }
    }
  }
}

core2Y = core1Y + core1Travel + C;
core2Width = core1Width;
module core2() {
  difference() {
    group() {
      translate([-core2Width/2,core2Y,keyThickness+core1Thickness])
        cube([core2Width,keyHeight-core2Y,core2Thickness]);
      translate([-15/2,keyHeight-3,keyThickness+core1Thickness])
        cube([15,3,core2Thickness+2]);
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        wafer_hole();
      }
    }
    minkowski() {
      core_limit_pin();
      cube([2*C,2*C,lots],true);
    }
  }
}

coreLimitPinHeight = roundToLayerHeight(1.5);
module core_limit_pin() {
  h = roundToLayerHeight(core2Thickness+coreLimitPinHeight);
  wy = h;
  wx = 5;
  x = wx + 1.5 - eps;
  translate([core2Width/2-x, keyHeight-wy/2-1.2, keyThickness + core1Thickness + h/2])
  //linear_extrude_x(2) chamfer_rect(w,h,0.8);
  linear_extrude_x(wx) circle(h/2);
}

//=============================================================================
// Housing
//=============================================================================

housingWidth = core2Width + 2*0.8;
housingHeight = keyHeight + core1Travel + core2Travel;
housingFloor = roundToLayerHeight(1.2);
housingDepth = housingFloor + keyThickness + core1Thickness + core2Thickness + 5;
module housing() {
  difference() {
    translate([-housingWidth/2, -1.2, -housingFloor])
      cube([housingWidth,housingHeight,housingDepth]);
    translate_y(-1.3)
    linear_extrude_y(keyHeight + keyTravel + 1.3) {
      minkowski() {
        key_profile();
        translate_x(-C) square([2*C,layerHeight]);
      }
    }
    translate([-(core1Width+2*C)/2, -C, keyThickness])
      cube([core1Width+2*C,keyHeight+keyTravel+2*C,core1Thickness+core2Thickness+1*layerHeight]);
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        top_pin_hole();
      }
    }
  }
}

//=============================================================================
// Assembly and test
//=============================================================================

default_colors = [
  "lightgreen", "lightblue", "Aquamarine", "lightsalmon", "lightyellow",
  "pink", "MediumSlateBlue", "DarkOrchid", "Orchid"
];

module visualize_cutout(min_x = undef, min_y = undef, min_z = undef, colors = default_colors) {
  for (i = [0:$children-1]) {
    color(colors[i]) {
      intersection() {
        group() {cube(0);children(i);}
        if (min_x != undef) translate_x(min_x + i * 2e-3) positive_x();
        if (min_y != undef) translate_y(min_y + i * 2e-3) positive_y();
        if (min_z != undef) translate_z(min_z + i * 2e-3) positive_z();
      }
    }
  }
}

module assembly(min_x = undef) {
  //pos = core1Travel + 1*core2Travel;
  pos = 1*core1Travel;
  keyPos = pos;
  core1Pos = max(0,pos);
  core2Pos = max(0,pos-core1Travel);
  limitPinZ = max(0,min(coreLimitPinHeight,core1Pos-core1Travel+coreLimitPinHeight));
  
  core2 = false;
  housing = true;
  
  visualize_cutout(min_x = min_x) {
    translate_y(keyPos) key();
    translate_y(core1Pos) translate_z(layerHeight*1/6) core1();
    if (core2) translate_y(core2Pos+3*eps) translate_z(layerHeight*2/6) core2();
    translate_y(core2Pos) translate_z(layerHeight*2/6-limitPinZ) core_limit_pin();
    if (housing) translate_z(-layerHeight*1/6) housing();
    // pins
    translate_y(core1Pos) {
      for (i=[0:len(pinPositions)-1]) {
        translate (pinPositions[i]) {
          z = keyPos >= 0 ? bitting[i]*waferThickness : 0;
          translate_z(z) key_pin(i=pinParity[i]);
        }
      }
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        z0 = (keyPos >= 0 ? bitting[i]*waferThickness : 0) + waferZ + layerHeight*1/6;
        for (j=[0:wafers-1]) {
          z = z0 + j * waferThickness + layerHeight*j/6/(wafers/2);
          translate_y((bitting[i] >= wafers-j ? core2Pos : core1Pos)-0.1*(j+1)) translate_z(z) wafer();
        }
        //z2 = z1 + waferThickness + layerHeight*1/6;
        *translate_y((bitting[i] >= 2 ? core2Pos : core1Pos)-0.1) translate_z(z1) wafer();
        *translate_y(bitting[i] >= 1 ? core2Pos : core1Pos) translate_z(z2) wafer();
      }
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        z = (keyPos >= 0 ? bitting[i]*waferThickness : 0) + keyThickness + core1Thickness + layerHeight*3/6;
        translate_y(core2Pos-0.1) translate_z(z) mid_pin(bitting[i]);
      }
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        z = (keyPos >= 0 ? bitting[i]*waferThickness : 0) - bitting[i]*waferThickness + keyThickness + core1Thickness + core2Thickness + layerHeight*4/6;
        translate_y(0+0.1) translate_z(z) top_pin(bitting[i]);
      }
    }
  }
}

module test() {
  assembly(min_x = 0);
  *assembly();
}
test();