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
keyHandleHeight = 15;
twoSided = false;
keyThickness = twoSided ? roundToLayerHeight(waferThickness * 3) : roundToLayerHeight(waferThickness * 2);

//core1Travel = 5.5;
core1Travel = 4.5;
core2Travel = 5;
keyTravel = core1Travel + core2Travel; // in y direction

pinR = 2.5;
pinH = 4;
pinW = roundToLayerHeight(1.8);
//pinR = 2.25;
firstPinY = keyTravel + wall;
//firstPinY = core1Travel + pinH/2 + 0.5 + wall;
pinRows = 4;
pinCols = 3;
xSpacing = pinW+2*pinC+1.2;
function pinPos(i,j) = [(j-(pinCols-1)/2)*xSpacing, firstPinY+i*core1Travel];
function pinParity(i,j) = i%2;
pinPositions = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) pinPos(i,j)];
pinParity = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 0) (i%2)];

pinPositions2 = [for (i=[0:pinRows-1]) for (j=[0:pinCols-1]) if ((i+j)%2 == 1) pinPos(i,j)];

//keyWidth = 31;
//keyWidth = xSpacing*pinCols+2;
keyWidth = xSpacing*pinCols+1;
echo(keyWidth);

core1Height = firstPinY + pinRows*core1Travel + 1.2;
//core2Height = firstPinY + pinRows*core1Travel + 2*pinR;
core2Height = core1Height + core1Travel;
keyHeight = firstPinY + (pinRows-1)*core1Travel + pinR + 2;

core1Width = keyWidth + 2*wall;
core1Thickness = roundToLayerHeight(wafers * waferThickness + 1.5 + 0.5);
core1Y = 0;

core2Width = core1Width;
core2Thickness = roundToLayerHeight(wafers * waferThickness + 1.5);
core2Y = core1Y;//core1Y + core1Travel + C;

// pin positions
//pinPositions = [[0,35],[8,32],[-8,32], [0,18], [0,35-8]];
//pinPositions = [[0,35],[7,35],[-8,32], [3.5,35-6], [0,35-2*6]];
//pinPositions = [[0,35],[7,35],[-7,32], [0,35-2*core1Travel]];

//bitting = [0,1,2,2,1,2,0,0,1,0,1,2];
//bitting = [0,1,0,2,1,2,0,0,1,0,1,2];
bitting = [0,1,0,2,1,1,0,0,1,0,1,2];

//=============================================================================
// Derived parameters
//=============================================================================

pinTravel = wafers * waferThickness; // in z direction

//=============================================================================
// Pins
//=============================================================================

waferShape = "rectangle";

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
keyPinLip = roundToLayerHeight(0.6);
keyPinLipH = pinH - 1.6;
keyPinH = pinH;
keyPinH1 = pinH;
//keyPinLip = pinH;
module key_pin(CX=0,CY=0,i=0,h=0,variant=false) {
  r1 = 0.8;
  z0 = keyThickness-wafers*waferThickness;
  z1 = min(wafers*waferThickness,keyPinR-r1) + z0;
  z2 = keyThickness + roundToLayerHeight(0.9);
  z3 = waferZ + h;
  if (waferShape == "circle") {
    translate_z(z0) cylinder(r1=r1+C,r2=keyPinR+C,h=z1-z0+eps);
    if (C>0) translate_z(z0) cylinder(r1=r1+C,r2=keyPinR+4+C,h=z1-z0+eps+4);
    translate_z(z1) cylinder(r=keyPinR+C,h=z2-z1);
    translate_z(z2) linear_extrude(z3-z2,convexity=2) key_pin_limiter_profile(CY,i);
  } else {
    r1 = 0.6;
    z1 = min(wafers*waferThickness,keyPinH1/2-r1) + z0;
    dc = CY>0 ? 2 : 0;
    w = variant ? pinW-keyPinLip : pinW;
    lh = variant ? pinH : keyPinLipH;
    translate_x(variant ? keyPinLip/2 : 0) {
      linear_extrude_x(w+2*CX,true) {
        sym_polygon_x([[r1+CY,z0],[keyPinH1/2+CY+dc,z1+dc],[keyPinH1/2+CY+dc,z2+dc],[keyPinH/2+CY+dc,z2+dc],[keyPinH/2+CY+dc,z3+dc]]);
      }
      translate_z(z2) linear_extrude(z3-z2) translate_x(-keyPinLip-eps) square([w+2*CX,lh+2*CY],true);
    }
  }
}
module key_pin_hole(i=0,variant=false) {
  z2 = keyThickness + roundToLayerHeight(0.9) - 3*layerHeight;
  if (waferShape == "circle") {
    linear_extrude(z2+eps) circle(keyPinR+pinC);
    translate_z(z2) linear_extrude(lots,convexity=2) key_pin_limiter_profile(pinC,i);
  } else {
    w = variant ? pinW-keyPinLip : pinW;
    lh = variant ? pinH : keyPinLipH;
    translate_x(variant ? keyPinLip/2 : 0) {
      linear_extrude(lots) square([w+2*pinC,keyPinH1+2*C],true);
      translate_z(z2) linear_extrude(lots) square([w+2*pinC,keyPinH+2*C],true);
      translate_z(z2) linear_extrude(lots) translate_x(-keyPinLip-eps) square([w+2*C,lh+2*C],true);
    }
  }
}

