//=============================================================================
// Eurocylinder with a twist
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

C = 0.125;

housingR = 17/2;
coreR = 13/2;
faceR = coreR+0.75;
faceThicknessA = 0.75;
faceThicknessB = 0.5;
bibleWidth = 10;
bibleHeight = 33-17/2;

pins = 5;
pinD = 3;
pinSep = 1;
firstSep = 3;
lastSep = 3;

housingDepth = firstSep + pins*pinD + (pins-1)*pinSep + lastSep;
clipThickness = 1;
clipR = coreR - 1;
tailDepth = 2;

keyWidth = 2;
keyHeight = 8.4;
keyBowR = 12;
keyBowHoleR = 3;
keyBowHoleSep = 3;

bittingOffset = -1.5;
//bitting=[1,2,3,4,5];
bitting=[3,1,5,4,2];
step=0.55;

// twist per mm in z direction
// Note: rotate is in opposite direction of twist!
twist = -80/25;
res = 1; // resolution of twist

function pin_pos(i) = firstSep + i*(pinD+pinSep) + pinD/2;

//-----------------------------------------------------------------------------
// lock profile
//-----------------------------------------------------------------------------

module housing_profile() {
  difference() {
    union() {
      circle(r=housingR);
      translate([-bibleWidth/2,0]) square([bibleWidth,bibleHeight-bibleWidth/2], center=false);
      translate([0,bibleHeight-bibleWidth/2]) circle(r=bibleWidth/2);
    }
    circle(r=coreR+C);
  }
}
module housing() {
  difference() {
    linear_extrude(housingDepth, convexity=10, twist=twist*housingDepth) housing_profile();
    translate([0,0,-eps]) cylinder(r=faceR,h=faceThicknessB+C);
    for (i=[0:pins-1]) {
      rotate(-twist*pin_pos(i))
      translate([0,0,pin_pos(i)]) rotate([-90]) cylinder(d=pinD,h=bibleHeight+1);
    }
  }
}
//!housing();

//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

module key_profile1() {
  w=keyWidth;
  h=keyHeight;
  translate([-w/2,-coreR])
  polygon([
    [0,0],[0,1.3],[w/2,1.5],[w/2,2.3],[0,3.5],[0,5.4],[w/2,5.6],[0,h],
    [w/2+0.1,h],[w,6.2],[w,4.5],[w/2,4.3],[w,3],[w,0]
  ]);
}
module key_profile(y=0,top=0,s=0.5) {
  w=keyWidth;
  h=keyHeight + top;
  l=w*s;
  r=w-w*s;
  translate([-w/2,-coreR])
  polygon([
    [0,y],[0,1.3],[l,1.5],[l,2.3],[0,3.0],[0,5.0],[l,5.8],[0,h],
    [r,h],[w,6.2],[w,5.2],[r,4.2],[r,3.8],[w,3.2],[w,y]
  ]);
}
//!key_profile();

//-----------------------------------------------------------------------------
// core
//-----------------------------------------------------------------------------

module core() {
  coreDepth = housingDepth + tailDepth + clipThickness;
  difference() {
    //cylinder(r=coreR,h=coreDepth);
    union() {
      translate([0,0,-faceThicknessA]) cylinder(r1=coreR,r2=faceR,h=faceThicknessA);
      cylinder(r=faceR,h=faceThicknessB);
      cylinder(r=coreR,h=housingDepth);
      //translate([0,0,housingDepth-0.5]) cylinder(r=coreR,r2=clipR,h=1);
      translate([0,0,housingDepth])   cylinder(r=clipR,r2=clipR,h=clipThickness);
      translate([0,0,housingDepth+1]) cylinder(r=coreR,h=tailDepth);
    }
    // clip
    // actuator
    translate([0,0,housingDepth-1]) cylinder(r=4,h=100);
    rotate(-twist*(housingDepth-1))
      translate([0,0,housingDepth-1]) 
        linear_extrude(10,twist=twist*10,convexity=10, slices=res*10*abs(twist))
          square([3,coreR*2+1],true);
    // keyway
    h = faceThicknessA + coreDepth+2*eps;
    translate([0,0,-faceThicknessA-eps])
    rotate(-twist*(-faceThicknessA-eps))
    linear_extrude(h,convexity=10, twist=twist*h, slices=res*h*abs(twist)) {
      offset(r=C) {key_profile(-2);}
    }
    // pins
    for (i=[0:pins-1]) {
      rotate(-twist*pin_pos(i))
      translate([0,-1.5,pin_pos(i)])
        rotate([-90])
          cylinder(d=pinD,h=bibleHeight+1);
    }
  }
}
//!core();

