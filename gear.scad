// Based on
//  https://www.thingiverse.com/thing:53451/files
//  by Emmett Lalish
//  licensed under the Creative Commons - Attribution - Share Alike license. 
// Planetary gear bearing (customizable)

module chamfer_cylinder(ro,ri,h,chamfer=undef,slope=1) {
  ri2 = ri==undef ? ro-chamfer : ri;
  y = (ro-ri2)/slope;
  cylinder(r1=ri2,r2=ro,h=y);
  translate([0,0,y-eps]) cylinder(r=ro, h=h-2*y+2*eps);
  translate([0,0,h-y]) cylinder(r1=ro, r2=ri2, h=y);
}

module chamfer_gear(number_of_teeth=15, circular_pitch=10, pressure_angle=28, depth_ratio=1, clearance=0, helix_angle=0, gear_thickness=5, slope=1) {
  ri = gear_inner_radius(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance);
  ro = gear_outer_radius(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance);
  intersection() {
    gear(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance,helix_angle,gear_thickness);
    group() {
      cylinder(r1=ri,r2=ro+eps,h=(ro-ri)/slope);
      translate([0,0,(ro-ri)/slope]) cylinder(r=ro+eps,h=gear_thickness - 2* (ro-ri)/slope);
      translate([0,0,gear_thickness-(ro-ri)/slope]) cylinder(r1=ro+eps,r2=ri,h=(ro-ri)/slope);
    }
  }
}

module chamfer_gear2(number_of_teeth=15, circular_pitch=10, pressure_angle=28, depth_ratio=1, clearance=0, helix_angle=0, gear_thickness=5, slope=1) {
  rb = gear_avg_radius(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance);
  ri = gear_inner_radius(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance);
  ro = gear_outer_radius(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance);
  intersection() {
    gear(number_of_teeth,circular_pitch,pressure_angle,depth_ratio,clearance,helix_angle,gear_thickness);
    chamfer_cylinder(ri=rb, ro=ro,h=gear_thickness);
  }
  cylinder(r1=rb,r2=ri,h=(rb-ri)/slope);
  translate([0,0,gear_thickness-(rb-ri)/slope]) cylinder(r1=ri,r2=rb,h=(rb-ri)/slope);
}

module rack(number_of_teeth=15, circular_pitch=10, pressure_angle=28, helix_angle=0, clearance=0, gear_thickness=5, flat=false) {
  addendum=circular_pitch/(4*tan(pressure_angle));

  flat_extrude(h=gear_thickness,flat=flat)translate([0,-clearance*cos(pressure_angle)/2])
    union(){
      translate([0,-0.5-addendum])square([number_of_teeth*circular_pitch,1],center=true);
      for(i=[1:number_of_teeth])
        translate([circular_pitch*(i-number_of_teeth/2-0.5),0])
        polygon(points=[[-circular_pitch/2,-addendum],[circular_pitch/2,-addendum],[0,addendum]]);
    }
}

module herringbone(number_of_teeth=15, circular_pitch=10, pressure_angle=28, depth_ratio=1, clearance=0, helix_angle=0, gear_thickness=5) {
  union(){
    gear(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance, helix_angle, gear_thickness/2);
    mirror([0,0,1])
      gear(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance, helix_angle, gear_thickness/2);
  }
}

module gear(number_of_teeth=15, circular_pitch=10, pressure_angle=28, depth_ratio=1, clearance=0, helix_angle=0, gear_thickness=5, flat=false) {
  pitch_radius = number_of_teeth*circular_pitch/(2*PI);
  twist=tan(helix_angle)*gear_thickness/pitch_radius*180/PI;

  flat_extrude(h=gear_thickness,twist=twist,flat=flat)
    gear2D(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance);
}

module flat_extrude(h,twist,flat){
  if(flat==false)
    linear_extrude(height=h,twist=twist,slices=twist/3, convexity=10) children();
  else
    child(0);
}

