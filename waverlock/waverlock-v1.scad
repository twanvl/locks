//=============================================================================
// Waverlock: a wavy waferlock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

eps = 0.01;
C = 0.1; // clearance
CX = 0.08; // clearance in x and y directions
tightC = 0.05;
bridgeC = 1; // clearance for bridges

coreR = 9;
useCoreBack = false;

//wafers = 12;
wafers = 3;
waferThickness = 2;
waferThicknessLast = 4;
waferStep = waferThickness+C;
waferWidth = 10;
waferLip = 0.6;
tabWidth = 8;
tabSlope = 0.3;

faceR = coreR+1;
faceThickness = 2;

keyWidth = 7;
keyDelta = 2;
keyHeight = 1.8;

toothSlope = 1;
keyC = C; // vertical clearance in keyhole
keyCX = 0.2; // horizontal clearance in keyhole (not critical)
keyHolePos = 0;

connectorR=1.25;
connectorPos=-5;
pinC = 2.5*C; // it is critical that there is enough clearance, better to have too much

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

tabC = 0.4; // Clearance on side of tabs
tabCtwist = 2; // extra clearance on back wafers
tabCY = 2*C; // Clearance above tabs
tabR = coreR + (bits-1)*step + tabCY;

waferSpace=5;
housingRX = coreR+3;
housingRY = housingRX + waferSpace;

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
module connector_halfpin(C=0,CX=0,dh=0) {
  a = 1.2;
  h = 1.2-dh;
  linear_extrude_y(6+2*CX,true) {
    //sym_polygon_x([[-a-C, 0], [-a-C+h,h]]);
    sym_polygon_x([[-a-C, 0], [-a+h,h+C]]);
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
      translate([0,coreR,0]) connector_halfpin(dh=0.2);
      translate([0,-coreR,0]) connector_halfpin(dh=0.2);
    }
  }
}

