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

C = 0.125;
pinC = 0.2;

wall = 1.2;

waferThickness = roundToLayerHeight(0.9);
wafers = 2;

pinWidth = 4;
pinHeight = 8;

//keyHeight = 4*5.5 + 10 + 7;
keyHandleHeight = 20;
keyThickness = roundToLayerHeight(waferThickness * 2.0);

//core1Travel = 5.5;
core1Travel = 6;
core2Travel = 5;
keyTravel = core1Travel + core2Travel; // in y direction

pinR = 2.5;
//pinR = 2.25;
firstPinY = keyTravel + wall;
pinRows = 4;
pinCols = 3;
xSpacing = 6;
function pinPos(i,j) = [(j-(pinCols-1)/2)*xSpacing, firstPinY+i*core1Travel];
function pinParity(i,j) = i%2;
pinPositions = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) pinPos(i,j)];
pinParity = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) (i%2)];

//keyWidth = 31;
keyWidth = xSpacing*pinCols+2;

core1Height = firstPinY + pinRows*core1Travel;
//core2Height = firstPinY + pinRows*core1Travel + 2*pinR;
core2Height = core1Height + core1Travel;
keyHeight = firstPinY + (pinRows-1)*core1Travel + pinR + 2;

core1Width = keyWidth + 2*wall;
core1Thickness = roundToLayerHeight(wafers * waferThickness + 1.5);
core1Y = 1.2;

core2Width = core1Width;
core2Thickness = roundToLayerHeight(wafers * waferThickness + 1.5);
core2Y = 1.2;//core1Y + core1Travel + C;

// pin positions
//pinPositions = [[0,35],[8,32],[-8,32], [0,18], [0,35-8]];
//pinPositions = [[0,35],[7,35],[-8,32], [3.5,35-6], [0,35-2*6]];
//pinPositions = [[0,35],[7,35],[-7,32], [0,35-2*core1Travel]];

//bitting = [0,1,2,2,1,2,0,0,1,0,1,2];
bitting = [0,1,0,2,1,2,0,0,1,0,1,2];

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
  *square(2*(pinR+C),true);
  //rotate(45)
  rotate(i*90) rotated(180) square(pinR+C);
  *intersection() {
    rotate(45+90*i) square([7+2*C,2+2*C],true);
    square(2*(3+C),true);
  }
  circle(pinR+C);
}
keyPinR = pinR;
module key_pin(C=0,i=0,h=0) {
  r1 = 0.8;
  z0 = keyThickness-wafers*waferThickness;
  z1 = min(wafers*waferThickness,keyPinR-r1) + z0;
  z2 = keyThickness + roundToLayerHeight(0.9);
  z3 = waferZ + h;
  translate_z(z0) cylinder(r1=r1+C,r2=keyPinR+C,h=z1-z0+eps);
  if (C>0) translate_z(z0) cylinder(r1=r1+C,r2=keyPinR+4+C,h=z1-z0+eps+4);
  translate_z(z1) cylinder(r=keyPinR+C,h=z2-z1);
  translate_z(z2) linear_extrude(z3-z2,convexity=2) key_pin_limiter_profile(C,i);
}
module key_pin_hole(i=0) {
  z2 = keyThickness + roundToLayerHeight(0.9) - 3*layerHeight;
  linear_extrude(z2+eps) circle(keyPinR+pinC);
  translate_z(z2) linear_extrude(lots,convexity=2) key_pin_limiter_profile(pinC,i);
}

module wafer() {
  cylinder(r=pinR,h=waferThickness);
}
module wafer_hole() {
  cylinder(r=pinR+pinC, h=lots);
}
module mid_pin(bit) {
  cylinder(r=pinR,h=core2Thickness - bit*waferThickness);
}
topPinThickness = roundToLayerHeight(2);
topPinR = pinR + 2.0;
topPinW = 2.0;
//topPinW = 1.7;
module top_pin_profile(C=0) {
  circle(pinR+C);
  rotate(90) square([2*(topPinR+C),topPinW+2*C],true);
}
module top_pin(bit) {
  //cylinder(r=2.5,h=2+bit*waferThickness);
  cylinder(r=pinR,h=bit*waferThickness+topPinThickness);
  translate_z(bit*waferThickness)
  linear_extrude(topPinThickness) {
    top_pin_profile(0);
  }
}
module top_pin_hole() {
  linear_extrude(lots) {
    //rotate(0) square(2*(pinR+C),true);
    top_pin_profile(pinC);
  }
}

