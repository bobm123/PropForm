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
 
/* [Dimensions] */ //Note: non-zero decimals used to get proper sig figs
// Prop hub to tip along the x-axis (inches)
prop_dia_in = 14;// 

// Theoretical distance traved in one revelution (inches)
prop_pitch_in = 22;// 

// Tip wash out in inches of pitch
washout_in = 0;// 

// Width of rectangular block (inches)
block_width_in = 2.75;// 

/* [Options] */ 
// Cross Sections
xsection="flat";  // [curved:Circular,flat:Flat]

// Radius of curved cross section
camber_radius_in = 5.1;// 

// Divisions between root and tip
g_sections = 50;// 
 
// Blade plan form
planform = "trimmed"; // [full:Full block,trimmed:Trimmed block,larrabee:Larrabee planform]

// For the trimmed block, the wall left across the root and tip as a
// fraction of chord. A square cut leaves tall spikes on the twisted
// surface, cutting the corners back at 45 degrees removes them.
end_wall_fraction = 0.33;//[0.1:0.05:1]

// Percent Flaring
flaring = 0;// 

// Spar Slot Radius (mm)
slotrad = 0.8;//

// Emboss the parameters on the back of the block
label_text = true;

/* [Template] */
// Which parts to generate
parts = "block"; // [block:Block only,template:Template only,both:Block and template]

// Widen the template by the camber arc. Leave off to trace the block outline
template_corrected = false;

// Upper limit on that widening
template_max_scale = 1.5;//


/* [Printer Adjustments] */ 

//Rotation Adjustment. Tilts the blade to lay it flatter, which lowers the
//block and keeps the base outline closer to the blade surface, so the
//template matches better. 1.5 measured best on 9x14, 9x12 and 14x22;
//much above that the blade starts to get clipped by Max height in.
Rotation_Multiplier = 1.5;//[.5:0.1:3]

//Printer Bed Size in mm
Bed_Size = 180;// 

//Maximum height helpful to trim root of flaring props
Max_height_in = 2.5;// 
 
/* [Hidden] */
//Template thickness in mm, thin enough to trace or cut around
template_thickness = 2.0;

mm = 25.4;
$fn = 48;

// convert user inputs to metric
prop_dia = prop_dia_in * mm;
prop_pitch = prop_pitch_in * mm;
washout = washout_in * mm;
block_width = block_width_in * mm;
max_height = Max_height_in * mm;
g_camber_radius = camber_radius_in * mm; // TODO: make this not a global

// generate the propeller form using the parameters above
if (parts == "block" || parts == "both")
    prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, planform, Bed_Size,max_height);

// the flat template. Alongside the block it is moved aside in y so both sit
// flat on the bed as separate bodies, on its own it stays at the origin.
if (parts == "template" || parts == "both") {
    // clear of the block's half width plus the template's own, which the
    // correction can widen well past the nominal chord
    offset_y = (parts == "both")
        ? block_width*(1+flaring/100)/2
          + block_width*(template_corrected ? template_max_scale : 1)/2 + 10
        : 0;
    translate([0, offset_y, 0])
        blade_template(prop_dia, prop_pitch, block_width,
                       template_corrected, template_max_scale, g_camber_radius);
}


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
//   planform - "full" for the whole block, "trimmed" for the block with its
//      root and tip corners cut back, or "larrabee" for a Larrabee style
//      blade outline. See LarrabeePlanformSpline.scad for more detauls
//
module prop_block_mkII(prop_dia, prop_pitch, block_width, xsection, planform, bed,max_height) {
    
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
 
