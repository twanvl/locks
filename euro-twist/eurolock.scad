//=============================================================================
// Eurocylinder with a twist
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;
include <../threads.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

C = 0.15;

housingR = 17/2;
coreR = 13/2;
faceR = coreR+0.75;
faceThicknessA = 0.8;
faceThicknessB = 1.1;
bibleWidth = 10;
bibleHeight = 33-17/2;

pins = 5;
pinD = 3.1;
pinSep = 4;
firstSep = 3 + 3/2;
lastSep = 2 - 3/2;

housingDepth = firstSep + pins*pinSep + lastSep;
clipThickness = 1.2;
clipR = coreR - 1.1;
tailDepth = 2;

keyWidth = 2;
keyHeight = 8.4;
keyBowR = 12;
keyBowHoleR = 3;
keyBowHoleSep = 3;
keyC = 0.2;

bittingOffset = -1.5;
//bitting=[1,2,3,4,5];
bitting=[3,1,5,4,2];
step=0.55;

// twist per mm in z direction
// Note: rotate is in opposite direction of twist!
//twist = -40/25;
//twist = -80/25;
twist = -120/25;
//twist = 0;
res = 1; // resolution of twist
bibleExtend = abs(twist) > 2 ? abs(twist) : 0; // extend bible to account for twisting

function pin_pos(i) = firstSep + i*pinSep;

//-----------------------------------------------------------------------------
// lock profile
//-----------------------------------------------------------------------------

module housing_profile() {
  step = $fn == undef || $fn == 0 ? 1 : 360/$fn;
  difference() {
    union() {
      circle(r=housingR);
      if (bibleExtend == 0) {
        translate([-bibleWidth/2,0]) square([bibleWidth,bibleHeight-bibleWidth/2], center=false);
        translate([0,bibleHeight-bibleWidth/2]) circle(r=bibleWidth/2);
      } else {
        sym_polygon_x(concat(
          [[0,0],
           rot(-bibleExtend,[-bibleWidth/2,0]),
           rot(-bibleExtend,[-bibleWidth/2,bibleHeight-bibleWidth/2])],
          [for (a=[0:step:90]) rot(-bibleExtend,[0,bibleHeight-bibleWidth/2] + bibleWidth/2*polar(180-a)) ],
          [for (a=[-bibleExtend:step:0]) rot(a,[0,bibleHeight]) ]
        ));
        }
    }
    circle(r=coreR+C);
  }
}

module housing() {
  difference() {
    linear_extrude(housingDepth, convexity=10, twist=twist*housingDepth) housing_profile();
    translate([0,0,-eps]) cylinder(r=faceR+C,h=faceThicknessB+C);
    for (i=[0:pins-1]) {
      rotate(-twist*pin_pos(i)) {
        translate([0,0,pin_pos(i)]) rotate([-90]) cylinder(d=pinD,h=bibleHeight+1);
        if (true) {
          screwHeight = 4;
          translate([0,bibleHeight-screwHeight,pin_pos(i)]) rotate([-90])
          //cylinder(d=4,h=screwHeight);
          m4_thread(screwHeight,C=C,internal=true);
        }
      }
    }
  }
}
//!housing();

module grub_screw() {
  rotate([180])
  difference() {
    m4_thread(3.5, leadin=1); 
    // 2mm hex key
    translate_z(-eps) cylinder(d=2/cos(180/6)+C,$fn=6,h=1.5);
  }
}

//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

module key_profile(y=0,top=0,s=0.5) {
  // s=0 gives a rectangle, s=0.5 gives key profile, in between interpolates
  w=keyWidth;
  h=keyHeight + top;
  l=w*s;
  r=w-w*s;
  intersection() {
    translate([-w/2,-coreR])
    polygon([
      [0,y],[0,1.3],[l,1.5],[l,2.3],[0,3.0],[0,5.0],[l,5.8],[0,h],
      [r,h],[w,6.2],[w,5.2],[r,4.2],[r,3.8],[w,3.2],[w,y]
    ]);
    circle(coreR-y);
  }
}
//!key_profile();

module test_key_profile() {
  C=0.2;
  translate_z(-1) color("lightgreen") linear_extrude(1) circle(coreR);
  translate_z(1) linear_extrude(1) key_profile(0,0,0.5);
  color("red") linear_extrude(1) offset(r=C) {key_profile(-2);}
}
//!test_key_profile();

//-----------------------------------------------------------------------------
// core
//-----------------------------------------------------------------------------

clipC = 0.1;
coreDepth = housingDepth + tailDepth + clipThickness + clipC;

