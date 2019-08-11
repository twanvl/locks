//=============================================================================
// Magnetic split lock
// by Twan van Laarhoven
// inspired by acslxs
//  https://old.reddit.com/r/lockpicking/comments/coigqa/could_you_pick_that_lock/
//=============================================================================

include <../util.scad>
include <../gear.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

bitting = [0,2,1,3,0,2,1];
layerHeight = 0.15;
function roundToLayerHeight(z) = round(z/layerHeight)*layerHeight;

eps = 0.01;
C = 0.125; // clearance
tightC = C/2;

keyR = 6.5/2;
keyD0 = roundToLayerHeight(2);
keyD1 = roundToLayerHeight(5);
keyD2a = roundToLayerHeight(1.5);
keyD2b = roundToLayerHeight(1);
keyD2 = keyD2a+keyD2b;
keyD3 = roundToLayerHeight(1);
keyD4 = roundToLayerHeight(1.5);
magnetR = 4/2;
//magnetDepth = roundToLayerHeight(2.65);
magnetDepth = roundToLayerHeight(0.875*2);
magnetSep = 2*layerHeight;

bitDepth = roundToLayerHeight(2);
bitSep = roundToLayerHeight(1);
bitStep = 0.5;
maxBit = 3;

gearPitch = 3.6;
gearDR = 0.3; // depth ratio
gearPA = 25; // pressure angle
gearTeeth1 = 10;
gearTeeth2 = 17;
gearHelix = 20;

axis = gear_radius(gearTeeth2,gearPitch) - gear_radius(gearTeeth1,gearPitch);
echo("shift: ",2*axis);
core1R = keyR*2/sqrt(3) + 1.2;
core2R = gear_outer_radius(gearTeeth2,gearPitch,gearPA,gearDR) + 1.2;
core3Ra = axis+keyR;
//core3Rb = core3Ra + 3;
core3Rb = core2R;
housingR = core2R + 1.5;

pinW1 = 6;
pinW2 = pinW1+2;
pinTravel = maxBit*bitStep+C;
pinLen = 0.5+pinTravel;

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module inset(r) {
  difference() {
    union() children();
    offset(-r) union() children();
  }
}
module linear_extrude_x_inset(a,b,r,center=true) {
  linear_extrude_x(a,center) children();
  linear_extrude_x(b,center) inset(r) children();
}

module keyHandle() {
  h0 = roundToLayerHeight(2);
  h0b = 0.5;
  h1 = keyD0 + keyD1;
  h2 = roundToLayerHeight(19);
  
  translate_z(-h2/2 - h0) 
  linear_extrude_x_inset(3,keyR*2/sqrt(3),1) {
    difference() {
      //chamfer_rect(h2,h2,4);
      intersection() {
        //circle(r=11);
        offset(2) circle(r=11,$fn=6);
        //square([lots,h2],true);
      }
      translate_y(-4) 
      intersection() {
        offset(1) circle(r=2.5,$fn=6);
        //circle(r=4);
        //square([lots,6],true);
      }
    }
  }
  
  linear_extrude_x(keyR*2/sqrt(3),true) {
    translate([0,-h0/2]) square([(core1R-1)*2,h0],true);
  }
  translate_z(-h0b)
  difference() {
    //cylinder(r=keyR,h=5);
    group() {
      cylinder(r=keyR*2/sqrt(3),h=h0b+h1,$fn=6);
      translate_z(-keyR*2)
      cylinder(r1=0,r2=keyR*2/sqrt(3),h=keyR*2,$fn=6);
    }
    translate_z(h0b+h1-magnetDepth-magnetSep)
    cylinder(r=magnetR+C,h=magnetDepth);
  }
}
module keyActuator() {
  h3 = keyD2;
  difference() {
    union() {
      //cylinder(r=keyR*2/sqrt(3),h=2,$fn=6);
      cylinder(r=keyR,h=keyD2);
      for (i=[0:len(bitting)-1]) {
        translate_z(h3+i*(bitDepth+bitSep)) {
          cylinder(r=keyR - bitting[i]*bitStep,h=bitDepth);
          translate_z(bitDepth)
          cylinder(r1=keyR - bitting[i]*bitStep, r2=keyR - (i+1==len(bitting) ? 0 : bitting[i+1])*bitStep,h=bitSep);
        }
      }
      translate_z(h3+len(bitting)*(bitDepth+bitSep)) {
        cylinder(r=keyR,h=keyD3);
        translate_z(keyD3) cylinder(r1=keyR,r2=1,h=roundToLayerHeight(keyR-1));
      }
    }
    translate_z(magnetSep) cylinder(r=magnetR+C,h=magnetDepth);
  }
}
module keyTest() {
  keyHandle();
  translate_z(keyD0+keyD1) keyActuator();
}
//keyTest();

