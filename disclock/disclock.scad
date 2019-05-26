
// Disc detainer lock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

bitting = [5,3,5,0,3,2,1,4,3,5];

SMALL = 1;
MEDIUM = 2;
LARGE = 3;
size = LARGE;
//size = "small";

C = 0.125;
keyC = C;
tightC = 0.05;

eps = 1e-2;

discR = size <= SMALL ? 8.5 : 10;
coreWall = size <= SMALL ? 1.6 : 1.7;
coreR = discR + coreWall;

firstLayerHeight = 0.2;
layerHeight = 0.15;
function roundToLayerHeight(z) = round((z-firstLayerHeight)/layerHeight)*layerHeight + firstLayerHeight;

discThickness = size <= MEDIUM ? 1.85 : 2.0;
spacerThickness = size <= MEDIUM ? 0.5 : 0.65;
spinnerThickness = size <= SMALL ? 2 : 2;
spinnerCountersink = spinnerThickness/2;

bits = 5;
//step = -90/4; // degrees
step = 120/bits; // degrees
//step = -100/4; // degrees

gateHeight = 2.5;
falseHeight = 1;
sidebarThickness = 1.85;
printSidebarSpring = true;

keyR1 = size <= SMALL ? 4.5 : 5;
keyR2 = 3.5;
keyWidth = size <= SMALL ? 2.5 : 3;
keywayAngle = 0;

limiterInside = true;
limiterAngle = 30;

discs = len(bitting);
coreHeight = (discs-1) * (discThickness + spacerThickness) + spinnerThickness - spinnerCountersink + C;
coreAngle = -90;

discPos = 8;
corePos = discPos + spinnerThickness - spinnerCountersink;
setScrewPos = 4+4/2-0.5;

shackleDiameter = 8;
shackleSpacing = 3;
shackleWidth = 2*coreR + shackleDiameter + 2*shackleSpacing;

lugR=coreR-2;
lugHeight=shackleDiameter+3;
lugOverlap=shackleDiameter/2-0.5;
lugRetainOverlap=1;
lugTravel=lugOverlap+0.5;
lugDepth=8;

housingHeight = 2*coreR + 2*shackleSpacing;
housingWidth = shackleWidth + shackleDiameter + 2*shackleSpacing;
housingDepth = corePos + coreHeight + 2 + lugDepth + 2 + 1.5 + 2*C;

sidebarPos = corePos;
sidebarDepth = (discs-1) * (discThickness + spacerThickness) + spinnerThickness - spinnerCountersink;

shackleLength = housingDepth + 5;
shackleLength1 = shackleLength;
shackleLength2 = shackleLength - coreHeight - corePos + 1;
shackleTravel = coreHeight + 3;

//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

function rot(a,p) = [cos(a)*p[0]+sin(a)*p[1], cos(a)*p[1]-sin(a)*p[0]];