module gear2D(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance) {
  pitch_radius = number_of_teeth*circular_pitch/(2*PI);
  base_radius = pitch_radius*cos(pressure_angle);
  depth=circular_pitch/(2*tan(pressure_angle));
  outer_radius = clearance<0 ? pitch_radius+depth/2-clearance : pitch_radius+depth/2;
  root_radius1 = pitch_radius-depth/2-clearance/2;
  root_radius = (clearance<0 && root_radius1<base_radius) ? base_radius : root_radius1;
  backlash_angle = clearance/(pitch_radius*cos(pressure_angle)) * 180 / PI;
  half_thick_angle = 90/number_of_teeth - backlash_angle/2;
  pitch_point = involute (base_radius, involute_intersect_angle (base_radius, pitch_radius));
  pitch_angle = atan2 (pitch_point[1], pitch_point[0]);
  min_radius = max (base_radius,root_radius);

  intersection() {
    rotate(90/number_of_teeth)
      circle($fn=number_of_teeth*3,r=pitch_radius+depth_ratio*circular_pitch/2-clearance/2);
    union(){
      rotate(90/number_of_teeth)
        circle($fn=number_of_teeth*2,r=max(root_radius,pitch_radius-depth_ratio*circular_pitch/2-clearance/2));
      for (i = [1:number_of_teeth])rotate(i*360/number_of_teeth){
        halftooth (
          pitch_angle,
          base_radius,
          min_radius,
          outer_radius,
          half_thick_angle);		
        mirror([0,1])halftooth (
          pitch_angle,
          base_radius,
          min_radius,
          outer_radius,
          half_thick_angle);
      }
    }
  }
}

module halftooth(pitch_angle, base_radius, min_radius, outer_radius, half_thick_angle) {
  index=[0,1,2,3,4,5];
  start_angle = max(involute_intersect_angle (base_radius, min_radius)-5,0);
  stop_angle = involute_intersect_angle (base_radius, outer_radius);
  angle=index*(stop_angle-start_angle)/index[len(index)-1];
  p=[[0,0],
    involute(base_radius,angle[0]+start_angle),
    involute(base_radius,angle[1]+start_angle),
    involute(base_radius,angle[2]+start_angle),
    involute(base_radius,angle[3]+start_angle),
    involute(base_radius,angle[4]+start_angle),
    involute(base_radius,angle[5]+start_angle)];

  difference(){
    rotate(-pitch_angle-half_thick_angle)polygon(points=p);
    square(2*outer_radius);
  }
}

// Utility functions

function gear_radius(number_of_teeth, circular_pitch) =
  number_of_teeth * circular_pitch / (2*PI);
function gear_avg_radius(number_of_teeth, circular_pitch, pressure_angle=28, depth_ratio=0, clearance=0) =
  number_of_teeth * circular_pitch / (2*PI) - clearance;
function gear_inner_radius(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance=0) =
  number_of_teeth * circular_pitch / (2*PI) - depth_ratio*circular_pitch/2-clearance/2;
function gear_outer_radius(number_of_teeth, circular_pitch, pressure_angle, depth_ratio, clearance=0) =
  number_of_teeth * circular_pitch / (2*PI) + depth_ratio*circular_pitch/2-clearance/2;

// Mathematical Functions
//===============

// Finds the angle of the involute about the base radius at the given distance (radius) from it's center.
//source: http://www.mathhelpforum.com/math-help/geometry/136011-circle-involute-solving-y-any-given-x.html

function involute_intersect_angle (base_radius, radius) = sqrt (pow (radius/base_radius, 2) - 1) * 180 / PI;

// Calculate the involute position for a given base radius and involute angle.

function involute (base_radius, involute_angle) =
[
	base_radius*(cos (involute_angle) + involute_angle*PI/180*sin (involute_angle)),
	base_radius*(sin (involute_angle) - involute_angle*PI/180*cos (involute_angle))
];