module wafer(CX=0,CY=0,h=waferThickness) {
  if (waferShape == "circle") {
    cylinder(r=pinR+C,h=h);
  } else {
    linear_extrude(h) {
      square([pinW+2*CX,pinH+2*CY],true);
    }
  }
}
module wafer_hole() {
  wafer(CX=pinC,CY=C,h=lots);
}
module mid_pin(bit) {
  wafer(h=core2Thickness - bit*waferThickness);
}

topPinThickness = roundToLayerHeight(1.5) + 1*waferThickness; // note: same as core2 thickness + some wafers so there are fewer different pins
topPinH = pinH + 3.0;
topPinW = pinW;
//topPinW = 1.7;
module top_pin_profile(CX=0,CY=0,dh=0) {
  if (waferShape == "circle") {
    circle(pinR+C);
    rotate(90) square([topPinH+2*CX,topPinW+2*CY],true);
  } else {
    //translate_y(dh*(topPinH-pinH)/2) square([topPinW+2*C,topPinH+2*C],true);
    square([pinW+2*CX,pinH+2*CY],true);
  }
}
module top_pin(bit,dh=0) {
  //cylinder(r=2.5,h=2+bit*waferThickness);
  //cylinder(r=pinR,h=bit*waferThickness+topPinThickness);
  wafer(CX=0,CY=0,h=bit*waferThickness+topPinThickness);
  translate_z(bit*waferThickness)
  linear_extrude(topPinThickness) {
    top_pin_profile(dh=dh);
  }
}
module top_pin_hole(dh=0) {
  linear_extrude(lots) {
    //rotate(0) square(2*(pinR+C),true);
    top_pin_profile(CX=pinC,CY=C,dh=dh);
  }
  translate_z(topPinThickness - 3*layerHeight) {
    linear_extrude(lots) {
      translate_y(dh*(topPinH-pinH)/2) square([topPinW+2*pinC,topPinH+2*pinC],true);
    }
  }
}

module rotate_wafer() {
  if (waferShape == "circle") {
    children();
  } else {
    rotate([0,90]) children();
  }
}

module export_wafer() { rotate_wafer() wafer(); }
module export_key_pin() { rotate_wafer() rotate([180]) key_pin(); }
module export_key_pin_variant() { rotate_wafer() rotate([180]) key_pin(variant=true); }
module export_mid_pin0() { rotate_wafer() rotate([180]) mid_pin(0); }
module export_top_pin0() { rotate_wafer() rotate([180]) top_pin(0); }
module export_mid_pin1() { rotate_wafer() rotate([180]) mid_pin(1); }
module export_top_pin1() { rotate_wafer() rotate([180]) top_pin(1); }
module export_mid_pin2() { rotate_wafer() rotate([180]) mid_pin(2); }
module export_top_pin2() { rotate_wafer() rotate([180]) top_pin(2); }
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
module key_blank(C=0) {
  //chamfer = roundToLayerHeight(1.2);
  chamfer = roundToLayerHeight(1.5);
  //round = 5;
  round = 3;
  w = keyWidth;
  h = keyHeight + keyTravel + keyHandleHeight;
  difference() {
    intersection() {
      minkowski() {
        difference() {
          translate([-(w-2*round)/2,round-(keyHandleHeight+keyTravel)])
            cube([w-2*round,h-2*round,keyThickness-chamfer]);
          *translate([0,-keyHandleHeight/2])
            cube([2*round+2,2*round-2,lots],true);
        }
        //cylinder(r1=round,r2=round-chamfer,h=chamfer);
        group() {
          h1=roundToLayerHeight(chamfer/2);
          cylinder(r1=round-h1,r2=round,h=h1);
          translate_z(h1) cylinder(r1=round,r2=round-h1,h=h1);
        }
      }
      shear([0,-1.0,0])
      minkowski() {
        difference() {
          translate([-(w-2*round)/2,round-(keyHandleHeight+keyTravel)])
            cube([w-2*round,h-2*round,keyThickness-chamfer]);
        }
        cylinder(r=round,h=chamfer);
      }
    }
    translate_y(-C) linear_extrude_y(lots) {
      for (i=[0:pinCols-2]) {
        h = 4*layerHeight-C;
        w = xSpacing-pinW-C;
        translate([(i-(pinCols-2)/2)*xSpacing-w/2,keyThickness-h]) square([w,h+eps]);
      }
    }
    minkowski() {
      translate([0,-keyTravel-keyHandleHeight+round+3,(keyThickness-chamfer)/2+eps])
        cube([2,2,keyThickness-chamfer+2*eps],true);
      group() {
        cylinder(r=round-1,h=lots,center=true);
        //h1=roundToLayerHeight(chamfer/2);
        //cylinder(r2=round-h1,r1=round,h=h1);
        //translate_z(h1) cylinder(r2=round,r1=round-h1,h=h1);
      }
    }
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
    key_blank(C=layerHeight);
    cylinder(r=C,h=CY + 2*eps);
  }
}