module key_profile(r=keyR1) {
  //x=3.5/2;y=keyR1;
  //square([3.5,10],true);
  intersection() {
    union() {
      rotate(0) square([keyWidth,r],true);
      rotate(-step*0.5) square([keyWidth,2*r],true);
      rotate(step*0.5) square([keyWidth,2*r],true);
    }
    circle(r);
  }
  //translate([-1.5,2.5]) square([3,5],true);
  //translate([1.5,-2.5]) square([3,5],true);
  //sym_polygon_xy([[0.8*x,y],[x,0.9*y],[0.8*x,0.6*y]]);
  //sym_polygon_xy([[x,y],[x,y*0.8],[x*1.5,y*0.6]]);
  //sym_polygon_xy([[x,y],[x*0.6,y*0.6]]);
  //sym_polygon_xy([[x,y],[x,y-1],[x-0.6,y-2.9]]);
  /*
  sym_polygon_xy([
    rot(-step*0.33,[0,5]), rot(-step*1.5,[0,5]), rot(-step*1.5,[0,3.5]),
    rot(-1.5*step,[0,3.5]), rot(-2*step,[0,3.5]), rot(-2*step,[0,2]) ]);
  */
  //sym_polygon_xy([[x-1,y],[x,y-2]]);
  //sym_polygon_180([[x-1,y],[x,y-2],[x,-y]]);
  //sym_polygon_180([[-x,y],[x,y],[x*0.6,y*0.6],[x*0.8,y*0.3]]);
}
module keyway_profile() {
  x=3.5/2;y=10/2;
  //sym_polygon_xy([[0.5*x,y],[x,0.8*y],[1*x,0.7*y],[1.8*x,0.6*y]]);
  //sym_polygon_xy([[0.5*x,y],[x,0.9*y],[1*x,0.7*y],[1.8*x,0.7*y]]);
  //key_profile();
  /*render() {
    square([3,10],true);
    rotate(-22.5) square([3,8],true);
    rotate(-45) square([3,6.2],true);
  }*/
  //sym_polygon_180([[3.5,-x],[x,-x],[x,-y],[-x+1,-y],[-x-0.5,-y*0.6]]);
  *render() {
    //intersection() {sym_polygon_180([[x-1,y],[x,y-2],[x+2,y-4],[x,-1],[x,-y+2],[x-1,-y]]);circle(5);}
    intersection() {sym_polygon_180([[x,y],[x,y-2],[x+2,y-4],[x,-1],[x,-y+2],[x,-y]]);circle(5);}
  }
  render() {
    /*
    intersection() {square([3,11],true);circle(5);}
    rotate(-22.5) intersection() {square([3,11],true);circle(4);}
    rotate(-45)   intersection() {square([3,11],true);circle(3);}
    rotate(-22.5*3) intersection() {square([3,11],true);circle(2);}
    */
    
    
    intersection() {key_profile();circle(keyR1);}
    //rotate(-1*step)   intersection() {key_profile();circle(5);}
    //rotate(0.5*step)   intersection() {key_profile();circle(4.5);}
    //rotate(1*step)   intersection() {key_profile();circle(4);}
    //rotate(1*step)   intersection() {key_profile();circle(4);}
    //rotate(2*step)   intersection() {key_profile();circle(3.5);}
    rotate(-2*step)   intersection() {key_profile();circle(keyR2);}
    //rotate(1*step)   intersection() {key_profile();circle(4);}
    //rotate(2*step)   intersection() {key_profile();circle(4);}
    //rotate(4*step)   intersection() {key_profile();circle(3);}
    //rotate(3*step)   intersection() {key_profile();circle(2.5);}
    //rotate(-step) intersection() {key_profile();circle(5);}
    //rotate(-step) intersection() {key_profile();circle(5);}
    //rotate(-22.5) intersection() {key_profile();circle(4);}
    //rotate(-45)   intersection() {key_profile();circle(3);}
    //rotate(2*step)   intersection() {key_profile();circle(3.5);}
    //rotate(2*step)   intersection() {square([3.8,11],true);circle(3.5);}
    //rotate(3*step)   intersection() {key_profile();circle(3.5);}
    //rotate(3*step)   intersection() {sym_polygon_180([[-4,0],[-4,11],[1,11],[1,0]]);circle(3.5);}
    //rotate(-60)   intersection() {key_profile();circle(3);}
    //rotate(-22.5*3) intersection() {key_profile();circle(3);}
    //rotate(-22.5*3) intersection() {key_profile();circle(3);}
    //rotate(4*step) intersection() {key_profile();circle(2.5);}
    //rotate(-90) intersection() {key_profile();circle(2);}
    //rotate(-30) intersection() {key_profile();circle(4);}
    //rotate(-60)   intersection() {key_profile();circle(3);}
    //rotate(-45)   intersection() {key_profile();circle(3);}
    //rotate(-22.5*3) intersection() {key_profile();circle(2);}
  }
}

//-----------------------------------------------------------------------------
// discs
//-----------------------------------------------------------------------------

