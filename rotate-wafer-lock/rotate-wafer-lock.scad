//

include <../util.scad>

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

bitting = [-1,0,1,-0.5,1,0.5];
//bitting = [1,-1,-1,0.5];

coreR = 15 / 2;
waferWidth = 9.5;
waferThickness = roundToLayerHeight(2);
sepThickness = roundToLayerHeight(2);

keyWidth   = 6;
keyHeight1 = roundToLayerHeight(2.2);
keyHeight2 = roundToLayerHeight(keyHeight1 + 0.3);
keyHeight3 = keyHeight1+0;
//keyHeight2 = keyHeight1;
keyChamfer  = 0.3;
keyChamfer2 = 0.4;
step = keyWidth/2-keyHeight3/2;

//-----------------------------------------------------------------------------
// Key
//-----------------------------------------------------------------------------

module key_profile() {
  if (0) {
    C=0;
    translate_x(-(keyHeight1-2*keyChamfer)/2) chamfer_rect(keyWidth+2*C-(keyHeight1-2*keyChamfer),keyHeight1+2*C,keyChamfer);
    translate_x((keyWidth-keyHeight1)/2) offset(delta=C) key_bit_profile();
  } else render() union() {
    chamfer_rect(keyWidth,keyHeight1,keyChamfer, r_bl=keyChamfer2, r_tr=1.5);
    // make room for rotating the bitting prongs at the edges of the key
    // shape traced out by key_bit_profile at -bit*step and bit*step, rotated around (0,0),
    // but shifted so that vertical height remains constant, i.e. by sin(a)*x+dy(a)
    // the points traced out are
    for (bit=[-1,1]) {
      for (a=[0:2:90]) {
        translate_y(-bit*step*sin(a) - dy(a))
        rotate(a) key_bit_profile(bit);
      }
    }
    //key_bit_profile(-1);
    // trace corners of key_bit_profile
    for (x=[-step,step]) {
      //p=[x+keyHeight1/2,-keyHeight1/2];
      dc=(keyHeight1-diagonal(keyHeight1/2,keyHeight1/2-keyChamfer2)) / sqrt(2);
      corners=[
        [x-keyHeight1/2,keyHeight1/2-keyChamfer],
        [x-keyHeight1/2+keyChamfer,keyHeight1/2],
        [x+keyHeight1/2-keyChamfer,-keyHeight1/2],
        [x+keyHeight1/2,-keyHeight1/2+keyChamfer],
        // point at distance keyHeight1 from both bottom left corners
        [x+dc,dc]
      ];
      for (p=corners) {
        polygon([for (a=[0:2:90]) rot(-a,p) + [0,-x*sin(a) - dy(a)]]);
      }
    }
  }
}
*!key_profile();

module key_bit_profile(bit=0) {
  translate_x(bit*step) {
    //square([keyHeight1,keyHeight1],true);
    //circle(keyHeight1/2);
    intersection() {
      h = keyHeight1;
      w = keyHeight3;
      chamfer_rect(w,h,keyChamfer,r_bl=keyChamfer2);
      // make sure that the shape can be rotated
      //translate([w/2,-h/2+keyChamfer]) scale([w/h,1]) circle(r=h);
      //translate([w/2-keyChamfer,-h/2]) scale([w/h,1]) circle(r=h);
      translate([-w/2,-h/2+keyChamfer2]) scale([w/h,1]) circle(r=h);
      translate([-w/2+keyChamfer2,-h/2]) scale([w/h,1]) circle(r=h);
    }
  }
}

module key_profile_test_wafer() {
  linear_extrude(waferThickness) {
    difference() {
      intersection() {
        translate_y(step) circle(r = coreR);
        translate_y(-step) circle(r = coreR);
        square([waferWidth,lots],true);
      }
      //translate_y(-(keyHeight2-keyHeight1)*0.5)
      key_profile(C=eps);
      translate_y(keyHeight2*1.2) key_profile(C=eps);
    }
  }
}

// point where bottom of keyway touches key at given angle
//function dy(a) = -1*sin(a) * (keyHeight2/2 - keyChamfer);
function dy(a) = min(-keyHeight1/2,min(
  rot(a, [keyHeight3/2 - keyChamfer2, -keyHeight1/2])[1],
  rot(a, [keyHeight3/2, -keyHeight1/2 + keyChamfer2])[1]))
  + keyHeight1/2;
