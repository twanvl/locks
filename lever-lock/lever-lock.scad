//=============================================================================
// Lever lock with warding
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

keyR = 2.5;
wardR = keyR + 1.2+C;
//keyWidth = 3;
//keyWidth = 2.5;
keyWidth = keyR*sqrt(2);
keyHeight = 9;

//leverPivot = [15,15];
//leverPivot = [15,12];
//leverPivot = [12,18];
leverPivot = [12,15];
//leverPivot = [10,13];
//leverPivot = [12,17];
//leverPivot = [-15,5];
leverPivotR = 2;

step = 0.9;

maxBit = 4;
bitting = [0,1,2,3,4];
leverThickness = roundToLayerHeight(2);
spacerThickness = 2*layerHeight;
leverStep = leverThickness + spacerThickness;

useFingers = false;

//-----------------------------------------------------------------------------
// Utilities
//-----------------------------------------------------------------------------

module rotate_around(pos,angle) {
  translate(pos)
  rotate(angle)
  translate(-pos)
  children();
}

module regular_polygon(r, sides=undef) {
  if (sides == undef) {
    circle(r);
  } else {
    rotate(180/sides) circle(r/cos(180/sides), $fn=sides);
  }
}

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module keyway_profile(ward = false, printFlat = false) {
  sides = printFlat ? 8 : undef;
  intersection() {
    regular_polygon(keyR,sides);
    if (0) {
      square([keyWidth,lots],true);
    } else {
      translate_x(-keyWidth/2) positive_x2d();
    }
  }
  difference() {
    translate([-keyWidth/2,-keyHeight]) square([keyWidth,keyHeight]);
    //translate([-(keyR-keyWidth)/2,-keyHeight])
    //translate([-keyWidth/2-(2*keyR-keyWidth)/2,-keyHeight]) square([keyWidth,keyHeight]);
    *hull() {
      regular_polygon(keyR,sides);
      translate([0,-keyHeight]) square([keyWidth,eps],true);
    }
    if (ward) circle(r=wardR+C);
  }
}
*!keyway_profile();

module key() {
  for (i=[0:len(bitting)]) {
    translate_z(i*leverStep)
    linear_extrude(leverThickness+eps) {
      intersection() {
        keyway_profile(ward = i>0);
        circle(keyHeight - step*bitting[i]);
        translate_x(-keyWidth/2) positive_x2d();
      }
    }
  }
  linear_extrude(30) {
    intersection() {
      regular_polygon(keyR);
      //square([keyWidth,lots],true);
      translate_x(-keyWidth/2) positive_x2d();
    }
  }
}

//-----------------------------------------------------------------------------
// Levers
//-----------------------------------------------------------------------------

module shroud() {
}

leverBottomY=keyHeight-4*step;
gateY = leverBottomY + 9;
gateHeight = 2.5;
gateC = 0.2;
leverR = 25;

// angle of lever, when moved by key of given cut
function lever_angle(bit) =
  let (d=keyHeight - bit*step)
  let (x=leverPivot[0], y=leverPivot[1]-d, r=diagonal(x,y))
  let (y2=leverPivot[1]-leverBottomY)
  let (a=asin(y2/r), b=atan2(y,x))
  //let (a=asin(y2/r), b=atan(x/y))
  b-a+(x<0?180:0);