module wedge_triangle(a,r) {
  //polygon([[0,0],rot(-a/2,[0,-r]),rot(a/2,[0,-r])]);
  rotate(270-a/2) wedge(a);
}
module rotation_limiter() {
  intersection() {
    difference() {
      circle(coreR);
      circle(discR-2);
    }
    a = limiterInside ? 270 : 270-bits*step/2;
    rotate(a) wedge(limiterAngle,center=true);
  }
}
module rotation_limiter_slot(fixed = false) {
  offset(C)
  intersection() {
    difference() {
      circle(coreR+1);
      circle(discR-2);
    }
    a = limiterInside || fixed ? 270 : 270-bits*step/2;
    rotate(a) wedge(-limiterAngle/2,(fixed ? 0 : bits*step)+limiterAngle/2,center=true);
  }
}

module sidebar_slot(deep) {
  w = sidebarThickness+1*C;
  Ca = 1;
  h = deep ? gateHeight : falseHeight;
  chamfer = 0.3;
  translate([0,discR]) {
    //sym_polygon_x([[-w/2,0],[-w/2,-h]]);
    sym_polygon_x([[-w/2-chamfer,0],[-w/2,-chamfer],[-w/2,-h]]);
    //sym_polygon_x([[-w/2-0.1,0],[-w/2,-0.2],[-w/2-0.1,-1],[-w/2,-h]]);
  }
}
module sidebar_slot_wiggle(deep) {
  Ca = 1;
  rotate(-Ca) sidebar_slot(deep);
  rotate(0) sidebar_slot(deep);
  rotate(Ca) sidebar_slot(deep);
}

module disc_profile(keyway = true, fixed = false) {
  difference() {
    circle(discR);
    rotate(keywayAngle) offset(keyC) keyway_profile();
    if (limiterInside) rotation_limiter_slot(fixed);
  }
  if (!limiterInside) rotate(-bits*step) rotation_limiter();
}

module disc(bit=0) {
  linear_extrude(discThickness, convexity=10) {
    difference() {
      disc_profile();
      // slots
      for (i=[0:bits-1]) {
        rotate(i*step) sidebar_slot_wiggle(i == bit);
      }
    }
  }
}
module spacer_disc() {
  linear_extrude(spacerThickness, convexity=10) {
    difference() {
      disc_profile(false,true);
      circle(keyR1+keyC);
      sidebar_slot_wiggle(true);
    }
  }
}
module tension_disc() {
  linear_extrude(discThickness, convexity=10) {
    difference() {
      disc_profile();
      rotate(bits*step)
      {
        //sidebar_slot_wiggle(true);
        w = 2+1*C;
        h = 2.5;
        translate([0,discR])
        polygon([[-w/2,0],[-w/2,-h],[w/2,-h],[w*4/2,0]]);
      }
    }
  }
}
module spinner_disc() {
  difference() {
    union() {
      //translate([0,0,1]) cylinder(r1=discR,r2=discR-2,h=2);
      /*linear_extrude(3) {
        circle(discR-2);
      }
      linear_extrude(2) {
        circle(discR);
      }*/
      //linear_extrude(1) circle(coreR);
      cylinder(r=limiterInside ? discR-2-C : discR, h=spinnerThickness);
    }
    translate([0,0,-C]) linear_extrude(3+2*C) {
      rotate(keywayAngle) offset(keyC) key_profile();
    }
  }
}
module spacer_disc1() {
  linear_extrude(spacerThickness, convexity=10) {
    difference() {
      disc_profile(false);
      circle(keyR1+keyC);
      sidebar_slot_wiggle(true);
    }
  }
}