module export_wafer() { wafer(); }
module export_key_pin() { rotate([180]) key_pin(); }
module export_mid_pin0() { mid_pin(0); }
module export_top_pin0() { rotate([180]) top_pin(0); }
module export_mid_pin1() { mid_pin(1); }
module export_top_pin1() { rotate([180]) top_pin(1); }
module export_mid_pin2() { mid_pin(2); }
module export_top_pin2() { rotate([180]) top_pin(2); }
module export_core_limit_pin() { rotate([0,90]) core_limit_pin(); }

//=============================================================================
// Key
//=============================================================================

module shear(d) {
  multmatrix([
    [1,0,d[0],0],
    [0,1,d[1],0],
    [0,0,1,0],
    [0,0,0,1]
  ]) children();
}

module key_profile() {
  chamfer = roundToLayerHeight(1.2);
  //polygon([[-keyWidth/2,0], [keyWidth/2,0], [keyWidth/2,keyThickness-chamfer], [keyWidth/2-chamfer,keyThickness], [-keyWidth/2,keyThickness]]);
  sym_polygon_x([[keyWidth/2,0], [keyWidth/2,keyThickness-chamfer], [keyWidth/2-chamfer,keyThickness]]);
}
module key_blank() {
  chamfer = roundToLayerHeight(1.2);
  round = 5;
  w = keyWidth;
  h = keyHeight + keyTravel + keyHandleHeight;
  minkowski() {
    translate([-(w-2*round)/2,round-(keyHandleHeight+keyTravel)])
      cube([w-2*round,h-2*round,keyThickness-chamfer]);
    cylinder(r1=round,r2=round-chamfer,h=chamfer);
  }
  *translate_y(-(keyHandleHeight+keyTravel))
  *intersection() {
    linear_extrude_y(keyHeight + keyTravel + keyHandleHeight) {
      key_profile();
    }
    linear_extrude(lots) {
      fillet(5) translate_x(-keyWidth/2) {
        square([keyWidth,keyHeight + keyTravel + keyHandleHeight]);
      }
    }
    translate_y(keyThickness-roundToLayerHeight(1.2))
    shear([0,-1,0])
    linear_extrude(keyThickness+1) {
      fillet(5) translate_x(-keyWidth/2) {
        square([keyWidth,keyHeight + keyTravel + keyHandleHeight]);
      }
    }
  }
}

module key_hole(CY = 0) {
  translate_z(-eps) minkowski() {
    key_blank();
    cylinder(r=C,h=CY + 2*eps);
  }
}

//lockPinPos = pinPos(pinRows-1,0);
lockPinPos = [-(pinCols-1)/2*xSpacing,keyHeight-1.2*2];
lockPinBit = wafers;
lockPinAngle = -45;
lockPinPos2 = pinPos(pinRows-1,pinCols-1);

module key() {
  difference() {
    key_blank();
    for (i=[0:len(pinPositions)-1]) {
      translate(pinPositions[i]) {
        translate_z(bitting[i] * waferThickness-2*eps) key_pin(C);
      }
    }
    // core retainer pin
    translate(lockPinPos) translate_z(lockPinBit * waferThickness-2*eps) key_pin(C);
  }
}

*!key();
module export_key() { key(); }

//=============================================================================
// Core
//=============================================================================

