/*
A script for generating blocks used to mold propeller blades suitable
for light-weight rubber band power model airplanes or simmilar low
power, low RPM applications.

Copywrite 2018, Robert Marchese
*/
use <LarrabeePlanformSpline.scad>;
use <alt_extrude.scad>;
 
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

// Radius of curved cross section
camber_radius_in = 2;

// Divisions between root and tip
sections = 50;
 
// Larrabee style planform
larrabee = true;
 
/* [Hidden] */
mm = 25.4;
$fn = 48;

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

function cir_x(rad, y) = rad - sqrt(rad*rad - y*y);

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
            translate([0,0,cir_x(camber_radius, block_width/2)+cos(mid_angle)*block_width/2-sin(mid_angle)*block_height/2])
            rotate([mid_angle,0,0]) {
                if (xsection == "curved")
                    blade_surface (prop_pitch, prop_dia, tip_width, camber_radius);
                else
                    blade_surface (prop_pitch, prop_dia, tip_width);
            }
        }
        
        //Text
        translate([bblock[0]/2-20,5,.8]) rotate([180,0,0]) linear_extrude(1.0) 
                text(str(prop_dia/mm," x ",prop_pitch/mm));    
    } 
}


module blade_surface (pitch, dia, width, camber=1000)
{
    nc = 16; // the number of chord partitions
    dw = width / (nc+1);

    pp = [for(i=[1+nc/2:-1:-1-nc/2]) [cir_x(camber, dw*i), dw*i], [50, -width/2], [50, width/2]];

    dr = (dia / 2) / sections;
    rotate([-90, 0, 0]) for(i=[0:sections-1]) {
        angle_i  = Pangle(pitch, dia*i/sections*dia, dia);
        angle_i1 = Pangle(pitch, dia*(i+1)/sections*dia, dia);
        rotate([0,90,0]) stretch (
            pp,
            transform_matrix(dr*i, angle_i),
            transform_matrix(dr*(i+1), angle_i1)
        );
    }
}


module blade_section (i, pitch, dia, width, sections, j)
{
    r = (i/sections)*dia/2;
    
    angle_i = Pangle(pitch, dia*i/sections*dia, dia);

    w = width;
    rotate([angle_i,0,0]) translate([r, 0, 0]) { 
        translate([0, -50, (w*j/10)-w/2]) cube([.01,50,w/10]);
    }
}
