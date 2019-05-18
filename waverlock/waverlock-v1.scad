//=============================================================================
// Waverlock: a wavy waferlock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

eps = 0.01;
C = 0.1; // clearnace

coreR = 9;
useCoreBack = false;

//wafers = 12;
wafers = 3;
waferThickness = 2;
waferThicknessLast = 4;
waferStep = waferThickness+C;
waferWidth = 10;
waferWidthExt = waferWidth+2;
tabWidth = 9;
tabSlope = 0.2;

faceR = coreR+1;
faceThickness = 2;

housingR = coreR+3;

keyWidth = 7;
keyDelta = 2;
keyHeight = 1.8;

toothSlope = 1;
keyC = C; // vertical clearance in keyhole
keyCX = 0.2; // horizontal clearance in keyhole (not critical)
keyHolePos = 0;

connectorR=1.25;
connectorPos=-5;

bitting = [3,1];
//step = 0.5;
step = 0.6;
//minBit = -4; maxBit = 4;
minBit = -3; maxBit = 3;
//minBit = -2; maxBit = 4;
//minBit = -1; maxBit = 5;
//minBit = 0; maxBit = 6;
bits = maxBit-minBit+1;
maxDelta = 3;

tabC = 0.5; // Clearance on side of tabs
tabCY = 2*C; // Clearance above tabs
tabR = coreR + (bits-1)*step + tabCY;

//-----------------------------------------------------------------------------
// Keyway
//-----------------------------------------------------------------------------

module key_profile(delta=0) {
  dx=2*delta*keyDelta/keyWidth;
  dy=delta;
  rotate([90,0,0])
  rotate([0,90])
  linear_extrude(eps,convexity=10) {
    polygon([
      [-keyDelta/2-dx,-keyWidth/2-dy],
      [keyDelta/2,0],
      [-keyDelta/2-dx,keyWidth/2+dy],
      [-keyDelta/2-dx+eps,keyWidth/2+dy],
      [keyDelta/2+eps,0],
      [-keyDelta/2-dx+eps,-keyWidth/2-dy]
    ]);
  }
}
module extrude_key(delta=0) {
  minkowski() {
    linear_extrude(eps) children();
    key_profile(delta);
  }
}
module key_hole(delta=keyCX) {
  l=0;
  rotate([0,-90,0])
  extrude_key(delta=delta) {
    polygon([
      [-l, keyHeight/2+keyC+toothSlope*(1+l)],
      [1,  keyHeight/2+keyC+toothSlope*0],
      [1.5,keyHeight/2+keyC+toothSlope*0],
      [2,  keyHeight/2+keyC+toothSlope*0.5],
      [2,  -keyHeight/2-keyC-toothSlope*0.5],
      [1.5,-keyHeight/2-keyC-toothSlope*0],
      [1,  -keyHeight/2-keyC-toothSlope*0],
      [-l, -keyHeight/2-keyC-toothSlope*(1+l)],
    ]);
  }
}
module last_key_hole(delta=keyCX) {
  l = 10; r = 10;
  rotate([0,-90,0])
  extrude_key(delta=delta) {
    sym_polygon_y([
      [-l, keyHeight/2+keyC+toothSlope*l],
      [0,  keyHeight/2+keyC+toothSlope*0],
      [r,  keyHeight/2+keyC+toothSlope*0],
    ]);
  }
}
//!key_hole();

//-----------------------------------------------------------------------------
// Wafer connector pins
//-----------------------------------------------------------------------------

connectorPos=0;

//module connector_halfpin(C=0) cylinder(r=3+C,h=1);
//module connector_halfpin(C=0) cube([2+2*C,6+2*C,2],true);
module connector_halfpin(C=0) {
  a = 1.5;
  h = 1.2;
  linear_extrude_y(6+2*C,true) {
    sym_polygon_x([[-a-C, 0], [-a-C+h,h]]);
  }
}

module connector_pin(C=0) {
  if (false) {
    union() {
      cylinder(r=connectorR+C,h=1-0.2);
      cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
      translate([0,0,1-0.2]) cylinder(r1=connectorR+C,r2=connectorR-0.2+C,h=0.2);
    }
  } else {
    group() {
      translate([0,coreR,0]) connector_halfpin();
      translate([0,-coreR,0]) connector_halfpin();
    }
  }
}

