/*
A script for generating blocks used to mold propeller blades suitable
for light-weight rubber band power model airplanes or simmilar low
power, low RPM applications.

Copywrite 2018, Robert Marchese
*/
 
/* [Dimensions] */
// Prop hub to tip along the x-axis (inches)
prop_dia_in = 14.0;

// Theoretical distance traved in one revelution (inches)
prop_pitch_in = 22.0;

// Width of rectangular block (inches)
block_width_in = 2.5;

/* [Options] */ 
// Cross Sections
xsection="curved";  // [curved:Circular,flat:Flat]

// Radius of curcved cross section
camber_radius_in = 10.0;

// Divisions between root and tip
sections = 50;

/* [Print Options] */
show_dimensions = true;
minimal_volume = true;

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

block_height =  t_block(prop_dia, prop_pitch, block_width);

// Fill in the basic block shape and add description
difference() {
    linear_extrude(block_height)
        polygon([[0,0],[prop_dia/2, block_width], [0, block_width]]);

    rotate([0,0, atan(2*block_width/prop_dia)]) {
        if (show_dimensions) {
            translate([10, 5, block_height-.8])
                linear_extrude(1.0) text(str(prop_dia/mm, " x ", prop_pitch/mm));
        }
        if (minimal_volume) {
            translate([0, 20, -1]) cube([prop_dia/2,block_width,block_height+2]);
        }
    }
}

// Iterate over the blade cross sections to generate the main surface
for(i=[0:sections-1]) {
    hull() {
        blade_section(i, block_width, block_height, sections, camber_radius, xsection);
        blade_section(i+1, block_width, block_height, sections, camber_radius, xsection);
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


 module blade_section(i, width, height, sections, camber_rad=125, xsection)
 {
    width_i = i*width/sections;
    chord_i = sqrt(height*height+width_i*width_i);
    angle_i = atan(width_i / height);

    translate([(i/sections)*prop_dia/2,0,0]) {
        // generate and orient the circular segments
        if (xsection == "curved") {
            rotate([-angle_i,0,0]) 
                translate([0, 0, chord_i/2]) 
                    rotate([90, 0, -90]) circular_segment(camber_rad, chord_i);
        }
        // generate triangle to 'support' the circular segments
        rotate([0,-90,0]) linear_extrude(1.1) 
            polygon([[0,0], [0, width_i], [height, width_i]]);
    }      
}

