//=============================================================================
// Waverlock: a wavy waferlock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

//bitting = [-2,-3,-1,1,3,3,2];
bitting = [-2,-3,-1,-3,-1,1,3,3,2];
//bitting = [-2,-3,-1,1,3,3,1,-1,-3,1];
//bitting = [-2,-3,-2,-1,1,3,3,2,0,-2];
echo("key bitting", bitting);

eps = 0.01;
C = 0.125; // clearance
CX = 0.125; // clearance in x and y directions
tightC = 0.08;
bridgeC = 0.5; // clearance for bridges

coreR = 9;

//wafers = 12;
wafers = len(bitting);
echo("nr wafers", wafers);
waferThickness = 2;
waferThicknessLast = 4;
waferStep = waferThickness+C;
waferWidth = 10;
waferLip = 0.6;
tabWidth = 8;
tabSlope = 0.3;

faceR = coreR+1;
faceThickness = 2;
faceCountersink = 1;

keyWidth = 7;
keyDelta = 2;
keyHeight = 1.8;

toothSlope = 1;
keyC = C + 0.05; // vertical clearance in keyhole
keyCX = 0.2; // horizontal clearance in keyhole (not critical)
keyHolePos = 0;

connectorR=1.25;
connectorPos=0;
connectorLen=6;
pinC = 0.2; // it is critical that there is enough clearance, better to have too much
pinCX = 0.05; // clearance in movement direction

step = 0.8;
//step = 0.8;
//step = 1.0;
//minBit = -6; maxBit = 6;
//minBit = -4; maxBit = 4;
minBit = -3; maxBit = 3;
//minBit = -2; maxBit = 4;
//minBit = -1; maxBit = 5;
//minBit = 0; maxBit = 6;
bits = maxBit-minBit+1;
//maxDelta = 3*step;
maxDelta = 1.6;

tabC = 0.4; // Clearance on side of tabs
tabCtwist = 3; // extra clearance on back wafers
tabCY = 2*C; // Clearance above tabs
tabR = coreR + (bits-1)*step + tabCY;

coreBack = 2;
clipSep = 0.8;
coreBackOverlap = 1;
coreStackHeight = wafers * waferStep + waferThicknessLast + bridgeC - coreBackOverlap;

echo ("bit difference",bits*step);
waferSpace=bits*step + 0.5;
housingRX = coreR + 4;
housingRY = coreR + 1.7 + waferSpace;
housingChamfer = 1;
coreHeight = faceCountersink + coreStackHeight;
housingDepth = coreHeight + coreBack + clipSep;
echo ("housing",2*housingRX,2*housingRY,housingDepth);

housingChamfer2 = housingChamfer*0.5; // chamfer inside cap
capEdge = 1.6;
capCountersink = 1.6;
capDepth = capEdge+capCountersink+1+6;
capClip = 1;
capClipLength = 10;

clipR = housingRX-capEdge-(C+tightC); // better a bit extra play here
clipW = 8;
clipCoreR = coreR-2;
clipCoreC = 0.05;
clipH = 4.4;

//-----------------------------------------------------------------------------
// Keyway
//-----------------------------------------------------------------------------