module disc_test() {
  disc(0);
  translate([2*coreR,0,0]) disc(1);
  translate([0,2*coreR,0]) spacer_disc();
  translate([2*coreR,2*coreR,0]) tension_disc();
  translate([4*coreR,2*coreR,0]) spinner_disc();
  translate([4*coreR,0*coreR,0]) intersection() {
    core();
    //translate_z(10) negative_z();
  }
}
//!disc_test();

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_bit_profile(bit) {
  intersection() {
    key_profile();
    rotate((bits-bit)*step) keyway_profile();
    if (bits-bit >= 2) intersection() {
      rotate((bits-bit-2)*step) key_profile();
      if (bits-bit > 2) rotate((bits-bit-2.5)*step) key_profile();
      if (bits-bit > 3) rotate((bits-bit-3)*step) key_profile();
      if (bits-bit > 3) rotate((bits-bit-3.5)*step) key_profile();
      if (bits-bit > 4) rotate((bits-bit-4)*step) key_profile();
      if (bits-bit > 4) rotate((bits-bit-4.5)*step) key_profile();
      circle(keyR2);
    }
  }
}

module inset(r) {
  difference() {
    union() children();
    offset(-r) union() children();
  }
}
module linear_extrude_x_inset(a,b,r) {
  linear_extrude_x(a,true) children();
  linear_extrude_x(b,true) inset(r) children();
}

module key(bitting = bitting) {
  linear_extrude(discPos) key_profile(keyR1+1);
  intersection() {
    cylinder(r=keyR1+1,h=discPos);
    linear_extrude_y(lots,true) {
      sym_polygon_x([[-5/2,0],[-3/2,discPos]]);
    }
  }
  translate_z(-9.5) group() {
    linear_extrude_x_inset(4,5,1,true) {
      difference() {
        intersection() {
          circle(11);
          square([lots,2*9.5],true);
        }
        translate_y(-4) intersection() {
          circle(3);
          square([lots,5],true);
        }
      }
    }
  }
  translate_z(discPos) group() {
    for (i=[0:len(bitting)-1]) {
      mirror([1,0,0])
      translate_z(i*(discThickness+spacerThickness)) {
        linear_extrude(discThickness) {
          key_bit_profile(bitting[i]);
        }
        if (i+1 < len(bitting)) {
          translate_z(discThickness) linear_extrude(discThickness) {
            key_bit_profile(min(bitting[i],bitting[i+1]));
          }
        }
      }
    }
  }
  translate_z(discPos + len(bitting)*(discThickness+spacerThickness) - spacerThickness)
  linear_extrude(discThickness, scale = 0.25) render() key_profile(keyR1);
}

module key_with_brim() {
  translate_z(2*9.5) key();
  scale([1,1.4,1]) cylinder(r=10,h=0.12);
}

//!key_with_brim();

//-----------------------------------------------------------------------------
// Locking mechanism
//-----------------------------------------------------------------------------

lugTravel1=lugOverlap-lugRetainOverlap+C;
lugTravel2=lugOverlap+0.5;
lugR1 = lugR + lugTravel - lugTravel1;
lugR2 = lugR + lugTravel - lugTravel2;

module actuator_profile(offset=0) {
  o = 4;
  intersection() {
    offset(r=o+offset) offset(r=-o)
    difference() {
      circle(lugR);
      translate([-lugR,0]) scale([lugTravel1*2,lugHeight]) circle(d=1,$fn=20);
      translate([lugR,0]) scale([lugTravel2*2,lugHeight]) circle(d=1,$fn=20);
    }
    circle(coreR);
  }
}