module export_key_bottom() { keyHandle(); }
module export_key_top() { keyActuator(); }

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module core1() {
  rG = gear_outer_radius(gearTeeth1,gearPitch,gearPA,gearDR);
  r1 = core1R;
  r2 = rG;
  difference() {
    group() {
      cylinder(r = r1, h = keyD0);
      translate_z(keyD0-roundToLayerHeight(1)) cylinder(r = r1+1, h = roundToLayerHeight(1));
      
      translate_z(keyD0)
      intersection() {
        gear(gearTeeth1, gearPitch, gearPA, gearDR, 0, gearHelix, gear_thickness=keyD1);
        //cylinder(r1 = r1, r2=r1+keyD1+1, h = keyD1+1);
      }
    }
    translate_z(-eps) cylinder(r=keyR*2/sqrt(3)+C,h=keyD0+keyD1+2*eps,$fn=6);
  }
}
keyEnd = keyD3+roundToLayerHeight(keyR-1);
keyD = len(bitting)*(bitDepth+bitSep) + keyEnd;
module core2(a=true,b=true) {
  translate_z(keyD0) {
    difference() {
      union() {
        if (a)
        cylinder(r=core2R, h=keyD1+keyD2a);
        //translate_y(-axis)
        if (b)
        translate_z(keyD1) {
          cylinder(r=core3Ra, h=keyD2+keyD-roundToLayerHeight(1.2));
          translate_z(keyD2+keyD-roundToLayerHeight(1.2))
          cylinder(r1=core3Ra, r2=core3Ra-(1.2), h=roundToLayerHeight(1.2));
          // limiter
          intersection() {
            linear_extrude(keyD2a+roundToLayerHeight(2)*2) {
              wedge(180-20,180+20,center=true,r=core3Ra+2);
            }
            union() {
              cylinder(r=core3Ra+2,h=keyD2a+roundToLayerHeight(2)+eps);
              translate_z(keyD2a+roundToLayerHeight(2))
                cylinder(r1=core3Ra+2,r2=core3Ra,h=roundToLayerHeight(2));
            }
          }
        }
      }
      rotate(0)
      gear(gearTeeth2, gearPitch, gearPA, gearDR, -C, gearHelix, keyD1);
      
      translate_y(-axis) {
        //cylinder(r=keyR+C,h=keyD1+keyD2+keyD+eps-roundToLayerHeight(keyR-1.5));
        //translate_z(keyD1+keyD2+keyD-roundToLayerHeight(keyR-1.5))
        //cylinder(r1=keyR+C,r2=1+C,h=roundToLayerHeight(keyR-1)+eps);
        cylinder(r=keyR+C,h=lots);
      }
      translate_y(-axis - keyR+1.5) translate_z(keyD1+keyD2a+lots) negative_y();
    }
  }
}
module core3() {
  translate_z(keyD0+keyD1+keyD2a) {
    difference() {
      cylinder(r=core3Rb, h=keyD+keyD4+keyD2b);
      translate_z(-eps) cylinder(r=core3Ra+C, h=keyD+keyD2b+2*eps-roundToLayerHeight(1));
      translate_z(keyD+keyD2b-roundToLayerHeight(1)-eps) 
        cylinder(r1=core3Ra+C, r2=core3Ra-(1)+C, h=roundToLayerHeight(1)+2*eps);
      // limiter
      intersection() {
        linear_extrude(roundToLayerHeight(2)*2+layerHeight) {
          wedge(180-20,180+20+180,center=true,r=core3Ra+2+C+eps);
        }
        union() {
          cylinder(r=core3Ra+2+C,h=roundToLayerHeight(2)+eps);
          translate_z(roundToLayerHeight(2))
            cylinder(r1=core3Ra+2+C,r2=core3Ra,h=roundToLayerHeight(2));
        }
      }
      // outer limiter
      translate_z(keyD+keyD2-roundToLayerHeight(2)*2)
      difference() {
        linear_extrude(roundToLayerHeight(2)*2+eps) {
          wedge(180-15,180+15+180,center=true,r=core3Rb+1-C+eps);
        }
        group() {
          translate_z(roundToLayerHeight(2))
          cylinder(r=core3Rb-2,h=roundToLayerHeight(2));
          cylinder(r2=core3Rb-2,r1=core3Rb,h=roundToLayerHeight(2));
        }
      }
      // pins
      translate([-(pinW1+2*C)/2,core3Ra+C-pinTravel,keyD2b-layerHeight+pinPos]) 
        cube([pinW1+2*C,6,len(bitting)*(bitDepth+bitSep)]);
      for (i=[0:len(bitting)-1]) {
        translate_z(keyD2b+i*(bitDepth+bitSep)-layerHeight+pinPos) {
          translate_y(core3Ra+C-pinTravel+pinLen)
          linear_extrude_y(lots) pin_profile(C=C,h=layerHeight+eps);
        }
      }
    }
  }
}

