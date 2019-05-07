// Model parameters

$fs = 0.1;
$fa = 3;

eps = 0.01;
C = 0.1; // clearnace

coreR = 11;

wafers = 13;
waferThickness = 2;
waferStep = waferThickness+C;
waferWidth = 12;
waferWidthExt = waferWidth+2;
tabWidth = 9;
tabIncline = 0.2;

faceR = coreR+1;
faceThickness = 2;

housingR = coreR+3;

keyWidth = 8;
keyDelta = 2;
keyHeight = 2;

toothAngle = 1;
keyC = C; // vertical clearance in keyhole
keyCX = 0.2; // horizontal clearance in keyhole (not critical)
keyHolePos = 1;

connectorR=1.25;
connectorPos=-5.5;

bidding = [3,1];
step = 0.5;
//minBid = -3; maxBid = 3;
minBid = -2; maxBid = 4;
bids = maxBid-minBid+1;
maxDelta = 3*step;

// Keyway
module key_profile(delta=0) {
  dx=2*delta*keyDelta/keyWidth;
  dy=delta;
  rotate([90,0,0])
  rotate([0,90])
  linear_extrude(eps) {
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
      [-l, keyHeight/2+keyC+toothAngle*(1+l)],
      [1,  keyHeight/2+keyC+toothAngle*0],
      [1.5,keyHeight/2+keyC+toothAngle*0],
      [2,  keyHeight/2+keyC+toothAngle*0.5],
      [2,  -keyHeight/2-keyC-toothAngle*0.5],
      [1.5,-keyHeight/2-keyC-toothAngle*0],
      [1,  -keyHeight/2-keyC-toothAngle*0],
      [-l, -keyHeight/2-keyC-toothAngle*(1+l)],
    ]);
  }
}
//!key_hole();