module lug_hole(dx=0,dz=C,dy=0) {
  linear_extrude_y(lugHeight+dy,true) {
    x = coreR-lugR-lugTravel+shackleSpacing+lugOverlap + dx;
    chamferX = 4;
    chamferZ = 3;
    sym_polygon_y([[0,-lugDepth/2+dz],[x-chamferX,-lugDepth/2+dz],[x,-lugDepth/2+dz+chamferZ]]);
  }
}
module lug(dx=0,dy=C) {
  linear_extrude(lugDepth-2*dy,center=true) {
    intersection() {
      scale([lugTravel*2-2*C,lugHeight]) circle(d=1,$fn=20);
      translate_x(-lots) square(2*lots,true);
    }
  }
  lug_hole(dx,dy);
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

coreBack=2;
module core() {
  rotate(coreAngle) group() {
    difference() {
      cylinder(r=coreR,h=coreHeight+coreBack);
      translate_z(-eps) cylinder(r=discR+C,h=coreHeight+eps);
      // sidebar slot
      translate([0,discR+2/2]) cube([sidebarThickness+2*C,2+2*gateHeight,coreHeight*2],true);
      // key end
      translate([0,0,coreHeight-2*eps]) cylinder(r1=keyR1+keyC,r2=keyR1*0.25+keyC,h=discThickness+0.5);
      if (!limiterInside) {
        translate_z(-eps) linear_extrude(coreHeight,convexity=10) rotation_limiter_slot();
      }
    }
    if (limiterInside) {
      linear_extrude(coreHeight,convexity=10) rotation_limiter();
    }
  }
  /*translate_z(coreHeight)
  difference() {
    cylinder(r=coreR,h=1);
    translate([0,0,-eps]) cylinder(r1=keyR1,r2=keyR1,h=1+2*eps);
  }*/
  rotate(-90)
  translate_z(coreHeight+coreBack) {
    // rotation limiter
    linear_extrude(2,convexity=10) {
      intersection() {
        rotate(45) union() {
          wedge_triangle(45,coreR*2);
          rotate(180) wedge_triangle(45,coreR*2);
        }
        circle(coreR);
      }
      circle(coreR-2);
    }
    translate_z(2)
    linear_extrude(lugDepth,convexity=10) {
      actuator_profile();
    }
    /*for(i=[0:0.05:3.2]) {
      translate_z(i) linear_extrude(0.1) lug_hole((3.2-i)*1.2);
    }*/
  }
}
//!core();

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

module shackle(shackleLabel = true) {
  // legs
  difference() {
    lugZ = -2 + corePos + coreHeight + coreBack + 2 + lugDepth/2;
    group() {
      translate([-shackleWidth/2,0,shackleLength-shackleLength1]) {
        cylinder(d1=shackleDiameter-4,d2=shackleDiameter,h=2);
        //translate_z(2) cylinder(d=shackleDiameter,h=shackleLength1-2);
        translate_z(lugZ-shackleTravel+2) cylinder(d=shackleDiameter,h=shackleLength-(lugZ-shackleTravel+2));
        translate_z(lugZ-shackleTravel+1) cylinder(d2=shackleDiameter,d1=shackleDiameter-2*lugRetainOverlap-2*C,h=1);
        translate_z(lugZ-shackleTravel-1) cylinder(d=shackleDiameter-2*lugRetainOverlap-2*C,h=2);
        translate_z(lugZ-shackleTravel-2) cylinder(d1=shackleDiameter,d2=shackleDiameter-2*lugRetainOverlap-2*C,h=1);
        translate_z(2) cylinder(d=shackleDiameter,h=(lugZ-shackleTravel-2)-2);
      }
      translate([shackleWidth/2,0,shackleLength-shackleLength2]) {
        cylinder(d1=shackleDiameter-4,d2=shackleDiameter,h=2);
        translate_z(2) cylinder(d=shackleDiameter,h=shackleLength2-2);
      }
    }
    mirrored([1,0,0]) {
      translate([lugR+lugTravel,0,lugZ]) lug_hole(C,-C);
    }
    x = -shackleWidth/2+shackleDiameter/2 - lugRetainOverlap - C;
    translate([x, -shackleDiameter/2, lugZ-shackleTravel]) cube([10,shackleDiameter,shackleTravel]);
  }
  // top part
  translate([0,0,shackleLength]) group() {
    // background for text
    color("red") intersection() {
      rotate([90,0,0]) rotate_extrude() {
        translate([shackleWidth/2,0]) circle(d=shackleDiameter-0.4);
      }
      positive_z();
    }
    difference() {
      intersection() {
        rotate([90,0,0]) rotate_extrude() {
          translate([shackleWidth/2,0]) circle(d=shackleDiameter);
        }
        positive_z();
      }
      if (shackleLabel)
      rotate([90,0,0])
      linear_extrude(6,convexity=10) {
        text="SOFTENED";
        for (i=[0:len(text)-1]) {
          a = (i-(len(text)-1)/2)*-12;
          translate([0,1])
          rotate(a)
          translate([0,shackleWidth/2])
          text(text[i],size=4.5,font="Ubuntu",halign="center",valign="center");
        }
      }
    }
  }
}

include <../threads.scad>

module housing(threads=true) {
  difference() {
    linear_extrude(housingDepth, convexity=10) {
      //chamfer_rect(housingWidth,housingHeight,5);
      sym_polygon_xy([
        //[1,housingHeight/2],
        [3,housingHeight/2],
        //[housingWidth/4,housingHeight/2-3],
        [housingWidth/2-1,shackleDiameter/2+shackleSpacing-1],
        [housingWidth/2,shackleDiameter/2+shackleSpacing-2],
      ]);
    }
    translate([0,0,-eps]) cylinder(r=coreR+C,h=coreHeight+2+lugDepth+2+corePos+2*C);
    // sidebar slot
    translate_z(sidebarPos) {
      //translate([coreR-1,-sidebarThickness/2-C,corePos-C]) cube([gateHeight+1,sidebarThickness+2*C,coreHeight+3*C]);
      translate_x(coreR-1) linear_extrude_x(gateHeight+1+2*C) {
        sym_polygon_x([
          [sidebarThickness/2+C-0.8,-0.5-C],
          [sidebarThickness/2+C,-0.5-C+0.7],
          /*[sidebarThickness/2+C,coreHeight/2-1],
          [0,coreHeight/2-0.2],
          [0,coreHeight/2+0.2],
          [sidebarThickness/2+C,coreHeight/2+1],
          */
          [sidebarThickness/2+C,sidebarDepth+0.5+C-0.7],
          [sidebarThickness/2+C-0.8,sidebarDepth+0.5+C],
        ]);
      }
      if (printSidebarSpring) {
        h = sidebarSpringDepth + 2*C + 1;
        translate([coreR-1,-sidebarSpringThickness/2+C,(sidebarDepth-h)/2]) {
          cube([sidebarSpringWidth+1,sidebarSpringThickness+2*C,h]);
          //cube([100,100,100]);
        }
      } else {
        translate_z(sidebarPos) {
          translate([coreR-1,0,4]) rotate([0,90,0]) cylinder(d=3.3,h=14);
          translate([coreR-1,0,sidebarDepth/2]) rotate([0,90,0]) cylinder(d=3.3,h=14);
          translate([coreR-1,0,sidebarDepth-4]) rotate([0,90,0]) cylinder(d=3.3,h=14);
        }
      }
    }
    // shackle holes
    translates([[-shackleWidth/2,0,shackleLength-shackleLength1],
                [shackleWidth/2,0,shackleLength-shackleLength2]]) {
      //translate([0,0,2]) cylinder(r1=shackleDiameter/2+C-2, r2=shackleDiameter/2+C, h=2);
      translate([0,0,1.5]) cylinder(r1=shackleDiameter/2+C-2.5, r2=shackleDiameter/2+C, h=2.5);
      translate([0,0,4]) cylinder(r=shackleDiameter/2+C, h=housingDepth);
    }
    // plug hole
    if (threads) {
      metric_thread(diameter=coreR*2+2,pitch=2,length=corePos-1+tightC,internal=true,leadin=1,angle=30);
    } else {
      cylinder(r=coreR+1+C,h=corePos-1+tightC);
    }
    cylinder(d=coreR*2+3+C,h=1.5+C);
    // lugs
    lugZ = corePos + coreHeight + coreBack + 2 + lugDepth/2 + C - 1;
    mirrored([1,0,0]) {
      translate([lugR+lugTravel-coreR,0,lugZ]) lug_hole(coreR+2*C,-C-1,2*C);
    }
    
    // set screw
    translate([-(coreR-3+10),0,setScrewPos]) rotate([0,-90,0]) cylinder(d=4,h=40);
    if (threads) {
      translate([-(coreR-3),0,setScrewPos]) rotate([0,-90,0]) m4_thread(length=10);
    } else {
      translate([-(coreR-3),0,setScrewPos]) rotate([0,-90,0]) cylinder(d=4,h=10);
    }
  }
}

module plug(threads=true) {
  difference() {
    union() {
      cylinder(r=coreR,h=corePos);
      cylinder(d=coreR*2+3,h=1.5);
      if (threads) {
        metric_thread(diameter=coreR*2+2,pitch=2,length=corePos-1,angle=30,leadin=1);
      } else {
        cylinder(r=coreR+1,h=corePos-1);
      }
    }
    translate([0,0,-eps]) cylinder(r=keyR1+1.5,h=lots);
    translate([0,0,-eps]) cylinder(r1=keyR1+2.5,r2=keyR1+1,h=1+eps);
    //translate([0,0,-1-eps]) cylinder(r1=keyR1+2,r2=keyR1+1,h=1+eps);
    if (threads) {
      translate([-(coreR-3),0,setScrewPos]) rotate([0,-90,0]) m4_thread(3+1); 
    } else {
      translate([-(coreR-3),0,setScrewPos]) rotate([0,-90,0]) cylinder(d=4,h=3+1); 
    }
    translate_z(discPos) cylinder(r=discR-2,h=spinnerCountersink+eps);
  }
}

//-----------------------------------------------------------------------------
// Sidebar
//-----------------------------------------------------------------------------

module sidebar() {
  translate_y(-sidebarThickness/2)
  difference() {
    cube([gateHeight+coreWall,sidebarThickness,sidebarDepth]);
    translate_x(-discR+gateHeight) cylinder(r=discR-2, h=spinnerThickness-spinnerCountersink+C);
  }
}

sidebarSpringWidth = 12;
sidebarSpringPrintWidth = sidebarSpringWidth + 1;
sidebarSpringDepth = sidebarDepth - 6;
sidebarSpringThickness = sidebarThickness + 2;

module wiggle(w,h,r) {
  a = atan2(h,w/2);
  rx = r/sin(a);
  ry = r/cos(a);
  //polygon([[0,0],[0,ry],[w/2-rx/2,h],[w/2+rx/2,h],[w,ry],[w,0],[w/2,h-ry]]);
  polygon([[rx/2,0],[0,0],[0,ry],[w/2-rx/2,h],[w/2+rx/2,h],[w,ry],[w,0],[w-rx/2,0],[w/2,h-ry]]);
}
module sidebar_spring() {
  h = sidebarSpringDepth;
  nx = 6;
  r = 0.5;
  linear_extrude_y(sidebarSpringThickness,center=true) {
    square([1,sidebarSpringDepth]);
    for (i=[0:nx-1]) {
      w = (sidebarSpringPrintWidth-1)/nx;
      //translate([1+i*w,0]) wiggle(w,sidebarSpringDepth,r);
      //translate([1+i*w,0]) wiggle(w,(sidebarSpringDepth-1)/2,r);
      //translate([1+i*w,sidebarSpringDepth]) mirror([0,1]) wiggle(w,(sidebarSpringDepth-1)/2,r);
      translate([i*w,i%2 ? sidebarSpringDepth-r : 0]) square([w,r]);
      translate([i*w+w-r,0]) square([r,sidebarSpringDepth]);
    }
    //square([sidebarSpringWidth,sidebarSpringDepth]);
  }
}

module sidebar_test() {
  sidebar();
  translate_x(gateHeight+coreWall) sidebar_spring();
}
!sidebar_test();

//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

//translate([0,20,0]) disc_test();

module keyway_test() {
  translate([0,0]) keyway_profile();
  for (i=[0:bits]) {
    translate([10+i*10,0]) {
      color("blue") render() key_bit_profile(bits-i);
      rotate(i*step) {
        translate([0,0,-1]) color("yellow") keyway_profile();
        translate([0,0,-2]) color("pink") rotate(2) offset(C) keyway_profile();
      }
    }
  }
}

module test() {
  $fs = 1;
  $fa = 8;
  threads = false;
  housing = true;
  key = true;
  discs = true;
  cut = false;
  //unlocked = 1;
  //open = 1;
  ts = 4;
  unlocked = max(0,min(1,ts*$t));
  open = max(0,min(1,ts*$t-1));
  shacklePos = shackleTravel*max(0,min(1,ts*$t-2));
  sidebarSpringPos = sidebarPos+(sidebarDepth-sidebarSpringDepth)/2;