module export_core1() { core1(); }
module export_core2() { core2(); }
module export_core3() { core3(); }

module core2Connector() {
  sym_polygon_x([[3,0.5],[5,-0.8],[6,-0.2],[3,5]]);
}
module export_core2a() {
  difference() {
    core2(true,false);
    translate_z(keyD0+keyD1-eps) linear_extrude(keyD2a+2*eps) {
      core2Connector();
    }
  }
}
//!export_core2a();
module export_core2b() {
  intersection() {
    core2(false,true);
    translate_z(keyD0+keyD1+keyD2a+eps) positive_z();
  }
  translate_z(keyD0+keyD1) linear_extrude(keyD2a+2*eps) {
    core2Connector();
  }
}
//!export_core2b();

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

back = roundToLayerHeight(1);
bible = 10;
bibleW = pinW2+2*1.2+1;

module housing(a=false,b=true) {
  difference() {
    group() {
      if (a) {
        translate_z(keyD0+keyD1/2-eps)
        cylinder(r=housingR, h=keyD1/2+keyD2+keyD+keyD4+layerHeight+back+eps);
        translate([-bibleW/2,core3Rb,keyD0+keyD1+keyD2a-2]) cube([bibleW,bible,keyD+keyD2b+keyD4+2+layerHeight+back]);
      }
      if (b) {
        cylinder(r=gear_inner_radius(gearTeeth2,gearPitch,gearPA,gearDR), h=keyD0+keyD1+2*eps);
        cylinder(r=housingR, h=keyD0+keyD1/2+1-3*eps);
      }
    }
    // gear walls
    if (true) {
      translate_z(-eps) translate_y(-axis) {
        cylinder(r=core1R + C, h=keyD0+2*eps);
        translate_z(keyD0-roundToLayerHeight(1)) 
        cylinder(r=core1R + 1 + C, h=roundToLayerHeight(1));
      }
      translate_z(keyD0-eps)
      difference() {
        cylinder(r=core2R + C, h=keyD1+keyD2a+layerHeight+2*eps);
        if (b)
        difference() {
          cylinder(r=gear_inner_radius(gearTeeth2,gearPitch,gearPA,gearDR) - C, h=keyD1+2*eps);
          translate_y(-axis) cylinder(r=gear_outer_radius(gearTeeth1,gearPitch,gearPA,gearDR) + C, h=keyD1+4*eps);
        }
      }
    }
    // fancy mating parts
    if (!b) {
      translate_z(keyD0+keyD1/2-eps) {
        intersection() {
          linear_extrude(1) rotated([0,90,180,270]) {
            wedge(45,center=true,r=housingR+1);
          }
          cylinder(r1=housingR,r2=core2R,h=1);
        }
        difference() {
          translate_z(-eps) linear_extrude(1) rotate(45) rotated([0,90,180,270]) {
            wedge(45,center=true,r=housingR+1);
          }
          cylinder(r2=housingR,r1=core2R,h=1);
        }
      }
    } else if (!a) {
      translate_z(keyD0+keyD1/2-eps) {
        difference() {
          linear_extrude(1) rotated([0,90,180,270]) {
            difference() {
              wedge(45,center=true,r=housingR+1);
              circle(core2R);
            }
          }
          cylinder(r1=housingR,r2=core2R,h=1);
        }
        intersection() {
          translate_z(-eps) linear_extrude(1) rotate(45) rotated([0,90,180,270]) {
            difference() {
              wedge(45,center=true,r=housingR+1);
              circle(core2R);
            }
          }
          cylinder(r2=housingR,r1=core2R,h=1);
        }
      }
    }
    // core hole
    translate_z(keyD0+keyD1+keyD2a-eps) {
      difference() {
        cylinder(r=core3Rb + C, h=keyD+keyD2b+keyD4+layerHeight+2*eps);
        // limiter
        translate_z(keyD+keyD2-roundToLayerHeight(4-2*C))
        difference() {
          linear_extrude(lots) {
            wedge(-15,+15,center=true,r=core3Rb+1-C+eps);
          }
          group() {
            translate_z(-eps)
            cylinder(r2=core3Rb-2+C,r1=core3Rb+C,h=roundToLayerHeight(2));
            translate_z(roundToLayerHeight(2)-2*eps)
            cylinder(r=core3Rb-2+C,h=roundToLayerHeight(2)+2*eps);
          }
        }
      }
      cylinder(r=core3Rb - 5 + C, h=lots);
    }
    // pins
    for (i=[0:len(bitting)-1]) {
      translate_z(keyD0+keyD1+keyD2+i*(bitDepth+bitSep)+pinPos) {
        translate_y(core3Rb-5)
        //linear_extrude_y(bible-1+5,convexity=5)
        linear_extrude_y(bible+6,convexity=5)
          pin_profile(C=C,h=layerHeight+eps,clearance=true);
      }
    }
    // pin cover
    translate_z(keyD0+keyD1+keyD2a-2-eps)
    linear_extrude(keyD+keyD2b,convexity=5) {
      sym_polygon_x([[bibleW/2-2,core3Rb+bible+eps],[bibleW/2-1.2,core3Rb+bible-1.2]]);
    }
  }
}
module bibleCover() {
  translate_z(keyD0+keyD1+0.5)
  linear_extrude(keyD+keyD2b,convexity=5) {
    sym_polygon_x([[bibleW/2-2-tightC,core3Rb+bible+eps],[bibleW/2-1.2-tightC,core3Rb+bible-1.2]]);
  }
}
module export_housing() { housing(); }
module export_housing_a() { housing(true,false); }
module export_housing_b() { housing(false,true); }
module export_bible_cover() { bibleCover(); }