    intersection () {

        // Generate the blade surface and anjust its position
        difference() {
            translate([0,0,vertical_adjust]) rotate([mid_angle,0,0]) {
                if (xsection == "curved")
                    blade_surface (prop_pitch, washout,prop_dia, tip_width, g_camber_radius);
                else
                    blade_surface (prop_pitch, washout, prop_dia, tip_width);
            }

            //cut out text showing the main parameters Dia x Pd
            if (label_text) {
                translate([bblock[0]/2-20,-6,1.1]) rotate([180,0,0]) linear_extrude(1.2)
                        text(str(prop_dia/mm,"d x ",prop_pitch/mm,"p"),6);
                translate([bblock[0]/2-20,2,1.1]) rotate([180,0,0]) linear_extrude(1.2)
                        text(str(block_width_in,"\" chord"),6);
                translate([bblock[0]/2-20,10,1.1]) rotate([180,0,0]) linear_extrude(1.2)
                        text(str(g_camber_radius/mm,"\" camber"),6);
            }

            
            //cut out a groove for the spar, or a minimal marking of spar location
            translate([-5,0,vertical_adjust]) rotate([0,90,0]) cylinder(block_length+10,slotrad,slotrad);
        }

        // Cut the block to the selected plan form. Other shapes could be
        // added here.
        if (planform == "larrabee") {
            linear_extrude(block_height*4) larrabee_planform(prop_dia/2, Pd, block_width);
        }
        else if (planform == "trimmed") {
            // An octagon rather than a plain rectangle. The corners of a
            // square cut leave tall spikes of material at the root and tip
            // where the twisted surface sweeps up, which are no use for
            // forming. Chamfering them at 45 degrees trims the spikes and
            // leaves a wall of about end_wall_fraction across each end.
            translate([0, Saved_block_width*flaring/100/2, limited_block_height/2])
                linear_extrude(limited_block_height, center=true)
                    octagon_planform(block_length, Saved_block_width, end_wall_fraction);
        }
        else {
            translate([block_length/2, Saved_block_width*flaring/100/2, limited_block_height/2])
                cube([block_length, Saved_block_width, limited_block_height], center=true);
        }
    //Cut corners for fitting bed platform diagonally
        if (block_length>bed) {rotate([0,0,-45])
        cube([bed,bed,block_height*4]);}
    }
}


// The 2D outline the block is cut to, so a template matches whatever plan
// form is selected rather than always drawing the Larrabee shape.
module block_outline(dia, Pd, block_width) {
    if (planform == "larrabee")
        larrabee_planform(dia, Pd, block_width);
    else if (planform == "trimmed")
        translate([0, block_width*flaring/100/2])
            octagon_planform(dia, block_width, end_wall_fraction);
    else
        translate([dia/2, block_width*flaring/100/2])
            square([dia, block_width], center=true);
}


// A rectangle with its four corners cut off at 45 degrees, used in place of
// a plain rectangular cut for the default plan form.
//
// The blade surface is twisted, so squaring off the ends leaves tall thin
// spikes of material at the root and tip corners. Cutting those corners back
// removes them and leaves a flat wall across each end, wall_fraction of the
// block width wide.
//
// Parameters:
//   length, width - the rectangle this is derived from, in mm
//   wall_fraction - width of the remaining end wall, as a fraction of width
//
module octagon_planform(length, width, wall_fraction) {
    wall = width * wall_fraction;
    // 45 degrees, so the corner is cut back equally in x and y
    cut = max(0, (width - wall) / 2);
    polygon([
        [cut,        -width/2],
        [length-cut, -width/2],
        [length,     -wall/2],
        [length,      wall/2],
        [length-cut,  width/2],
        [cut,         width/2],
        [0,           wall/2],
        [0,          -wall/2],
    ]);
}


//
// Generates a flat template for cutting blade blanks, as a separate body
// beside the block so it can be printed or ignored as needed.
//
// The outline follows whichever plan form the block is cut to. The block's
// base outline is that plan form in top-down projection, while material laid
// on the block follows the cambered blade surface, so a blank traced from the
// base comes out slightly narrow. How much depends mostly on
// Rotation_Multiplier: laying the blade flatter brings the base outline and
// the surface closer together. At the 1.5 default the base is within about
// 2mm of the surface on a 9x14, so tracing it directly works well, which is
// the default here.
//
// Setting corrected=true widens the template by the section's arc over its
// chord, which recovers roughly half of what is left. It does not model the
// twist, so it still runs about 1mm narrow at the widest station.
//
// Parameters:
//   prop_dia, prop_pitch, block_width - as for prop_block_mkII, in mm
//   corrected - false traces the plan form as-is, true applies the widening
//   max_scale - upper limit on the widening
//   camber - cross section radius in mm, 1000 is essentially flat
//
module blade_template(prop_dia, prop_pitch, block_width, corrected, max_scale, camber=1000)
{
    Pd = prop_pitch / prop_dia;
    dia = prop_dia / 2;


