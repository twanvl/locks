//=============================================================================
// Lever lock with warding
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

keyR = 2.5; // central pin of the key
wardR = keyR + 1.29+C; // Note: 1.29 is 3 perimiters with 0.4mm nozzle at 0.15mm layer height according to prusa slicer
curtainR = wardR + 1.29+C;
//keyWidth = 3;
//keyWidth = 2.5;
keyWidth = roundToLayerHeight(keyR*sqrt(2));


// Location of lever pivot point
//leverPivot = [15,15];
//leverPivot = [15,12];
//leverPivot = [12,18];
//leverPivot = [12,15];
//leverPivot = [10,18];
leverPivot = [10,13];
//leverPivot = [14,12];
//leverPivot = [10,13];
//leverPivot = [12,17];
//leverPivot = [-15,5];
// Radius of lever pivot pin
leverPivotR = 2.5;

// difference in lever angle between cuts
//stepA = -4.5; // step between cuts in terms of lever angle
stepA = -6; // step between cuts in terms of lever angle
// maximum bitting
maxBit = 4;

//gateY = leverBottomY + 8;
gateHeight = 2.3;
//gateY = leverPivot[1];
gateY = leverPivot[1] + 2;
gateC = 0.2;
leverR = 27;
//leverTopY = max(gateY + gateHeight + 4, leverPivot[1]+leverPivotR+3);

//leverBottomY = keyHeight-4*step;
leverBottomY = curtainR;
//leverTopY = gateY+gateHeight/2+3;
leverTopY = max(gateY+gateHeight/2+2, leverPivot[1]+leverPivotR+3);
//topLeverAngle = 180-(maxBit*-stepA)+4;
//topLeverAngle = 180;
topLeverAngle = 90;
//bottomLeverAngle = 10; // rotate lever bottom, to get earlier contact with key
//bottomLeverAngle = 30;
//bottomLeverAngle = 25;
bottomLeverAngle = 20;

bitting = [0,1,2,3,4];
//bitting = [4,3,2,1,0];

//-----------------------------------------------------------------------------
// Vertical (z) positions
//-----------------------------------------------------------------------------

housingThickness = roundToLayerHeight(1.5); // top and bottom
leverThickness   = roundToLayerHeight(1.5);
spacerThickness  = 2*layerHeight;
leverStep = leverThickness + spacerThickness;

boltZ       = 0;
actuatorZ   = 0;
firstLeverZ = housingThickness;
leverZ      = [for(i=0,z=firstLeverZ; i<=len(bitting); i=i+1, z=z + leverThickness + spacerThickness) z];

//housingThickness = 0;
echo("leverZ",leverZ);

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

/*
// find the normal of a line at distance d from the origin that intersects p
// i.e. solve for a: polar(a,d) + polar(a+90,e) == p
function perp_angle(d,p) = acos(d/norm(p)) + atan2(p[1],p[0]);

echo(perp_angle(5,[-10,-5]), atan2(-5,-10), acos(5/norm([5,10])));

// angle that a rectangle ([0,0],p) will be rotated around p to touch point q
function rect_angle(p,q) = 0;

// where to cut the key
function key_cut(bit)=undef;
*/

/*
// angle of lever, when moved by key of given cut
function lever_angle_given_bit(bit) =
  let (d=keyHeight - bit*step)
  let (x=leverPivot[0], y=leverPivot[1]-d, r=diagonal(x,y))
  let (y2=leverPivot[1]-leverBottomY)
  let (a=asin(y2/r), b=atan2(y,x))
  //let (a=asin(y2/r), b=atan(x/y))
  b-a+(x<0?180:0);
*/

// distance of a halfplane to a point
//function 

// how much to displace above curtainR to move lever by a given angle
// i.e. the key cuts
// based on a 90deg angle with the lever bottom
function lever_move_given_angle(a) =
  let (p = rot(-bottomLeverAngle,leverPivot))
  //let (p = leverPivot)
  let (yd = p[1] / cos(a))
  let (xd = sin(abs(a)) * (p[0] - side_given_diagonal(yd,p[1])) )
  //let (xd = sin(abs(a)) * (p[0] - tan(abs(a))*leverPivot[1]) )
  xd + (yd - p[1]);

