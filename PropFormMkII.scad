/*
A script for generating blocks used to mold propeller blades suitable
for light-weight rubber band power model airplanes or simmilar low
power, low RPM applications.

Copywrite 2018, Robert Marchese
*/
use <LarrabeePlanformSpline.scad>;
 
/* [Dimensions] */
// Prop hub to tip along the x-axis (inches)
prop_dia_in = 10.0;

// Theoretical distance traved in one revelution (inches)
prop_pitch_in = 15;

// Width of rectangular block (inches)
block_width_in = 1.25;

/* [Options] */ 
// Cross Sections
xsection="curved";  // [curved:Circular,flat:Flat]

// Radius of curcved cross section
camber_radius_in = 10.0;

// Divisions between root and tip
sections = 10;
 
// Larrabee style planform
larrabee = false;
 
/* [Hidden] */
mm = 25.4;
$fn = 192;

// convert user inputs to metric
prop_dia = prop_dia_in * mm;
prop_pitch = prop_pitch_in * mm;
block_width = block_width_in * mm;
camber_radius = camber_radius_in * mm;

// Determine the block thickness given diameter, pitch and width
// https://indoornewsandviews.files.wordpress.com/2012/10/inav_121_press.pdf
// From page 22, Indoor Props - Practice
function t_block(d, p, w) = p*w/(3.14159*d);

function Pangle(Pd, r, R) = atan( Pd / (3.14159 * r/R));

block_height =  t_block(prop_dia, prop_pitch, block_width);
block_length = prop_dia / 2;

tip_angle = atan(block_width / block_height);
tip_width = sqrt(block_width*block_width+block_height*block_height);

Pd = prop_pitch / prop_dia;


intersection () {
    prop_block_mkII();
    if (larrabee) {
        linear_extrude(block_height*2) larrabee_planform(prop_dia/2, Pd, block_width);
    }
    else {
        translate([block_length/2, 0, block_height]) 
        cube([block_length, block_width, block_height*2], center=true);
    }
}

module prop_block_mkII() {

    mid_angle = tip_angle/2;
    bblock = [prop_dia/2,tip_width*cos(mid_angle),tip_width*sin(mid_angle)];

    difference() {
        intersection() {
            translate([0,0,cos(mid_angle)*block_width/2-sin(mid_angle)*block_height/2])
                rotate([mid_angle,0,0]) {
                //rotate([90,0,0]) {
                for(j=[0:10]) {
                    for(i=[.1:sections]) {
                        hull() {
                            blade_section_mkII(i, prop_pitch, prop_dia, tip_width, sections, j);
                            blade_section_mkII(i+1, prop_pitch, prop_dia, tip_width, sections, j);
                        }
                    }
                }
            }
        }
        
        //Text
        translate([bblock[0]/2-20,5,.8]) rotate([180,0,0]) linear_extrude(1.0) 
                text(str(prop_dia/mm," x ",prop_pitch/mm));    
    } 
}

module blade_section_mkII (i, pitch, dia, width, sections, j)
{
    r = (i/sections)*dia/2;
    
    angle_i = Pangle(pitch, dia*i/sections*dia, dia);
    //w = width * cos(angle_i);
    w = width;
    rotate([angle_i,0,0]) translate([r, 0, 0]) { 
        translate([0, -50, (w*j/10)-w/2]) cube([.01,50,w/10]);
    }
}


module circular_segment(R, c)
{
    // see https://en.wikipedia.org/wiki/Circular_segment
    d = sqrt(R*R-(c*c)/4);
    linear_extrude(0.1) difference() {
        translate([-d,0,0]) circle(R);
        translate([-R,0,0]) square(2*R, center=true);
    }
}
