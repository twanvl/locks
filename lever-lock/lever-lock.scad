//=============================================================================
// Lever lock with warding
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

keyR = 2.5;
wardR = keyR + 1.29+C; // Note: 1.29 is 3 perimiters with 0.4mm nozzle at 0.15mm layer height according to prusa slicer
shroudR = wardR + 1.29+C;
//keyWidth = 3;
//keyWidth = 2.5;
keyWidth = roundToLayerHeight(keyR*sqrt(2));
keyHeight = 9.5;


//leverPivot = [15,15];
//leverPivot = [15,12];
//leverPivot = [12,18];
//leverPivot = [12,15];
leverPivot = [10,18];
//leverPivot = [10,13];
//leverPivot = [12,17];
//leverPivot = [-15,5];
leverPivotR = 2.5;

step = 0.9;
//stepA = -4.5; // step between cuts in terms of lever angle
stepA = -6; // step between cuts in terms of lever angle

//leverBottomY = keyHeight-4*step;
leverBottomY = shroudR;
//gateY = leverBottomY + 8;
gateHeight = 2.2;
gateY = leverPivot[1];
gateC = 0.2;
leverR = 27;
//leverTopY = max(gateY + gateHeight + 4, leverPivot[1]+leverPivotR+3);

maxBit = 4;
bitting = [0,1,2,3,4];
leverThickness = roundToLayerHeight(1.5);
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

// find the normal of a line at distance d from the origin that intersects p
// i.e. solve for a: polar(a,d) + polar(a+90,e) == p
function perp_angle(d,p) = acos(d/norm(p)) + atan2(p[1],p[0]);

echo(perp_angle(5,[-10,-5]), atan2(-5,-10), acos(5/norm([5,10])));

// angle that a rectangle ([0,0],p) will be rotated around p to touch point q
function rect_angle(p,q) = 0;

// where to cut the key
function key_cut(bit)=undef;

// angle of lever, when moved by key of given cut
function lever_angle(bit) =
  let (d=keyHeight - bit*step)
  let (x=leverPivot[0], y=leverPivot[1]-d, r=diagonal(x,y))
  let (y2=leverPivot[1]-leverBottomY)
  let (a=asin(y2/r), b=atan2(y,x))
  //let (a=asin(y2/r), b=atan(x/y))
  b-a+(x<0?180:0);

function lever_angle_simple(bit) = (maxBit-bit) * stepA;

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
    keyHeightMax = keyHeight + 1;
    //translate([-keyWidth/2,-keyHeight]) square([keyWidth,keyHeight]);
    translate([-keyWidth/2,-keyHeightMax]) square([keyWidth,keyHeightMax]);
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

