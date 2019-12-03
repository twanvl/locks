//=============================================================================
// Lever lock with warding
//=============================================================================

include <../util.scad>
use <../threads.scad>

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
leverPivot = [10,13];
// Radius of lever pivot pin
leverPivotR = 2.5;

// difference in lever angle between cuts
//stepA = -6; // step between cuts in terms of lever angle
stepA = -3; // step between cuts in terms of lever angle
// maximum bitting
//maxBit = 4;
maxBit = 8;

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

//bitting = [0,1,2,3,4];
//bitting = [4,3,2,1,0];
//bitting = [4,1,2,0,3];
bitting = [8,3,5,1,4];

//-----------------------------------------------------------------------------
// Vertical (z) positions
//-----------------------------------------------------------------------------

housingThickness = roundToLayerHeight(1.5); // top and bottom
leverThickness   = roundToLayerHeight(1.5);
spacerThickness  = 2*layerHeight;
wardedSpacerThickness = roundToLayerHeight(1.0);
boltThickness = roundToLayerHeight(2);
curtainThickness = roundToLayerHeight(1.5);
leverStep = leverThickness + spacerThickness;

function ward_after_lever(i) = i == 2;

actuatorZ   = 0;
firstLeverZ = housingThickness;
wardZ       = firstLeverZ + roundToLayerHeight(2) + C;
leverZ      = [for(i=0,z=firstLeverZ; i<=len(bitting); i=i+1, z=z + leverThickness + (ward_after_lever(i-1) ? wardedSpacerThickness : spacerThickness)) z];
boltZ       = leverZ[len(bitting)];
keyBottomZ  = firstLeverZ - 2*layerHeight;
curtainZ    = boltZ + boltThickness;

//-----------------------------------------------------------------------------
// Utilities
//-----------------------------------------------------------------------------

module rotate_around(pos,angle) {
  translate(pos)
  rotate(angle)
  translate(-pos)
  children();
}
function rot_around(c,a,p) = rot(a,p-c)+c;

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

// distance from key to lever that is rotated to a given angle, when the key is at 180-bottomLeverAngle
function key_distance_given_angle(a) =
  let (d = curtainR + lever_move_given_angle(a))
  d / cos(a);

function key_distance_given_bit(bit) = key_distance_given_angle(stepA*bit);

// key needs to be high enough for moving lever at maxBit
keyHeight = key_distance_given_bit(maxBit);

// angle of lever, when moved by key of given cut
//function lever_angle(bit) = (maxBit-bit) * stepA;
function lever_angle(bit) = bit * stepA;


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

// key profile for the given bitting. If bitting is undef, for max bitting
module key_profile(bit = undef, ward = false) {
  intersection() {
    circle(keyR);
    translate_x(-keyWidth/2) positive_x2d();
  }
  difference() {
    intersection() {
      translate([-keyWidth/2,-keyHeight]) square([keyWidth,keyHeight]);
      if (bit == undef) {
        circle(keyHeight);
      } else {
        circle(key_distance_given_bit(bit));
      }
    }
    if (ward) circle(r=wardR+C);
  }
}

