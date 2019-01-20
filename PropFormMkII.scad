/*
A script for generating blocks used to mold propeller blades suitable
for light-weight rubber band power model airplanes or simmilar low
power, low RPM applications.

It uses two modules:
    alt_extrude.scad, that provides functions similar to hull()
    larrabee_planform.scad to generates blade outlines based the the prop's pitch

The top sections are the main user inputs formatted for use with the customizer user
interface found at thingiverse.com or current versions of the OpenSCAD application.

Copywrite 2018, Robert Marchese
*/
use <LarrabeePlanformSpline.scad>;
use <alt_extrude.scad>;
 
/* [Dimensions] */
// Prop hub to tip along the x-axis (inches)
prop_dia_in = 10.0;

// Theoretical distance traved in one revelution (inches)
prop_pitch_in = 20.0;

// Width of rectangular block (inches)
block_width_in = 1.75;

/* [Options] */ 
// Cross Sections
xsection="curved";  // [curved:Circular,flat:Flat]

// Radius of curved cross section
camber_radius_in = 3;

// Divisions between root and tip
g_sections = 50;
 
// Larrabee style planform
larrabee = true;
 
/* [Hidden] */
mm = 25.4;
$fn = 48;

// convert user inputs to metric
prop_dia = prop_dia_in * mm;
prop_pitch = prop_pitch_in * mm;
block_width = block_width_in * mm;
g_camber_radius = camber_radius_in * mm; // TODO: make this not a global

// generate the propeller form using the parameters above
prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, larrabee);


// Determine the block thickness given diameter, pitch and width
// https://indoornewsandviews.files.wordpress.com/2012/10/inav_121_press.pdf
// From page 22, Indoor Props - Practice
function t_block(d, p, w) = p*w/(3.14159*d);

// returns the pitch angle at radius r for the parameters
// Design Pitch Pd and Radius R
function Pangle(Pd, R, r) = atan( Pd / (3.14159 * r/R));

// returns the x-axis coords at y for a circle of radius R with
// center at (-R,0)
function cir_x(R, y) = R - sqrt(R*R - y*y);

//
// Generates a block for forming simple propellers out of sheets of material such
// as balsa or thin plastic.
//
// Parameters:
//   prop_dia - propeller diameter, given in mm
//   prop_pitch - Theoretical distance traved in one revelution, given in mm
//   block_width - the width of the resulting form, given in mm.
//      note: this sets the prop max chord and is a vestage of the original
//      MKI application. TODO, refactor so it uses chord directly
//   xsection - "curved" or "flat" blade cross sections, from the customizer user interface
//   larrabee - Boolean to select a Larrabee style plan form. See LarrabeePlanformSpline.scad
//      for more detauls
//
module prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, larrabee) {

    block_height =  t_block(prop_dia, prop_pitch, block_width);
    block_length = prop_dia / 2;

    Pd = prop_pitch / prop_dia;

    tip_angle = atan(block_width / block_height);
    tip_width = sqrt(block_width*block_width+block_height*block_height);

    mid_angle = tip_angle/2;
    bblock = [prop_dia/2, tip_width*cos(mid_angle), tip_width*sin(mid_angle)];

    // This complicated calulation makes sure the blade surface is above the xy-plane
    vertical_adjust = cir_x(g_camber_radius, block_width/2) +
                        cos(mid_angle)*block_width/2-sin(mid_angle)*block_height/2;

    intersection () {

        // Generate the blade surface and anjust its position
        difference() {
            translate([0,0,vertical_adjust]) rotate([mid_angle,0,0]) {
                if (xsection == "curved")
                    blade_surface (prop_pitch, prop_dia, tip_width, g_camber_radius);
                else
                    blade_surface (prop_pitch, prop_dia, tip_width);
            }

            //cut out text showing the main parameters Dia x Pd
            translate([bblock[0]/2-20,5,.8]) rotate([180,0,0]) linear_extrude(1.0)
                    text(str(prop_dia/mm," x ",prop_pitch/mm));
        }

        // Cut out the larrabee plan form or a simple box. Other shapes could be added here.
        if (larrabee) {
            linear_extrude(block_height*4) larrabee_planform(prop_dia/2, Pd, block_width);
        }
        else {
            translate([block_length/2, 0, block_height*2])
                cube([block_length, block_width, block_height*4], center=true);
        }
    }
}


//
// Generates the surface of the propeller blade form by drawing a polygon
// representing the blade cross section and stores in the variable pp. It
// The iterates over the stations along the length and calculates the twist
// needed at the start and end of that stations (angle_i and angle_i1). the
// variable dr represents the width of each station. 
//
// The module stretch() and transform_matrix() operate silimarly to the built-in
// hull() operation, but gives a little more control to how the verticies are 
// mapped in order ensure the smoothest surface which is not necessarily a
// convex hull.
//
// Transfrom transfrom_matrix module calculates a transform for the twist
// and offset distance. The stretch module applies these transfroms to the 
// original polygon points pp and forms a solid body by defining edges between
// the corresponding verticis atr their new possitions. See the comments in
// alt_extrud.scad for more details
//
module blade_surface (pitch, dia, width, camber=1000)
{
    nc = 16; // the number of chord partitions. TODO: make this a parameter?
    dw = width / (nc+1);  // increments of chord width
    dr = (dia / 2) / g_sections; // increment of the overall radius, TODO: not a global

    // generates a square with a rounded top at the camber radius the
    // default camber radius of 1000 is essentially flat but still
    // has a number of small line segments needed by the alt_extrude module
    pp0 = [for(i=[1+nc/2:-1:-1-nc/2]) [cir_x(camber, dw*i), dw*i]];
    pp = concat(pp0,[[50, -width/2], [50, width/2]]);

    // Rotate so the blade lies along the x-axis
    rotate([-90, 0, 0]) rotate([0,90,0]) {

        // generate the blade segmens as described above
        for(i=[0:g_sections-1]) {
            angle_i  = Pangle(pitch, dia, dia*i/g_sections*dia);
            angle_i1 = Pangle(pitch, dia, dia*(i+1)/g_sections*dia);
            stretch (
                pp,
                transform_matrix(dr*i, angle_i),
                transform_matrix(dr*(i+1), angle_i1)
            );
        }
    }
}