module connector_profile(y=0,hole=0) {
  w = 1.2;
  slope = 0.8;
  x = core1Width/2;
  h1 = roundToLayerHeight(1);
  h2 = roundToLayerHeight(w*slope);
  h3 = roundToLayerHeight(0.3);
  mirrored([1,0,0]) {
    polygon([
    [x+hole*eps,y+eps], [x-w-hole*C,y+eps], [x-w-hole*C,y-h1], [x+hole*eps-(1-hole)*h3/slope,y-h1-h2-hole*C+(1-hole)*h3], [x+hole*eps,y-h1-h2-hole*C+(1-hole)*h3]]);
  }
}

connectorY = 4;
connectorHeight = 20;

module core1() {
  difference() {
    *group() {
      translate([-core1Width/2,0,keyThickness])
        cube([core1Width,keyHeight+C,core1Thickness]);
      translate([-core1Width/2,0,keyThickness])
        cube([core1Width,core1Y,core1Thickness+core2Thickness]);
      translate([-keyWidth/2,keyHeight+C,0])
        cube([keyWidth,1.2,keyThickness + core1Thickness + core2Thickness]);
    }
    translate([-core1Width/2,core1Y,0])
      cube([core1Width,core1Height,keyThickness+core1Thickness]);
    key_hole();
    translate_y(core1Y+connectorY-C/2) linear_extrude_y(connectorHeight+core1Travel+C) {
      connector_profile(y=keyThickness+core1Thickness, hole=1);
    }
    // pins
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        //wafer_hole();
        key_pin_hole(pinParity[i]);
      }
    }
    // core retainer pin
    translate(lockPinPos) key_pin_hole(0);
    // limiter
    translate([0,-core1Travel,-coreLimitPinHeight])
    //translate_y(-core1Travel)
    minkowski() {
      core_limit_pin(true);
      cube([2*pinC,2*C,eps],true);
      *linear_extrude_x(2*C,eps) {
        polygon([[-C,0],[0,0],[coreLimitPinHeight,coreLimitPinHeight]]);
      }
    }
    *translate(lockPinPos2) translate_z(keyThickness+core1Thickness-1) key_pin(C);
  }
}
*!core1();

module core2() {
  difference() {
    group() {
      translate([-core2Width/2,core2Y,keyThickness+core1Thickness])
        cube([core2Width,core2Height,core2Thickness]);
      *translate([-15/2,keyHeight-3,keyThickness+core1Thickness])
        cube([15,3,core2Thickness+2]);
      translate_y(core1Y+connectorY+core1Travel) linear_extrude_y(connectorHeight) {
        connector_profile(y=keyThickness+core1Thickness);
      }
    }
    translate_y(core2Y+connectorY-C/2) linear_extrude_y(connectorHeight+core2Travel+C) {
      connector_profile(y=keyThickness+core1Thickness+core2Thickness, hole=1);
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        wafer_hole();
      }
    }
    translate(lockPinPos) wafer_hole();
    minkowski() {
      core_limit_pin();
      cube([2*pinC,2*pinC,lots],true);
    }
  }
}
*!core2();

coreLimitPinHeight = roundToLayerHeight(1.5);
module core_limit_pin(pointy = false) {
  if (1) {
    h = core2Thickness+coreLimitPinHeight;
    w = 2*pinR-1;
    translate(lockPinPos2)
    translate_y(core1Travel)
    translate_z(h/2 + keyThickness + core1Thickness)
    linear_extrude_x(2*pinR,true) {
      chamfer_rect(w,pointy ? h+(w-2*coreLimitPinHeight) : h,pointy ? w/2 : coreLimitPinHeight);
    }
  } else {
    h = roundToLayerHeight(core2Thickness+coreLimitPinHeight);
    wy = h;
    wx = 5;
    x = wx + 1.5 - eps;
    translate([core2Width/2-x, keyHeight-wy/2-1.2, keyThickness + core1Thickness + h/2])
    //linear_extrude_x(2) chamfer_rect(w,h,0.8);
    linear_extrude_x(wx) circle(h/2);
  }
}

module export_core1() { rotate([180]) core1(); }
module export_core2() { rotate([180]) core2(); }
module export_housing() { rotate([180]) housing(); }

//=============================================================================
// Housing
//=============================================================================

