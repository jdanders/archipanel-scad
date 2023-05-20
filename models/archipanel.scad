// This is modeled on the polypanels project:
// https://www.makeanything.design/polypanels
//
// The target of this project is for kids to play with as toys, so rather
// than a tight, solid fit, these provide a easier fit with easy rotation.
// Additionally, my printer is cheap, so tolerance in print quality is built
// in.
//
// The primary difference between this and polypanels is scaling down 70% size
// for material savings and ease of packing in bags/purses. The smaller scale
// and kid-friendly latching drives a different interconnect design.

// Dimensions
//
// See the polypanels page for a description of the virtual edge, which is
// the rotate line of latched pieces.
// In this design:
// * the virtual edges are 31.5 mm in length.
// * the virtual to physical distance is 1.75 mm
// * the latch depth is 3.5 mm, centered about the virtual edge
// * a basic wall has these lengths
//    |--------------------------31.5---------------------------------|
//    |-3.75--|---4---|---4---|---4---|---4---|---4---|---4---|--3.75-|
//
//    ________________|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_______|¯¯¯¯¯¯¯|_________
//    |                --ball--          -------socket-------          |
//
// The lengths above apply to the base of the "ball" and "socket" finger joints
// The socket is on the left, and the ball of the joining piece goes in between
// the two socket pieces.
// The ball in the one extending piece on the right.
// (that's the best I could come up with for vocabulary, I'm not a mech eng!)
// The length dimension is the virtual line (mid-point) between the joints
//
// The dimensions described are the rounded numbers for the base of the joints
// In reality, for ease of printing, gaps will be grown and extrusions will be
// shrunk by a parameterized offset.

// set of shapes needed for archimedean solids:
// triangles:  80 (32 if ignore snub dodecahedron)
// squares:    30
// pentagons:  12
// hexagons:   20
// octagons:   6
// decagons:   12 (0 if ignore 2 shapes using decagons)

MODEL=0;

// tolerance offset (fudge factor). Make larger for looser connections.
// 0.3 worked well for uncalibrated Monoprice Select Mini V1
ff = 0.13;

bd=1.5; // bump diameter
sk_sc=1.2; // socket scale, scale hole relative to bump
sk_st=1.2; // socket stretch, spread socket closer to edges of finger
bump_gap=0.75; // gap between the two bumps for flex

//color("khaki")translate([vedge_l,0,0])rotate([-75,0,180])edge();

//edge_str=str(ff," ",sk_st," ",sk_sc); // can print on edge for calibration
edge_str=str(" ff = ", ff); // can print on edge for calibration

show_virt_edge = false; // Do not render with this set to true

// Thickness of joints
joint_dia = 3.5;

// Length of joints
inner_l = 4;
// Length of distance surrounding joints
outer_l = 3.75;

// Dimensions of shape wall attached to joints
wall_h = 2;
wall_th = 2;

// Smoothness
ofn=12; //outer number facets
bfn=12; //ball number facets
sfn=12; //socket number facets
body_r=1.4; //curve of body corners

// Things below this point are derived from parameters
virt_off = 1.125*(joint_dia/2); // offset of wall edge from virt edge
rnd=joint_dia/5; // roundness of the cylinder

vedge_l = outer_l*2 + inner_l*6;
in_edge_l = inner_l*6;

// rounded square shape, rotated for rounded cylinder
//rcylinder(d=20,h=30,n=4,$fn=15);
module rsquare(d,h,n) {
    offset(r=n) offset(delta=-n) square([d/2,h]);
    square([n,h]);
}
module rcylinder(d,h,n) {
  rotate_extrude(convexity=1) {
      rsquare(d,h,n);
  }
}

