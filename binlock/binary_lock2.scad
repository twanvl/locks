//=============================================================================
// Binary lock
// by Twan van Laarhoven
//=============================================================================

include <../util.scad>;

//=============================================================================
// Parameters
//=============================================================================

//=============================================================================

C = 0.125;
coreR = 6.5;
keyR = 3.0;
pinWidth = 5;
pinWidth1 = 3;
pinWidth2 = 2.5;
pinR = keyR;
pinLen = 1.5;
pinThickness = 3;
travel = 1.2;
connectorWidth = 5;
connectorHeight = 1;
connectorClearance = 0.7;
$fa = 2;

steps = [0,120,240];
//steps = [0,90,180,270];
keyR2 = norm([pinWidth2/2,pinR-pinLen]);
keyA2 = atan2(pinWidth2/2,pinR-pinLen);

module pin(type=0) {
  intersection() {
    profile1 = [
          [-pinWidth/2,coreR],[-pinWidth/2,pinR],[-pinWidth1/2,pinR],
          for (i=[-1:2:1]) polar(90-keyA2*i,keyR2),
          [pinWidth1/2,pinR],[pinWidth/2,pinR],[pinWidth/2,coreR]];
    profile2 = [
          [-pinWidth/2,coreR],[-pinWidth/2,pinR],[-pinWidth1/2,pinR],
          for (i=[-1:2:1]) polar(90-keyA2*i,keyR2 + travel),
          [pinWidth1/2,pinR],[pinWidth/2,pinR],[pinWidth/2,coreR]];
    linear_extrude(pinThickness, convexity=10) {
      intersection() {
        difference() {
          translate_y(-travel) circle(coreR);
          translate_y(-travel-connectorHeight*(1-type)) difference() {
            square([connectorWidth,lots],true);
            circle(coreR);
          }
        }
        polygon(profile1);
      }
    }
    prism([profile2,profile1,profile1,profile2],[-eps,1,pinThickness-1,pinThickness+eps], convexity=10);
  }
}
module mid_pin(type=0) {
  linear_extrude(pinThickness) {
    intersection() {
      difference() {
        circle(coreR);
        translate_y(-travel) circle(coreR);
      }
      square([pinWidth,lots],true);
    }
    intersection() {
      difference() {
        circle(coreR);
        translate_y(-travel-connectorHeight*(1-type)) circle(coreR);
      }
      square([connectorWidth-2*connectorClearance,lots],true);
    }
    intersection() {
      difference() {
        translate_y(connectorHeight*type) circle(coreR);
        circle(coreR);
      }
      square([connectorWidth-2*connectorClearance,lots],true);
    }
  }
}
module spring(type=0,pos=0) {
  linear_extrude(pinThickness) {
    difference() {
      union() {
        translate([-pinWidth/2,0]) square([pinWidth,coreR+connectorHeight+0.5]);
        nx = 3;
        angle = 5 - 5*pos - 1;
        r = 0.5;
        w = 1;
        wLimit = 0.8;
        h = pinWidth;
        wa = w + h * sin(angle);
        gon = 60;
        translate([pinWidth/2-r/2,coreR+connectorHeight+0.5-r/2])
        rotate(90)
        line(cumsum(
          [for (i=[0:nx]) each
            [polar(i == 0 ? 90 : i%2 ? -90+angle : 90-angle,
                   h - w - r + (i==0||i==nx ? w/2 : 0))
            ,if (i<nx) for (j=[-90:360/gon:90]) polar((i%2 ? j : -j)*(180-2*angle)/180,w*sin(180/gon)) ]
          ],[0,0]), r);
        for (i=[0:nx]) {
          wa = i*w + max(0,i-0.5)*(pinWidth-(w+r)/2)*sin(angle);
          translate([0,coreR+connectorHeight+0.5+wa-r/2])
          rotate(i == 0 ? 0 : i%2 ? angle : -angle)
          intersection() {
            chamfer_rect(1.5,wLimit,r/2);
            if (i==0) positive_y2d();
            if (i==nx) negative_y2d();
          }
        }
      }
      translate_y(type*connectorHeight) circle(coreR);
    }
  }
}

module core() {
  linear_extrude(0.5) {
    circle(coreR);
  }
  translate_z(0.5)
  linear_extrude(1*pinThickness) {
    difference() {
      circle(coreR);
      circle(keyR2);
      //rotate(30) wedge(30,r=keyR,center=true);
      //rotate(30) wedge(40,r=keyR,center=true);
      //rotate(30) wedge(120,r=keyR-0.0,center=true);
      rotate(30+60) wedge(2*120,r=keyR2+travel,center=true);
      //rotate(30) translate_y(-1) square([keyR,2]);
      //rotate(30) sym_polygon_y([[0,1],[keyR-1,1],[keyR,0]]);
      rotated(steps) {
        //translate([-pinWidth/2,keyR]) square([pinWidth,coreR]);
        sym_polygon_x([[pinWidth2/2+C,0],[pinWidth2/2+C,pinR-pinLen],[pinWidth1/2+C,pinR],[pinWidth/2+C,pinR],[pinWidth/2+C,coreR]]);
        //translate([-2/2,keyR-1]) square([2,coreR]);
      }
    }
  }
}

module housing() {
  h = coreR+travel+connectorHeight+0.5+3*1+C - 0.2;
  difference() {
    linear_extrude(3+1,convexity=10) {
      offset(1.6)
      polygon([for (i=[0:len(steps)-1]) each [rot(steps[i],[-pinWidth/2,h]),rot(steps[i],[pinWidth/2,h])]]);
      //polygon([for (i=[0:2]) each [rot(i*120,[-pinWidth/2-1,h]),rot(i*120,[pinWidth/2+1,h])]]);
    }
    translate_z(0.5-eps)
    linear_extrude(3.5+2*eps+1,convexity=10) {
      circle(coreR+C);
    }
    translate_z(1)
    linear_extrude(3+2*eps+1,convexity=10) {
      rotated(steps) {
        translate([-pinWidth/2-C,0]) square([pinWidth+2*C,h]);
      }
    }
  }
}

module test() {
  displayAngle=5;
  pos=[0,0,1,1];
  type=[0,0,1,0];

  translate_z(1+2*eps)
  for (i=[0:len(steps)-1]) {
    rotate(steps[i]+displayAngle) translate_y(pos[i]*travel) group() {
      color("pink") pin(type[i]);
      if (pos[i]<1) color("lightgreen") mid_pin(type[i]);
    }
    rotate(steps[i]) translate_y(pos[i]*travel) group() {
      if (pos[i]>=1) color("lightgreen") mid_pin(type[i]);
      color("lightblue") spring(type[i],pos=pos[i]);
    }
  }
  translate_z(0.5+2*eps)
  rotate(displayAngle) core();
  color("lightyellow") housing();
}
//test();

module parts() {
  housing();
  translate([22,0]) core();
  for (i=[0:2]) {
    type = i>1 ? 1 : 0;
    translate([35 + 8*i,-10]) group() {
      pin(type);
      translate_y(3) mid_pin(type);
      translate_y(6) spring(type);
    }
  }
}
parts();