module key_profile_test() {
  bit = 1;
  a = 10;
  rotate(a) linear_extrude(sepThickness) key_profile();
  translate_y(bit*step * sin(a)) {
    translate_x(bit*step * cos(a))
    rotate(a) color("green") linear_extrude(10) key_bit_profile();
    //color("yellow") rotate(0) key_profile_test_wafer();
    translate_z(3) color("yellow") translate_y(dy(a)) key_profile_test_wafer();
  }
}
*!key_profile_test();

module linear_extrude_z_chamfer_y(height,chamfer) {
  intersect_offset_y(chamfer)
  minkowski() {
    linear_extrude(eps) {
      children();
    }
    translate_z(height/2) linear_extrude_x(eps) {
      chamfer_rect(2*chamfer,height,chamfer);
    }
  }
}
module intersect_offset_y(y=1) {
  intersection() {
    translate_y(-y) children();
    translate_y(y) children();
  }
}

module linear_extrude_chamfer2(height,chamfer1,chamfer2,center=false,convexity=4) {
  translate_z(center ? -height/2 : 0) {
    minkowski() {
      linear_extrude(eps) children();
      c = 0.5;
      cylinder(h=c,r1=c,r2=0,$fn=4);
    }
  }
}

// linear extrude with hacky chamfer based on scaling, works ok for rectangular shapes
module linear_extrude_scale_chamfer(height,xsize,ysize,chamfer1,chamfer2,center=false,slope=1,convexity=4) {
  translate_z(center ? -height/2 : 0) {
    if (chamfer1 > 0) {
      scale([1-2*slope*chamfer1/xsize,1-2*slope*chamfer1/ysize])
      linear_extrude(chamfer1+eps, scale=[1/(1-2*slope*chamfer1/xsize),1/(1-2*slope*chamfer1/ysize)]) children();
    }
    translate_z(chamfer1)
    linear_extrude(height-chamfer1-chamfer2) children();
    if (chamfer2 > 0) {
      translate_z(height-chamfer2-eps)
      linear_extrude(chamfer2+eps, scale=[1-2*slope*chamfer2/xsize,1-2*slope*chamfer2/ysize]) children();
    }
  }
}

*!linear_extrude_scale_chamfer(sepThickness,keyWidth*2,keyHeight1,0.31,0.31,slope=1) {
  key_profile();
}
*!linear_extrude_z_chamfer_y(sepThickness,0.3) {
  key_profile();
}

module key() {
  for (i=[0:len(bitting)-1]) {
    chamfer=0.3;
    translate_z(i*(waferThickness+sepThickness) + (i>0 ? C : -2))
    linear_extrude_scale_chamfer(sepThickness - C - (i>0 ? C : -2), 2*keyWidth,keyHeight1, chamfer,chamfer) {
      key_profile();
    }
    translate_z(i*(waferThickness+sepThickness) + sepThickness/2-eps)
    if (i == len(bitting)-1) {
      translate_x(bitting[i]*step)
      linear_extrude_scale_chamfer(waferThickness + sepThickness/2 + eps, keyHeight1,keyHeight1, 0,chamfer)
      translate_x(-bitting[i]*step) {
        key_bit_profile(bitting[i]);
      }
    } else {
      linear_extrude(waferThickness + sepThickness + 2*eps) {
        key_bit_profile(bitting[i]);
      }
    }
  }
  h1 = 3;
  translate_z(-(h1+4)) {
    linear_extrude(h1+4+eps) {
      intersection() {
        circle(r = keyHoleR);
        chamfer_rect(2*keyHoleR,keyHeight1,keyChamfer+0.1);
      }
    }
  }
  translate_z(-h1) key_handle();
}
module key_handle() {
  w = 16; // handle
  r = 2.5; // hole
  translate_z(-w/2)
  rotate([90]) {
    difference() {
      group() {
        cylinder(r=w/2,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=w/2,r2=w/2-keyChamfer,h=keyChamfer);
      }
      translate_y(-3.5)
      group() {
        cylinder(r=r,h=keyHeight1-2*keyChamfer+2*eps,center=true);
        mirrored([0,0,1]) translate_z(keyHeight1/2-keyChamfer)
        cylinder(r1=r,r2=r+keyChamfer,h=keyChamfer+2*eps);
      }
    }
  }
}

*!key();

module export_key() { rotate([90]) key(); }
*!export_key();

//-----------------------------------------------------------------------------
// Wafers
//-----------------------------------------------------------------------------

//gateC = C/2;
gateC = 0;
gateCHousing = C/2;
falseGate = 0.5;

module keyway(height) {
  chamfer = roundToLayerHeight(0.4);
  translate_z(-eps)
  linear_extrude_scale_chamfer(height+2*eps, 2*keyWidth,keyHeight1, chamfer,chamfer, slope=-1) {
    offset(delta=C) key_profile();
  }
}