module core() {
  difference() {
    //cylinder(r=coreR,h=coreDepth);
    union() {
      translate([0,0,-faceThicknessA]) cylinder(r1=coreR,r2=faceR,h=faceThicknessA);
      cylinder(r=faceR,h=faceThicknessB);
      cylinder(r=coreR,h=housingDepth+clipC);
      //translate([0,0,housingDepth-0.5]) cylinder(r=coreR,r2=clipR,h=1);
      translate([0,0,housingDepth+clipC])   cylinder(r=clipR,r2=clipR,h=clipThickness);
      translate([0,0,housingDepth+clipC+clipThickness]) cylinder(r=coreR,h=tailDepth);
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
      offset(r=keyC) {key_profile(-2);}
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

module twisted(z1,z2, twist=twist) {
  if (twist == 0) {
    children();
  } else {
    step = 0.05;
    for (z=[z1:step:z2-eps]) {
      rotate(-twist*z)
      intersection() {
        group() children();
        translate([-lots/2,-lots/2,z]) cube([lots,lots,min(step,z2-z)]);
      }
    }
  }
}

module key(twistBow=true) {
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
  flatSize = 3 + faceThicknessA;
  steps = flatSize/0.05;
  for (i=[1:steps]) {
    z = i*flatSize/steps;
    h = flatSize/steps;
    rotate(-twist*-z)
    translate([0,0,-z])
    linear_extrude(h, convexity=10, twist=twist*h, slices=res*h*abs(twist)) {
      //translate([-keyWidth/2,-coreR]) square([keyWidth,keyHeight+3]);
      if (z-h>=faceThicknessA+C) translate([-keyWidth/2,keyHeight-coreR]) square([keyWidth,2]);
      key_profile(s=0.5-0.5*i/steps);
    }
  }
  // bow
  x = -coreR+(keyHeight+2)/2;
  y = -keyBowR*1.7/2 - flatSize;
  //rotate(-twist*-3) group() {
  twisted(y-keyBowR*1.7/2, y+keyBowR*1.7/2, twistBow ? twist : 0) {
    linear_extrude_x(keyWidth,true) {
      difference() {
        //translate([-coreR+(keyHeight)/2,-keyBowR]) circle(keyBowR);
        //translate([x,y]) scale([1,0.9]) circle(keyBowR);
        //translate([x,y]) square(keyBowR*1.6,true);
        translate([x,y]) chamfer_rect(keyBowR*1.7,keyBowR*1.7,4);
        translate([x-keyHeight/2,-3]) square(keyHeight);
        translate([x,y-keyBowR*0.9+keyBowHoleSep+keyBowHoleR]) circle(keyBowHoleR);
      }
    }
    color("darkgrey")
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
    translate([0,x,0])
    group() {
      rotated([0,0,180])
      linear_extrude_x((keyWidth+0.4)/2,false) {
        translate([0,y+4])
        text("twist",5,font="Ubuntu",halign="center",valign="center");
      }
    }
  }
}
//!key();

module key_with_brim() {
  flatSize = 3 + faceThicknessA;
  bow = keyBowR*1.7;
  x = -coreR+(keyHeight+2)/2;
  translate_z(bow+flatSize) key();
  translate_y(x) scale([1,1.2,1]) cylinder(r=10,h=0.12);
}
//!key_with_brim();

//-----------------------------------------------------------------------------
// clip
//-----------------------------------------------------------------------------

module clip() {
  r1 = clipR+C;
  r2 = clipR+2;
  gap = 60;
  rotate(90)
  linear_extrude(clipThickness - 0.1) {
    difference() {
      circle(r2);
      circle(r1);
      //translate_y(r2/2)square([gap+r2-r1,housingR],true);
      wedge(gap,center=true);
      translate_x(-r1+1) circle(1.5);
    }
    translate(polar(gap/2,(r1+r2)/2)) circle((r2-r1)/2);
    translate(polar(-gap/2,(r1+r2)/2)) circle((r2-r1)/2);
  }
}
//!clip();

//-----------------------------------------------------------------------------
// testing
//-----------------------------------------------------------------------------

module test_parts() {
  housing();
  translate([20,0,0]) color("pink") core();
  translate([40,0,0]) color("lightgreen") key();
}

module test_together() {
  $fn=20;
  intersection() {
    group() {
      housing();
      color("pink") core();
      color("lightgreen") key(false);
      translate_z(housingDepth+clipC/2) rotate(-twist*housingDepth) color("blue") clip();
    }
    //positive_x();
    //translate_z(1)positive_z();
  }
}
test_together();
//test_parts();

//-----------------------------------------------------------------------------
// Export
//-----------------------------------------------------------------------------

module export_key() { key(); }
module export_key_with_brim() { key_with_brim(); }
module export_housing() { housing(); }
module export_core() { core(); }
module export_clip() { clip(); }
