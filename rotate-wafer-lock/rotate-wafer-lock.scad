//

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

bitting = [-1,0,1,-0.5];

coreR = 15 / 2;
waferWidth = 9.5;
waferThickness = roundToLayerHeight(2);
sepThickness = roundToLayerHeight(2);

keyWidth   = 6;
keyHeight1 = roundToLayerHeight(2.2);
keyHeight2 = roundToLayerHeight(keyHeight1 + 0.3);
keyHeight3 = keyHeight1+0;
//keyHeight2 = keyHeight1;
keyChamfer = 0.35;
step = keyWidth/2-keyHeight3/2;

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_profile(C=0) {
  translate_x(-(keyHeight1-2*keyChamfer)/2) chamfer_rect(keyWidth+2*C-(keyHeight1-2*keyChamfer),keyHeight1+2*C,keyChamfer);
  translate_x((keyWidth-keyHeight1)/2) offset(delta=C) key_bit_profile();
}
*!key_profile();

module key_bit_profile(bit=0) {
  translate_x(bit*step) {
    //square([keyHeight1,keyHeight1],true);
    //circle(keyHeight1/2);
    intersection() {
      h = keyHeight1;
      w = keyHeight3;
      chamfer_rect(w,h,keyChamfer);
      // make sure that the shape can be rotated
      //translate([w/2,-h/2+keyChamfer]) scale([w/h,1]) circle(r=h);
      //translate([w/2-keyChamfer,-h/2]) scale([w/h,1]) circle(r=h);
      translate([-w/2,-h/2+keyChamfer]) scale([w/h,1]) circle(r=h);
      translate([-w/2+keyChamfer,-h/2]) scale([w/h,1]) circle(r=h);
    }
  }
}

module key_profile_test_wafer() {
  linear_extrude(waferThickness) {
    difference() {
      intersection() {
        translate_y(step) circle(r = coreR);
        translate_y(-step) circle(r = coreR);
        square([waferWidth,lots],true);
      }
      //translate_y(-(keyHeight2-keyHeight1)*0.5)
      key_profile(C=eps);
    }
  }
}

// point where bottom of keyway touches key at given angle
//function dy(a) = -1*sin(a) * (keyHeight2/2 - keyChamfer);
function dy(a) = min(-keyHeight1/2,min(
  rot(a, [keyHeight3/2 - keyChamfer, -keyHeight1/2])[1],
  rot(a, [keyHeight3/2, -keyHeight1/2 + keyChamfer])[1]))
  + keyHeight1/2;
module key_profile_test() {
  bit = 1;
  a = 10;
  rotate(a) linear_extrude(sepThickness) key_profile();
  translate_y(bit*step * sin(a)) {
  translate_x(bit*step * cos(a))
  rotate(a) color("red") linear_extrude(10) key_bit_profile();
  //color("yellow") rotate(0) key_profile_test_wafer();
  translate_z(3) color("yellow") translate_y(dy(a)) key_profile_test_wafer();
  }
}
!key_profile_test();

module key() {
  for (i=[0:len(bitting)-1]) {
    translate_z(i*(waferThickness+sepThickness)+C/2)
    linear_extrude(sepThickness-C) key_profile();
    translate_z(i*(waferThickness+sepThickness)+sepThickness-C/2-eps)
    linear_extrude(waferThickness+C+2*eps) key_bit_profile(bitting[i]);
  }
  h1 = 3;
  linear_extrude(C+eps) {
    key_profile();
  }
  translate_z(-(h1+4)) {
    linear_extrude(h1+4-C/2) {
      intersection() {
        circle(r = keyHoleR);
        chamfer_rect(2*keyHoleR,keyHeight1,keyChamfer);
      }
    }
  }
  translate_z(-h1) key_handle();
}
module key_handle() {
  w = 16; // handle
  r = 2.5; // hole
  translate_z(-w/2)
  rotate([90]) {
    difference() {
      group() {
        cylinder(r=w/2,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=w/2,r2=w/2-keyChamfer,h=keyChamfer);
      }
      translate_y(-3.5)
      group() {
        cylinder(r=r,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=r,r2=r+keyChamfer,h=keyChamfer+2*eps);
      }
    }
  }
}

*!key();

module export_key() { rotate([90]) key(); }
*!export_key();

//-----------------------------------------------------------------------------
// Wafers
//-----------------------------------------------------------------------------

gateC = C/2;
falseGate = 0.2;

module wafer(bit) {
  linear_extrude(waferThickness, convexity=2) {
    difference() {
      intersection() {
        translate_y(step) circle(r = coreR);
        translate_y(-step) circle(r = coreR);
        square([waferWidth,lots],true);
      }
      translate_y(-(keyHeight3-keyHeight1)*0.5)
      offset(delta=C) key_profile();
      // gate
      translate_y(-bit*step) offset(delta=gateC) sidebar_profile();
      for (i=[-1:0.5:1]) {
        if (abs(i-bit)>=1)
        translate_y(-i*step) offset(delta=gateC) sidebar_profile(1 - falseGate);
      }
    }
  }
}
*!wafer(-1);

spacerR = waferWidth/2 + 0.0;
limiterThickness = roundToLayerHeight(sepThickness/2);
module spacer() {
  for (limiter = [0,1]) {
    translate_z(limiter ? sepThickness-limiterThickness : 0)
    linear_extrude(limiter ? limiterThickness : sepThickness, convexity=2) {
      difference() {
        union() {
          circle(r = spacerR);
          if (limiter) spacer_limiter_profile();
        }
        translate_y(-(keyHeight3-keyHeight1)*0.5)
        offset(delta=C) key_profile();
        rotate(-90) offset(C) sidebar_profile();
      }
    }
  }
}
spacerLimiterR = sqrt(2)*spacerR - 0.5;
module spacer_limiter_profile() {
  intersection() {
    circle(r = spacerLimiterR);
    square(waferWidth,true);
    //square(spacerR);
    rotate(-45) square([2,lots],true);
  }
}