module key_profile(delta=0,chamfer=0) {
  dx=2*delta*keyDelta/keyWidth;
  dy=delta;
  cy=chamfer*0.9;
  cx=chamfer-2*cy*keyDelta/keyWidth;
  cyt=chamfer*0.6;
  cxt=2*cyt*keyDelta/keyWidth;
  linear_extrude(height=eps,convexity=106) {
    rotate(90)
    polygon([
      [-keyDelta/2-dx,-keyWidth/2-dy],
      [-keyDelta/2-dx-cx,-keyWidth/2-dy+cy],
      [keyDelta/2-chamfer,0],
      [-keyDelta/2-dx-cx,keyWidth/2+dy-cy],
      [-keyDelta/2-dx,keyWidth/2+dy],
      [-keyDelta/2-dx+eps+chamfer,keyWidth/2+dy],
      [keyDelta/2+eps+chamfer-cxt,cyt],
      [keyDelta/2+eps+chamfer-cxt,-cyt],
      [-keyDelta/2-dx+eps+chamfer,-keyWidth/2-dy]
    ]);
  }
}
module extrude_key(delta=0,chamfer=0) {
  minkowski() {
    linear_extrude_x(eps) children();
    key_profile(delta,chamfer);
  }
}
module key_profile_test() {
  color("blue")translate_z(-5) extrude_key(delta=1) {square([7,5],true);}
  extrude_key(chamfer=0) {square([7,5],true);}
  color("red")translate_z(5) extrude_key(chamfer=1) {square(5,true);}
  color("green")translate_z(10) extrude_key(chamfer=0) {square([5,5],true);}
}
module key_hole(delta=keyCX) {
  l=0;
  extrude_key(delta=delta) {
    sym_polygon_x([
      [keyHeight/2+keyC+toothSlope*(1+l), -l],
      [keyHeight/2+keyC+toothSlope*0,    1],
      [keyHeight/2+keyC+toothSlope*0,    1.5],
      [keyHeight/2+keyC+toothSlope*0.5,  2],
    ]);
  }
}
module last_key_hole(delta=keyCX) {
  l = 10; r = 10;
  extrude_key(delta=delta) {
    sym_polygon_x([
      [keyHeight/2+keyC+toothSlope*l, -l],
      [keyHeight/2+keyC+toothSlope*0, 0],
      [keyHeight/2+keyC+toothSlope*0, r],
    ]);
  }
}
//!key_hole();

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_shape(h = keyHeight) {
  ebitting = concat([0],bitting,[0]);
  n = len(ebitting);
  point = 0.3;
  flat = 0.2;
  coflat = 0.1;
  end = (n-1)*waferStep + waferThicknessLast - 0.5;
  top = concat(
    [[-h/2, 0]],
    [for (i=[0:n-1]) for (j=[0,1])
      [ebitting[i]*step - h/2, i*waferStep +
        (j==0 ? ((i>0   && ebitting[i-1]<ebitting[i]) ? 1-flat : 1+coflat)
              : ((i+1<n && ebitting[i+1]<ebitting[i]) ? 1.5+flat : 1.5-coflat))]
    ],
    [[-h/2, end - (h-point)/2]
    ,[-point/2, end]]
  );
  bot = concat(
    [[h/2, 0]],
    [for (i=[0:n-1]) for (j=[0,1])
      [ebitting[i]*step + h/2, i*waferStep +
        (j==0 ? ((i>0   && ebitting[i-1]>ebitting[i]) ? 1-flat : 1+coflat)
              : ((i+1<n && ebitting[i+1]>ebitting[i]) ? 1.5+flat : 1.5-coflat))]
    ],
    [[h/2, end - (h-point)/2]
    ,[point/2, end]]
  );
  polygon(concat(top,reverse(bot)));
}
module key() {
  end = (len(bitting)+1)*waferStep + waferThicknessLast - 0.5;
  keyBottomChamfer = 0.4;
  chamfer = 0.7;
  keyHandleSizeX = 21;
  keyHandleSizeY = 21;
  keyHandleChamfer = 5;
  keyHandleHole = 6;
  keyHandleHoleChamfer = keyHandleHole/3.5;
  group() {
    intersection() {
      extrude_key(chamfer=keyBottomChamfer) {
        key_shape(h = keyHeight-2*keyBottomChamfer);
      }
      linear_extrude_y(lots,true) {
        sym_polygon_x([[-keyWidth,-10], [-keyWidth,end-chamfer], [-keyWidth/2,end-chamfer], [-keyWidth/2+chamfer,end]]);
      }
    }
    intersection() {
      extrude_key(chamfer=keyBottomChamfer) {
        polygon([[-keyHeight/2+keyBottomChamfer,0],[keyHeight/2-keyBottomChamfer,0],[keyBottomChamfer,-4]]);
      }
      extrude_key(chamfer=keyBottomChamfer) {
        polygon([[-keyHeight/2+keyBottomChamfer,0],[keyHeight/2-keyBottomChamfer,0],[-keyBottomChamfer,-4]]);
      }
    }
    linear_extrude_y(2,true) {
      difference() {
        translate([0,-keyHandleSizeY/2]) chamfer_rect(keyHandleSizeX,keyHandleSizeY,keyHandleChamfer);
        translate([0,-keyHandleSizeY+keyHandleHole/2+2]) chamfer_rect(keyHandleHole,keyHandleHole,keyHandleHoleChamfer);
      }
    }
  }
}
!key();

module key_stack(color = "darkred", offset=0) {
  translate_y(1) color(color) linear_extrude_x(1,true) key_shape();
  //color(color) key();
  n = len(bitting);
  translate_z(offset+C)
  intersection() {
    group() {
      first_wafer();
      for (i=[0:n-1]) {
        a = offset/waferStep;
        p = (1-a)*bitting[i] + a*(i==n-1 ? 0 : bitting[i+1]);
        translate([0,(p-bitting[i])*step,faceThickness + i*waferStep])
        if (i==0) {
          wafer(bitting[i]);
        } else {
          wafer(bitting[i]);
        }
      }
      translate_z(faceThickness + n*waferStep) last_wafer();
    }
    negative_x();
  }
}
module key_stacks() {
  key_stack();
  translate_y(coreR*2+8) key_stack(color="darkblue",offset=waferStep*0.5);
}