module lever_profile(bit) {
  difference() {
    //x1 = -10;
    x1 = leverPivot[0] - leverR;
    x2 = 10;
    r1 = leverR;
    y1 = leverBottomY;
    y2 = max(gateY + gateHeight + 4, leverPivot[1]+leverPivotR+3);
    //yGate = y2 - 3*0.8-3;
    yGate = gateY;
    group() {
      //translate([-20,leverBottomY]) square([40,15]);
      hull() {
        intersection() {
          translate([x1,y1]) square([x2-x1,y2-y1]);
          translate(leverPivot) circle(r1);
        }
        translate(leverPivot) circle(leverPivotR+3);
      }
      *intersection() {
        translate([x1,leverBottomY]) square([30,y2-leverBottomY]);
        translate(leverPivot) circle(r1);
      }
      *translate(leverPivot) hull() {
        wedge(180-30,180+10,center=true,r=r1);
        circle(leverPivotR+3);
      }
      
      if (useFingers) {
        fingerW = 1;
        fingerH = 0.8;
        *translate([x1-fingerW,y2-fingerH]) square([fingerW+20,fingerH]);
        *translate([x1-fingerW,y2-3*fingerH]) square([fingerW+20,fingerH]);
        translate(leverPivot) {
          a0 = 180-30;
          r2 = r1 + 0.8;
          da=(lever_angle(4)-lever_angle(3))/2;
          wedge(a0,a0+da,r=r2);
          wedge(a0+2*da,a0+3*da,r=r2);
          wedge(a0+4*da,a0+5*da,r=r2);
        }
      }
    }
    translate(leverPivot) circle(leverPivotR+C);
    *translate([keyWidth+1,leverBottomY]) square([lots,5]);
    if (useFingers)
    intersection() {
      hull() for (bit=[0:maxBit]) {
        rotate_around(leverPivot,-lever_angle(bit))
        //circle(r=keyHeight+C+1.2+C);
        difference() {
          wedge(a1=0,a2=80+1,r=keyHeight+C+1.2+C);
          wedge(a1=0,a2=80+1,r=keyHeight);
          translate_x(keyWidth/2) negative_x2d();
        }
      }
      //translate([keyWidth+1,leverBottomY]) square([lots,lots]);
      //translate([keyWidth+1,leverBottomY]) rotate(10) square([lots,lots]);
    }
    //bottomR=20;
    //translate([2,leverBottomY-bottomR]) circle(r=bottomR);
    //bottomR=10;
    hull() for (bit=[0:maxBit]) {
      bottomR=keyHeight;
      rotate_around(leverPivot,-lever_angle(bit))
      //translate([0,keyHeight+C-bottomR]) circle(r=bottomR-bit*step);
      translate([0,keyHeight-bottomR]) circle(r=bottomR-bit*step);
    }
    // gates
    //badBit = (bit+3) % (maxBit+1);
    badBits = [4,3,0,0,1];
    //badBit = bit<maxBit/2 ? maxBit : 0;
    badBit = badBits[bit];
    for (j=[0:maxBit]) {
      rotate_around(leverPivot, -lever_angle(j)) {
        if (j == bit) {
          translate([x1,yGate-gateC]) square([boltTravel+C,gateHeight+2*gateC]);
          translate([x1+boltTravel-boltWidth-0.5,yGate-gateC]) square([boltWidth+2*0.5,gateHeight+1.5+2*gateC]);
        } else if (j == badBit) {
          translate([0,(gateHeight+2*gateC)/2])
          translate([x1,yGate-gateC]) chamfer_rect(4+2*C,gateHeight+2*gateC,0.4);
        } else if (abs(j-bit)>1 && abs(j-badBit)>1) {
          translate([0,(0.5+2*gateC)/2])
          translate([x1,yGate-gateC]) chamfer_rect(1+C,0.5+2*gateC,0.25);
        }
      }
    }
  }
}

module lever(bit=0, pos=0) {
  rotate_around(leverPivot,pos)
  linear_extrude(leverThickness) lever_profile(bit);
}

//leverBottomY=keyR+1.2;
//leverBottomY=0;
echo(lever_angle(5));

//-----------------------------------------------------------------------------
// Bolt
//-----------------------------------------------------------------------------

boltTravel = 10;
boltWidth = 6;
boltThickness = roundToLayerHeight(2);

module bolt(pos = 1) {
  x1 = leverPivot[0] - leverR;
  linear_extrude(boltThickness) {
    translate([x1,4])
    square(10);
  }
  linear_extrude(10) {
    translate([-boltWidth/2,gateHeight/2])
    translate([x1 + pos*boltTravel,gateY]) chamfer_rect(boltWidth,gateHeight,0.5);
  }
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

rotate(-180) key();
*rotate(-220) key();
*rotate(-120) key();
color("blue") linear_extrude(10) translate(leverPivot) circle(leverPivotR);
//color("red") lever(pos=0);

color("green") bolt();

*color("yellow") linear_extrude(10) {
  difference() {
    intersection() {
      difference() {
        wedge(a1=0,a2=80,r=keyHeight+C+1.2);
        wedge(a1=0,a2=80,r=keyHeight+C);
      }
      *circle(r=keyHeight+C+1.2);
      *translate([keyWidth+1,leverBottomY]) square([lots,lots]);
    }
    circle(r=keyHeight+C);
  }
}

// warding
color("cyan") translate_z(leverThickness+layerHeight) linear_extrude(10) {
  difference() {
    circle(r=wardR);
    circle(r=keyR+C);
    translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
  }
}

// shroud
rotate(-180)
color("salmon") {
  linear_extrude(leverThickness) {
    difference() {
      circle(r=keyHeight);
      offset(C) keyway_profile();
    }
  }
  linear_extrude(10) {
    difference() {
      //circle(r=wardR+C+1.2);
      circle(r=keyHeight-maxBit*step);
      circle(r=wardR+C);
      translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
    }
  }
}

for (i=[0:len(bitting)-1]) {
//for (i=[4]) {
//for (i=[4]) {
  translate_z(boltThickness + i*leverStep)
  color("red") lever(bitting[i], pos=lever_angle(bitting[i]));
}