module connector_slot(bit=3) {
  a = -maxDelta*step;
  b = maxDelta*step;
  CX = 0.05; // clearance in movement direction
  if (true) {
    group() {
      hull() {
        translate([0,coreR+a,0]) connector_halfpin(pinC,CX=CX);
        translate([0,coreR+b,0]) connector_halfpin(pinC,CX=CX);
      }
      hull() {
        translate([0,-coreR+a,0]) connector_halfpin(pinC,CX=CX);
        translate([0,-coreR+b,0]) connector_halfpin(pinC,CX=CX);
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
  waferWidthExt = waferWidth+2;
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
module wafer_profile(C=0,CX=0) {
  a = waferLip + 2*C;
  b = a + waferLip;
  linear_extrude_y(coreR*2+eps,center=true,convexity=2)
  sym_polygon_x([
    [-waferWidth/2-CX-waferLip,0],
    [-waferWidth/2-CX-waferLip,a],
    [-waferWidth/2-CX,b],
    [-waferWidth/2-CX,waferThickness+C]
  ]);
}
module last_wafer_profile(C=0,CX=0,bridgeC=0) {
  thickness = waferThicknessLast;
  a = waferLip + 2*C;
  w = thickness+C-a-waferLip;
  linear_extrude_y(coreR*2+eps,center=true,convexity=2)
  sym_polygon_x([
    [-waferWidth/2-CX-waferLip,0],
    [-waferWidth/2-CX-waferLip,a],
    [-waferWidth/2-CX+w+bridgeC,thickness+C+bridgeC]
  ]);
}

module wafer_profiles(C=C,CX=CX) {
  for (i = [0:wafers-1]) {
    translate([0,0,i*waferStep]) {
      wafer_profile(C+eps,CX=CX);
    }
  }
  translate([0,0,wafers*waferStep]) {
    last_wafer_profile(C+eps,CX=CX,bridgeC=bridgeC);
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
        wafer_profile();
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
module first_wafer(bit=0) {
  wafer(0,minBit=max(minBit,bit-3),maxBit=min(maxBit,bit+3),slot=false,tabs=false);
}
module last_wafer(bit=0) {
  //wafer(bit,pin=false);
  //wafer(0,minBit=0,maxBit=0,pin=false);  
  thickness = 2*waferThickness;
  y = 0;
  difference() {
    intersection() {
      last_wafer_profile();
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
  translate([60,0,0]) first_wafer();
  translate([80,0,0]) last_wafer();
  translate([-20,0,0]) wafer(minBit+1);
}
module waferTest() {
  intersection() {
    group() {
      wafer(minBit);
      color("lightgreen") translate([0,-6*step,2+C]) wafer(minBit+3);
      //color("lightgreen") translate([0,-0*step,2+C]) wafer(minBit+3);
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

coreBack = 2;
clipSep = 0.8;
coreBackOverlap = 1;
coreStackHeight = wafers * waferStep + waferThicknessLast + bridgeC - coreBackOverlap;

module core(C=C,CX=C) {
  union() {
    face_plate();
    translate([0,0,faceThickness])
    intersection() {
      difference() {
        union() {
          cylinder(r=coreR,h=coreStackHeight);
          translate_z(coreStackHeight) cylinder(r1=coreR,r2=coreR-coreBack,h=coreBack);
          translate_z(coreStackHeight+coreBack) cylinder(r=clipCoreR,h=clipH+clipSep);
        }
        // slots for wafers
        translate([0,0,-eps])
        wafer_profiles(C=C,CX=CX);
        // chamfer for wafer slots
        ww = waferWidth/2 + waferLip + CX;
        y = sqrt(coreR*coreR-ww*ww); // where wafer slots end
        h = wafers * waferStep + C-2*eps;
        chamfer = 0.5;
        translate([0,-y-chamfer,0])cube([2*coreR,2*chamfer,2*h],center=true);
        translate([0,y+chamfer,0])cube([2*coreR,2*chamfer,2*h],center=true);
        // top chamfer for printability
        if (false) {
          //h2 = wafers * waferStep -2*eps + waferLip;
          h2 = coreStackHeight + bridgeC + C;
          ww2 = waferWidth/2 + waferLip + waferLip - waferThicknessLast + C*2 - bridgeC;
          y2 = sqrt(coreR*coreR-ww2*ww2);
          linear_extrude_x(2*coreR,true) {
            mirrored([1,0,0])
            polygon([[y2,h2],[y2+10,h2+10],[y2+10,h2]]);
          }
        }
        // slot for retaining clip
        translate_z(coreStackHeight+coreBack+clipSep)
          linear_extrude_x(2*coreR,true) retaining_clip_profile(C=tightC,bridgeC=bridgeC);
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
//!core();

//-----------------------------------------------------------------------------
// Retaining clip
//-----------------------------------------------------------------------------

clipR = coreR+1.5;
clipW = 8;
clipCoreR = coreR-2;
clipH = 4.5;

module retaining_clip_profile(C=0,bridgeC=0) {
  h = 2 + bridgeC;
  sym_polygon_x([[clipW/2+C,0], [clipW/2+C,waferLip], [clipW/2+C-h,h+waferLip]]);
}
module retaining_clip_connector(clip=true) {
  e = clip ? 0 : tightC;
  if (clip)
  intersection() {
    linear_extrude_y(2*clipR+2,true) {
      retaining_clip_profile();
    }
    cylinder(r=clipCoreR,h=clipH);
    // snap connector
    linear_extrude(clipH,convexity=10) {
      pinR = 0.5;
      pos = clipCoreR-3;
      difference() {
        union() {
          translate([0,-clipR]) square([10,2*clipR]);
          translate([0,pos]) circle(r=pinR);
        }
        translate([0,-pos]) circle(r=pinR+0.1);
        slot = pos*1.0;
        translate([0.8,0]) square([pinR,slot+pinR]);
        translate([0,slot+pinR]) square([0.8+pinR,0.2]);
      }
    }
  }
  difference() {
    union() {
      intersection() {
        linear_extrude_y(2*clipR+2,true) {
          xLip= clip ? 0.3 : 0;
          w = 2.3;
          polygon([[w+e,0],[w+e,waferLip],[xLip,w+e+waferLip-xLip],[0,w+e+waferLip-xLip],[0,0]]);
        }
        difference() {
          cylinder(r=clipR-1+e,h=clipH);
          cylinder(r=clipCoreR-eps,h=clipH);
        }
        //cylinder(r=clipR-1,h=clipH);
      }
    }
  }
  s = clipH*0.4 + e/2;
  translate([-(clipR+clipCoreR)/2,-eps,clipH/2])
  rotate([-90]) cylinder(r1=s,r2=0,h=s,$fn=7);
}
module retaining_clip_ring() {
  union() {
    //cylinder(r=clipR,h=clipH);
    d = 0.9;
    lip = waferLip;
    a = (clipH-2*d-lip)/2;
    cylinder(r=clipR-d,h=clipH);
    cylinder(r=clipR,h=a);
    translate_z(a) cylinder(r1=clipR,r2=clipR-d,h=d);
    intersection() {
      union() {
        translate_z(clipH-a-d) cylinder(r1=clipR-d,r2=clipR,h=d);
        translate_z(clipH-a) cylinder(r=clipR,h=a);
      }
      cube([2*clipR-2*d-2*d,100,100],true);
    }
  }
}
module retaining_clip() {
  difference() {
    union() {
      difference() {
        retaining_clip_ring();
        translate_z(-eps) cylinder(r=clipCoreR,h=clipH+2*eps);
        positive_y();
      }
      intersection() {
        retaining_clip_connector(true);
        retaining_clip_ring();
      }
    }
    rotate(180) retaining_clip_connector(false);
  }
}
module retaining_clip_test() {
  retaining_clip();
  translate([0,0,0.0]) color("pink") rotate(180) retaining_clip();
}
//!retaining_clip();
//!retaining_clip_test();

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module housing_tabslot(tabC=0.5) {
  intersection() {
    tab_profile(height=2*tabR, width=tabWidth+2*(tabR-coreR)*tabSlope + tabC);
    circle(tabR);
  }
}

housingChamfer = 1;
faceCountersink=1;
coreHeight = faceCountersink + coreStackHeight;
housingDepth = coreHeight + coreBack + clipSep;

module housing() {
  faceC=0.2; // extra space because of supports used
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
    translate([0,0,housingDepth/2])
    chamfer_cube(2*housingRX,2*housingRY,housingDepth,housingChamfer);
    
    // core
    //translate([0,0,-eps]) cylinder(r=coreR+C,h=housingDepth+2*eps);
    translate([0,0,-eps]) cylinder(r=coreR+C,h=coreHeight+2*eps);
    translate([0,0,coreHeight]) cylinder(r1=coreR+C,r2=coreR+C-coreBack,h=coreBack);
    translate([0,0,coreHeight+coreBack]) cylinder(r=clipCoreR+C,h=coreBack);
    // face
    translate([0,0,-eps]) cylinder(r=faceR+C,h=faceCountersink+faceC+2*eps);
    // tab slots
    // Note: slightly wider slots towards the front, to make back wafers bind first
    // Note: first wafer is an alignment wafers, and doesn't need tab slots, but include a half slot for some clearance
    // Note: for printability of bridges, we add 2mm
    h = waferStep*wafers+C + 2;
    for (twist=[-tabCtwist,tabCtwist])
    translate([0,0,faceCountersink+1-C])
      linear_extrude(h, twist=twist, slices=4*wafers, convexity=10) {
      housing_tabslot(tabC);
    }
    // ledge for cap
    w = capEdge + tightC;
    translate_z(housingDepth-capDepth) difference() {
      positive_z();
      chamfer_cube(2*housingRX-2*w,2*housingRY-2*w,100,housingChamfer2);
    }
  }
}
//!housing();

backDepth = 20;
housingChamfer2 = housingChamfer*0.5;
capEdge = 1.5-2*C;
capDepth = 1.5;
capClip = 1;
capClipLength = 10;

module housing_back() {
  w = 1;
  intersection() {
    translate_z(backDepth/2-10)
    difference() {
      chamfer_cube(2*housingRX,2*housingRY,backDepth + 10,housingChamfer);
      chamfer_cube(2*housingRX-2*capEdge,2*housingRY-2*capEdge,backDepth-2*capEdge + 10,housingChamfer2);
    }
    positive_z();
  }
  lip = waferLip;
  mirrored([1,0,0])
  translate([housingRX-capEdge,0,capDepth+clipH/2])
  linear_extrude_y(capClipLength,true) {
    polygon([[0,-capClip-lip/2],[-capClip,-lip/2],[-capClip,lip/2],[0,capClip+lip/2]]);
  }
}
//!housing_back();

//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

//color("grey") translate([0,0,faceThickness-1]) housing();


//core();
//intersection() {core(); cube(2*32,true);}

module test() {
  $fn=20;
  intersection() {
    group() {
      translate([0,0,1]) housing();
      rotate(90) {
        translate([0,0,0]) color("pink") core();
        if (0) {
          translate([0,0,faceThickness+C/2]) color("lightgreen") first_wafer();
          translate([0,0,faceThickness+waferStep+C/2]) color("lightblue") wafer(0);
          translate([0,0,faceThickness+3*waferStep+C/2]) color("lightyellow") last_wafer();
        }
        translate([0,0,faceThickness+coreStackHeight+coreBack+clipSep+C/2]) rotate(90) color("lightgreen") retaining_clip();
      }
      translate([0,0,1+housingDepth-capDepth+tightC]) color("lightblue") housing_back();
    }
    positive_y();
    //translate_y(3) negative_y();
  }
}
!test();

if (false) {
translate([0,step*3,faceThickness+waferThickness/2+C/2]) color("red") wafer(minBit+3);
translate([0,step*6,faceThickness+waferThickness/2+C/2+waferStep]) color("red") wafer(minBit+0);
translate([0,-step*6,faceThickness+waferThickness/2+C/2+waferStep*2]) color("blue") wafer(minBit+6);
translate([0,-step*0,faceThickness+waferThickness/2+C/2+waferStep*3]) color("green") wafer(minBit+6);
translate([0,step*1,faceThickness+waferThickness/2+C/2+waferStep*4]) color("limegreen") wafer(minBit+5);
}

module labled_core(CX,label) {
  lbl = label==undef ? str(CX) : label;
  core(CX=CX);
  stackHeight = wafers * waferStep + waferThicknessLast;
  translate([0,0,faceThickness + stackHeight + 2]) linear_extrude(0.2)
    text(lbl,size=5,font="Ubuntu",halign="center",valign="center");
}
labled_core(CX=CX);
 
module housing_test(CX,label) {
  housingHeight = 4;
  housingR = coreR+2.5;
  faceCountersink=1;
  d = 5;
  lbl = label==undef ? str(CX) : label;
  difference() {
    translate([0,d/2,housingHeight/2])
    chamfer_cube(2*housingR,2*housingR+d,housingHeight,1);
    // core
    translate([0,0,-eps]) cylinder(r=coreR+CX,h=housingHeight+2*eps);
    // face
    translate([0,0,-eps]) cylinder(r=faceR+CX,h=faceCountersink+2*eps);
    translate([0,0,housingHeight-faceCountersink]) cylinder(r=faceR+CX,h=faceCountersink+2*eps);
    // label
    translate([0,housingR+d/2-1.2,housingHeight-0.2]) linear_extrude(0.2+eps)
      text(lbl,size=5,font="Ubuntu",halign="center",valign="center");
  }
  //translate([0,housingR+d/2-1.5,housingHeight]) linear_extrude(0.2)
  //  text(lbl,size=5,font="Ubuntu",halign="center",valign="center");
}
//!housing_test(0);
 
//-----------------------------------------------------------------------------
// Export
//-----------------------------------------------------------------------------

module export_wafer0() { wafer(minBit+0); }
module export_wafer1() { wafer(minBit+1); }
module export_wafer2() { wafer(minBit+2); }
module export_wafer3() { wafer(minBit+3); }
module export_wafer4() { wafer(minBit+4); }
module export_wafer5() { wafer(minBit+5); }
module export_wafer6() { wafer(minBit+6); }
module export_all_wafers() {
  for (i=[minBit:maxBit]) {
    translate(i*(waferWidth+8)) wafer(i);
  }
}
module export_first_wafer() { first_wafer(); }
module export_last_wafer() { last_wafer(); }
module export_core() { core(); }
module export_coretest_wide() { labled_core(CX=C);  }
module export_coretest_narrow() { labled_core(CX=C/2);  }
module export_housing() { housing(); }
module export_housingtest_zero() { housing_test(0); }
module export_housingtest_narrow() { housing_test(0.05); }
module export_housingtest_wide() { housing_test(0.1); }
module export_housingtest_wider() { housing_test(0.125); }
module export_core_small() { core(); }
module export_retaining_clip() { retaining_clip(); }
module export_cap() { rotate([180,0,0]) housing_cap(); }