module connector_slot(bit=3) {
  a = -maxDelta*step;
  b = maxDelta*step;
  if (true) {
    group() {
      hull() {
        translate([0,coreR+a,0]) connector_halfpin(C);
        translate([0,coreR+b,0]) connector_halfpin(C);
      }
      hull() {
        translate([0,-coreR+a,0]) connector_halfpin(C);
        translate([0,-coreR+b,0]) connector_halfpin(C);
      }
    }
  } else {
    hull() {
      translate([0,a,0]) cylinder(r=connectorR+C,h=1);
      translate([0,b,0]) cylinder(r=connectorR+C,h=1);
    }
    hull() {
      translate([0,a,0]) cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
      translate([0,b,0]) cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
    }
  }
}

//-----------------------------------------------------------------------------
// Wafers
//-----------------------------------------------------------------------------

module wafer_profile1(C=C) {
  rotate([90,0,0])
  linear_extrude(coreR*2+eps,center=true)
  polygon([
    [-waferWidth/2,-waferThickness/2-C],
    [-waferWidthExt/2-C,0],
    [-waferWidth/2,waferThickness/2+C],
    [waferWidth/2,waferThickness/2+C],
    [waferWidthExt/2+C,0],
    [waferWidth/2,-waferThickness/2-C]
  ]);
}
module wafer_profile(C=C,CX=C) {
  offset = 0.6;
  a = 0.6 + 2*C;
  b = a + offset;
  linear_extrude_y(coreR*2+eps,center=true,convexity=2)
  polygon([
    [-waferWidth/2-CX-offset,0],
    [-waferWidth/2-CX-offset,a],
    [-waferWidth/2-CX,b],
    [-waferWidth/2-CX,waferThickness+C],
    [waferWidth/2+CX,waferThickness+C],
    [waferWidth/2+CX,b],
    [waferWidth/2+CX+offset,a],
    [waferWidth/2+CX+offset,0],
  ]);
}
module last_wafer_profile(C=C,CX=C) {
  offset = 0.6;
  thickness = waferThicknessLast;
  a = 0.6 + 2*C;
  w = thickness+C-a-offset;
  linear_extrude_y(coreR*2+eps,center=true,convexity=2)
  polygon([
    [-waferWidth/2-CX-offset,0],
    [-waferWidth/2-CX-offset,a],
    [-waferWidth/2-CX+w,thickness+C],
    [waferWidth/2+CX-w,thickness+C],
    [waferWidth/2+CX+offset,a],
    [waferWidth/2+CX+offset,0],
  ]);
}

module wafer_profiles(C=C,CX=C) {
  for (i = [0:wafers-1]) {
    translate([0,0,i*waferStep]) {
      wafer_profile(C+eps,CX=CX);
    }
  }
  translate([0,0,wafers*waferStep]) {
    last_wafer_profile(C+eps,CX=CX);
  }
}
module wafer_outer() {
  intersection() {
    wafer_profile(C=0);
    cylinder(r=coreR,waferThickness,center=true);
  }
}
module tab_profile(width=tabWidth,height=2*coreR) {
  x = width/2 - tabSlope*height/2;
  polygon([
    [-width/2,-height/2],
    [-x,0],
    [-width/2,height/2],
    [width/2,height/2],
    [x,0],
    [width/2,-height/2],
  ]);
}
//!linear_extrude(waferThickness,true) tab_profile();
//connectorR=2;connectorO=[0,0,-0.5];

