//=============================================================================
// Lock pinning tweezers
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>

pinR = 3/2;
w = 2;
l = 60;
tipW = 1.5;
tipDelta = 0.8;

space = 0.75;
thickness = 3;
thickness2 = 3;
overlap = -2;
angle = asin( (pinR + space + overlap) / l );
// want: l*sin(angle) - overlap = pinR + space
calculatedSpace = l*sin(angle)-overlap;
echo(calculatedSpace);
echo(pinR + space);
fuse = 2;

module tweezer() {
  linear_extrude(thickness,convexity=10) {
    difference() {
      union() {
        o=0.3;
        offset(o) offset(-o)
        union()
        mirrored([0,1,0]) {
          rotate(angle)
          translate([l+1,-space/2-overlap]) {
            intersection() {
              union() {
                difference() {
                  circle(r=pinR+tipW);
                  translate([tipDelta,0,0]) circle(r=pinR);
                }
                translate([-l-1,space/2]) square([l,w]);
              }
              translate([-l-1,space/2]) square([l+pinR*2+1,w*2]);
            }
            for (i=[0:8]) {
              translate([-l+10+fuse+i*0.7*2,w]) circle(0.7);
            }
          }
        }
        circle(w-overlap);
        rw = w-2*overlap;
        translate([0,-rw/2]) square([fuse,rw]);
      }
      
    //square(2*(w-overlap),true);
    //difference() {
      rr = fuse*sin(angle) - overlap;
      translate([fuse,0]) circle(rr);
      translate([fuse+rr,0]) square(2*rr,true);
    //}
    }
  }
}

module double_cone(r) {
  mirrored([0,0,1]) cylinder(r1=r,r2=0,h=r);
}
module chamfer_z(r) {
  minkowski() {
    children();
    double_cone(r);
  }
}
module chamfer_z2(r) {
  minkowski() {
    minkowski_difference() {
      children();
      cylinder(r=r,h=2*r,center=true);
    }
    double_cone(r);
  }
}

*group() {
  translate([0,0,6]) tweezer();
  chamfer_z2(0.5,$fn=8) tweezer();
}

//chamfer_z2(1) tweezer();

intersection() {
  tweezer();
  linear_extrude_y(100,true) {
    polygon([[-10,thickness],[fuse,thickness],[l+2+2*pinR,thickness2],[l+2+2*pinR,0],[-10,0]]);
  }
}
#translate([l+2,0,0]) circle(pinR);
#translate([l+3+pinR/2,0,0]) circle(pinR+space);