//-----------------------------------------------------------------------------
// Springs and pins
//-----------------------------------------------------------------------------

module pin_profile(C=0,h=0,clearance=false) {
  dx = 1;
  dy = roundToLayerHeight(0.8);
  l = roundToLayerHeight(0.3);
  h = bitDepth+bitSep-layerHeight+h;
  w = pinW2;
  sym_polygon_x([
    clearance ? [-w/2-C+dx+0.6*dx,-0.6*dy] : [-w/2-C+dx,0],
    [-w/2-C,dy],[-w/2-C,h-l-dy],[-w/2-C+dx,h-l],[-w/2-C+dx,h]]);
}
module keyPin(bit) {
  difference() {
    translate([-pinW1/2,core3Ra+C/2-1,0]) {
      cube([pinW1,pinLen+1,bitDepth+bitSep-layerHeight]);
    }
    cylinder(r=core3Ra+C,h=bitDepth+bitSep+2*eps);
    d = roundToLayerHeight(0.7);
    translate_z(-eps) cylinder(r1=core3Ra+C+d,r2=core3Ra+C,h=d);
    translate_z(bitDepth+bitSep-layerHeight-d+eps) cylinder(r2=core3Ra+C+d,r1=core3Ra+C,h=d);
    // chamfer
    mirrored([1,0,0])
    linear_extrude(bitDepth+bitSep,convexity=5)
    sym_polygon_xy([[pinW1,0],[pinW1,core3Ra+C],[pinW1/2,core3Ra+C+pinLen],[pinW1/2-2,core3Ra+C-2]]);
  }
  intersection() {
    translate([0,core3Ra+C/2 + pinLen,0]) {
      //cube([pinW2,lots,bitDepth+bitSep-layerHeight]);
      linear_extrude_y(lots) pin_profile();
    }
    translate_y(bitStep*bit)
    translate_z(-eps)
    cylinder(r=core3Rb+eps,h=bitDepth+bitSep+2*eps);
  }
}
module driverPin(bit) {
  difference() {
    translate([0,core3Rb+C+bitStep*bit-3,0])
      //cube([pinW2,4+3-bitStep*bit,bitDepth+bitSep-layerHeight]);
      linear_extrude_y(4+3-bitStep*bit) {
        pin_profile();
      }
    
    translate_y(bitStep*bit)
    translate_z(-eps)
    cylinder(r=core3Rb+C,h=bitDepth+bitSep+2*eps);
  }
}