module wafer(bit, minBit=minBit, maxBit=maxBit, slot=true, pin=true, tabs=true) {
  y = bit*step;
  thickness = waferThickness;
  difference() {
    union() {
      // tabs
      if (tabs) intersection() {
        linear_extrude(thickness) tab_profile();
        cylinder(r=coreR,thickness);
      }
      // profile
      intersection() {
        wafer_profile(C=0);
        translate([0,y-maxBit*step,0]) cylinder(r=coreR,thickness);
        translate([0,y-minBit*step,0]) cylinder(r=coreR,thickness);
      }
      // connector
      if (pin) {
        intersection() {
          translate([0,y+connectorPos,waferThickness]) connector_pin();
          if (tabs) {
            cylinder(r=coreR,thickness+2);
          } else {
            intersection() {
              translate([0,y-maxBit*step,0]) cylinder(r=coreR,thickness+2);
              translate([0,y-minBit*step,0]) cylinder(r=coreR,thickness+2);
            }
          }
        }
      }
    }
    translate([0,y+keyHolePos,-eps/2])
      key_hole();
    // connectorSlot
    if (slot) {
      translate([0,y+connectorPos,-eps]) connector_slot(bit);
    }
  }
  //translate([2,y+connectorPos,waferThickness/2]) connector_slot(bit);
}
module first_wafer(bit) {
  wafer(0,minBit=max(minBit,bit-3),maxBit=min(maxBit,bit+3),slot=false,tabs=false);
}
module last_wafer(bit=0) {
  //wafer(bit,pin=false);
  //wafer(0,minBit=0,maxBit=0,pin=false);  
  thickness = 2*waferThickness;
  y = 0;
  difference() {
    intersection() {
      last_wafer_profile(C=0);
      cylinder(r=coreR,thickness);
    }
    translate([0,y+keyHolePos,1-eps/2]) last_key_hole();
    translate([0,y+connectorPos,-eps]) connector_slot(bit);
  }
}
module wafers() {
  wafer(minBit);
  //translate([0,0,3]) wafer(minBit+3);
  //translate([0,0,3]) wafer(maxBit);
  //translate([0,0,2]) wafer(4);
  translate([20,0,0]) wafer(0);
  translate([40,0,0]) wafer(maxBit);
  translate([60,0,0]) first_wafer(0);
  translate([80,0,0]) last_wafer(0);
  translate([-20,0,0]) wafer(minBit+1);
}
module waferTest() {
  intersection() {
    group() {
      wafer(minBit);
      //color("lightgreen") translate([0,0,2+C]) wafer(minBit+3);
      color("lightgreen") translate([0,-0*step,2+C]) wafer(minBit+3);
      color("pink") translate([0,-6*step,2*waferStep]) wafer(maxBit);
      color("lightyellow") translate([0,0*step,3*waferStep]) wafer(maxBit-3);
      color("lightyellow") translate([0,6*step,4*waferStep]) wafer(minBit);
    }
    //translate([50,0,0]) cube([100,100,100],center=true);
    translate([1,0,0]) cube([2,100,100],center=true);
  }
}
//!waferTest();
//!wafers();

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module face_plate() {
  sideChamfer = 0.5;
  difference() {
    rotate_extrude() {
      polygon([[0,faceThickness],[0,0],[faceR-1,0],[faceR,1],[faceR,faceThickness]]);
    }
    translate([0,keyHolePos,-eps/2]) {
      key_hole();
      // chamfer sides
      intersection() {
        key_hole(delta=keyCX+sideChamfer);
        w=(keyWidth+2*sideChamfer)/sqrt(2);
        rotate([0,45,0]) cube([w,10,w],center=true);
      }
    }
  }
}
module core(C=C,CX=C) {
  stackHeight = wafers * waferStep + waferThicknessLast;
  union() {
    face_plate();
    translate([0,0,faceThickness])
    intersection() {
      difference() {
        linear_extrude(stackHeight + 2) {
          circle(coreR);
        }
        // space for wafers
        translate([0,0,-eps])
        wafer_profiles(C=C,CX=CX);
        /*
        // chamfer for wafer inner part
        h = wafers * waferStep - waferStep/2 + C-2*eps;
        cube([waferWidth + 0.5,2*coreR,2*h],center=true);
        */
        // chamfer for wafer slots
        ww = waferWidth/2 + 0.6 + CX;
        y = sqrt(coreR*coreR-ww*ww); // where wafer slots end
        h = wafers * waferStep + C-2*eps;
        chamfer = 0.5;
        translate([0,-y-chamfer,0])cube([waferWidthExt,2*chamfer,2*h],center=true);
        translate([0,y+chamfer,0])cube([waferWidthExt,2*chamfer,2*h],center=true);
        // top chamfer for printability
        //h2 = wafers * waferStep -2*eps + 0.6;
        h2 = stackHeight;
        ww2 = waferWidth/2 + 0.6 + 0.6 - waferThicknessLast + C*2;
        y2 = sqrt(coreR*coreR-ww2*ww2);
        linear_extrude_x(2*coreR,true) {
          polygon([[y2,h2],[y2+10,h2+10],[y2+10,h2]]);
          polygon([[-y2,h2],[-y2-10,h2+10],[-y2-10,h2]]);
        }
      }
    }
    if (useCoreBack)
    translate([0,0,faceThickness + stackHeight + 2]) {
      translate([0,0,0]) cylinder(r1=coreR-1,r2=coreR-1,h=1);
      translate([0,0,1]) cylinder(r1=coreR-1,r2=coreR,h=1);
      translate([0,0,2]) cylinder(r1=coreR,r2=coreR,h=2);
    }
  }
};

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module housing_tabslot(tabC=0.5) {
  intersection() {
    tab_profile(height=2*tabR, width=tabWidth+2*(tabR-coreR)*tabSlope + tabC);
    circle(tabR);
  }
}
module housing(tabC1=0.4,tabC2=0.8) {
  waferSpace=5;
  faceCountersink=1;
  housingHeight = faceThickness-faceCountersink + wafers * waferStep + C + 2;
  difference() {
    /*
    linear_extrude(housingHeight) {
      //square([2*housingR,2*housingR+3],center=true);
      /*hull() {
        translate([0,-waferSpace,0]) circle(housingR);
        translate([0,waferSpace,0]) circle(housingR);
      }* /
      //fillet(10) square([2*housingR,2*housingR+waferSpace],center=true);
      chamfer_rect(2*housingR,2*housingR+waferSpace,1);
    }*/
    translate([0,0,housingHeight/2])
    chamfer_cube(2*housingR,2*housingR+waferSpace,housingHeight,1);
    
    // core
    translate([0,0,-eps]) cylinder(r=coreR+C,h=housingHeight+2*eps);
    // face
    translate([0,0,-eps]) cylinder(r=faceR+C,h=faceCountersink+2*eps);
    // tab slots
    // Note: slightly wider slots towards the front, to make back wafers bind first
    // Note: first wafer and last two wafers are alignment wafers, and don't need tab slots, but include a half slot for some clearance
    for(i=[0:wafers-1]) {
      a = i/(wafers-1);
      translate([0,0,i*waferStep+faceCountersink+1-C])
      linear_extrude(waferThickness+2*C) {
        housing_tabslot((1-a)*tabC1 + a*tabC2);
      }
    }
    /*
    translate([0,0,-eps]) linear_extrude(housingHeight+2*C) {
      housing_tabslot(tabC);
    }*/
  }
}

