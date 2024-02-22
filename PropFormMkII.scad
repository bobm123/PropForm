/*
A script for generating blocks used to mold propeller blades suitable
for light-weight rubber band power model airplanes or simmilar low
power, low RPM applications.

It uses two modules:
    alt_extrude.scad, that provides functions similar to hull()
    larrabee_planform.scad to generates blade outlines based the the prop's pitch

The top sections are the main user inputs formatted for use with the customizer user
interface found at thingiverse.com or current versions of the OpenSCAD application.

todo: Add some bounds checking for camber vs. chord and dia/pitch between 1 (for overall block) and 3 (for Larrabee option)
Copywrite 2018, Robert Marchese

Modifications by Chuck Andraka, 2020:
    Added flaring capability. However, no adjustment is made to prop form rotation. The spar line is where the pitch is defined, so combining camber and flare may give a lower effective pitch than anticipated
    
    Added washout capability. Washout is expressed in inches of pitch, and begins at 70% diameter, lineraly increasing washout to the specified value at the tip
    
    Added a spar pocket. Set to 0.5mm for a simple spar reference line, or set larger to accomodate a spar below the prop surface
    
    Added a printer bed size. If the diameter exceeds the bed size, then a diagonal box is used to clip. It sets the root (0 diameter) at the origin, and clips at 45 degrees. If needed the tip is also clipped. You will have to rotate  the object 45 degrees in your slicer.
    
    Added a manual block height limiter. On some flaring props in which a rotation adjustment is added, the height was unnessarily large at the root, where there is typically no blade. This allows chopping that high point off
    
    Added manual rotation adjustment. This is because the flaring capability is not accounted for in the block rotation calculation. Also, when the root corners are trimmed, a small adjustment (1.3 for F1D prop) helped reduce the total block height.
    
*/
use <LarrabeePlanformSpline.scad>;
use <alt_extrude.scad>;
 
/* [Dimensions] */
// Prop hub to tip along the x-axis (inches)
prop_dia_in = 18.51;// //[0:0.1:30]

// Theoretical distance traved in one revelution (inches)
prop_pitch_in = 28.1;// //[0:0.1:40]

// Tip wash out in inches of pitch
washout_in = 2.1;// //[0:0.1:10]

// Width of rectangular block (inches)
block_width_in = 3.01;// //[0:0.01:10]

    /* [Ventilation Louvers:] */
// Need ventilation slots or not
vent_choice=0; // [1:Yes, 0:No]
// Need string wrapping slots or not
string_choice=0; // [1:Yes, 0:No]
// Distance between ventilation slots 
vent_dist=3;   //[2:0.5:5]
// Width of each ventilation slot
vent_width=2;  //[1:0.5:3]
vent_apart=(vent_dist+vent_width);
// Base height (below the vent louvers)
vent_baseheight= 3; //[2:0.5:4]
// Vent Depth 
vent_depth= 4; //[2:0.5:6]


/* [Covering Frame] */
// Length of inside of frame (inches), 0 for none
frame_length_in = 0;// //[0:.1:15]

// Width of inside of frame (inches), 0 for none
frame_width_in = 0;// //[0:.1:15]

// Frame edge width
frame_edge_in = .15;// //[0:.05:.5]

/* [Options] */ 
// Cross Sections
xsection="flat";  // [curved:Circular,flat:Flat]

// Radius of curved cross section
camber_radius_in = 3.1;// //[0:0.1:1000]

// Divisions between root and tip
g_sections = 50;// //[0:1:250]
 
// Larrabee style planform
larrabee = false;

// Percent Flaring
flaring = 0;// //[0:1:100]

// Spar Slot Radius (mm)
slotrad = 0.5;// //[0:0.1:10]

/* [Printer Adjustments] */ 

//Rotation Adjustment to minimize height
Rotation_Multiplier = 1.0;//[.5:0.1:3]

//Printer Bed Size in mm
Bed_Size = 180;// //[100:1:1000]

//Maximum height helpful to trim root of flaring props
Max_height_in = 2.5;// //[.5:0.1:10]
 
/* [Hidden] */
mm = 25.4;
$fn = 48;