// based on a key angle of 0 or 180deg
function lever_move_given_angle2(a,contactAngle=0) =
  let (d = curtainR + lever_move_given_angle(a))
  d / cos(a-contactAngle) - curtainR + (abs(a)>=abs(3*stepA)?0.0*abs(a-2*stepA):0);

// based on a fixed contact point on the lever
function rot_around(c,a,p) = rot(a,p-c)+c;
function lever_move_given_angle3(a) =
  norm(rot_around(leverPivot, a,rot(bottomLeverAngle,[0,curtainR]))) - curtainR;
/*
  let (p=leverPivot - rot(-bottomLeverAngle,[0,curtainR]))
  norm(rot(a,p) - p);
*/
echo("move",lever_move_given_angle3(stepA));

// key needs to be high enough for moving lever at maxBit
keyHeight = curtainR+lever_move_given_angle(stepA*maxBit);
echo("keyHeight",keyHeight, curtainR+lever_move_given_angle2(stepA*maxBit));

// angle of lever, when moved by key of given cut
//function lever_angle(bit) = (maxBit-bit) * stepA;
function lever_angle(bit) = bit * stepA;
maxLeverAngle = lever_angle(maxBit);

module contact_point_test() {
  translate_z(30) color("yellow") linear_extrude(1) {
    circle(1);
    translate(leverPivot) circle(1);
    for (i=[0:maxBit]) {
      a = i*stepA;
      //translate([0,-(leverPivot[1]-curtainR)]) square(2);
      //rotate(a) translate([0,-(leverPivot[1]-curtainR)]) circle(0.5);
      rotate_around(leverPivot,a) rotate(bottomLeverAngle) translate([0,curtainR]) square([18,0.05],true);
      rotate(bottomLeverAngle) rotate(a) translate([0,curtainR+lever_move_given_angle(a)]) circle(0.25);
    }
  }
  b = -0;
  translate_z(31) color("cyan") linear_extrude(1) {
    for (i=[0:maxBit]) {
      a = i*stepA;
      rotate(bottomLeverAngle+b) translate([0,curtainR+lever_move_given_angle2(a,b)]) circle(0.25);
    }
  }
  translate_z(32) color("lime") linear_extrude(1) {
    for (i=[0:maxBit]) {
      a = i*stepA;
      rotate_around(leverPivot,a) rotate(bottomLeverAngle) translate([0,curtainR]) circle(0.25);
      rotate_around(leverPivot,a) translate(rot(bottomLeverAngle,[0,curtainR])) circle(0.25);
    }
  }
  translate_z(29) color("lime") linear_extrude(1) {
    for (i=[0:maxBit]) {
      r = curtainR+lever_move_given_angle(i*stepA);
      difference() {
        circle(r=r);
        circle(r=r-0.05);
      }
    }
  }
  translate_z(28) color("gray") linear_extrude(1) {
    for (i=[0:maxBit]) {
      r = curtainR+lever_move_given_angle2(i*stepA,b);
      //r = curtainR+lever_move_given_angle3(i*stepA);
      difference() {
        circle(r=r);
        circle(r=r-0.05);
      }
    }
  }
}
*contact_point_test();


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
      *rotated(range_to_list([-20:5:20])) {
        rotate_around(leverPivot,lever_angle(bit)) base_lever_profile();
      }
      step = 5;
      for (i=[-30:step:30]) {
        rotate(i) rotate_around(leverPivot,lever_angle(bit)) base_lever_profile();
      }
    }
  }
}

