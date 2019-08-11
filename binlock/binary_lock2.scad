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
coreC = 0.15;

coreR = 8;
pinR = 3.3;
pinWidth = 8;
pinWidth0 = pinWidth;
pinWidth1 = 5;
pinWidth2 = 4.5;
springWidth = pinWidth0;
driverHeight = 0.0;
pinLen = 1.5+0.5;
pinThickness = 3;
travel = 1.6;
/*
connectorWidth = pinWidth-1;
connectorWidth2 = springWidth-1;
connectorClearance = 0.5;
*/
connectorHeight = 1.2;
$fa = 2;
midPinAngle = 12;

steps = [0,120,240];
//steps = [0,90,180,270];
keyR2 = norm([pinWidth2/2,pinR-pinLen]);
keyA2 = atan2(pinWidth2/2,pinR-pinLen);

layerHeight = 0.15;
firstLayerHeight =  layerHeight;
function roundToLayerHeight(z) = round((z-firstLayerHeight)/layerHeight)*layerHeight + firstLayerHeight;

module pin_profile(C=0) {
  w = roundToLayerHeight(0.9);
  h = roundToLayerHeight(0.3);
  linear_extrude_y(lots,true) {
    sym_polygon_x([[pinWidth/2+C,0],[pinWidth/2+C,pinThickness-w-h],[pinWidth/2-w+C,pinThickness-h],[pinWidth/2-w+C,pinThickness+eps+layerHeight]]);
  }
  *linear_extrude_y(100,true) {
    sym_polygon_x([[pinWidth/2+C,0],[pinWidth/2+C,pinThickness+eps+C]]);
  }
}

module pin(type=0) {
  chamferX = 0.5;
  chamferY = 1.2;
  chamferZ = roundToLayerHeight(1);
  pinWidth3 = pinWidth2 + (pinWidth1-pinWidth2)*(chamferY/pinLen);
  color("red")
  intersection() {
    profile1 = [
          [-pinWidth0/2,coreR],[-pinWidth/2,pinR],[-pinWidth1/2,pinR],
          [-pinWidth2/2,pinR-pinLen],[pinWidth2/2,pinR-pinLen],
          //for (i=[-1:2:1]) polar(90-keyA2*i,keyR2),
          [pinWidth1/2,pinR],[pinWidth/2,pinR],[pinWidth0/2,coreR]];
    profile2 = [
          [-pinWidth0/2,coreR],[-pinWidth/2,pinR],[-pinWidth1/2+chamferX,pinR],
          //for (i=[-1:2:1]) polar(90-keyA2*i,keyR2 + travel),
          [-pinWidth3/2+chamferX,pinR-pinLen+chamferY],[pinWidth3/2-chamferX,pinR-pinLen+chamferY],
          [pinWidth1/2-chamferX,pinR],[pinWidth/2,pinR],[pinWidth0/2,coreR]];
    linear_extrude(pinThickness, convexity=10) {
      intersection() {
        translate_y(-travel) circle(coreR-connectorHeight*(1-type));
        //polygon(profile1);
      }
    }
    prism([profile2,profile1,profile1,profile2],[-eps,chamferZ,pinThickness-chamferZ,pinThickness+eps], convexity=10);
    pin_profile();
  }
}
module mid_pin(type=0) {
  intersection() {
    linear_extrude(pinThickness) difference() {
      circle(coreR);
      translate_y(-travel) circle(coreR+C);
    }
    pin_profile();
  }
  intersection() {
    linear_extrude(pinThickness) difference() {
      circle(coreR+connectorHeight*type);
      translate_y(-travel) circle(coreR-connectorHeight*(1-type)+C);
    }
    if (type == 0) intersection() {
      rotate(midPinAngle) pin_profile();
      rotate(-midPinAngle) pin_profile();
    } else intersection() {
      dx = coreR * sin(midPinAngle);
      translate_x(dx) pin_profile();
      translate_x(-dx) pin_profile();
    }
  }
}
!mid_pin(0);
module driver_pin(type=0) {
  intersection() {
    linear_extrude(pinThickness, convexity=5) {
      difference() {
        translate([-springWidth/2,0]) square([springWidth,coreR+connectorHeight+driverHeight]);
        translate_y(type*connectorHeight) circle(coreR);
        translate_y(type*connectorHeight+coreR-0.8) negative_y2d();
      }
    }
    pin_profile();
  }
}
module spring(type=0,pos=0,extend=0) {
  linear_extrude(pinThickness - 1, convexity=5) {
    nx = 2;
    angle = 10 - 10*pos + 5*extend;
    r = 0.5;
    w = (7-type*travel) / nx;
    wLimit = 1.8;
    dh = 1;
    h = springWidth-dh;
    wa = w + h * sin(angle);
    gon = 60;
    flatEnds = true;
    translate([springWidth/2-r/2-dh/2,coreR+connectorHeight*(type)+driverHeight+r/2])
    rotate(90)
    line(cumsum(
      [for (i=[0:nx]) each
        [polar(flatEnds&&(i == 0||i==nx) ? 90 : i%2 ? -90+angle : 90-angle,
               h - w - r + (i==0||i==nx ? w/2 : 0))
        ,if (i<nx) for (j=[-90:360/gon:90]) polar((i%2 ? j : -j)*(180-2*angle)/180,w*sin(180/gon)) ]
      ],[0,0]), r);
  }
}
//!spring(0);