// convert user inputs to metric
prop_dia = prop_dia_in * mm;
prop_pitch = prop_pitch_in * mm;
washout = washout_in * mm;
block_width = block_width_in * mm;
max_height = Max_height_in * mm;
g_camber_radius = camber_radius_in * mm; // TODO: make this not a global
frame_length=frame_length_in * mm;
frame_width=frame_width_in * mm;
frame_edge=frame_edge_in * mm;



// generate the propeller form using the parameters above
prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, larrabee, Bed_Size,max_height);


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


module prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, larrabee, bed,max_height) {
    
    //This section added (CEA) to allow printing partial block for flaring props. 
    //However, I did not adjust the tilt or height of block, so inefficient for printing
    //Still more efficient than printing entire symetric block
    
    Saved_block_width=block_width;
    block_width=block_width*(1+flaring/100);
    
    block_height =  t_block(prop_dia, 
    prop_pitch, block_width);
    block_length = prop_dia / 2;

    Pd = prop_pitch / prop_dia;

    tip_angle = atan(block_width / block_height);
    tip_width = sqrt(block_width*block_width+block_height*block_height);

    mid_angle = Rotation_Multiplier*tip_angle/2; //Adjusted rotation for better fit
    bblock = [prop_dia/2, tip_width*cos(mid_angle), tip_width*sin(mid_angle)];

    // This complicated calulation makes sure the blade surface is above the xy-plane
    vertical_adjust = cir_x(g_camber_radius, block_width/2) +
                        cos(mid_angle)*block_width/2-sin(mid_angle)*block_height/2;
                        
    //This will limit the block height. With flaring props, teh root height can get quite high, and is never used. This only happens when the rotation multiplier is used
    
    limited_block_height=min(block_height*4,max_height);
    groove_depth=2; //mm of string groove depth, may be different than venting. 2mm should work
 