//-----------------------------------------------------------------------------
// Test
//-----------------------------------------------------------------------------
pinPos = -(bitSep)/2+layerHeight;

module test() {
  key = true;
  core = true;
  pins = false;
  housing = true;
  rot = 180-1;
  rot2 = 0;
  b = 0*max(0,(rot/180)*4-3);
  rot1 = -(rot+rot2)*gearTeeth2/gearTeeth1;
  Cy = layerHeight/4;
  intersection() {
    group() {
      if (key) {
        translate_y(-axis) rotate(-rot1) color("orange") keyHandle();
        rotate(rot+rot2) color("pink") translate_y(-axis) translate_z(keyD0+keyD1+2*Cy) keyActuator();
      }
      if (core) {
        translate_z(Cy) translate_y(-axis) rotate(-rot1) color("lightgreen") core1();
        translate_z(2*Cy) rotate(rot+rot2) color("lightblue") core2();
        translate_z(3*Cy) rotate(rot2) color("lightsalmon") core3();
      }
      if (pins)
      //*for (i=[0:len(bitting)-1]) {
      for (i=[0:2]) {
        translate_z(keyD0+keyD1+keyD2+i*(bitDepth+bitSep) + pinPos) {
          rotate(rot2) translate_y(-b*bitStep*bitting[i]) {
            color("blue") keyPin(bitting[i]);
          }
          translate_y(-b*bitStep*bitting[i]) {
            color("red") driverPin(bitting[i]);
          }
        }
      }
      if (housing) {
        color("yellow") housing(true,true);
        *color("yellow") housing(false,true);
        *translate_z(layerHeight) color("green") housing(true,false);
        color("purple") bibleCover();
      }
    }
    positive_x();
    *positive_y();
    *translate_z(31) negative_z();
    *translate_z(keyD0+keyD1+keyD2) positive_z();
  }
}
test();