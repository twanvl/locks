//=============================================================================
// Disc detainer lock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//-----------------------------------------------------------------------------
// Model parameters
//-----------------------------------------------------------------------------

C = 0.125;
keyC = C;

eps = 1e-2;

discR = 10;
coreR = discR + 2;

discThickness = 2;
spacerThickness = 0.45;

bits = 5;
//step = -90/4; // degrees
step = -120/bits; // degrees
//step = -100/4; // degrees

gateHeight = 2.5;
falseHeight = 1;

limiterInside = true;

keyR1 = 5;
keyR2 = 3.5;
keywayAngle = 0;

discs = 10;
coreHeight = discs * (discThickness + spacerThickness);
coreAngle = 0;

corePos = 9;
setScrewPos = 4+4/2-0.5;

shackleDiameter = 8;
shackleSpacing = 4;
shackleWidth = 2*coreR + shackleDiameter + 2*shackleSpacing;

lugR=coreR-2;
lugHeight=shackleDiameter+3;
lugTravel=shackleDiameter/2+0.5;
lugDepth=8;

housingHeight = 2*coreR + 2*shackleSpacing;
housingWidth = shackleWidth + shackleDiameter + 2*shackleSpacing;
housingDepth = corePos + coreHeight + 2 + lugDepth + 2 + 2*C;

shackleLength = housingDepth + 5;

//-----------------------------------------------------------------------------
// key profile
//-----------------------------------------------------------------------------

function rot(a,p) = [cos(a)*p[0]+sin(a)*p[1], cos(a)*p[1]-sin(a)*p[0]];

module key_profile() {
  x=3.5/2;y=keyR1;
  //square([3.5,10],true);
  rotate(0) square([keyR2,5],true);
  rotate(-step*0.5) square([3,2*keyR1],true);
  rotate(step*0.5) square([3,2*keyR1],true);
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
    rotate(2*step)   intersection() {key_profile();circle(keyR2);}
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
    rotate(270) wedge(30,center=true);
  }
}
module rotation_limiter_slot() {
  for (i=[0:bits]) rotate(-i*step) offset(keyC) rotation_limiter();
}