    // Alignment marks at the chord centreline, matching the spar groove in
    // the block. Inset from the very ends where the outline runs out of width
    // for a hole of this size.
    mark_r = slotrad;
    root_x = max(mark_r*2, dia*0.04);
    tip_x  = dia - max(mark_r*3, dia*0.05);

    difference() {
        template_outline(dia, Pd, prop_dia, block_width, corrected,
                         max_scale, camber);
        for (x = [root_x, tip_x])
            translate([x, 0, -0.5])
                cylinder(template_thickness + 1, mark_r, mark_r);
    }
}

// The template's flat outline, before the alignment marks are cut.
module template_outline(dia, Pd, prop_dia, block_width, corrected, max_scale,
                        camber)
{
    if (!corrected) {
        linear_extrude(template_thickness) block_outline(dia, Pd, block_width);
    }
    else if (planform != "larrabee") {
        // The block outlines have a constant chord, so the camber
        // widening applies evenly and the shape does not change.
        scale([1, surface_factor(block_width, camber, 1), 1])
            linear_extrude(template_thickness)
                block_outline(dia, Pd, block_width);
    }
    else {
        // Walk the plan form's own spline for the half chord at each station,
        // then widen each side by its own correction. Building one polygon
        // avoids distorting the span while scaling the chord.
        //
        // Stations are cosine spaced so they bunch up at the root and the tip
        // where the outline turns sharply. Even spacing there cuts across the
        // curve and leaves a visible corner.
        steps = 120;
        xs = [for (i=[0:steps]) 0.5*(1 - cos(180*i/steps))];
        upper = [for (f = xs)
            [dia*f,  template_halfwidth(dia, Pd, prop_dia, block_width, f,
                                        max_scale, camber, 1)]];
        lower = [for (i=[len(xs)-1:-1:0])
            let (f = xs[i])
            [dia*f, -template_halfwidth(dia, Pd, prop_dia, block_width, f,
                                        max_scale, camber, -1)]];
        linear_extrude(template_thickness) polygon(concat(upper, lower));
    }
}

// Half width of the template on one side of the centreline, at radius
// fraction f. side is +1 for the leading edge (+y here) and -1 for the
// trailing edge.
//
// Flat sheet laid onto the block follows the cambered arc, so the template
// needs arc/chord more material than the block's base outline shows.
function template_halfwidth(dia, Pd, prop_dia, block_width, f, max_scale,
                            camber, side) =
    planform_halfchord(dia, Pd, block_width, f)
    * min(surface_factor(block_width, camber, side), max_scale);

// Extra material needed across one side of the chord, as a ratio to the
// base width the plan form cuts.
//
// Flat sheet laid onto the block follows the cambered arc of the section,
// while the base outline is the straight chord, so the template needs
// arc/chord more material. The block's tilt does not enter this: rotating
// the section is rigid and changes no lengths.
//
// NOTE: measured against rendered blocks this under-predicts toward the tip,
// where the twist makes a constant-x cut cross the section obliquely. At the
// widest part of the blade, which is what sets the blank, it lands within
// about 2mm on a 9x14. See template_corrected in the customizer.
//
// side is +1 for the leading edge (+y here) and -1 for the trailing edge.
function surface_factor(block_width, camber, side, steps=60) =
    let (h = block_width/2,
         pts = [for (i=[0:steps])
                   let (u = side * h * i/steps) [u, cir_x(camber, u)]],
         arc = add([for (i=[0:steps-1])
                       norm([pts[i+1][0]-pts[i][0], pts[i+1][1]-pts[i][1]])]))
    h < 0.001 ? 1 : arc/h;

function add(v, i=0) = i >= len(v) ? 0 : v[i] + add(v, i+1);



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