//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

//color("grey") translate([0,0,faceThickness-1]) housing();


core();
//intersection() {core(); cube(2*32,true);}

if (false) {
translate([0,step*3,faceThickness+waferThickness/2+C/2]) color("red") wafer(minBit+3);
translate([0,step*6,faceThickness+waferThickness/2+C/2+waferStep]) color("red") wafer(minBit+0);
translate([0,-step*6,faceThickness+waferThickness/2+C/2+waferStep*2]) color("blue") wafer(minBit+6);
translate([0,-step*0,faceThickness+waferThickness/2+C/2+waferStep*3]) color("green") wafer(minBit+6);
translate([0,step*1,faceThickness+waferThickness/2+C/2+waferStep*4]) color("limegreen") wafer(minBit+5);
}

//-----------------------------------------------------------------------------
// Export
//-----------------------------------------------------------------------------

module labled_core(CX,label) {
  lbl = label==undef ? str(CX) : label;
  core();
  stackHeight = wafers * waferStep + waferThicknessLast;
  translate([0,0,faceThickness + stackHeight + 2]) linear_extrude(0.2)
    text(lbl,size=5,font="Ubuntu",halign="center",valign="center");
 }
 
module export_wafer0() { wafer(minBit+0); }
module export_wafer1() { wafer(minBit+1); }
module export_wafer2() { wafer(minBit+2); }
module export_wafer3() { wafer(minBit+3); }
module export_wafer4() { wafer(minBit+4); }
module export_wafer5() { wafer(minBit+5); }
module export_wafer6() { wafer(minBit+6); }
module export_first_wafer() { first_wafer(); }
module export_last_wafer() { last_wafer(); }
module export_core() { core(); }
module export_coretest_wide() { labled_core(CX=C);  }
module export_coretest_narrow() { labled_core(CX=C/2);  }
module export_housing() { housing(); }
module export_core_small() { core(); }