module sidebar_slot(deep) {
  w = 2+1*C;
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

module disc(bit=0) {
  linear_extrude(discThickness) {
    difference() {
      circle(discR);
      rotate(keywayAngle) offset(keyC) keyway_profile();
      // slots
      for (i=[0:bits-1]) {
        rotate(-i*step) sidebar_slot_wiggle(i == bit);
      }
      if (limiterInside) rotation_limiter_slot();
    }
    if (!limiterInside) rotation_limiter();
  }
}
module spacer_disc() {
  linear_extrude(spacerThickness) {
    difference() {
      circle(discR);
      circle(keyR1+keyC);
      sidebar_slot_wiggle(true);
      offset(keyC) rotation_limiter();
    }
  }
}
module tension_disc() {
  linear_extrude(discThickness) {
    difference() {
      circle(discR);
      rotate(keywayAngle) offset(keyC) keyway_profile();
      rotate(-bits*step)
      {
        //sidebar_slot_wiggle(true);
        w = 2+1*C;
        h = 2.5;
        translate([0,discR])
        polygon([[-w/2,0],[-w/2,-h],[w/2,-h],[w*4/2,0]]);
      }
      rotation_limiter_slot();
    }
  }
}
module spinner_disc() {
  difference() {
    union() {
      translate([0,0,1])
      cylinder(r1=discR,r2=discR-2,h=2);
      /*linear_extrude(3) {
        circle(discR-2);
      }
      linear_extrude(2) {
        circle(discR);
      }*/
      linear_extrude(1) {
        circle(coreR);
      }
    }
    translate([0,0,-C]) linear_extrude(3+2*C) {
      rotate(keywayAngle) offset(keyC) intersection() { key_profile(); circle(keyR1); }
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
    translate_z(10) negative_z();
  }
}
!disc_test();

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module lug_hole(offset=0) {
  o = 4;
  intersection() {
    offset(r=o+offset) offset(r=-o)
    difference() {
      circle(lugR);
      translate([-lugR,0]) scale([lugTravel*2,lugHeight]) circle(d=1,$fn=20);
      translate([lugR,0]) scale([lugTravel*2,lugHeight]) circle(d=1,$fn=20);
    }
    circle(coreR);
  }
}

module core() {
  rotate(coreAngle) group() {
    difference() {
      /*
      linear_extrude(coreHeight,convexity=10) {
        difference() {
          circle(coreR);
          circle(discR+C/2);
          translate([0,discR+2/2]) square([2,2],true);
        }
        rotation_limiter();
      }*/
      cylinder(r=coreR,h=coreHeight+1);
      translate_z(-eps) cylinder(r=discR+C,h=coreHeight+eps);
      translate([0,discR+2/2]) cube([2,2+2*gateHeight,coreHeight*2],true);
      translate([0,0,coreHeight-2*eps]) cylinder(r=keyR1+keyC,h=1+eps);
    }
    linear_extrude(coreHeight,convexity=10) rotation_limiter();
  }
  /*translate_z(coreHeight)
  difference() {
    cylinder(r=coreR,h=1);
    translate([0,0,-eps]) cylinder(r1=keyR1,r2=keyR1,h=1+2*eps);
  }*/
  rotate(90)
  translate_z(coreHeight+1) {
    linear_extrude(2) {
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
    linear_extrude(lugDepth) {
      lug_hole();
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

module shackle() {
  translate([-shackleWidth/2,0,0]) cylinder(d1=shackleDiameter-4,d2=shackleDiameter,h=2);
  translate([shackleWidth/2,0,0]) cylinder(d1=shackleDiameter-4,d2=shackleDiameter,h=2);
  translate([-shackleWidth/2,0,2]) cylinder(d=shackleDiameter,h=shackleLength-2);
  translate([shackleWidth/2,0,2]) cylinder(d=shackleDiameter,h=shackleLength-2);
  color("red") translate([0,0,shackleLength])
    intersection() {
      rotate([90,0,0]) rotate_extrude() {
        translate([shackleWidth/2,0]) circle(d=shackleDiameter-0.4);
      }
      positive_z();
    }
  translate([0,0,shackleLength])
  difference() {
    intersection() {
      rotate([90,0,0]) rotate_extrude() {
        translate([shackleWidth/2,0]) circle(d=shackleDiameter);
      }
      positive_z();
    }
    *rotate([90,0,0])
    linear_extrude(6,convexity=10) {
      text="SOFTENED";
      for (i=[0:len(text)-1]) {
        a = (i-(len(text)-1)/2)*-12;
        translate([0,1])
        rotate(a)
        translate([0,20])
        text(text[i],size=4.5,font="Ubuntu",halign="center",valign="center");
      }
    }
  }
}

include <../threads.scad>

module housing() {
  difference() {
    linear_extrude(housingDepth, convexity=10) {
      //chamfer_rect(housingWidth,housingHeight,5);
      sym_polygon_xy([
        [1,housingHeight/2],
        //[housingWidth/4,housingHeight/2-3],
        [housingWidth/2-1,shackleDiameter/2+shackleSpacing-1],
        [housingWidth/2,shackleDiameter/2+shackleSpacing-2],
      ]);
    }
    translate([0,0,-eps]) cylinder(r=coreR+C,h=coreHeight+2+lugDepth+2+corePos+2*C);
    translates([[-shackleWidth/2,0,0],[shackleWidth/2,0,0]]) {
      translate([0,0,2]) cylinder(r1=shackleDiameter/2+C-2, r2=shackleDiameter/2+C, h=2);
      translate([0,0,4]) cylinder(r=shackleDiameter/2+C, h=housingDepth);
    }
    metric_thread(diameter=coreR*2+2,pitch=2,length=corePos-1,internal=true,leadin=1,angle=30);
    cylinder(d=coreR*2+3+C,h=2);
    translate([coreR-3+10,0,setScrewPos]) rotate([0,90,0]) cylinder(d=4,h=40); // for set screw
    translate([coreR-3,0,setScrewPos]) rotate([0,90,0]) m4_thread(length=10); // for set screw
  }
}

module plug() {
  difference() {
    union() {
      cylinder(r=coreR,h=corePos);
      cylinder(d=coreR*2+3,h=1);
      //translate_z(-1) cylinder(r1=coreR-1,r2=coreR,h=1);
      metric_thread(diameter=coreR*2+2,pitch=2,length=corePos-1,angle=30,leadin=1);
    }
    translate([0,0,-eps]) cylinder(r=keyR1+1,h=corePos+10);
    translate([0,0,-eps]) cylinder(r1=keyR1+2,r2=keyR1+1,h=1+eps);
    //translate([0,0,-1-eps]) cylinder(r1=keyR1+2,r2=keyR1+1,h=1+eps);
    translate([coreR-3,0,setScrewPos]) rotate([0,90,0]) m4_thread(3+1); 
    translate_z(corePos-1) cylinder(r=discR-2+C,h=1+eps);
  }
}

$fs = 1;
$fa = 8;

!translate([0,-20,0])
group() {
intersection() {
  group() {
    housing();
    translate([0,0,corePos+C]) core();
    translate([0,0,2+C]) shackle();
    //color("pink") translate([0,0,0]) plug();
    color("pink") translate([60,0,0]) plug();
  }
  positive_y();
  //translate_z(10) positive_z();
}
  rotate(-70) color("lightblue") translate([0,coreR+4.5]) cube([3,9,coreHeight*2],true);
//translate([coreR-3,0,corePos-3.5/2-1.5]) rotate([0,90,0]) cylinder(d=4,h=6); 
}


//-----------------------------------------------------------------------------
// Tests
//-----------------------------------------------------------------------------

translate([0,20,0]) disc_test();

translate([0,0]) keyway_profile();
for (i=[0:bits]) {
  translate([10+i*10,0]) 
  rotate(-i*step){
    color("blue")
    intersection() {
      keyway_profile();
      rotate(i*step) key_profile();
      //for_intersection (j=[0:0.1:1]) rotate(i*step*j) key_profile();
      rotate(i*step*0.95) keyway_profile();
      rotate(i*step*0.75) keyway_profile();
      //rotate(i*step*0.65) keyway_profile();
      rotate(i*step*0.40) keyway_profile();
      rotate(i*step*0.45) keyway_profile();
      rotate(i*step*0.50) keyway_profile();
      rotate(i*step*0.35) keyway_profile();
      rotate(i*step*0.25) keyway_profile();
      rotate(i*step*0.15) keyway_profile();
      rotate(i*step*0.10) keyway_profile();
      rotate(i*step*0.5) keyway_profile();
      rotate(i*step*0.2) keyway_profile();
      rotate(i*step*0)    keyway_profile();
      rotate(i*step) keyway_profile();
    }
    translate([0,0,-1]) color("yellow") keyway_profile();
    translate([0,0,-2]) color("pink") rotate(2) offset(C) keyway_profile();
  }
}