housingWidth = core2Width + 0*0.8;
housingHeight = keyHeight + core1Travel + core2Travel;
housingFloor = roundToLayerHeight(1.2);
housingDepth = housingFloor + keyThickness + core1Thickness + core2Thickness + 5;
module housing() {
  h = roundToLayerHeight(2 + wafers*waferThickness + 6);
  difference() {
    group() {
      *translate([-housingWidth/2, -1.2, -housingFloor])
        cube([housingWidth,housingHeight,housingDepth]);
      translate([-housingWidth/2, 0, 0])
        cube([housingWidth,1.2,core1Thickness+core2Thickness+5]);
      translate([-housingWidth/2, 0, keyThickness+core1Thickness+core2Thickness])
        cube([housingWidth,housingHeight,h]);
      translate_y(core2Y+connectorY+core2Travel) linear_extrude_y(connectorHeight) {
        connector_profile(y=keyThickness+core1Thickness+core2Thickness);
      }
    }
    key_hole();
    
    *translate([-(core1Width+2*C)/2, -C, keyThickness])
      cube([core1Width+2*C,keyHeight+keyTravel+2*C,core1Thickness+core2Thickness+1*layerHeight]);
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        top_pin_hole();
      }
    }
    translate (lockPinPos) rotate(lockPinAngle) top_pin_hole();
    minkowski() {
      core_limit_pin();
      cube([2*C,2*pinC,layerHeight],true);
    }
  }
}
*!housing();

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

module test() {
  assembly(min_x = 0);
  *assembly();
  *assembly(min_x = -6);
}
module assembly(min_x = undef) {
  pos = 1*core1Travel + 1*core2Travel;
  keyPos = pos;
  core1Pos = max(0,pos);
  core2Pos = max(0,pos-core1Travel);
  limitPinZ = max(0,min(coreLimitPinHeight,core1Pos-core1Travel+coreLimitPinHeight));
  keyZ = keyPos > 0 ? 1 : max(0,keyPos/5+1);
  
  core2 = true;
  housing = false;
  
  visualize_cutout(min_x = min_x) {
    translate_y(keyPos) key();
    translate_y(core1Pos) translate_z(layerHeight*1/6) core1();
    if (core2) translate_y(core2Pos+3*eps) translate_z(layerHeight*2/6) core2();
    translate_y(core2Pos) translate_z(layerHeight*2/6-limitPinZ) core_limit_pin();
    //if (housing) translate_z(-layerHeight*1/6) housing();
    if (housing) translate_z(layerHeight*4/6) housing();
    // pins
    translate_y(core1Pos) {
      for (i=[0:len(pinPositions)-1]) {
        translate (pinPositions[i]) {
          z = keyZ * bitting[i]*waferThickness;
          translate_z(z) key_pin(i=pinParity[i]);
        }
      }
      translate(lockPinPos) translate_z(keyZ * lockPinBit * waferThickness) key_pin(h=(wafers-lockPinBit)*waferThickness);
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        z0 = keyZ * bitting[i]*waferThickness + waferZ + layerHeight*1/6;
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
        z = keyZ * bitting[i]*waferThickness + keyThickness + core1Thickness + layerHeight*3/6;
        translate_y(core2Pos-0.1) translate_z(z) mid_pin(bitting[i]);
      }
      z = (keyZ-1) * waferThickness + keyThickness + core1Thickness + layerHeight*3/6;
      translate(lockPinPos) translate_y(core2Pos-0.1) translate_z(z) mid_pin(0);
    }
    for (i=[0:len(pinPositions)-1]) {
      translate (pinPositions[i]) {
        z = keyZ * bitting[i]*waferThickness - bitting[i]*waferThickness + keyThickness + core1Thickness + core2Thickness + layerHeight*4/6;
        translate_y(0+0.1) translate_z(z) top_pin(bitting[i]);
      }
      z = (keyZ) * lockPinBit * waferThickness + keyThickness + core1Thickness + layerHeight*3/6;
      translate(lockPinPos) translate_y(core2Pos-0.1) translate_z(z) rotate(lockPinAngle) top_pin(wafers);
    }
  }
}

test();