module wafer(bit) {
  difference() {
    linear_extrude(waferThickness, convexity=2) {
      difference() {
        intersection() {
          translate_y(step) circle(r = coreR);
          translate_y(-step) circle(r = coreR);
          square([waferWidth,lots],true);
        }
        *translate_y(-(keyHeight3-keyHeight1)*0.5)
          offset(delta=C) key_profile();
        // gate
        translate_y(-bit*step) offset(delta=gateC) sidebar_profile();
        for (i=[-1:0.5:1]) {
          if (abs(i-bit)>=1)
          translate_y(-i*step) offset(delta=gateC) sidebar_profile(1 - falseGate);
        }
        if (springTravel>0) {
          offset(delta=C) spring_gate_profile(chamfered=false);
        }
      }
    }
    keyway(waferThickness);
  }
}
*!wafer(-1);

spacerR = waferWidth/2 + 0.15;
limiterThickness = roundToLayerHeight(sepThickness/2);
module spacer() {
  intersection() {
    difference() {
      //for (limiter = [0,1]) {
      limiter = 1;{
        //translate_z(limiter ? sepThickness-limiterThickness : 0)
        //linear_extrude(limiter ? limiterThickness : sepThickness, convexity=2) {
        linear_extrude(sepThickness, convexity=4) {
          difference() {
            union() {
              circle(r = spacerR);
              if (limiter) spacer_limiter_profile();
            }
            *translate_y(-(keyHeight3-keyHeight1)*0.5)
              offset(delta=C) key_profile();
            rotate(-90) offset(delta=C) sidebar_profile();
            if (springTravel>0) {
              offset(delta=C) spring_gate_profile();
            }
          }
        }
      }
      keyway(sepThickness);
    }
    union() {
      z2 = sepThickness - 3*layerHeight;
      *translate_z(-eps) cylinder(r=spacerLimiterR,h=z1+2*eps);
      *translate_z(z1) cylinder(r1=spacerLimiterR,r2=spacerR,h=z2-z1+eps);
      cylinder(r=spacerR,h=sepThickness+2*eps);
      difference() {
        translate_z(3*layerHeight-eps) cylinder(r=spacerLimiterR,h=sepThickness-3*layerHeight+2*eps);
        core_spacer_holders(C=0);
        rotate(90) core_spacer_holders(C=0);
      }
    }
  }
}
spacerLimiterR = sqrt(2)*spacerR - 0.5;
module spacer_limiter_profile() {
  intersection() {
    circle(r = spacerLimiterR);
    square(waferWidth,true);
    //square(spacerR);
    rotate(-45) square([2,lots],true);
  }
}
*!spacer();

module spacer_slot(C=0) {
  z1 = roundToLayerHeight(sepThickness * 0.2);
  z2 = roundToLayerHeight(sepThickness * 0.7);
  z3 = roundToLayerHeight(sepThickness * 1) - layerHeight;
  x = waferWidth/2+C;
  x2 = x + z2-z1;
  //translate_z(layerHeight/2)
  mirrored([1,0,0]) rotated(180) {
    translate_y(side_given_diagonal(spacerLimiterR+C,waferWidth/2)) {
      linear_extrude_y(coreR) {
        polygon([[x,z1],[x2,z2],[x2,z3],[x,z3]]);
      }
    }
  }
}

module export_spacer() { rotate([180]) spacer(); }
module export_wafers() {
  for (i=[0:len(bitting)-1]) {
    translate_x(i * (waferWidth + 5)) {
      rotate([180]) wafer(bitting[i]);
      translate_y(2*coreR+5) rotate([180]) spacer();
    }
  }
}

//-----------------------------------------------------------------------------
// Core
//-----------------------------------------------------------------------------