module spacer_slot(C=0) {
  z1 = roundToLayerHeight(sepThickness * 0.2);
  z2 = roundToLayerHeight(sepThickness * 0.7);
  z3 = roundToLayerHeight(sepThickness * 1) - layerHeight;
  x = waferWidth/2+C;
  x2 = x + z2-z1;
  mirrored([1,0,0]) rotated(180) {
    translate_y(side_given_diagonal(spacerLimiterR+C,waferWidth/2)) {
      linear_extrude_y(coreR) {
        polygon([[x,z1],[x2,z2],[x2,z3],[x,z3]]);
      }
    }
  }
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module core_profile(part_slots) {
  difference() {
    circle(r=coreR);
    square([waferWidth+2*C,lots],true);
    translate_x(-lots/2) square([lots,sidebarThickness+C],true);
    if (part_slots) square([waferWidth+2+C,6+C],true);
  }
}
module core() {
  h = len(bitting)*(waferThickness+sepThickness) + layerHeight;
  h1 = len(bitting)/2*(waferThickness+sepThickness);
  coreBack = roundToLayerHeight(1);
  difference() {
    group() {
      linear_extrude(h1, convexity=4) {
        core_profile(true);
      }
      translate_z(h1) linear_extrude(h-h1, convexity=4) {
        core_profile(false);
      }
    }
    for (i=[2:len(bitting)-1]) {
      translate_z(i*(waferThickness+sepThickness)) {
        tightC = C/2;
        spacer_slot(tightC);
      }
    }
  }
  *translate_z(h) linear_extrude(coreBack) {
    circle(r=coreR);
  }
}

module core_part(x_slot=false, z_slot=true) {
  tightC = C/2;
  difference() {
    linear_extrude(sepThickness + waferThickness, convexity=2) {
      difference() {
        union() {
          intersection() {
            circle(r=coreR);
            square([waferWidth+2*C-2*tightC,lots],true);
          }
          //translate_x(waferWidth/2) square([2,6],true);
          if (x_slot) {
            square([waferWidth+2,6],true);
          }
        }
        circle(r=spacerR+C);
        translate_x(-lots/2) square([lots,sidebarThickness+C],true);
      }
    }
    translate_z(sepThickness - layerHeight) {
      linear_extrude(lots) {
        square([waferWidth+2*C+2*eps,lots],true);
      }
    }
    translate_z(sepThickness - limiterThickness - layerHeight) {
      linear_extrude(lots, convexity=2) {
        rotated(90) offset(delta=C) spacer_limiter_profile();
        rotated(180) rotate(45) wedge(90,r=spacerLimiterR+C);
      }
    }
  }
  if (z_slot) {
    intersection() {
      spacer_slot();
      cylinder(r=coreR-eps, h=sepThickness);
    }
  }
}

sidebarThickness = roundToLayerHeight(2.0);
sidebarChamfer = sidebarThickness/2;//0.8;
sidebarChamfer2 = 0.6;
sidebarTravel = 0.7;
module sidebar_profile(pos = 0) {
  x = side_given_diagonal(coreR,sidebarThickness/2);
  w = x - waferWidth/2 + sidebarTravel;
  translate_x(-pos*sidebarTravel) intersection() {
    circle(r=coreR);
    union() {
      translate_x(w/2 - x) {
        chamfer_rect(w,sidebarThickness,sidebarChamfer);
      }
      translate_x(sidebarThickness/2 - x) {
        chamfer_rect(sidebarThickness,sidebarThickness,sidebarChamfer2);
      }
    }
  }
}
module sidebar(pos = 0) {
  h = len(bitting)*(waferThickness+sepThickness);
  linear_extrude(h) {
    sidebar_profile(pos);
  }
}

module export_core() { rotate([180]) core(); }
module export_core_part() { core_part(); }
module export_sidebar() { rotate([90]) sidebar(); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

keyHoleR = diagonal(keyWidth/2,keyHeight1/2-keyChamfer) + 0.0;
module housing() {
  t = roundToLayerHeight(1.5);
  w = (coreR+C+0.8);
  rotate(45) translate_z(-t) linear_extrude(t+eps) {
    difference() {
      chamfer_rect(2*w,2*w,2);
      circle(r=keyHoleR+C);
    }
  }
  h = len(bitting)*(waferThickness+sepThickness) + layerHeight;
  translate_z(-t) linear_extrude(h+t) {
    difference() {
      union() {
        circle(r=w);
        offset(C+0.8) sidebar_profile(1);
      }
      circle(r=coreR+C);
      offset(C) sidebar_profile(1);
    }
  }
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly() {
  anim = 100;
  angle = min(90,anim);
  sidebarPos = 1 - min(1,max(0,anim-90)/10);
  
  *color("lightyellow") housing();
  color("lightblue") core();
  color("Aquamarine") core_part(true,false);
  color("Aquamarine") translate_z(2*(waferThickness+sepThickness)) core_part(false,true);
  color("pink") rotate(angle) key();
  color("DarkViolet") sidebar(sidebarPos);
  color("lightgreen") for (i=[0:len(bitting)-1]) {
    translate_z(i*(waferThickness+sepThickness)+sepThickness)
    translate_y(dy(angle) + bitting[i] * step * sin(angle))
    wafer(bitting[i]);
  }
  color("lightsalmon") for (i=[0:len(bitting)-1]) {
    translate_z(i*(waferThickness+sepThickness))
    rotate(angle)
    spacer();
  }
}

!assembly();