    intersection () {

        // Generate the blade surface and adjust its position
        difference() {
            translate([0,0,vertical_adjust]) rotate([mid_angle,0,0]) {
                if (xsection == "curved")
                    blade_surface (prop_pitch, washout,prop_dia, tip_width, g_camber_radius);
                else
                    blade_surface (prop_pitch, washout, prop_dia, tip_width);
            }

            //cut out text showing the main parameters Dia x Pd
            translate([bblock[0]/2-20,0,.8]) rotate([180,0,0]) linear_extrude(1.0)
                    text(str(prop_dia/mm,"d x ",prop_pitch/mm,"p"),6);
            translate([bblock[0]/2-20,10,.8]) rotate([180,0,0]) linear_extrude(1.0)
                    text(str(washout/mm," wash, ",g_camber_radius/mm," camber"),6);
            
            //cut out a groove for the spar, or a minimal marking of spar location, or make frame shape if covering frame
            if (frame_width){
                translate([-5,0,vertical_adjust]) rotate([0,90,0]) cylinder(block_length-frame_edge,slotrad,slotrad);
                // Slot for breather holes underneath
                translate([-5,0,0]) rotate([0,90,0]) cylinder(block_length+10,10,10);

            }
            else
            {
                translate([-5,0,vertical_adjust]) rotate([0,90,0]) cylinder(block_length+10,slotrad,slotrad);
                //Add venting if requested, using difference
                if(vent_choice){
                    //First add venting following top surface
                    translate([0,0,-vent_depth]){
                        difference(){
                            union(){
                                //Two sets of vents one on each side of spar line
                                for(i=[0*0.5+2*vent_apart:vent_apart:prop_dia*0.5-2*vent_apart])
                                translate ([i, -block_width-(1+slotrad),vent_depth+vent_baseheight-block_height*0]) 
                                cube([vent_width, block_width*1, block_height ]);
                                for(i=[0*0.5+2*vent_apart:vent_apart:prop_dia*0.5-2*vent_apart])
                                translate ([i, 1+slotrad,vent_depth+vent_baseheight-block_height*0]) 
                                cube([vent_width, block_width*1, block_height ]);
                            }
                            //Difference with the blade shape surface so vents follow blade shape
                            translate([0,0,vertical_adjust]) rotate([mid_angle,0,0]) {
                                if (xsection == "curved")
                                    blade_surface (prop_pitch, washout,prop_dia, tip_width, g_camber_radius);
                                else
                                    blade_surface (prop_pitch, washout, prop_dia, tip_width);
                            }
                            
                        }

                    }
                }
                if(string_choice){
                 //Now add slots along bottom corners to capture strings wrapping the blade on
                 //Only needed for wet forming, so only added if venting
                 //Use same data as venting (spacing etc)
                 //Want to add on all sides
                 //Front corner
           for(i=[0*0.5+2*vent_apart:vent_apart:prop_dia*0.5-2*vent_apart]) 
                        translate ([i, Saved_block_width*(flaring/100-1)/2,0]) 
                            rotate([-45,0,0])
                                cube([vent_width, 20, groove_depth*2 ],true);

                 //back corner
                    for(i=[0*0.5+2*vent_apart:vent_apart:prop_dia*0.5-2*vent_apart]) 
                        translate ([i, Saved_block_width*(flaring/100+1)/2,0]) 
                            rotate([45,0,0])
                                cube([vent_width, 20, groove_depth*2 ],true);

                 
                 //Root corner
                    for(i=[1*vent_apart:vent_apart:Saved_block_width-1*vent_apart]) 
                        translate ([ 0,i+Saved_block_width*(flaring/100-1)/2,0]) 
                            rotate([0,45,0])
                                cube([20, vent_width, groove_depth*2 ],true);
                 
                 //Tip corner
                    for(i=[1*vent_apart:vent_apart:Saved_block_width-1*vent_apart]) 
                        translate ([ prop_dia*0.5,i+Saved_block_width*(flaring/100-1)/2,0]) 
                            rotate([0,-45,0])
                                cube([20, vent_width, groove_depth*2 ],true);
    
                }
                
            }
            //Cut outline of covering form if used. Internal hole is by difference
            if (frame_width) {
                linear_extrude(block_height*4) translate([block_length-frame_length/2-frame_edge,0,0]) resize([frame_length,frame_width])circle(d=20);
            }
        }

        // Cut out the larrabee plan form or a simple box. Other shapes could be added here.
        if (larrabee) {
            linear_extrude(block_height*4) larrabee_planform(prop_dia/2, Pd, block_width);
        }
        else {
//            translate([block_length/2, Saved_block_width*flaring/100/2, block_height*2])
//                cube([block_length, Saved_block_width, block_height*4], center=true);
            translate([block_length/2, Saved_block_width*flaring/100/2, limited_block_height/2])
                cube([block_length, Saved_block_width, limited_block_height], center=true);
        }
        //Cut outline of covering form if used. external shape is by intersection
        if (frame_width) {
            linear_extrude(block_height*4) translate([block_length-frame_length/2-frame_edge,0,0]) resize([frame_length+2*frame_edge,frame_width+2*frame_edge])circle(d=20);

        }
        
    //Cut corners for fitting bed platform diagonally
        if (block_length>bed) {rotate([0,0,-45])
        cube([bed,bed,block_height*4]);}
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
module blade_surface (pitch, washout, dia, width, camber=1000)
{
    nc = 16; // the number of chord partitions. TODO: make this a parameter?
    dw = width / (nc+1);  // increments of chord width
    dr = (dia / 2) / g_sections; // increment of the overall radius, TODO: not a global
    
    //Set breakpoint in washout at 70% radius
    ibreak=ceil(g_sections*.70);
    //set vector of pitches
    constvect=[for(i=[0:ibreak-1]) pitch];
    tipvect=[for(i=[ibreak:g_sections]) pitch-(i-ibreak)/(g_sections-ibreak)*washout];
    pitchvect=concat(constvect,tipvect);

    // generates a square with a rounded top at the camber radius the
    // default camber radius of 1000 is essentially flat but still
    // has a number of small line segments needed by the alt_extrude module
    pp0 = [for(i=[1+nc/2:-1:-1-nc/2]) [cir_x(camber, dw*i), dw*i]];
    pp = concat(pp0,[[50, -width], [50, width]]);
    //todo: replace hardcoded value

    // Rotate so the blade lies along the x-axis
    rotate([-90, 0, 0]) rotate([0,90,0]) {

        // generate the blade segmens as described above
        for(i=[0:g_sections-1]) {
            angle_i  = Pangle(pitchvect[i], dia, dia*i/g_sections*dia);
            angle_i1 = Pangle(pitchvect[i+1], dia, dia*(i+1)/g_sections*dia);
            stretch (
                pp,
                transform_matrix(dr*i, angle_i),
                transform_matrix(dr*(i+1), angle_i1)
            );
        }
    }
}