module rotate_test() {
  linear_extrude(10,twist=90) {
    square([10,2]);
  }
  for (z=[1:10]) {
    rotate(-z/10*90)
    translate([10,0,z]) color("red") cube([1,1,1],true);
  }
}
//!rotate_test();

//-----------------------------------------------------------------------------
// key
//-----------------------------------------------------------------------------

module key() {
  h=housingDepth;
  difference() {
    z = 0;
    rotate(-twist*z)
    translate([0,0,z])
    linear_extrude(h-z, convexity=10, twist=twist*(h-z), slices=res*(h-z)*abs(twist)) {
      key_profile();
    }
    for (i=[0:pins-1]) {
      w = 0.5; // halfwidth of pin flat
      rotate(-twist*pin_pos(i))
      translate([0,bittingOffset+bitting[i]*step,pin_pos(i)]) {
        linear_extrude_x(4,true) {
          sym_polygon_y([[10,-10-w],[0,-w]]);
        }
      }
    }
    w=0.5;
    h=housingDepth+1;
    rotate(-twist*h)
    translate([0,-3.5,h]) {
      linear_extrude_x(4,true) {
        sym_polygon_x([[10,10],[10,-10+w],[w,0]]);
      }
    }
  }
  steps=10;
  for (i=[1:steps]) {
    z = i*3/steps;
    h = 1;
    rotate(-twist*-z)
    translate([0,0,-z])
    linear_extrude(h, convexity=10, twist=twist*h, slices=res*h*abs(twist)) {
      //translate([-keyWidth/2,-coreR]) square([keyWidth,keyHeight+3]);
      translate([-keyWidth/2,keyHeight-coreR]) square([keyWidth,2]);
      key_profile(s=0.5-0.5*i/steps);
    }
  }
  // bow
  x = -coreR+(keyHeight)/2;
  y = -keyBowR-0.4;
  rotate(-twist*-3)
  linear_extrude_x(keyWidth,true) {
    difference() {
      x = -coreR+(keyHeight)/2;
      y = -keyBowR-0.4;
      //translate([-coreR+(keyHeight)/2,-keyBowR]) circle(keyBowR);
      //translate([x,y]) scale([1,0.9]) circle(keyBowR);
      //translate([x,y]) square(keyBowR*1.6,true);
      translate([x,y]) chamfer_rect(keyBowR*1.7,keyBowR*1.7,4);
      translate([x-keyHeight/2,-3]) square(keyHeight);
      translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR);
    }
  }
  color("darkgrey")
  rotate(-twist*-3)
  linear_extrude_x(keyWidth+0.4,true) {
    difference() {
      translate([x,y]) chamfer_rect(keyBowR*1.7,keyBowR*1.7,4);
      translate([x,y]) chamfer_rect(keyBowR*1.7-2,keyBowR*1.7-2,4-1);
      //translate([x-keyHeight/2,-3]) square(keyHeight);
    }
    difference() {
      translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR+1);
      translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR);
    }
  }
  color("darkgrey")
  rotate(-twist*-3)
  translate([0,x,0])
  group() {
    rotated([0,0,180])
    translate_x((keyWidth+0.4)/2)
    linear_extrude_x((keyWidth+0.4)/2,false) {
      translate([0,y+4])
      text("twist",5,font="Ubuntu",halign="center",valign="center");
    }
  }
}
!key();

//-----------------------------------------------------------------------------
// testing
//-----------------------------------------------------------------------------

housing();
translate([20,0,0]) color("pink") core();
translate([40,0,0]) color("lightgreen") key();

//-----------------------------------------------------------------------------
// Export
//-----------------------------------------------------------------------------

module export_key() { key(); }
module export_housing() { housing(); }
module export_core() { core(); }