module key() {
  difference() {
    union() {
      for (i=[0:len(bitting)-1]) {
        extra_bot = 
          ward_after_lever(i-1) ? -C :
          (i>0 && bitting[i] <= bitting[i-1]) ? spacerThickness : 0;
        extra_top = 
          ward_after_lever(i) || i == len(bitting)-1 ? -C :
          ((i<len(bitting)-1) && bitting[i] <= bitting[i+1]) ? spacerThickness : 0;
        translate_z(leverZ[i]-extra_bot)
        linear_extrude(leverThickness+extra_top+extra_bot+eps) {
          key_profile(bitting[i]);
        }
      }
      // blade base
      translate_z(keyBottomZ) {
        linear_extrude(leverZ[len(bitting)]-keyBottomZ) {
          key_profile(0);
        }
      }
    }
    // warding
    translate_z(wardZ - C) {
      linear_extrude(lots,convexity=2) {
        circle(r=wardR+C);
      }
    }
  }
  // shaft of key
  translate_z(keyBottomZ) {
    keyLength = 32;
    intersection() {
      linear_extrude(keyLength) {
        intersection() {
          circle(keyR);
          translate_x(-keyWidth/2) positive_x2d();
        }
      }
      // chamfer top
      cylinder(r1=1+keyLength*0.5,r2=1,h=keyLength);
    }
    // handle
    translate_z(keyLength+handleHeight/2 - 0.5 - (keyR-1)/0.5) {
      translate_x(-keyWidth/2)
      linear_extrude_x(keyWidth, convexity=2) {
        difference() {
          key_handle_profile();
          offset(-0.5) key_handle_profile();
        }
        translate([0,handleHeight/2-2.1]) {
          offset(0.2)
          text("L L 1",2,font="Ubuntu",halign="center",valign="center");
        }
      }
      translate_x(-keyWidth/2)
      linear_extrude_x(keyWidth-roundToLayerHeight(0.5), convexity=2) {
        key_handle_profile();
      }
    }
  }
}
handleHeight = 16;
handleWidth = 20;
module key_handle_profile() {
  t = 8;
  difference() {
    scale([1,handleHeight/handleWidth]) circle(d=handleWidth);
    scale([1,(handleHeight-t)/(handleWidth-t)]) circle(d=handleWidth-t);
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
*!key_profile_test();

module export_key() { rotate([0,-90,0]) key(); }

//-----------------------------------------------------------------------------
// Levers
//-----------------------------------------------------------------------------

module base_lever_profile(hole = false) {
  difference() {
    group() {
      // the profile starts with a circle around the pivot hole,
      translate(leverPivot) circle(leverPivotR+3);
      // .. and a wedge, limited in y
      translate(leverPivot) wedge(a1=90,a2=270,r=leverR);
    }
    // remove high and low parts
    translate_y(leverTopY) positive_y2d();
    translate_y(0) negative_y2d();
    // remove left of interaction point
    rotate(-stepA*maxBit) translate([-lots,-lots+leverBottomY]) square(lots);
    // remove places where the key moves after lever is set
    for (i=[0:0.5:maxBit-eps]) {
      i2 = i+0.5;
      hull() {
        rotate_around(leverPivot,-i*stepA) circle(key_distance_given_bit(i));
        rotate_around(leverPivot,-i2*stepA) circle(key_distance_given_bit(i2));
      }
    }
    // hole for pivot
    if (hole) {
      translate(leverPivot) circle(leverPivotR+C);
    }
  }
}
*!base_lever_profile();

falseGateTravel = 3.5;
falseGateTravel2 = 1;

//gateHeight2 = 0.87;
gateHeight2 = gateHeight - 0.8;
gateSkip = abs(stepA) > 5 ? 1 : 2; 

function bad_bit(bit) = (bit+floor((maxBit+1)/2)) % roundTo(maxBit+1,gateSkip);

module lever_profile(bit) {
  difference() {
    base_lever_profile(hole = true);
    // gates
    for (j=[0:maxBit]) {
      if ((bit-j)%gateSkip == 0)
      rotate_around(leverPivot, -lever_angle(j)) {
        gate_profile(j == bit, shallowFalseGate = j != bad_bit(bit), includeDrop=j>0);
      }
    }
  }
}

module gate_profile(trueGate=true,shallowFalseGate=false,includeDrop=true) {
  x1 = leverPivot[0] - leverR;
  if (trueGate) {
    translate([x1,gateY-gateHeight/2-gateC]) square([boltTravel+gateC,gateHeight+2*gateC]);
    if (includeDrop) {
      translate([x1+boltTravel-boltStumpWidth/2,gateY+gateHeight-gateHeight2]) chamfer_rect(boltStumpWidth+2*gateC,gateHeight+2*gateC,0.1,r_tl=0.7);
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
  linear_extrude(leverThickness,convexity=2) lever_profile(bit);
}

module spacer_profile(ward = false, full_ward = false) {
  difference() {
    union() {
      base_lever_profile(hole = true);
      rotate_around(leverPivot,stepA*maxBit) base_lever_profile(hole = true);
      if (ward) {
        rotate(90) wedge(250,center=true,r=keyHeight);
      }
      if (full_ward) {
        difference() {
          circle(r=keyHeight);
          offset(C) key_profile();
        }
      }
    }
    // slightly oversized hole
    translate(leverPivot) circle(leverPivotR+0.1+C);
    // gates + wiggle room
    gate_profile(includeDrop = false);
    rotate_around(leverPivot,1) gate_profile(includeDrop = false);
    rotate_around(leverPivot,-1) gate_profile(includeDrop = false);
    // spring
    spring_hole_profile();
    if (ward) {
      circle(r=curtainR+C);
      translate([-(curtainR+C),-(curtainR+C)])
        square([(curtainR+C)*2,curtainR+C]);
    } else {
      circle(r=keyHeight+C);
    }
  }
}
module warded_spacer() {
  difference() {
    linear_extrude(wardedSpacerThickness, convexity=2) spacer_profile(ward=true);
    h=2*layerHeight;
    translate_z(-eps) cylinder(r1=curtainR+C+h,r2=curtainR+C,h=h);
    translate_z(wardedSpacerThickness+eps-h) cylinder(r1=curtainR+C,r2=curtainR+C+h,h=h);
  }
}
module spacer() {
  linear_extrude(spacerThickness) spacer_profile();
}
module end_spacer() {
  linear_extrude(spacerThickness) {
    spacer_profile(ward=true, full_ward=true);
  }
  linear_extrude(spacerThickness+boltThickness) {
    difference() {
      group() {
        spacer_profile(ward=true, full_ward=true);
        circle(r=curtainTopR);
      }
      circle(r=curtainR+C);
      circle(r=actuatorR+actuatorPinR+C);
      offset(C) key_profile();
      translate_y(boltBottomY-C) positive_y2d();
    }
  }
}
*!spacer();
*!warded_spacer();
*!end_spacer();

module export_levers() {
  for (i=[0:len(bitting)-1]) {
    translate([0,i * leverR]) lever(bit = bitting[i]);
    translate([leverR+leverPivotR+10,i * leverR]) {
      rotate_around(leverPivot,i%2?0:180)
      if (ward_after_lever(i)) {
        warded_spacer();
      } else {
        spacer();
      }
    }
  }
}
*!export_levers();
*echo("bitting", bitting, [for(bit=bitting)bad_bit(bit)]);

//-----------------------------------------------------------------------------
// Bolt
//-----------------------------------------------------------------------------

boltTravel = 10;
//boltTravel = 6;
boltHeight = 20;

boltStumpWidth = 6;

boltBottomY = curtainR + C - 2;
boltTopY = boltBottomY + boltHeight;
// note: positions are when bolt is extended/the lock is locked
boltLeftX = leverPivot[0] - leverR - 2*boltTravel - 1;
boltRightX = leverPivot[0] - boltTravel + leverPivotR - C;

boltLimiterPos = [leverPivot[0] - leverR + 2.5, gateY + 4];
//boltLimiterPos = [leverPivot[0] - leverR + 2.5, gateY - 4];
boltLimiterR = 2;

// y at which actuator starts to engage the bolt
boltActuatorBottomY = curtainR + C + 0;
// if actuator moves in a circle of radius r around [0,0],
// and starts interacting if y>=boltActuatorBottomY, it will move bolt by
// 2*sqrt(r^2-boltBottomY^2)
actuatorR = diagonal(boltActuatorBottomY,boltTravel/2);
actuatorPinR = 1.75;

// key angle at which lever should start moving
boltStartMoveAngle = -180 + bottomLeverAngle - 7; // offset of actuator
// rotate actuator by a such that actuatorR*cos(boltStartMoveAngle+boltActuatorAngle) = boltActuatorBottomY
boltActuatorAngle = acos(boltActuatorBottomY/actuatorR) - boltStartMoveAngle;

// bolt position for given key angle
function bolt_pos(a) =
  let(b = a + boltActuatorAngle)
  cos(b)*actuatorR < boltActuatorBottomY ? // has actuator reached the bolt?
    (-b<0 ? 0 : boltTravel)
  :
  let (x = -sin(b) * actuatorR + boltTravel/2)
  x;


module bolt_base_profile(holes = true) {
  x1 = leverPivot[0] - leverR - 0.5;
  x2 = x1-10;
  //boltRightX = leverPivot[0]-boltTravel-leverPivotR-C;
  difference() {
    translate([boltLeftX,boltBottomY]) square([boltRightX-boltLeftX,boltTopY-boltBottomY]);
    //translate([-boltTravel/2,boltBottomY]) chamfer_rect(5,5,2);
    //translate_x(-boltTravel/2) {
    // don't exceed lever profile
    translate_x(-boltTravel) rotate_around(leverPivot,stepA*maxBit) {
      translate_y(leverPivot[1]+leverPivotR+3) positive_y2d();
    }
    *translate_x(-boltTravel) difference() {
      translate_x(x1+leverR/2) positive_x2d();
      base_lever_profile();
      rotate_around(leverPivot,stepA*maxBit) base_lever_profile();
      //translate(leverPivot+[-2,-15]) square(15); // bottom corner needed for actuator
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
      group() {
        for (a=[-360:5:0]) {
          hull() {
            translate_x(-bolt_pos(a)) rotate(a) actuator_profile();
            translate_x(-bolt_pos(a+5))  rotate(a+5) actuator_profile();
          }
          hull() {
            translate_x(-bolt_pos(a)) rotate(a) actuator_profile2();
            translate_x(-bolt_pos(a+5))  rotate(a+5) actuator_profile2();
          }
          hull() {
            translate_x(-bolt_pos(a)) circle(r=curtainR+C);
            translate_x(-bolt_pos(a+5)) circle(r=curtainR+C);
          }
        }
      }
    }
  }
}
*!bolt_base_profile();

boltStumpCountersink = 2*layerHeight;

module bolt() {
  // base: connecting things together, interacting with actuator
  translate_z(boltZ) linear_extrude(boltThickness) {
    bolt_base_profile();
  }
  // bolt (the part that locks a door)
  translate_z(firstLeverZ) linear_extrude(boltZ-firstLeverZ+eps) {
    difference() {
      translate([boltLeftX,boltBottomY]) square([-boltLeftX,boltTopY-boltBottomY]);
      translate(leverPivot-[boltTravel,0]) circle(r=leverR+0.5);
    }
  }
  // bolt stump (the part that interacts with the levers
  x1 = leverPivot[0] - leverR;
  translate_z(firstLeverZ - boltStumpCountersink)
  linear_extrude(boltZ-firstLeverZ+boltStumpCountersink) {
    difference() {
      translate([x1-boltStumpWidth/2,gateY]) chamfer_rect(boltStumpWidth,gateHeight,0.1);
      translate([x1,gateY]) square([1,gateHeight/3],true);
    }
  }
  // connect bolt stump to bolt
  translate_z(firstLeverZ)
  linear_extrude(boltZ-firstLeverZ) {
    translate([x1-boltTravel/2-1,gateY-(gateHeight-gateHeight2)/2]) chamfer_rect(boltTravel,gateHeight2,0);
  }
}
*!bolt();

module actuator_profile() {
  difference() {
    if (1) {
      hull() {
        rotate(boltActuatorAngle) translate_y(actuatorR) circle(actuatorPinR);
      }
    } else {
      intersection() {
        rotate(boltActuatorAngle) translate_x(-actuatorPinR) square([actuatorPinR*2,actuatorR]);
        circle(r=actuatorR);
      }
    }
    offset(C) key_profile();
  }
}
module actuator_profile2() {
  r=1.1;
  *rotate(-24) translate_y(curtainTopR-r) circle(r);
  //rotate(-10) translate_y(curtainTopR+1-r) circle(r);
}

module export_bolt() { rotate([180]) translate_z(-(boltZ+boltThickness)) bolt(); }

//-----------------------------------------------------------------------------
// Curtain
//-----------------------------------------------------------------------------

curtainTopR = keyHeight+0.87;

// curtain + bolt actuator
module curtain() {
  // curtain for bitting
  translate_z(keyBottomZ)
  linear_extrude(curtainZ-keyBottomZ+eps) {
    difference() {
      circle(r=curtainR);
      circle(r=wardR+C);
      translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
    }
  }
  // close below warding
  difference() {
    translate_z(keyBottomZ)
    linear_extrude(wardZ-layerHeight-keyBottomZ, convexity=2) {
      difference() {
        circle(r=curtainR);
        offset(C) key_profile();
      }
    }
    h = wardZ-layerHeight-keyBottomZ;
    translate_z(keyBottomZ-2*eps)
    cylinder(r1=wardR+C-h*1.5,r2=wardR+C,h=h+3*eps);
  }
  // bump for snapping curtain when lock is closed
  intersection() {
    group() {
      translate_z(leverZ[0]) {
        h = leverThickness+1;
        cylinder(r1=curtainR+h*1.2,r2=curtainR,h=h);
      }
    }
    translate_z(keyBottomZ) linear_extrude(boltZ-keyBottomZ,convexity=2) {
      difference() {
        fillet(2) {
          difference() {
            //circle(r = curtainR + 2);
            *rotate(90)wedge(90,center=true,r = curtainR + 2);
            union() {
              circle(r=curtainR);
              rotate(-maxBit*stepA) translate_x(-curtainR) square(2*curtainR);
            }
            base_lever_profile();
          }
        }
        *hull() {
          circle(r=curtainR);
          // flat top to snap curtain using levers
          r1 = 1.5;
          x = 4;
          rotate(-maxBit*stepA) {
            translate([x,curtainR-r1]) circle(r=r1);
            translate([-x,curtainR-r1]) circle(r=r1);
          }
        }
        circle(r=wardR+C);
        translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
      }
    }
  }
  // actuator
  translate_z(boltZ+layerHeight)
  linear_extrude(boltThickness-layerHeight+eps) {
    actuator_profile();
    actuator_profile2();
  }
  // curtain top
  translate_z(curtainZ) 
  linear_extrude(curtainThickness) {
    difference() {
      circle(r=curtainTopR);
      offset(C) key_profile();
      circle(r=wardR+C);
    }
  }
}

module export_curtain() { rotate([180]) translate_z(-(curtainZ+curtainThickness)) curtain(); }

//-----------------------------------------------------------------------------
// Spring
//-----------------------------------------------------------------------------

//spring_type = "flat";
spring_type = "flat_circle";
//spring_type = "wiggle";

springThickness = 2*layerHeight;
//springPivot = leverPivot + [-4,14];
springPivot = leverPivot + [-5,13];
//springAngle = 35;
springRestAngle = 35; // angle by which spring is rotated when lever is not raised
springAngle = springRestAngle+10; // preload angle
//springExtraLength = 1;
//springLength = (springPivot[1] - leverTopY) / sin(springAngle) + springExtraLength; // touching lever top
springLength = (springPivot[1] - leverTopY) / sin(springRestAngle); // touching lever top
springHeightZ = leverZ[len(bitting)] - spacerThickness - leverZ[0] - C;
springRetainThickness = springThickness + 4 * layerHeight;
springRetainWidth = 0.87;
springRetainShift = 2;
// angle by which spring is rotated when lever is not raised
//springRestAngle = asin((springPivot[1] - leverTopY) / springLength);
// angle by which spring is rotated when lever is fully raised
springFlexedAngle = asin((rot_around(leverPivot, -stepA*maxBit, springPivot)[1] - leverTopY) / springLength) + stepA*maxBit;



module spring_profile_flat(angle=0, retainingHole=true) {
  translate(springPivot) rotate(springAngle) {
    if (retainingHole) {
      translate([springRetainShift-springRetainWidth,springThickness-springRetainThickness])
        square([springRetainWidth,springRetainThickness]);
    }
    if (angle == 0) {
      translate([-springLength+(retainingHole?0:-1),0])
        square([springLength+(retainingHole?springRetainShift:1),springThickness]);
    } else {
      // bent spring
      unbendingL = springRetainShift - 1.5;
      l = springLength-springThickness + springRetainShift - unbendingL;
      step = l/10;
      translate([springRetainShift-springThickness/2,springThickness/2])
      line(cumsum([[-unbendingL,0], for (i=[0:step:l-step+eps]) polar(180-i*angle/step, step)], [0,0]), springThickness);
    }
  }
}
module spring_hole_profile_flat() {
  extraLength = 1;
  intersection() {
    group() {
      offset(C) spring_profile_flat();
      rotate_around(springPivot,springFlexedAngle-springAngle) {
        offset(C) spring_profile_flat(retainingHole=false);
      }
      offset(C)
      translate(springPivot) {
        //wedge(a1=180+springAngle,a2=180+springFlexedAngle,r=springLength+extraLength);
        //wedge(a1=180+springRestAngle,a2=180+springFlexedAngle,r=springLength+extraLength);
        polygon([[0,0], for(i=[0:0.1:1]) polar(180+lerp(springAngle,springFlexedAngle,i),springLength+i) ]);
      }
    }
    translate_y(leverTopY) positive_y2d();
  }
}

module export_spring() {
  linear_extrude(springThickness) square([springLength + springRetainShift,springHeightZ]);
  linear_extrude(springRetainThickness) square([springRetainWidth,springHeightZ]);
}

module spring_test() {
  translate(springPivot) cylinder(r=0.1,h=lots);
  *#linear_extrude(housingTopZ) spring_hole_profile();
  color("green") translate_z(-1) linear_extrude(3) spring_hole_profile();
  color("blue") linear_extrude(housingTopZ) spring_profile();
  color("blue") linear_extrude(housingTopZ) spring_profile(angle=7);
  rotate_around(springPivot,springRestAngle-springAngle)
  color("blue") linear_extrude(housingTopZ) spring_profile();
  rotate_around(springPivot,springFlexedAngle-springAngle)
  color("blue") linear_extrude(housingTopZ) spring_profile();
  
  color("red")lever(0);
  translate_z(-1) color("yellow") rotate_around(leverPivot,stepA*maxBit) lever(0);
}
*!spring_test();

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

screwD = 6;

housingWall = 1.29;
housingChamfer = 0.45;
housingLeftX = boltLeftX + boltTravel - 2*C;
housingRightX = max(keyHeight, leverPivot[0]+leverPivotR+3) + C + housingWall*2;
//housingTopY = (leverPivot+polar(topLeverAngle + maxBit*stepA,leverR))[1] + C + housingWall;
housingTopY = max((leverPivot+rot(maxBit*stepA,[-leverR,leverPivotR+3]))[1] + C, boltTopY+screwD+4) + housingWall;
housingBottomY = -curtainTopR - housingWall*2;

housingTopZ = curtainZ + curtainThickness + layerHeight + housingThickness;
//housingSeamZ = roundToLayerHeight(curtainZ + curtainThickness/2);
housingSeamZ = roundToLayerHeight(boltZ + 2);
lipThickness = roundToLayerHeight(1);

screwOffset = screwD/2+housingWall+2;
screwLocations = [
  [housingLeftX+screwOffset,housingTopY-screwOffset],
  //[housingLeftX+screwOffset,housingBottomY+screwOffset],
  [housingLeftX+screwOffset,(housingBottomY+boltBottomY)/2],
  [housingRightX-screwOffset,housingTopY-screwOffset]];


module housing_outer_profile() {
  rounding = 5;
  translate([(housingLeftX+housingRightX)/2,(housingTopY+housingBottomY)/2])
  rounded_rect(housingRightX-housingLeftX,housingTopY-housingBottomY,rounding);
}

module pivot_pin() {
  linear_extrude(curtainZ + curtainThickness) translate(leverPivot) circle(leverPivotR);
}

module housing(threads=true) {
  difference() {
    //linear_extrude(housingThickness + boltThickness + len(bitting)*leverStep + layerHeight) {
    linear_extrude_cone_chamfer(housingSeamZ, housingChamfer, 0) {
      housing_outer_profile();
    }
    housing_innards(down = false, threads = threads);
    // lip
    translate_z(housingSeamZ - lipThickness)
    linear_extrude(lots,convexity=2) {
      difference() {
        offset(-housingWall) housing_outer_profile();
        circle(r=curtainTopR);
      }
    }
  }
  *linear_extrude(boltThickness) {
    translate(boltLimiterPos) circle(boltLimiterR);
  }
  pivot_pin();
}
*!housing();

tightC = C;

module housing_lip() {
  difference() {
    group() {
      translate_z(housingSeamZ)
      linear_extrude_cone_chamfer(housingTopZ-housingSeamZ, 0, housingChamfer) {
        housing_outer_profile();
      }
      translate_z(housingSeamZ-lipThickness)
      linear_extrude(housingTopZ-(housingSeamZ-lipThickness)-eps,convexity=2) {
        difference() {
          offset(-(housingWall+tightC)) housing_outer_profile();
          circle(r=curtainTopR+tightC);
        }
      }
      // press down on spring hole
      translate_z(boltZ-spacerThickness+layerHeight)
      linear_extrude(housingTopZ-eps-(boltZ-spacerThickness+layerHeight),convexity=2) {
        offset(0.5) offset(-0.5-C)
        spring_hole_profile();
      }
    }
    housing_innards(down = true, threads = false);
    // pivot pin
    linear_extrude(curtainZ + curtainThickness+layerHeight) translate(leverPivot) circle(leverPivotR+tightC);
  }
  // bolt limiter
  translate_z(boltZ+layerHeight)
  linear_extrude(boltThickness + eps) {
    translate(boltLimiterPos) circle(boltLimiterR+C);
  }
  // warding
  translate_z(wardZ) linear_extrude(housingTopZ-1-wardZ) {
    difference() {
      circle(r=wardR);
      circle(r=keyR+C);
      translate([-keyWidth/2-C,-keyHeight]) square([keyWidth+2*C,keyHeight]);
    }
  }
}

module housing_innards(down, threads = true) {
  dz = down ? -lots : 0;
  // keyway
  translate_z(firstLeverZ + dz)
  linear_extrude(housingTopZ-firstLeverZ+eps + lots,convexity=2) {
  //linear_extrude_chamfer_hole(housingTopZ-firstLeverZ+eps + lots, 0, housingChamfer, convexity=2) {
    offset(C) key_profile();
    circle(keyR+C);
  }
  translate_z(housingTopZ-housingChamfer) {
    cylinder(r1=keyR+C,r2=keyR+C+housingChamfer,h=housingChamfer+eps);
  }
  // levers + key
  translate_z(firstLeverZ + dz)
  linear_extrude(leverZ[len(bitting)]+layerHeight - firstLeverZ + lots,convexity=2) {
    // levers
    offset(C) base_lever_profile();
    rotate_around(leverPivot,stepA*maxBit) offset(C) base_lever_profile();
    // key space
    circle(r=keyHeight+C);
  }
  // spring
  translate_z(firstLeverZ + dz)
  linear_extrude(boltZ-spacerThickness+layerHeight - firstLeverZ + lots,convexity=2) {
    spring_hole_profile();
  }
  // lip for curtain
  translate_z(curtainZ + dz)
  linear_extrude(curtainThickness+layerHeight + lots) {
    circle(r=curtainTopR+C);
  }
  // bolt plate
  translate_z(boltZ + dz)
  linear_extrude(boltThickness+layerHeight + lots, convexity=2) {
    offset(C) bolt_base_profile(holes=false);
    translate_x(boltTravel) offset(C) bolt_base_profile(holes=false);
  }
  // bolt
  translate_z(firstLeverZ + dz)
  linear_extrude(boltZ+boltThickness+layerHeight-firstLeverZ + lots, convexity=2) {
    intersection() {
      offset(C) bolt_base_profile(holes=false);
      negative_x2d(); // TODO: do this properly
    }
  }
  // bolt stump countersink
  translate_z(firstLeverZ-boltStumpCountersink + dz)
  linear_extrude(boltZ-firstLeverZ + lots, convexity=2) {
    gate_profile(trueGate=true,includeDrop=false);
    translate_x(-boltStumpWidth-2*C) gate_profile(trueGate=true,includeDrop=false);
  }
  // curtain countersink
  translate_z(keyBottomZ + dz)
  linear_extrude(curtainZ-keyBottomZ + lots, convexity=2) {
    circle(r=curtainR+C);
  }
  // screws
  for (l=screwLocations) {
    translate(l) screw_hole(threads=threads);
  }
}

module screw_hole(threads=true) {
  screw(threads=threads,internal=true);
}
module screw(threads=true, internal=false) {
  c = internal ? C : 0;
  z = housingThickness;
  z2 = housingSeamZ-lipThickness + (internal ? 0 : 2*layerHeight);
  z3 = housingTopZ;
  h1 = roundToLayerHeight(1.5);
  h2 = roundToLayerHeight(0.5);
  difference() {
    intersection() {
      group() {
        translate_z(z) if(threads) {
          standard_thread(d=screwD,length=z2-z+eps,internal=internal,C=c);
        } else {
          cylinder(d=screwD+2*c,h=z3-z);
        }
        translate_z(z2) {
          cylinder(d=screwD+2*c,h=z3-z2-eps);
        }
        translate_z(z3-h1-h2) cylinder(d1=screwD+2*c,d2=screwD+2*c+2*h1,h=h1);
        translate_z(z3-h2) cylinder(d=screwD+2*c+2*h1,h=h2+(internal?eps:0));
      }
      if (!internal) {
        translate_z(z+roundToLayerHeight(1))
        cylinder(d1=screwD-2,d2=screwD+2*lots,h=lots,$fn=90);
      }
    }
    // screw head
    if (!internal) {
      slot_type = "hex";
      if (slot_type == "hex") {
        slotD = 4;
        d = (slotD+2*C)*2/sqrt(3);
        depth = roundToLayerHeight(2.0);
        translate_z(housingTopZ-depth) {
          cylinder(d=d, h=lots, $fn=6);
        }
        translate_z(housingTopZ-depth-1) {
          cylinder(d1=d-2, d2=d, h=1+eps, $fn=6);
        }
        translate_z(housingTopZ-1) {
          cylinder(d1=d-2,d2=d+2, h=1+1);
        }
      }
    }
  }
}
*!screw(threads=true);

module export_housing() { housing(); }
module export_housing_lip() { rotate([180]) translate_z(-housingTopZ) housing_lip(); }
module export_screw() { rotate([180]) translate_z(-housingTopZ) screw(); }

//-----------------------------------------------------------------------------
// Spring
//-----------------------------------------------------------------------------

springWidth = 4;
springHeight = housingTopY - housingWall - C - leverTopY;
springX = -springWidth/2;
/*module spring_profile(angle=0, retainingHole=true) {
  translate([0,leverTopY]) {
    square([springWidth,springHeight]);
  }
}*/
module base_spring_hole_profile() {
  translate([springX-C,leverTopY-C]) {
    square([springWidth+2*C,springHeight+2*C]);
  }
}
module spring_hole_profile_wiggle() {
  base_spring_hole_profile();
  // some clearance where levers meet the housing
  r = 1;
  offset(-r) union() {
    offset(r) base_spring_hole_profile();
    rotate_around(leverPivot,maxBit*stepA) translate_y(leverTopY) square([lots,2*r],true);
  }
}

module spring_wiggle() {
  springThickness = leverZ[len(bitting)] - leverZ[0] - 2*C;
  translate([springX,leverTopY,firstLeverZ])
  linear_extrude_x(springWidth) {
    spring_profile(springHeight, springThickness, turns=6);
  }
}

module spring_hole_profile() {
  if (spring_type == "wiggle") {
    spring_hole_profile_wiggle();
  } else if (spring_type == "flat_circle") {
    spring_hole_profile_flat_circle();
  } else {
    spring_hole_profile_flat();
  }
}
module spring(pos = 0) {
  if (spring_type == "wiggle") {
    spring_wiggle();
  } else if (spring_type == "flat_circle") {
  } else {
    translate_z(firstLeverZ) linear_extrude(boltZ - firstLeverZ) {
      rotate_around(springPivot,lerp(springRestAngle,springFlexedAngle,pos)-springAngle)
      spring_profile_flat();
    }
  }
}

//-----------------------------------------------------------------------------
// Spring v3
//-----------------------------------------------------------------------------

spring3_pos = [housingRightX-screwD*2-2,housingTopY - housingWall - C - 5];
spring3R = 3;

module spring_hole_profile_flat_circle() {
  springTopY = housingTopY - housingWall - C;
  translate(spring3_pos+[spring3R,0]) {
    square([springThickness,springTopY-spring3_pos[1]]);
  }
  translate(spring3_pos) difference() {
    wedge(a1=0,a2=-90,r=spring3R+springThickness);
    wedge(a1=0,a2=-90,r=spring3R);
  }
}

//-----------------------------------------------------------------------------
// Test
//-----------------------------------------------------------------------------

module housing_test() {
  color("LightYellow")
  intersection() {
    housing(threads = false);
    translate_z(firstLeverZ-5*layerHeight)
    linear_extrude(lots, convexity=2) {
      offset(C + 0.89) {
        base_lever_profile();
        rotate_around(leverPivot,stepA*maxBit) base_lever_profile();
        spring_hole_profile();
      }
    }
  }
}
*!housing_test();

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly_cut(e) {
  intersection() {
    children();
    *translate_x(e*eps) positive_x();
  }
}

module assembly() {
  $fn = 60;
  //keyAngle = -180 - 45;
  //keyAngle = -180 + 30;
  //keyAngle = boltStartMoveAngle;
  keyAngle = -180 - 0;
  //keyAngle = 0;
  leverPos = 1;
  boltPos = bolt_pos(keyAngle);
  threads = false;

  color("white") assembly_cut(1) rotate(keyAngle) key();

  color("LightYellow") assembly_cut(2) housing(threads=threads);
  *color("Yellow") assembly_cut(3) housing_lip();
  *color("LightYellow") assembly_cut(4) pivot_pin();
  if (0) {
    translate_x(housingLeftX-housingRightX)
    color("yellow") housing_lip();

    translate_x(2*(housingLeftX-housingRightX))
    color("LightYellow") housing(threads=false);
  }

  *color("green") assembly_cut(5) translate_x(boltPos) translate_z(layerHeight*0.8) bolt();

  color("salmon") assembly_cut(6) rotate(keyAngle) translate_z(layerHeight*0.9) curtain();

  // spring
  color("blue") spring();
  
  // levers
  function lever_color(i) = [1-0.0*i,(i%2)*0.4+i*0.1,(i%2)*0.4+i*0.1];
  for (i=[0:len(bitting)-1]) {
    translate_z(leverZ[i])
    color(lever_color(i)) assembly_cut(8+i) lever(bitting[i], pos=leverPos*lever_angle(bitting[i]));
  }

  // spacers
  for (i=[0:len(bitting)-1]) {
    translate_z(leverZ[i] + leverThickness)
    color("lightblue") assembly_cut(30+i) {
      if (ward_after_lever(i)) {
        warded_spacer();
      } else {
        spacer();
      }
    }
  }
}

assembly();