module key_profile(bit, ward=true) {
  difference() {
    intersection() {
      keyway_profile(ward = ward);
      *circle(keyHeight - step*bit);
      *translate_x(-keyWidth/2) positive_x2d();
    }
    rotate(180) {
      rotated(range_to_list([-20:5:20]))
      rotate_around(leverPivot,lever_angle_simple(bit)) base_lever_profile();
    }
  }
}
shroudBit = 2;
module key() {
  linear_extrude(boltThickness+eps) {
    key_profile(shroudBit,ward=false);
  }
  if (shroudBit>=bitting[0]) translate_z(boltThickness) linear_extrude(spacerThickness+eps) {
    key_profile(shroudBit,ward=true);
  }
  for (i=[0:len(bitting)-1]) {
    extra_bot = (bitting[i] >= ((i==0)?shroudBit:bitting[i-1])) ? spacerThickness : 0;
    extra_top = ((i<len(bitting)-1) && bitting[i] >= bitting[i+1]) ? spacerThickness : 0;
    translate_z(i*leverStep+boltThickness+spacerThickness-extra_bot)
    linear_extrude(leverThickness+extra_top+extra_bot+eps) {
      key_profile(bitting[i]);
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
*!key();

//-----------------------------------------------------------------------------
// Levers
//-----------------------------------------------------------------------------

//topLeverAngle = 180-(maxBit*-stepA)+4;
//topLeverAngle = 180;
topLeverAngle = 90;
bottomLeverAngle = 10;
leverTopY = gateY+gateHeight/2+3;
module base_lever_profile() {
  x1 = leverPivot[0] - leverR;
  x2 = 10;
  hull() {
    //intersection() {
      
      //translate([x1,leverBottomY]) square([x2-x1,leverTopY-leverBottomY]);
    intersection() {
      rotate(bottomLeverAngle) translate([x1,leverBottomY]) square([x2-x1,lots]);
      translate_y(leverTopY) negative_y2d();
      //translate(leverPivot) circle(leverR);
      translate(leverPivot) wedge(a1=topLeverAngle,a2=270,r=leverR);
    }
    //translate([x1,leverBottomY]) square([x2-x1,leverTopY-leverBottomY]);
    //translate(leverPivot) translate(polar(leverR,-180)) square(eps,true);
    //translate(leverPivot) circle(leverR);
    *translate(leverPivot) wedge(-180-10,-180+10,r=leverR);
    
    translate(leverPivot) circle(leverPivotR+3);
  }
}
*!base_lever_profile();

falseGateTravel = 3;
falseGateTravel2 = 1;

//gateHeight2 = 0.89;
gateHeight2 = gateHeight - 0.8;

module lever_profile(bit) {
  difference() {
    //x1 = -10;
    x1 = leverPivot[0] - leverR;
    r1 = leverR;
    y1 = leverBottomY;
    y2 = leverTopY;
    group() {
      base_lever_profile();
      //translate([-20,leverBottomY]) square([40,15]);
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
          r2 = leverR + 0.8;
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
    *hull() for (bit=[0:maxBit]) {
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
      rotate_around(leverPivot, -lever_angle_simple(j)) {
        gate_profile(j == bit, shallowFalseGate = j != badBit);
      }
    }
  }
}
module gate_profile(trueGate=true,shallowFalseGate=false) {
  x1 = leverPivot[0] - leverR;
  if (trueGate) {
    translate([x1,gateY-gateHeight/2-gateC]) square([boltTravel+gateC,gateHeight+2*gateC]);
    translate([x1+boltTravel-boltWidth/2,gateY+gateHeight-gateHeight2]) chamfer_rect(boltWidth+2*gateC,gateHeight+2*gateC,0.1);
  } else if (!shallowFalseGate) {
    translate([x1,gateY]) chamfer_rect(falseGateTravel,gateHeight+2*gateC,0.5);
  } else {
    w = gateHeight*0.9;
    translate([x1,gateY]) chamfer_rect(falseGateTravel2,w+2*gateC,0.5);
  }
}

module lever(bit=0, pos=0) {
  rotate_around(leverPivot,pos)
  linear_extrude(leverThickness) lever_profile(bit);
}

module spacer_profile(ward = false) {
  x1 = leverPivot[0] - leverR;
  x2 = 10;
  y1 = ward ? 0 : leverBottomY;
  y2 = leverTopY;
  difference() {
    union() {
      base_lever_profile();
      rotate_around(leverPivot,lever_angle_simple(0)) base_lever_profile();
      if (ward) {
        rotate(90) wedge(220,center=true,r=keyHeight);
      }
    }
    gate_profile();
    *hull() {
      intersection() {
        translate([x1,y1]) square([x2-x1,y2-y1]);
        translate(leverPivot) circle(leverR);
      }
      rotate_around(leverPivot,lever_angle(0))
      intersection() {
        translate([x1,y1]) square([x2-x1,y2-y1]);
        translate(leverPivot) circle(leverR);
      }
      translate(leverPivot) circle(leverPivotR+3);
    }
    translate(leverPivot) circle(leverPivotR+C);
    if (ward) {
      circle(r=shroudR+C);
    } else {
      circle(r=keyHeight+C);
    }
  }
}
module warded_spacer() {
  linear_extrude(leverThickness) spacer_profile(ward=true);
}
module spacer() {
  linear_extrude(spacerThickness) spacer_profile();
}
*!spacer();
*!warded_spacer();

//leverBottomY=keyR+1.2;
//leverBottomY=0;
//echo(lever_angle(5));

//-----------------------------------------------------------------------------
// Bolt
//-----------------------------------------------------------------------------

boltTravel = 10;
//boltTravel = 6;
boltWidth = 6;
boltThickness = roundToLayerHeight(2);
//boltBottomY = keyHeight-1;
boltBottomY = keyHeight-2;
boltTopY = boltBottomY+20;
boltLeftX = leverPivot[0] - leverR - 2*boltTravel - 1;

// if actuator moves in a circle of radius r around [0,0],
// and starts interacting if y>=boltBottomY, it will move bolt by
// 2*sqrt(r^2-boltBottomY^2)
actuatorCutoffR = boltBottomY-0.0;
actuatorR = diagonal(actuatorCutoffR,boltTravel/2);
actuatorPinR = 2;
actuatorPinR2 = 3;

function bolt_pos(a) =
  cos(a)*actuatorR < boltBottomY-2 ?
    (-a<0 ? 0 : boltTravel)
  :
  let (pinH = cos(a)*actuatorR - boltBottomY)
  let (pinW = pinH > 0 ? actuatorPinR : side_given_diagonal(actuatorPinR,pinH))
  let (slotW = lerp(actuatorPinR,actuatorPinR2,1-max(0,min(1,pinH/(actuatorR-boltBottomY)))))
  let (x = -sin(a) * actuatorR + boltTravel/2 - sign(a)*(pinW-slotW))
  max(0,min(boltTravel,x));

boltThickness2 = boltThickness + len(bitting)*leverStep;

boltLimiterPos = [leverPivot[0] - leverR + 2.5, gateY + 4];
boltLimiterR = 2;
boltRightX = leverPivot[0]-boltTravel+leverPivotR-C;

module bolt_base_profile(holes = true) {
  x1 = leverPivot[0] - leverR - 0.5;
  x2 = x1-10;
  //boltRightX = leverPivot[0]-boltTravel-leverPivotR-C;
  difference() {
    translate([boltLeftX,boltBottomY]) square([boltRightX-boltLeftX,boltTopY-boltBottomY]);
    //translate([-boltTravel/2,boltBottomY]) chamfer_rect(5,5,2);
    //translate_x(-boltTravel/2) {
    // don't exceed lever profile
    translate_x(-boltTravel) difference() {
      translate_x(x1+leverR/2) positive_x2d();
      base_lever_profile();
      rotate_around(leverPivot,lever_angle_simple(0)) base_lever_profile();
    }
    if (holes) {
      // lever pivot
      hull() {
        translate(leverPivot) circle(leverPivotR+C);
        translate(leverPivot-[boltTravel,0]) circle(r=leverPivotR+C);
      }
      // limiter pin
      hull() {
        translate(boltLimiterPos) circle(boltLimiterR+C);
        translate(boltLimiterPos-[boltTravel,0]) circle(boltLimiterR+C);
      }
      // actuator
      offset(C)
      hull() {
        for (a=[-40:2:40]) {
        //for (a=[0]) {
          //translate_x(actuatorR*sin(a))
          translate_x(-bolt_pos(a)) rotate(a) rotate(180) actuator_profile();
        }
        *translate([-boltTravel/2,0]) rotate(180)actuator_profile();
        *translate([-boltTravel/2,boltBottomY]) square([2*actuatorPinR2,eps],true);
        *hull() {
          //translate_y(boltBottomY+1) circle(2+C);
          offset(1.3+C) rotate(180) key_profile(shroudBit,ward=false);
          translate_y(actuatorR) circle(2+C);
          //circle(r=shroudR+C);
        }
      }
    }
  }
}
*!bolt_base_profile();

module bolt() {
  linear_extrude(boltThickness) {
    bolt_base_profile();
  }
  linear_extrude(boltThickness2) {
    difference() {
      translate([boltLeftX,boltBottomY]) square([-boltLeftX,boltTopY-boltBottomY]);
      translate(leverPivot-[boltTravel,0]) circle(r=leverR+0.5);
    }
  }
  linear_extrude(boltThickness + len(bitting)*leverStep) {
    x1 = leverPivot[0] - leverR;
    translate([x1-boltWidth/2,gateY]) chamfer_rect(boltWidth,gateHeight,0.5,r_tl=0.2);
    translate([x1-boltTravel/2-1,gateY-(gateHeight-gateHeight2)/2]) chamfer_rect(boltTravel,gateHeight2,0);
  }
}
*!bolt();

module actuator_profile() {
  hull() {
    offset(0) key_profile(shroudBit,ward=false);
    translate_y(-actuatorR) circle(actuatorPinR);
    translate([0,-boltBottomY+1]) square([2*actuatorPinR2,eps],true);
  }
}

// shroud + bolt actuator
module shroud() {
  linear_extrude(boltThickness) {
    difference() {
      *group() {
        circle(r=keyHeight);
        translate_y(-keyHeight) square(4,true);
      }
      group() {
        circle(r=boltBottomY-C);
        actuator_profile();
        *rotated([0]) hull() {
          offset(0) key_profile(shroudBit,ward=false);
          //translate_y(-(boltBottomY+1)) circle(2);
          translate_y(-actuatorR) circle(2);
        }
      }
      *offset(C) keyway_profile();
      offset(C) key_profile(shroudBit,ward=false);
    }
  }
  linear_extrude(boltThickness + len(bitting)*leverStep) {
    difference() {
      //circle(r=wardR+C+1.2);
      hull() {
        circle(r=shroudR);
        // flat top to snap shroud using levers
        r1 = 1.5;
        x = 4;
        rotate(bottomLeverAngle) {
          translate([x,shroudR-r1]) circle(r=r1);
          translate([-x,shroudR-r1]) circle(r=r1);
        }
      }
      circle(r=wardR+C);
      translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
    }
  }
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housingThickness = roundToLayerHeight(1.5);
housingWall = 1.29;
housingChamfer = 0.45;

echo(leverPivot+polar(topLeverAngle,leverR));

module housing_outer_profile() {
  rounding = 5;
  x1 = boltLeftX + boltTravel;
  x2 = max(keyHeight, leverPivot[0]+leverPivotR+3) + C + housingWall;
  y1 = -keyHeight - C - housingWall;
  y2 = (leverPivot+polar(topLeverAngle + maxBit*stepA,leverR))[1] + C + housingWall;
  echo(x1,x2,y1,y2);
  translate([(x1+x2)/2,(y1+y2)/2])
  rounded_rect(x2-x1,y2-y1,rounding);
}
module pivot_pin() {
  linear_extrude(boltThickness + len(bitting)*leverStep + 4*layerHeight) translate(leverPivot) circle(leverPivotR);
}
module housing() {
  difference() {
    translate_z(-housingThickness)
    //linear_extrude(housingThickness + boltThickness + len(bitting)*leverStep + layerHeight) {
    linear_extrude_cone_chamfer(housingThickness + boltThickness + len(bitting)*leverStep + layerHeight, housingChamfer, 0) {
      housing_outer_profile();
    }
    linear_extrude(boltThickness + len(bitting)*leverStep + layerHeight + 2*eps, convexity=2) {
      circle(r = keyHeight+C);
      *translate([-lots,boltBottomY-C]) square([lots+boltRightX+boltTravel+C,boltTopY-boltBottomY+2*C]);
      translate_x(boltTravel) offset(C) bolt_base_profile(holes=false);
    }
    translate_z(boltThickness)
    linear_extrude(len(bitting)*leverStep + layerHeight + 2*eps) {
      offset(C) base_lever_profile();
      rotate_around(leverPivot,stepA*maxBit) {
        offset(C) base_lever_profile();
      }
    }
    lipThickness = roundToLayerHeight(1);
    translate_z(boltThickness + len(bitting)*leverStep + layerHeight - lipThickness)
    linear_extrude(lipThickness+2*eps) {
      offset(-housingWall) housing_outer_profile();
    }
  }
  linear_extrude(boltThickness) {
    translate(boltLimiterPos) circle(boltLimiterR);
  }
  pivot_pin();
}
*!housing();

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

keyAngle = -180 - 50;
//keyAngle = 0;
leverPos = 0;
boltPos = bolt_pos(keyAngle+180);

rotate(keyAngle) key();

color("LightYellow") housing();

color("green") translate_x(boltPos) bolt();

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
rotate(keyAngle)
color("salmon") shroud();

function lever_color(i) = [1-0.0*i,i*0.1,i*0.1];

for (i=[0:len(bitting)-1]) {
  translate_z(boltThickness + spacerThickness + i*leverStep)
  color(lever_color(i)) lever(bitting[i], pos=leverPos*lever_angle_simple(bitting[i]));
}

*for (i=[0:len(bitting)-1]) {
  translate_z(boltThickness + i*leverStep+20)
  color("lightblue") {
    if (i==0) warded_spacer(); else spacer();
  }
}