module core_profile(part_slots) {
  difference() {
    circle(r=coreR);
    square([waferWidth+2*C,lots],true);
    circle(r=spacerR+C);
    translate_x(-lots/2) square([lots,sidebarThickness+C],true);
    if (springTravel > 0) {
      translate_x(lots/2) square([lots,springThickness+2*C],true);
    }
    if (part_slots) square([waferWidth+2+C,6+C],true);
  }
}
module core(back = true) {
  h = len(bitting)*(waferThickness+sepThickness) + layerHeight;
  h1 = 0;//len(bitting)/2*(waferThickness+sepThickness);
  coreBack = roundToLayerHeight(1);
  difference() {
    group() {
      linear_extrude(h1, convexity=4) {
        core_profile(true);
      }
      translate_z(h1) linear_extrude(h-h1, convexity=4) {
        core_profile(false);
      }
    }
    *for (i=[2:len(bitting)-1]) {
      translate_z(i*(waferThickness+sepThickness)) {
        tightC = C/2;
        spacer_slot(tightC);
      }
    }
  }
  for (i=[0:len(bitting)-1]) {
    translate_z(i*(waferThickness+sepThickness)) {
      difference() {
        core_spacer_holders();
        translate_z(-eps) cylinder(r=spacerR+C,h=sepThickness+2*eps);
      }
    }
  }
  if (back) {
    translate_z(h) linear_extrude(coreBack) {
      circle(r=coreR);
    }
  }
}
module core_spacer_holders(C=C) {
  z1 = sepThickness - 2*layerHeight;
  z2 = 3*layerHeight;
  z3 = 1*layerHeight-(C>0?0:2*layerHeight);
  h = 2*side_given_diagonal(coreR,waferWidth/2+C);
  linear_extrude_y(h,true) {
    x1 = waferWidth/2+C+eps;
    x2 = x1 - (z1-z2) * 1.2;
    mirrored([1,0,0]) polygon([[x1,z1],[x2,z2],[x2,z3],[x1,z3]]);
  }
}
*!core();

module core_part(x_slot=false, z_slot=true) {
  tightC = C/2;
  difference() {
    linear_extrude(sepThickness + waferThickness, convexity=2) {
      difference() {
        union() {
          intersection() {
            circle(r=coreR);
            square([waferWidth+2*C-2*tightC,lots],true);
          }
          //translate_x(waferWidth/2) square([2,6],true);
          if (x_slot) {
            square([waferWidth+2,6],true);
          }
        }
        circle(r=spacerR+C);
        translate_x(-lots/2) square([lots,sidebarThickness+C],true);
      }
    }
    translate_z(sepThickness - layerHeight) {
      linear_extrude(lots) {
        square([waferWidth+2*C+2*eps,lots],true);
      }
    }
    translate_z(sepThickness - limiterThickness - layerHeight) {
      linear_extrude(lots, convexity=2) {
        rotated(90) offset(delta=C) spacer_limiter_profile();
        rotated(180) rotate(45) wedge(90,r=spacerLimiterR+C);
      }
    }
  }
  if (z_slot) {
    intersection() {
      spacer_slot();
      cylinder(r=coreR-eps, h=sepThickness);
    }
  }
}

sidebarThickness = roundToLayerHeight(2.0);
sidebarChamfer = sidebarThickness/2;//0.8;
sidebarChamfer2 = 0.6;
sidebarTravel = 0.7;
module sidebar_profile(pos = 0, extraY = 0, lessChamfer=0) {
  //x = side_given_diagonal(coreR,sidebarThickness/2);
  x = coreR;
  w = x - spacerR + sidebarTravel;
  translate_x(-pos*sidebarTravel) intersection() {
    circle(r=coreR);
    translate_x(w/2 - x)
      chamfer_rect(w, sidebarThickness + 2*extraY, sidebarChamfer+extraY-lessChamfer, r_tl=sidebarChamfer2+extraY, r_bl=sidebarChamfer2+extraY);
    *union() {
      *translate_x(w/2 - x) {
        chamfer_rect(w,sidebarThickness,sidebarChamfer);
      }
      *translate_x(sidebarThickness/2 - x) {
        chamfer_rect(sidebarThickness,sidebarThickness,sidebarChamfer2);
      }
    }
  }
}
module sidebar(pos = 0) {
  h = len(bitting)*(waferThickness+sepThickness);
  linear_extrude(h) {
    sidebar_profile(pos,lessChamfer=layerHeight/2);
  }
}

springTravel = 0.5;
springThickness = roundToLayerHeight(1);

module spring_gate_profile(pos = 0, chamfered = true) {
  *translate([spacerR - (1-pos)*springTravel, -springThickness/2]) {
    square([coreR-spacerR, springThickness]);
  }
  chamfer = chamfered ? springTravel : 0;
  extraW  = chamfered ? springTravel-0.1 : 0.1;
  translate([(coreR+spacerR)/2 - (1-pos)*springTravel, 0]) {
    chamfer_rect(coreR-spacerR, springThickness + 2*extraW, chamfer);
  }
}
module spring(pos = 0, extra = 0.0, angle = 0) {
  h = len(bitting) * (waferThickness + sepThickness);
  baseW = side_given_diagonal(coreR, springThickness/2) - spacerR;
  barW = baseW - 0.2;
  w = baseW + (1-pos) * springTravel + extra;
  barLW = springTravel + 0.2;
  bar = 1.5;
  sep = 0.5;
  