module core() {
  union() {
    linear_extrude(roundToLayerHeight(0.6)+eps) {
      circle(coreR);
    }
    translate_z(roundToLayerHeight(0.6))
    difference() {
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
        }
      }
      rotated(steps) {
        intersection() {
          translate_z(-eps)
          linear_extrude(1*pinThickness+2*eps, convexity=3) {
            //translate([-pinWidth/2,keyR]) square([pinWidth,coreR]);
            sym_polygon_x([[pinWidth2/2+C,0],[pinWidth2/2+C,pinR-pinLen],[pinWidth1/2+C,pinR],[pinWidth/2+C,pinR],[pinWidth0/2+C,coreR]]);
            //translate([-2/2,keyR-1]) square([2,coreR]);
          }
          pin_profile(C=C);
        }
      }
    }
  }
}


module housing() {
  h = coreR+travel+connectorHeight+driverHeight+3*2+C - 0.2;
  difference() {
    linear_extrude(3+2*roundToLayerHeight(0.6),convexity=10) {
      offset(1.6)
      polygon([for (i=[0:len(steps)-1]) each [rot(steps[i],[-springWidth/2,h]),rot(steps[i],[springWidth/2,h])]]);
      //polygon([for (i=[0:2]) each [rot(i*120,[-pinWidth/2-1,h]),rot(i*120,[pinWidth/2+1,h])]]);
    }
    translate_z(roundToLayerHeight(0.6)-eps)
    linear_extrude(3.5+2*eps+1,convexity=10) {
      circle(coreR+coreC);
    }
    translate_z(2*roundToLayerHeight(0.6) - 1*layerHeight)
    rotated(steps) {
      intersection() {
        *linear_extrude(3+2*eps+1,convexity=10) {
          translate([-springWidth/2-C,0]) square([springWidth+2*C,coreR+travel+connectorHeight+driverHeight+C]);
          translate([-(springWidth-1)/2-C,0]) square([(springWidth-1)+2*C,h]);
        }
        union() {
          //translate([-springWidth/2-C,0,0]) cube([springWidth+2*C,coreR+travel+connectorHeight+driverHeight+C, pinThickness+layerHeight+eps]);
          translate([0,travel,0]) cylinder(r=coreR+coreC, pinThickness+layerHeight+eps);
          //translate([-(springWidth-1)/2-C,0,layerHeight]) cube([springWidth-1+2*C,h, pinThickness-1+0.5]);
          translate([-(springWidth-1)/2-C,0,0]) cube([springWidth-1+2*C,h, pinThickness+layerHeight+eps]);
        }
        pin_profile(C=C);
      }
    }
  }
}

module test() {
  displayAngle=5;
  type=[0,0,1,0];
  pos=[0,1,0,1];

  translate_z(2*roundToLayerHeight(0.6)+1*eps)
  for (i=[0:len(steps)-1]) {
    rotate(steps[i]+displayAngle) translate_y(pos[i]*travel) group() {
      color("pink") pin(type[i]);
      if (pos[i]<1) color("lightgreen") mid_pin(type[i]);
    }
    rotate(steps[i]) translate_y(pos[i]*travel) group() {
      if (pos[i]>=1) color("lightgreen") mid_pin(type[i]);
      //color("lightsalmon") driver_pin(type[i]);
      translate_z(0.3) color("lightblue") spring(type[i],pos=pos[i]);
    }
  }
  translate_z(roundToLayerHeight(0.6)+2*eps)
  rotate(displayAngle) core();
  color("lightyellow") intersection() {
    housing();
    translate_z(1.3) positive_z();
  }
}
//!test();

module parts() {
  housing();
  translate([28,0]) core();
  for (i=[0:2]) {
    type = i>=1 ? 1 : 0;
    translate([45 + 10*i,-10]) group() {
      pin(type);
      translate_y(3) mid_pin(type);
      translate_y(6) spring(type,extend=1);
    }
  }
}
parts();