// Math to help with ball/socket fingers
jd=joint_dia-ff;
jrff=(joint_dia-ff)/2;
jr=joint_dia/2;
ch=inner_l-ff; // cylinder height, width of the ball base
// 45/45/90 triangle hypotenuse is sqrt(2)*side_len
jrff_height_45 = jrff/sqrt(2); // dist axis to ff radius at 45 degrees
jrff_to_jr_45 = (jr - jrff_height_45)*sqrt(2);
off45_p = jrff_height_45-jrff_to_jr_45/sqrt(2); // offset to base point


module finger(ch){
    // core (rotate 135 to align whatever ofn shaped object to the 45 slope
    rotate([0,90,0]) rotate([0,0,135]) rcylinder(d=jd, h=ch, n=rnd, $fn=ofn);
    // base
    rotate([0,45,-90]) translate([0,0,-jrff_to_jr_45])
        linear_extrude(jrff_to_jr_45)
        rsquare(d=jd, h=ch, n=rnd, $fn=ofn);
    difference(){
        translate([0,-off45_p,-jr]) cube([ch,jd,jr]);
        translate([-sqrt(2)*ch+.33,-off45_p-.01,-jr])
           rotate([0,45,0]) cube([ch,30,ch]);
        translate([ch-.33,-off45_p-.01,-jr])
           rotate([0,45,0]) cube([ch,30,ch]);
    }
}

module ball(){
    cut_th = .75;
    translate([ff/2,0,0]) union(){
         difference() {
             finger(ch);
             translate([ch/2-cut_th/2,0,0]) rotate([0,90,0]) cylinder(h=cut_th,d=ch*2);
         }
         // "ball" bumps
         for (x_rot = [[ch, 90], [0, -90]])
             translate([x_rot[0],0,0]) rotate([0,x_rot[1],0])
                 sphere(d=bd, $fn=bfn);
    }
}

module socket(side=0, num_side){
    translate([ff/2,0,0])
    translate([-inner_l,0,0]) union(){
            // "ball" sockets
        if (side==0) {
            difference() {
                translate([ff/2,0,0]) finger(ch-ff);
                //translate([1*ch/3-ff/2,0,0]) finger(2*ch/3);
                translate([ch+.01,0,0]) rotate([0,-90,0])
                    scale([sk_st,sk_st,1]) sphere(d=bd*sk_sc, $fn=sfn);
            }
        } else {
            difference() {
                if (num_side == 3) translate([ff/2,0,0]) finger(ch*.75); // Triangles are extra short
                else translate([ff/2,0,0]) finger(ch-ff);
                //translate([ff/2,0,0]) finger(2*ch/3);
                translate([-.01,0,0]) rotate([0,90,0])
                    scale([sk_st,sk_st,1]) sphere(d=bd*sk_sc, $fn=sfn);
            }
        }
    }
}

module sockets(num_side){
    socket(0, num_side);
    translate([inner_l*2,0,0]) socket(1, num_side);
}

module edge(beam=true, num_side){
    translate([outer_l+inner_l, 0, 0]) union() {
        ball();
        translate([inner_l*3,0,0]) sockets(num_side);
    }
    // Keep wall far enough away for full roatation of fingers
    if (beam)
        translate([inner_l-ff+.06,virt_off,-jr]) cube([in_edge_l,wall_th*2,wall_h]);
    // Draw a line on the virtual edge for ease of alignment and visualization
    if (show_virt_edge) rotate([0,90,0]) cylinder(r=.1, h=vedge_l);
}


module p_edge(beam=true){
    difference(){
        edge(beam);
        // Write the ff value on edge for calibration
        translate([outer_l+.1,virt_off+.4,wall_h-jr-.35])linear_extrude(.6)
            text(edge_str, font="Liberation Sans:style=Bold", size=3.5);
    }
}


module poly(num_side=3) {
    polyang = 360/num_side;  // Angle of polygon
    tri_angle = (180-((polyang)))/2; // Angle of right triangle for radius
    v_rad = (vedge_l/2)/cos(tri_angle); // radius of circle around polygon
    init = polyang/2 + 180; // angle of initial piece
    // Generate, rotate and place the edges
    for (a = [0 : polyang : 360-1])
        translate([v_rad*sin(init-a),v_rad*cos(init-a),0])
          rotate(a) edge(false, num_side);