  group() {
    intersection() {
      group() {
        if (housing) intersection() {
          housing(threads);
          positive_y();
        }
        rotate(open*90)
        group() {
          translate([0,0,corePos + C]) color("lightgreen") core();
          if (discs) translate_z(discPos + C/2) {
            //translate_z(0) color("lightyellow") rotate(coreAngle) spinner_disc();
            for (i=[0:len(bitting)-1]) {
              translate_z(i*(discThickness+spacerThickness)) color("lightyellow") rotate(coreAngle + unlocked * bitting[i]*step)
              mirror([1,0,0]) if (i==0) {
                spinner_disc();
              } else if (bitting[i] == 5) {
                tension_disc();
              } else {
                disc(bitting[i]);
              }
              *if (i < len(bitting)-1)
              translate_z(i*(discThickness+spacerThickness)+discThickness) color("lightyellow") rotate(coreAngle) spacer_disc();
            }
          }
          if (key) translate_z(0) color("magenta") rotate(coreAngle + keywayAngle + unlocked*bits*step) key();
          color("green") translate([discR-unlocked*gateHeight+C/2,0,sidebarPos+C/2]) sidebar();
        }
        color("blue") translate([discR-unlocked*gateHeight+C/2+gateHeight+coreWall,0,sidebarSpringPos+C/2]) scale([(sidebarSpringWidth-(1-unlocked)*gateHeight)/sidebarSpringPrintWidth,1,1]) sidebar_spring();
        translate([0,0,2+C+shacklePos]) shackle();
        color("pink") translate([0,0,0]) plug(threads);
        if (false) {
          color("pink") translate([-lugR1-(1-open)*lugTravel1,0,corePos+coreHeight+coreBack+2+lugDepth/2+C]) mirror([1,0,0]) lug();
          color("pink") translate([lugR2+(1-open)*lugTravel2,0,corePos+coreHeight+coreBack+2+lugDepth/2+C]) lug();
        }
      }
      if (cut) positive_y();
      //translate([0,-5,0]) rotate([-15]) positive_y();
      //translate_z(10) positive_z();
    }
    //rotate(-70) color("lightblue") translate([0,coreR+4.5]) cube([3,9,coreHeight*2],true);
  //translate([coreR-3,0,corePos-3.5/2-1.5]) rotate([0,90,0]) cylinder(d=4,h=6);
  }
}
!test();

//-----------------------------------------------------------------------------
// Exported parts
//-----------------------------------------------------------------------------

module export_discs() {
  translate([-1*coreR*2,0]) spinner_disc();
  for (i=[0:5]) {
    translate([i*coreR*2,0]) if (i==5) tension_disc(); else disc(i);
    translate([i*coreR*2,coreR*2]) spacer_disc();
  }
}
module export_core() {
  rotate([180]) core();
}
module export_sidebar() {
  rotate([90]) sidebar();
}
module export_sidebar_spring() {
  rotate([90]) sidebar_spring();
}
module export_shackle() {
  rotate([-90]) shackle();
}
module export_housing() {
  rotate([180]) housing();
}
module export_plug() plug();
module export_key_with_brim() key_with_brim();
export_discs();
export_core();
export_sidebar();