  translate_x(spacerR - (1-pos)*springTravel) {
    linear_extrude_y(springThickness,true) {
      translate([barLW-0.5,bar+sep])
      spring_profile(w-barLW+0.5,h-2*bar-2*sep,turns=2,curved=false,angle=angle,right_flat=true);
      square([barLW,h]);
      square([barW,bar]);
      translate_y(h-bar) square([barW,bar]);
    }
  }
}
*!spring();
*!group() {
  translate_y(6) spring(angle=4);
  translate_y(4) spring(extra=0.5,angle=2);
  translate_y(2) spring(extra=0.5);
  spring();
  translate_y(-2) spring(pos=1);
  translate_y(-4) translate_x(springTravel) spring(extra=0.5, angle=-4);
  translate_y(-6) translate_x(springTravel) spring(extra=0.0, angle=-3);
}

module export_core() { rotate([180]) core(); }
module export_core_part1() { core_part(true,false); }
module export_core_part() { core_part(); }
module export_sidebar() { rotate([90]) sidebar(); }
module export_spring() { rotate([90]) spring(angle=4); }

//-----------------------------------------------------------------------------
// Housing
//-----------------------------------------------------------------------------

keyHoleR = diagonal(keyWidth/2,keyHeight1/2-keyChamfer) + 0.1;
housingWall = 0.8;
housingR = coreR+C+housingWall;
module housing() {
  t = roundToLayerHeight(1.5);
  w = housingR;
  translate_z(-t) {
    difference() {
      linear_extrude(t+eps, convexity=2) {
        difference() {
          rotate(45) chamfer_rect(2*w,2*w,2);
          circle(r=keyHoleR+C);
        }
      }
      chamfer = roundToLayerHeight(0.4);
      translate_z(-eps)
      cylinder(r1=keyHoleR+C+chamfer,r2=keyHoleR+C,h=chamfer);
    }
  }
  h = len(bitting)*(waferThickness+sepThickness) + layerHeight;
  translate_z(-t) linear_extrude(h+t) {
    difference() {
      union() {
        circle(r=w);
        offset(gateCHousing+housingWall) sidebar_profile(1);
      }
      circle(r=coreR+C);
      offset(gateCHousing) sidebar_profile(1, extraY=C);
    }
  }
}

module export_housing() { housing(); }

//-----------------------------------------------------------------------------
// Lock body
//-----------------------------------------------------------------------------

padLock = true;
shackleR = 7.5/2;
shackleX = coreR + shackleR + 2;

module shackle() {
  translate_x(shackleX) {
    cylinder(r=shackleR,h=20);
  }
  translate_x(-shackleX) {
    cylinder(r=shackleR,h=20);
  }
}

module screw() {
}

module lug(pos = 0) {
  h = len(bitting)*(waferThickness+sepThickness) + layerHeight;
  lugR = 3;
  coreBackR = coreR - 2;
  lugTravel = 2;
  lugW = shackleX - shackleR + lugTravel - coreBackR;
  lugH = roundToLayerHeight(5);
  linear_extrude_y(2*shackleR+2,true) {
    translate([-(shackleX-shackleR-lugR+lugTravel), h + lugR + 1]) circle(lugR);
    translate([coreBackR + lugW/2, h + lugR + 1]) {
      chamfer_rect(lugW,lugH,lugTravel,r_tl=0,r_bl=0);
    }
  }
}

module lock_body() {
}

//-----------------------------------------------------------------------------
// Assembly
//-----------------------------------------------------------------------------

module assembly() {
  anim = 180;
  angle = min(90,anim);
  coreAngle = max(0,anim-90);
  sidebarPos = 1 - min(1,max(0,anim-80)/10);
  springPos = min(1,anim/7);
  
  color("lightyellow") housing();
  color("lightpink") lug();
  color("cyan") shackle();
  rotate(coreAngle) {
    color("lightblue") core(back=false);
    *color("Aquamarine") core_part(true,false);
    *color("Aquamarine") translate_z(2*(waferThickness+sepThickness)) core_part(false,true);
    *color("pink") rotate(angle) key();
    color("DarkViolet") sidebar(sidebarPos);
    color("violet") spring(springPos);
    color("lightgreen") for (i=[0:len(bitting)-1]) {
      translate_z(i*(waferThickness+sepThickness)+sepThickness)
      translate_y(dy(angle) + bitting[i] * step * sin(angle))
      wafer(bitting[i]);
    }
    color("lightsalmon") for (i=[0:len(bitting)-1]) {
      translate_z(i*(waferThickness+sepThickness))
      rotate(angle)
      spacer();
    }
  }
}

!assembly();