    // Create the filling polygon
    rad_body = v_rad - 1/sin(tri_angle)*(virt_off + body_r);
    rad_hole = v_rad - 1/sin(tri_angle)*(virt_off + wall_th + body_r);
    hole_th = rad_hole - wall_th;
    // outer points
    points_o = [for (a = [0:polyang:360-1])
                  [rad_body*sin(a), rad_body*cos(a)]];
    // inner cutout
    points_i = [for (a = [0:polyang:360-1])
                  [(hole_th)*sin(a), (hole_th)*cos(a)]];
    sc = rad_hole/(rad_hole-3);
    rotate([0,0,init]) difference(){
        translate([0,0,-jr]) linear_extrude(wall_h)
            offset(r=body_r, $fn=ofn)
            polygon(points_o);
        translate([0,0,-jr-0.5]) linear_extrude(wall_h+1)
            offset(r=body_r, $fn=ofn)
            polygon(points_i);
    }
    // inner cylinder to round internal edges
    hole_l = rad_hole * sqrt(2 - 2*cos(polyang));
    for (a = [0 : polyang : 360-1])
        translate([(hole_th)*sin(init-a),(hole_th)*cos(init-a),0])
            rotate([0,0,a-90]) translate([wall_h/2,-body_r,-jr+wall_h/2])
            rotate([270,0,0]) cylinder(d=wall_h,h=hole_l,$fn=ofn);
}


// Make an array, spaced by poly radius
module polyarray(arr_size=[2,2], num_side=3, arr_scale=1){
    polyang = 360/num_side;  // Angle of polygon
    tri_angle = (180-((polyang)))/2; // Angle of right triangle for radius
    v_rad = (vedge_l/2)/cos(tri_angle); // radius of circle around polygon
    // could probably figure out actual max x,y but this is easier...
    arr_len = v_rad*2 * arr_scale;
    for (xi=[0:arr_size[0]-1]) {
        for (yi=[0:arr_size[1]-1]) {
            translate([xi*arr_len + v_rad, yi*arr_len + v_rad, 0]) children();
        }
    }
}


// combo modules for dense printing
module 3in5() { poly(5); translate([.6,0.1,0]) poly(3); }
module 3in6() { poly(6); poly(3); }
module 4in6() { poly(6); rotate([0,0,-19]) poly(4); }
module 6in8() { poly(8); rotate([0,0,-10]) poly(6); }
module 4in6in8() { poly(8); rotate([0,0,-10]) 4in6(); }
module 3in6in8() { poly(8); rotate([0,0,-10]) 3in6(); }
module 3in8in10() {
    poly(10); poly(8);
    translate([-32,-24,0]) polyarray([2,1], 3, arr_scale=.76) poly(3);
    translate([0,15,0]) rotate([0,0,-60]) poly(3);
}
module 3in10() {
    poly(10);
    translate([-32,-24,0]) polyarray([2,1], 3, arr_scale=.76) poly(3);
    translate([0,15,0]) rotate([0,0,-60]) poly(3);
}

// various things to print
//p_edge();
//translate([0,8,0]) p_edge();
//color("khaki")translate([vedge_l,0,0])rotate([-75,0,180])edge();
//translate([-20,-10,0])poly(3);

//poly(3);
//rotate([0,0,60]) poly(3);
//poly(4);
//poly(5);
//rotate([0,0,36])poly(5);
//poly(6);
//poly(8);
//poly(10);

//3in5();
//3in6();
//4in6();
//3in6in8();
//4in6in8();
//3in8in10();
//polyarray([4,4], 3, arr_scale=.76) poly(3);
//polyarray([3,3], 4, arr_scale=0.8) poly(4);
//polyarray([2,2], 5, arr_scale=0.78) 3in5();
//polyarray([2,2], 6, arr_scale=0.93) 3in6();
//polyarray([2,2], 6, arr_scale=0.93) 4in6();