curtainBit = 3;
module key() {
  linear_extrude(boltThickness+eps) {
    key_profile(curtainBit,ward=false);
  }
  if (curtainBit>=bitting[0]) translate_z(boltThickness) linear_extrude(spacerThickness+eps) {
    key_profile(curtainBit,ward=true);
  }
  for (i=[0:len(bitting)-1]) {
    extra_bot = (bitting[i] >= ((i==0)?curtainBit:bitting[i-1])) ? spacerThickness : 0;
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

module key_profile_test() {
  for (bit=[0:maxBit]) {
    translate_x(20*bit) {
      color("red")linear_extrude(1) {
        key_profile(bit,false);
      }
      translate_z(1) color("green")linear_extrude(1) {
        intersection() {
          keyway_profile();
          circle(r=curtainR+lever_move_given_angle2(bit*stepA));
        }
      }
    }
  }
}
!key_profile_test();

//-----------------------------------------------------------------------------
// Levers
//-----------------------------------------------------------------------------

module base_lever_profile() {
  x1 = leverPivot[0] - leverR;
  x2 = 10;
  group() {
    //intersection() {
      
      //translate([x1,leverBottomY]) square([x2-x1,leverTopY-leverBottomY]);
    *intersection() {
      rotate(bottomLeverAngle) translate([x1,leverBottomY]) square([x2-x1,lots]);
      translate_y(leverTopY) negative_y2d();
      //translate(leverPivot) circle(leverR);
      translate(leverPivot) wedge(a1=topLeverAngle,a2=270,r=leverR);
    }
    difference() {
      translate(leverPivot) wedge(a1=90,a2=270,r=leverR);
      translate_y(leverTopY) positive_y2d();
      //translate_y(0) negative_y2d();
      *rotate(bottomLeverAngle) translate_y(leverBottomY) negative_y2d();
      *translate_y(boltBottomY) negative_y2d();
      translate_y(0) negative_y2d();
      rotate(-stepA*maxBit) translate([-lots,-lots+leverBottomY]) square(lots);
      *hull() for (i=[0:maxBit]) {
        rotate_around(leverPivot,-i*stepA) circle(curtainR+lever_move_given_angle(i*stepA));
      }
      *group() for (i=[0:0.2:maxBit]) {
        b = 0;
        rotate_around(leverPivot,-i*stepA) circle(curtainR+lever_move_given_angle2(i*stepA,b));
      }
      for (i=[0:0.5:maxBit-eps]) {
        i2 = i+0.5;
        hull() {
          rotate_around(leverPivot,-i*stepA) circle(curtainR+lever_move_given_angle2(i*stepA));
          rotate_around(leverPivot,-i2*stepA) circle(curtainR+lever_move_given_angle2(i2*stepA));
        }
      }
      *group() for (i=[0:maxBit]) {
        rotate_around(leverPivot,-i*stepA) circle(curtainR+lever_move_given_angle3(i*stepA));
      }
      circle(curtainR);
    }
    //translate([x1,leverBottomY]) square([x2-x1,leverTopY-leverBottomY]);
    //translate(leverPivot) translate(polar(leverR,-180)) square(eps,true);
    //translate(leverPivot) circle(leverR);
    *translate(leverPivot) wedge(-180-10,-180+10,r=leverR);
    difference() {
      translate(leverPivot) circle(leverPivotR+3);
      for (i=[maxBit]) {
        rotate_around(leverPivot,-i*stepA) circle(curtainR+lever_move_given_angle2(i*stepA));
      }
    }
  }
}
*!base_lever_profile();

falseGateTravel = 3;
falseGateTravel2 = 1;

//gateHeight2 = 0.89;
gateHeight2 = gateHeight - 0.8;

module lever_profile(bit) {
  difference() {
    base_lever_profile();
    translate(leverPivot) circle(leverPivotR+C);
    // gates
    //badBit = (bit+3) % (maxBit+1);
    badBits = [4,3,0,0,1];
    //badBit = bit<maxBit/2 ? maxBit : 0;
    badBit = badBits[bit];
    for (j=[0:maxBit]) {
      rotate_around(leverPivot, -lever_angle(j)) {
        gate_profile(j == bit, shallowFalseGate = j != badBit, includeDrop=j<maxBit);
      }
    }
  }
}
module gate_profile(trueGate=true,shallowFalseGate=false,includeDrop=true) {
  x1 = leverPivot[0] - leverR;
  if (trueGate) {
    translate([x1,gateY-gateHeight/2-gateC]) square([boltTravel+gateC,gateHeight+2*gateC]);
    if (includeDrop) {
      translate([x1+boltTravel-boltWidth/2,gateY+gateHeight-gateHeight2]) chamfer_rect(boltWidth+2*gateC,gateHeight+2*gateC,0.1,r_tl=0.7);
    }
  } else if (!shallowFalseGate) {
    translate([x1,gateY]) chamfer_rect(falseGateTravel,gateHeight+2*gateC,0.1);
  } else {
    w = gateHeight*0.9;
    translate([x1,gateY]) chamfer_rect(falseGateTravel2,w+2*gateC,0.4);
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
      rotate_around(leverPivot,stepA*maxBit) base_lever_profile();
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
      rotate_around(leverPivot,stepA*maxBit)
      intersection() {
        translate([x1,y1]) square([x2-x1,y2-y1]);
        translate(leverPivot) circle(leverR);
      }
      translate(leverPivot) circle(leverPivotR+3);
    }
    translate(leverPivot) circle(leverPivotR+C);
    if (ward) {
      circle(r=curtainR+C);
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
//boltBottomY = keyHeight-4;
//boltBottomY = keyHeight-3;
boltBottomY = curtainR;
//boltBottomY = wardR;
//boltBottomY = wardR+1;
//boltBottomY = 0;
boltTopY = boltBottomY+20;
boltLeftX = leverPivot[0] - leverR - 2*boltTravel - 1;
boltRightX = leverPivot[0] - boltTravel + leverPivotR - C;

// if actuator moves in a circle of radius r around [0,0],
// and starts interacting if y>=boltBottomY, it will move bolt by
// 2*sqrt(r^2-boltBottomY^2)
actuatorCutoffR = boltBottomY-0.0;
//actuatorR = diagonal(actuatorCutoffR,boltTravel/2);
//actuatorR = keyHeight-1;
//actuatorPinR = 2;
//actuatorPinR2 = 3;
//actuatorPinR = 2;
actuatorPinR = 1;
actuatorPinR2 = 3;
//actuatorR = keyHeight - actuatorPinR;
actuatorR = keyHeight - 2;
echo("actuator",boltBottomY,actuatorR);

/*function bolt_pos(a) =
  cos(a)*actuatorR < boltBottomY-2 ?
    (-a<0 ? 0 : boltTravel)
  :
  let (pinH = cos(a)*actuatorR - boltBottomY)
  let (pinW = pinH > 0 ? actuatorPinR : side_given_diagonal(actuatorPinR,pinH))
  //let (pinW = (keyWidth+1*1.29)/2+1)
  let (slotW = lerp(actuatorPinR,actuatorPinR2,1-max(0,min(1,pinH/(actuatorR-boltBottomY)))))
  let (x = -sin(a) * actuatorR + boltTravel/2 - sign(a)*(pinW-slotW))
  max(0,min(boltTravel,x));
*/
function bolt_pos(a) =
  //let (b = max(-45,min(45,a)))
  let (b = max(-55,min(55,a)))
  //-sin(b)*actuatorR + 0.75*sign(a)*(1-cos(b))*actuatorR + boltTravel/2;
  -sin(b)*actuatorR + 0.*sign(a)*(1-cos(b))*actuatorR + boltTravel/2;

echo("bolt_pos",bolt_pos(+50),bolt_pos(0),bolt_pos(-50));

boltThickness2 = boltThickness + len(bitting)*leverStep;

boltLimiterPos = [leverPivot[0] - leverR + 2.5, gateY + 4];
boltLimiterR = 2;
//boltLimiterR = eps;

module bolt_base_profile(holes = true) {
  x1 = leverPivot[0] - leverR - 0.5;
  x2 = x1-10;
  //boltRightX = leverPivot[0]-boltTravel-leverPivotR-C;
  difference() {
    translate([boltLeftX,boltBottomY]) square([boltRightX-boltLeftX,boltTopY-boltBottomY]);
    //translate([-boltTravel/2,boltBottomY]) chamfer_rect(5,5,2);
    //translate_x(-boltTravel/2) {
    // don't exceed lever profile
    *translate_x(-boltTravel) difference() {
      translate_x(x1+leverR/2) positive_x2d();
      base_lever_profile();
      rotate_around(leverPivot,stepA*maxBit) base_lever_profile();
      translate(leverPivot+[-2,-15]) square(15); // bottom corner needed for actuator
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
      //offset(C)
      //hull() {
      group() {
        for (a=[-60:2:60]) {
        //for (a=[0]) {
          //translate_x(actuatorR*sin(a))
          translate_x(-bolt_pos(a)) rotate(a) rotate(180) actuator_profile();
        }
        
        *translate([-boltTravel/2,0]) rotate(180)actuator_profile();
        *translate([-boltTravel/2,boltBottomY]) square([2*actuatorPinR2,eps],true);
        *hull() {
          //translate_y(boltBottomY+1) circle(2+C);
          offset(1.3+C) rotate(180) key_profile(curtainBit,ward=false);
          translate_y(actuatorR) circle(2+C);
          //circle(r=curtainR+C);
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
  x1 = leverPivot[0] - leverR;
  linear_extrude(boltThickness + len(bitting)*leverStep + 2*layerHeight) {
    difference() {
      translate([x1-boltWidth/2,gateY]) chamfer_rect(boltWidth,gateHeight,0.1);
      translate([x1,gateY]) square([1,gateHeight/3],true);
    }
  }
  linear_extrude(boltThickness + len(bitting)*leverStep) {
    translate([x1-boltTravel/2-1,gateY-(gateHeight-gateHeight2)/2]) chamfer_rect(boltTravel,gateHeight2,0);
  }
}
*!bolt();


actuatorSmoothR = 1.29;
actuator_profile_corners = 
  [//for (a=[0:30:360-1]) polar(a,curtainR)
  [-keyWidth/2,0], [keyWidth/2,0]
  ,[-keyWidth/2,-curtainR], [keyWidth/2,-curtainR]
  ,[-keyWidth/2,-curtainR-1], [keyWidth/2,-curtainR-1]
  ,[0,-keyHeight+actuatorSmoothR]
  ];

//!actuator_profile();

module actuator_profile() {
  *offset(actuatorSmoothR) hull() polygon(actuator_profile_corners);
  *hull() {
    offset(1.2) key_profile(curtainBit,ward=false);
    translate_y(-actuatorR) circle(actuatorPinR);
    *offset(1) intersection() {
      circle(actuatorR);
      translate_y(-lots) square([keyWidth+1*1.29,2*lots],true);
    }
    translate([0,-boltBottomY+1]) square([2*actuatorPinR2,eps],true);
  }
  translate_y(-(keyHeight-2)) circle(2);
  *hull() {
    //offset(1) key_profile(curtainBit,ward=false);
    //translate_y(-actuatorR) circle(actuatorPinR);
    *offset(0.1) key_profile(0,ward=false);
    intersection() {
      //circle(r=actuatorR);
      circle(r=keyHeight);
      offset(1) key_profile(0,ward=false);
    }
    *offset(1) intersection() {
      circle(actuatorR);
      translate_y(-lots) square([keyWidth+1*1.29,2*lots],true);
    }
    *translate([0,-boltBottomY+1]) square([2*actuatorPinR2,eps],true);
  }
}

curtainZ = boltZ + boltThickness;
curtainThickness = roundToLayerHeight(1.5);

// curtain + bolt actuator
module curtain() {
  translate_z(boltZ)
  linear_extrude(boltThickness) {
    difference() {
      *group() {
        circle(r=keyHeight);
        translate_y(-keyHeight) square(4,true);
      }
      group() {
        circle(r=boltBottomY-C);
        actuator_profile();
      }
      *offset(C) keyway_profile();
      *offset(C) key_profile(curtainBit,ward=false);
    }
  }
  translate_z(curtainZ) 
  linear_extrude(curtainThickness) {
    circle(r=keyHeight+1);
  }
  linear_extrude(boltThickness + len(bitting)*leverStep) {
    difference() {
      //circle(r=wardR+C+1.2);
      hull() {
        circle(r=curtainR);
        // flat top to snap curtain using levers
        r1 = 1.5;
        x = 4;
        rotate(bottomLeverAngle) {
          translate([x,curtainR-r1]) circle(r=r1);
          translate([-x,curtainR-r1]) circle(r=r1);
        }
      }
      circle(r=wardR+C);
      translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
    }
  }
}

use <../gear.scad>

// gear_inner_radius(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance=0) = number_of_teeth * circular_pitch / (2*PI) - depth_ratio*circular_pitch/2-clearance/2;

*!group() {
  a = -180 - 20;
  innerRadius = curtainR;
  outerRadius = keyHeight;
  // num_teeth * circular_pitch / (2*PI) - depth_ratio*circular_pitch/2-clearance/2;
  // =circular_pitch * (num_teeth / (2*PI) - depth_ratio/2)-clearance/2;
  num_teeth = 12;
  depth_ratio=0.3;
  clearance = C;
  //circular_pitch = (innerRadius+C/2) / (num_teeth/(2*PI) - depth_ratio/2);
  circular_pitch = (outerRadius+C/2) / (num_teeth/(2*PI) + depth_ratio/2);
  pressure_angle=40;
  avg_radius = gear_avg_radius(num_teeth, circular_pitch, pressure_angle, depth_ratio);
  color("pink") curtain();
  translate_z(-5) {
    rotate(a)
    linear_extrude(2) {
      echo("gear",innerRadius, gear_inner_radius(num_teeth, circular_pitch, pressure_angle, depth_ratio, clearance), keyHeight, gear_outer_radius(num_teeth, circular_pitch, pressure_angle, depth_ratio, clearance));
      //gear2D_limited(num_teeth, 2, circular_pitch, pressure_angle, depth_ratio, clearance);
      circle(gear_inner_radius(num_teeth, circular_pitch, pressure_angle, depth_ratio, clearance));
      rotate(-90) {
        gear_tooth_profile(num_teeth, 2, circular_pitch, pressure_angle, depth_ratio, clearance);
        rotate(360/num_teeth)
        gear_tooth_profile(num_teeth, 2, circular_pitch, pressure_angle, depth_ratio, clearance);
      }
    }
  }
  color("green") translate_z(-5) color("green") linear_extrude(2) {
    translate_x(-(a+180)/360 * num_teeth*circular_pitch)
    translate_y(keyHeight - depth_ratio*circular_pitch/2)
    intersection() {
      mirror([0,1,0])
        rack(3, circular_pitch, pressure_angle, clearance=clearance, flat=true);
      square([lots,depth_ratio*circular_pitch],true);
    }
  }
  translate_x(50) {
    a = -180-57;
    echo("new bolt travel", boltTravelNew(-10), boltTravelNew(-180), boltTravelNew(-180-10));
    translate_x(boltTravelNew(a))
    color("green") linear_extrude(2) bolt_new();
    color("red") linear_extrude(2) {
      rotate(a)
      difference() {
        circle(r=keyHeight-C);
        for (a=[0:-1:-360]) {
          //offset(C)
          rotate(-a) translate_x(boltTravelNew(a)) bolt_new();
          *hull() {
            rotate(-(a-2)) translate_x(boltTravelNew(a-2)) bolt_new();
            rotate(-a) translate_x(boltTravelNew(a)) bolt_new();
          }
        }
      }
    }
  }
}

boltTravelMax = 11;
function boltTravelNew(a) =
  let (r = keyHeight-actuatorHoleHeight*0.5)
  max(0,min(boltTravelMax,(a+180)/360 * -r*2*PI)) - boltTravelMax;

actuatorHoleWidth = 3;
//actuatorHoleHeight = 3.45;
actuatorHoleHeight = 2.45;
echo("travel",boltTravel);
module bolt_new() {
  difference() {
    //dw = 3.3;
    dw = 2;
    translate([-30,keyHeight-actuatorHoleHeight])square(2*30);
    translate_x(actuatorHoleWidth/2+dw/2) actuatorHole();
    //translate_x(boltTravelMax-actuatorHoleWidth/2) actuatorHole();
    translate_x(boltTravelMax-dw/2-actuatorHoleWidth/2) actuatorHole();
  }
}
module actuatorHole() {
  dw = actuatorHoleHeight*0.8;
  sym_polygon_x([[-actuatorHoleWidth/2-dw/2,keyHeight-actuatorHoleHeight], [-actuatorHoleWidth/2+dw/2,keyHeight]]);
  //polygon([for (a=[-180:5:180]) [a/180*actuatorHoleWidth, keyHeight + actuatorHoleHeight*(-1+cos(a))/2] ]);
}

module gear_tooth_profile(number_of_teeth, actual_teeth, circular_pitch, pressure_angle, depth_ratio, clearance) {
  pitch_radius = number_of_teeth*circular_pitch/(2*PI);
  base_radius = pitch_radius*cos(pressure_angle);
  depth=circular_pitch/(2*tan(pressure_angle));
  outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
  root_radius1 = pitch_radius-depth/2-clearance/2;
  root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
  backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
  half_thick_angle = 90/number_of_teeth - backlash_angle/2;
  pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
  pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
  min_radius = max (base_radius,root_radius);

  intersection() {
    rotate(90/number_of_teeth)
      circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
    union(){
      *rotate(90/number_of_teeth)
        circle(r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
      halftooth (
        pitch_angle,
        base_radius,
        min_radius,
        outer_radius,
        half_thick_angle);		
      mirror([0,1])halftooth (
        pitch_angle,
        base_radius,
        min_radius,
        outer_radius,
        half_thick_angle);
    }
  }
}

module gear2D_limited(number_of_teeth, actual_teeth, circular_pitch, pressure_angle, depth_ratio, clearance) {
  pitch_radius = number_of_teeth*circular_pitch/(2*PI);
  base_radius = pitch_radius*cos(pressure_angle);
  depth=circular_pitch/(2*tan(pressure_angle));
  outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
  root_radius1 = pitch_radius-depth/2-clearance/2;
  root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
  backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
  half_thick_angle = 90/number_of_teeth - backlash_angle/2;
  pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
  pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
  min_radius = max (base_radius,root_radius);

  intersection() {
    rotate(90/number_of_teeth)
      circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
    union(){
      rotate(90/number_of_teeth)
        circle(r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
      for (i = [0:actual_teeth-1])rotate(i*360/number_of_teeth){
        halftooth (
          pitch_angle,
          base_radius,
          min_radius,
          outer_radius,
          half_thick_angle);		
        mirror([0,1])halftooth (
          pitch_angle,
          base_radius,
          min_radius,
          outer_radius,
          half_thick_angle);
      }
    }
  }
}

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

housingWall = 1.29;
housingChamfer = 0.45;
housingRightX = max(keyHeight, leverPivot[0]+leverPivotR+3 + 1) + C + housingWall;
housingTopY = (leverPivot+polar(topLeverAngle + maxBit*stepA,leverR))[1] + C + housingWall;

screwD = 6;
screwLocations = [[boltLeftX+boltTravel+screwD,30], [boltLeftX+boltTravel+screwD,-keyHeight+screwD/2+1], [housingRightX-screwD/2-housingWall - 0.89,30]];

echo(leverPivot+polar(topLeverAngle,leverR));

lipThickness = roundToLayerHeight(1);
module housing_outer_profile() {
  rounding = 5;
  x1 = boltLeftX + boltTravel;
  x2 = housingRightX;
  y1 = -keyHeight - C - housingWall;
  y2 = housingTopY;
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
    translate_z(boltThickness + len(bitting)*leverStep + layerHeight - lipThickness)
    linear_extrude(lipThickness+2*eps) {
      difference() {
        offset(-housingWall) difference() {
          housing_outer_profile();
      circle(r = keyHeight+C);
        }
        *offset(-housingWall-2) housing_outer_profile();
      }
    }
    for (l=screwLocations) {
      translate(l) screw_hole();
    }
  }
  linear_extrude(boltThickness) {
    translate(boltLimiterPos) circle(boltLimiterR);
  }
  pivot_pin();
}
*!housing();

module housing_lip() {
  difference() {
    linear_extrude_cone_chamfer(housingThickness, 0, housingChamfer) {
      housing_outer_profile();
    }
  }
  for (l=screwLocations) {
    translate(l) screw_hole();
  }
}

module screw_hole() {
  h = boltThickness + len(bitting)*leverStep + layerHeight - lipThickness;
  cylinder(d=screwD,h=h);
  translate_z(h-1) cylinder(d1=screwD,d2=screwD+2,h=1+eps);
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

//keyAngle = -180 - 45;
keyAngle = -180 + 20;
//keyAngle = -180 - 40;
//keyAngle = 0;
leverPos = 1;
boltPos = bolt_pos(keyAngle+180);

rotate(keyAngle) key();

*color("LightYellow") housing();

color("green") translate_x(boltPos) bolt();

// warding
color("cyan") translate_z(leverThickness+layerHeight) linear_extrude(10) {
  difference() {
    circle(r=wardR);
    circle(r=keyR+C);
    translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
  }
}

// curtain
rotate(keyAngle)
color("salmon") curtain();

function lever_color(i) = [1-0.0*i,(i%2)*0.4+i*0.1,(i%2)*0.4+i*0.1];

for (i=[0:len(bitting)-1]) {
  translate_z(boltThickness + spacerThickness + i*leverStep)
  color(lever_color(i)) lever(bitting[i], pos=leverPos*lever_angle(bitting[i]));
}

*for (i=[0:len(bitting)-1]) {
  translate_z(boltThickness + i*leverStep+20)
  color("lightblue") {
    if (i==0) warded_spacer(); else spacer();
  }
}