// Wafers
module wafer_profile(C=C) {
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
module wafer_profiles() {
  for (i = [0:wafers-1]) {
    translate([0,0,i*waferStep+waferStep/2]) {
      wafer_profile(C);
    }
  }
}
//!waferProfiles();
module wafer_outer() {
  intersection() {
    wafer_profile(C=0);
    cylinder(r=coreR,waferThickness,center=true);
  }
}
module tab_profile(width=tabWidth,height=2*coreR) {
  x = width/2 - tabIncline*height/2;
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
/*
$preview=true;
module connector_base(C=0) {
  translate(connectorO)
  // cylinder connector
  rotate([90,0,0]) cylinder(r=connectorR,h=connectorH,center=true);
  //sphere(r=connectorR+C);
  //scale([connectorR+C,connectorR*0.5+C,connectorR+C]) sphere(1);
}
module connector_pin() {
  r=10;
  intersection() {
    connector_base(C=0);
    translate([0,0,r-eps]) cube(2*r,true);
  }
}
module connector_slot(bid=3) {
  //a = max(-maxDelta,-bid*step)-C;
  //b = min(maxDelta,(bids-1-bid)*step)+C;
  a = -maxDelta-C;
  b = maxDelta+C;
  if (true) {
    // cylinder connector
    translate(connectorO)
    translate([0,(a+b)/2,0])
    rotate([90,0,0])
    cylinder(r=connectorR,h=connectorH+(b-a),center=true);
  } else {
    if (!$preview) {
      hull() {
        translate([0,a,0]) connector_base(C=C);
        translate([0,b,0]) connector_base(C=C);
      }
    } else {
      union() {
        translate([0,a,0]) connector_base(C=C);
        translate([0,b,0]) connector_base(C=C);
        r=connectorR+C;
        translate(connectorO)
        rotate([90,0,0])
        cylinder(r=r,h=(maxDelta)*2,center=true);
      }
    }
  }
}
*/
module connector_pin(C=0) {
  union() {
    cylinder(r=connectorR+C,h=1+C);
    cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
  }
}
module connector_slot(bid=3) {
  a = -maxDelta;
  b = maxDelta;
  /*hull() {
    translate([0,a,0]) connector_pin(C=C);
    translate([0,b,0]) connector_pin(C=C);
  }*/
  hull() {
    translate([0,a,0]) cylinder(r=connectorR+C,h=1+C);
    translate([0,b,0]) cylinder(r=connectorR+C,h=1+C);
  }
  hull() {
    translate([0,a,0]) cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
    translate([0,b,0]) cylinder(r1=connectorR+0.2+C,r2=connectorR+C,h=0.2);
  }
}

module wafer(bid, minBid=minBid, maxBid=maxBid, slot=true, pin=true, tabs=true) {
  y = bid*step;
  difference() {
    union() {
      // tabs
      if (tabs) intersection() {
        linear_extrude(waferThickness,center=true) tab_profile();
        cylinder(r=coreR,waferThickness,center=true);
      }
      // profile
      intersection() {
        wafer_profile(C=0);
        translate([0,y-maxBid*step,0])
          cylinder(r=coreR,waferThickness,center=true);
        translate([0,y-minBid*step,0])
          cylinder(r=coreR,waferThickness,center=true);
      }
    }
    translate([0,y+keyHolePos,-waferThickness/2-eps/2])
      key_hole();
    // connectorSlot
    if (slot) {
      translate([0,y+connectorPos,-waferThickness/2-eps]) connector_slot(bid);
    }
  }
  // connector
  if (pin) {
    translate([0,y+connectorPos,waferThickness/2]) connector_pin();
  }
  //translate([2,y+connectorPos,waferThickness/2]) connector_slot(bid);
}
module first_wafer(bid) {
  wafer(0,minBid=-3,maxBid=3,slot=false,tabs=false);
}
module last_wafer(bid) {
  //wafer(bid,pin=false);
  wafer(0,minBid=0,maxBid=0,pin=false);
}
module wafers() {
  wafer(minBid);
  translate([0,0,3]) wafer(minBid+3);
  //translate([0,0,2]) wafer(4);
  translate([20,0,0]) wafer(0);
  translate([40,0,0]) wafer(maxBid);
  translate([60,0,0]) first_wafer(minBid+1);
  translate([80,0,0]) last_wafer(minBid+1);
}
//!wafers();

// Core
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
module core() {
  union() {
    face_plate();
    translate([0,0,faceThickness])
    difference() {
      linear_extrude(wafers * waferStep + C-2*eps + 2) {
        circle(coreR);
      }
      // space for wafers
      translate([0,0,C/2-eps])
      wafer_profiles();
    }
    translate([0,0,faceThickness + wafers * waferStep + C-2*eps + 2]) {
      translate([0,0,0]) cylinder(r1=coreR-1,r2=coreR-1,h=1);
      translate([0,0,1]) cylinder(r1=coreR-1,r2=coreR,h=1);
      translate([0,0,2]) cylinder(r1=coreR,r2=coreR,h=2);
    }
  }
};

// Housing
module chamfer(r) {
  offset(r=r) offset(delta=-r) children();
}
module housing() {
  //houdingHeight = faceThickness + wafers * waferStep + C - 1;
  housingHeight = 12;
  waferSpace=5;
  translate([0,0,15])
  difference() {
    linear_extrude(housingHeight) {
      //square([2*housingR,2*housingR+3],center=true);
      /*hull() {
        translate([0,-waferSpace,0]) circle(housingR);
        translate([0,waferSpace,0]) circle(housingR);
      }*/
      chamfer(10)
      square([2*housingR,2*housingR+waferSpace],center=true);
    }
    translate([0,0,-eps]) linear_extrude(housingHeight+2*C) {
      tab_profile(height=2*(coreR+(bids-1)*step));
    }
    translate([0,0,-eps]) cylinder(r=coreR+C,h=housingHeight+2*eps);
    translate([0,0,-eps]) cylinder(r=faceR+C,h=1+2*eps);
  }
}
housing();


core();
translate([0,step*3,faceThickness+waferThickness/2+C/2]) color("red") wafer(minBid+3);
translate([0,step*6,faceThickness+waferThickness/2+C/2+waferStep]) color("red") wafer(minBid+0);
translate([0,-step*6,faceThickness+waferThickness/2+C/2+waferStep*2]) color("blue") wafer(minBid+6);