if (MODEL== 1) poly(3);
if (MODEL== 2) poly(4);
if (MODEL== 3) poly(5);
if (MODEL== 4) poly(6);
if (MODEL== 5) poly(8);
if (MODEL== 6) poly(10);
if (MODEL== 7) 3in5();
if (MODEL== 8) 3in6();
if (MODEL== 9) 4in6();
if (MODEL==10) 3in6in8();
if (MODEL==11) 4in6in8();
if (MODEL==12) 3in8in10();

// set of shapes needed for archimedean solids:
// triangles:  80 (32 if ignore snub dodecahedron)
// squares:    30
// pentagons:  12
// hexagons:   20
// octagons:   6
// decagons:   12 (0 if ignore 2 shapes using decagons)

//120x120 build plate
if (MODEL==13) {
    // 2 hex, 1 pent, 3 square, 6 tri (10x gives 20, 10, 30, 60)
    %color("darkgreen") translate([-60,-60,-4]) cube([120,120,1]);
    translate([-29.8,28.4,0]) rotate([0,0,30]) 4in6();
    translate([29,29.2,0]) 4in6();
    translate([-16.5,-26,0]) rotate([0,0,19.5]) 3in5();
    translate([-47.5,-43.7,0]) rotate([0,0,30]) poly(3);
    translate([-46.9,-8.7,0]) rotate([0,0,30]) poly(3);
    translate([19.3,-15,0]) rotate([0,0,30]) poly(3);
    translate([45,-9.5,0]) rotate([0,0,60]) poly(3);
    translate([12,-48.4,0]) rotate([0,0,8]) poly(3);
    translate([42,-42,0]) poly(4);
}

//220x220 build plate a
if (MODEL==14) {
    // 7 hex, 4 pent, 10 square, 16 tri (3x gives 21, 12, 30, 48)
    %color("darkgreen") translate([0,0,-4]) cube([220,220,1]); // outline
    translate([0,0,0]) polyarray([2,2], 6, arr_scale=0.93) 4in6();
    translate([0,116,0]) polyarray([2,1], 6, arr_scale=0.93) 4in6();
    translate([151,140,0]) 4in6();
    translate([113.5,-5,0]) polyarray([2,2], 6, arr_scale=0.78) 3in5();
    translate([177,100,0]) polyarray([1,3], 4, arr_scale=0.8) poly(4);
    translate([-2,169.5,0]) polyarray([6,1], 3, arr_scale=.74) poly(3);
    translate([182.5,226,0]) rotate([0,0,180])
        polyarray([6,1], 3, arr_scale=.74) poly(3);
}

//220x220 build plate b
if (MODEL==15) {
    // 4 deca, 2 octo, 12 tri (3x gives 12, 6, 36)
    %color("darkgreen") translate([0,0,-4]) cube([220,220,1]); // outline
    polyarray([1,2], 10, arr_scale=1) 3in8in10();
    translate([105,0,0]) polyarray([1,2], 10, arr_scale=1) 3in10();
}

if (false) {
    poly(3);
    translate([20,15,0]) poly(3);
    translate([20,-15,0]) poly(3);
    rotate([0,0,180])translate([-42,5,0]) poly(3);
    translate([-20,25,0]) poly(4);
    translate([-20,-25,0]) poly(4);
}

// test connectivity, not for printing
if (false) {
    poly(4);
    translate([-vedge_l/2,0,vedge_l/2]) rotate([0,90,0]) poly(4);
    translate([.335*vedge_l,0,.238*vedge_l]) rotate([0,234.7,0]) rotate([0,0,30]) poly(3);
    translate([0,.335*vedge_l,.238*vedge_l])  rotate([125.3,0,0]) poly(3);
    translate([0,-vedge_l/2,vedge_l/2]) rotate([90,0,180]) poly(4);
}