//!key_stacks();

//-----------------------------------------------------------------------------
// Wafer connector pins
//-----------------------------------------------------------------------------

//module connector_halfpin(C=0) cylinder(r=3+C,h=1);
//module connector_halfpin(C=0) cube([2+2*C,6+2*C,2],true);
module connector_halfpin(C=0,CX=0,dh=0) {
  a = 1.2;
  h = 1.2-dh;
  linear_extrude_y(connectorLen+2*CX,true) {
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
  a = -maxDelta;
  b = maxDelta;
  if (true) {
    group() {
      hull() {
        translate([0,coreR+a,0]) connector_halfpin(pinC,CX=pinCX);
        translate([0,coreR+b,0]) connector_halfpin(pinC,CX=pinCX);
      }
      hull() {
        translate([0,-coreR+a,0]) connector_halfpin(pinC,CX=pinCX);
        translate([0,-coreR+b,0]) connector_halfpin(pinC,CX=pinCX);
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
        cylinder(r=coreR,h=thickness);
      }
      // profile
      intersection() {
        wafer_profile();
        translate([0,y-maxBit*step,0]) cylinder(r=coreR,h=thickness);
        translate([0,y-minBit*step,0]) cylinder(r=coreR,h=thickness);
      }
      // connector
      if (pin) {
        intersection() {
          translate([0,y+connectorPos,waferThickness]) connector_pin();
          if (tabs) {
            cylinder(r=coreR,h=thickness+2);
          } else {
            intersection() {
              translate([0,y-maxBit*step,0]) cylinder(r=coreR,h=thickness+2);
              translate([0,y-minBit*step,0]) cylinder(r=coreR,h=thickness+2);
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
  wafer(0,minBit=max(minBit,-maxDelta/step),maxBit=min(maxBit,maxDelta/step),slot=false,tabs=false);
}

module last_wafer(bit=0) {
  thickness = waferThicknessLast;
  y = 0;
  difference() {
    intersection() {
      last_wafer_profile();
      union() {
        // note: we might run into the core back chamfer
        ch = max(0,coreBackOverlap + C - bridgeC);
        cylinder(r=coreR,h=thickness-ch);
        translate_z(thickness-ch) cylinder(r1=coreR,r2=coreR-ch,h=ch);
      }
    }
    translate([0,y+keyHolePos,1-eps/2]) last_key_hole();
    translate([0,y+connectorPos,-eps]) connector_slot(bit);
  }
}

//Tests
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

module core(C=C,CX=C) {
  union() {
    face_plate();
    translate([0,0,faceThickness])
    intersection() {
      difference() {
        union() {
          cylinder(r=coreR,h=coreStackHeight);
          translate_z(coreStackHeight) cylinder(r1=coreR,r2=coreR-coreBack,h=coreBack);
          translate_z(coreStackHeight+coreBack) cylinder(r=clipCoreR,h=clipH+clipSep+C);
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
        translate_z(coreStackHeight+coreBack+clipSep+C)
          linear_extrude_x(2*coreR,true) retaining_clip_profile(C=tightC,bridgeC=bridgeC);
      }
    }
  }
};
//!core();

//-----------------------------------------------------------------------------
// Retaining clip
//-----------------------------------------------------------------------------

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
    cylinder(r=clipCoreR+clipCoreC,h=clipH);
    // snap connector
    linear_extrude(clipH,convexity=10) {
      pinR = 0.5;
      pos = clipCoreR+clipCoreC-3;
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
          cylinder(r=clipCoreR+clipCoreC-eps,h=clipH);
        }
        //cylinder(r=clipR-1,h=clipH);
      }
    }
  }
  s = clipH*0.4 + e/2;
  translate([-(clipR+clipCoreR+clipCoreC)/2,-eps,clipH/2])
  rotate([-90]) cylinder(r1=s,r2=0,h=s,$fn=7);
}
module retaining_clip_ring() {
  union() {
    //cylinder(r=clipR,h=clipH);
    d = 1.1;
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
      cube([2*clipR-3*d,100,100],true);
    }
  }
}
module retaining_clip() {
  difference() {
    union() {
      difference() {
        retaining_clip_ring();
        translate_z(-eps) cylinder(r=clipCoreR+clipCoreC,h=clipH+2*eps);
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
    translate_z(housingDepth-capCountersink) difference() {
      positive_z();
      chamfer_cube(2*housingRX-2*w,2*housingRY-2*w,100,housingChamfer2+0.1+C);
    }
  }
}
//!housing();

module housing_back() {
  w = 1;
  intersection() {
    difference() {
      chamfer_cube(2*housingRX,2*housingRY,2*capDepth,housingChamfer);
      chamfer_cube(2*housingRX-2*capEdge,2*housingRY-2*capEdge,2*(capDepth-capEdge),housingChamfer2);
    }
    positive_z();
  }
  lip = waferLip;
  mirrored([1,0,0])
  translate([housingRX-capEdge,0,capCountersink+clipH/2])
  linear_extrude_y(capClipLength,true) {
    polygon([[0,-capClip-lip/2],[-capClip,-lip/2],[-capClip,lip/2],[0,capClip+lip/2]]);
  }
  translate([-5,0,capDepth-capEdge]) rotate([180]) rotate(90) linear_extrude(1)
  text("waverlock",size=4.5,font="ubuntu",halign="center",valign="center");
  translate([5,0,capDepth-capEdge]) rotate([180]) rotate(90) linear_extrude(1)
  text("by twanvl",size=4.5,font="ubuntu",halign="center",valign="center");
}
//!housing_back();

module exposed_housing() {
  difference() {
    housing();
    w=6;h=8;
    d = lots;
    translate([-lots/2,-w/2,2.5]) cube([lots,w,d]);
    translate([-h/2,-lots/2,2.5]) cube([h,lots,d]);
  }
}
!exposed_housing();

//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

//color("grey") translate([0,0,faceThickness-1]) housing();


//core();
//intersection() {core(); cube(2*32,true);}

module test() {
  $fn=20;
  exposed=1;
  showHousing=1;
  showCore=0;
  showWafers=1;
  intersection() {
    group() {
      if (showHousing) translate([0,0,1]) color("white")
        if (exposed) exposed_housing(); else housing();
      rotate(0) {
        if (showCore) {
          translate([0,0,0]) color("pink") core();
        }
        if (showWafers) {
          translate([0,0,faceThickness+C/2]) color("lightgreen") first_wafer();
          translate([0,0,faceThickness+waferStep+C/2]) color("lightblue") wafer(0);
          translate([0,0,faceThickness+wafers*waferStep+C/2]) color("lightyellow") last_wafer();
        }
        translate([0,0,faceThickness+coreStackHeight+coreBack+clipSep+C+tightC/2]) rotate(90) color("lightgreen") retaining_clip();
      }
      if (showHousing) translate([0,0,1+housingDepth-capCountersink+tightC]) color("lightblue") housing_back();
    }
    positive_y();
    //translate_y(3) negative_y();
  }
}
//!test();
//!export_needed_wafers();
!everything();

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
  translate([0,0,faceThickness + coreStackHeight + coreBack + clipSep + clipH]) linear_extrude(0.2)
    text(lbl,size=5,font="Ubuntu",halign="center",valign="center");
}
!labled_core(CX=CX);
 
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
module export_first_wafer() { first_wafer(); }
module export_last_wafer() { last_wafer(); }

module export_all_wafers(copies = 2) {
  for (j=[0:copies-1]) {
    translate_y(j*(coreR*2+6))
    for (i=[minBit:maxBit]) {
      translate_x(i*(waferWidth+6)) wafer(i);
    }
  }
  translate_x((minBit-1)*(waferWidth+6)) first_wafer();
  translate_x((maxBit+1)*(waferWidth+6)) last_wafer();
}
module export_needed_wafers() {
  for (i=[0:wafers]) {
    translate_x(i*(waferWidth+6))
    if (i==0) {
      first_wafer();
    } else if (i==wafers) {
      last_wafer();
    } else {
      wafer(bitting[i]);
    }
  }
}

module export_core() { core(); }
module export_housing() { housing(); }
module export_exposed_housing() { exposed_housing(); }
module export_retaining_clip() { retaining_clip(); }
module export_cap() { rotate([180,0,0]) housing_back(); }
module export_key() { key(); }

module everything() {
  translate([-wafers/2*(waferWidth+6),coreR+housingRY+8]) export_needed_wafers();
  translate([-2*housingRX-8,0]) export_core();
  translate([0,0]) export_housing();
  translate([2*housingRX+8,0,capDepth]) export_cap();
  translate([2*(2*housingRX+8),coreR,0]) export_retaining_clip();
  translate([-2*(2*housingRX+8),coreR,0]) export_retaining_clip();
  translate([0,-2*housingRY,0]) export_key();
}
module export_everything() {
  if (0) {
    everything();
  } else {
    cube(1);
  }
}