//lockPinPos = pinPos(pinRows-1,0);
lockPinPos = (waferShape == "circle") ? [-(pinCols-1)/2*xSpacing,keyHeight-1.2*2] : [-(pinCols-1)/2*xSpacing-0.45, keyHeight-keyPinH1/2+C-pinC];
lockPinBit = wafers;
lockPinAngle = (waferShape == "circle") ? -45 : 0;
lockPinPos2 = pinPos(pinRows-1,pinCols-1) + [0,0.2];

module key() {
  keyC = 4*C;
  difference() {
    key_blank();
    for (i=[0:len(pinPositions)-1]) {
      translate(pinPositions[i]) {
        translate_z(bitting[i] * waferThickness-1*eps) key_pin(CX=pinC,CY=0.6);
      }
    }
    // core retainer pin
    *translate(lockPinPos) translate_z(lockPinBit * waferThickness-2*eps) key_pin(CX=0.5,CY=1);
    // bottom pins?
    if (twoSided)
    for (i=[0:len(pinPositions)-1]) {
      j = len(pinPositions) + i;
      translate(pinPositions2[i]) {
        translate_z(keyThickness)
        mirror([0,0,1])
        translate_z(bitting[j] * waferThickness-1*eps)
        key_pin(CX=pinC,CY=0.6);
      }
    }
  }
}

!key();
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
        key_pin_hole(pinParity[i],variant=pinPositions[i][0]<0);
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
module export_core1_test() {
  rotate([180]) intersection() {
    core1();
    translate_y(firstPinY) cube([lots,pinH+2*wall,lots],true);
  }
}
*!export_core1_test();

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
      cube([2*pinC,2*C,lots],true);
    }
  }
}
*!core2();

coreLimitPinHeight = roundToLayerHeight(1.2);
//coreLimitPinHeight = roundToLayerHeight(pinH-core2Thickness);
module core_limit_pin(pointy = false) {
  if (1) {
    h = core2Thickness+coreLimitPinHeight;
    //w = min(pinH,h);
    w = h;
    translate(lockPinPos2)
    translate_y(core1Travel)
    translate_z(h/2 + keyThickness + core1Thickness)
    linear_extrude_x(pinW,true) {
      if (0) {
        chamfer = h / (1+sqrt(2)) / sqrt(2);
        chamfer_rect(w,pointy ? h+(w-2*coreLimitPinHeight) : h,pointy ? w/2 : chamfer);
      } else {
        circle(w/2);
        if (pointy) {
          rotate(180+45) square(w/2);
        }
      }
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
housingHeight = core2Y + core2Height + core2Travel;
housingFloor = roundToLayerHeight(1.2);
housingDepth = housingFloor + keyThickness + core1Thickness + core2Thickness + 5;
module housing() {
  //h = roundToLayerHeight(2 + wafers*waferThickness + 6);
  h = roundToLayerHeight(2 + wafers*waferThickness + 2);
  difference() {
    group() {
      *translate([-housingWidth/2, -1.2, -housingFloor])
        cube([housingWidth,housingHeight,housingDepth]);
      if (core1Y>0)
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
        translate_z(keyThickness+core1Thickness+core2Thickness-eps) top_pin_hole();
      }
    }
    translate (lockPinPos) translate_z(keyThickness+core1Thickness+core2Thickness-eps)  rotate(lockPinAngle) top_pin_hole(dh=1);
    minkowski() {
      core_limit_pin();
      cube([2*pinC,1*C,layerHeight],true);
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
  *assembly(min_x = 0);
  *assembly();
  *assembly(min_x = -xSpacing);
  assembly(min_x = xSpacing);
  //assembly();
  *translate_z(0.9) mirror([0,0,1]) assembly();
}
module assembly(min_x = undef) {
  pos = 0*core1Travel + 0*core2Travel;
  keyPos = pos;
  core1Pos = max(0,pos);
  core2Pos = max(0,pos-core1Travel);
  limitPinZ = max(0,min(coreLimitPinHeight,core1Pos-core1Travel+coreLimitPinHeight));
  keyZ = keyPos > 0 ? 1 : max(0,keyPos/5+1);
  
  core2 = true;
  housing = true;
  
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
      z = (keyZ * lockPinBit - lockPinBit) * waferThickness + keyThickness + core1Thickness + core2Thickness + layerHeight*4/6;
      translate(lockPinPos) translate_y(core2Pos-0.1) translate_z(z) rotate(lockPinAngle) top_pin(wafers);
    }
  }
}

test();