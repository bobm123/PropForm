##  Propeller Form MKII

Scripts for making propellers for use in rubber powered model airplanes.

These OpenSCAD scripts generates a form for molding a propeller suitable for use on lightweight rubber band powered indoor model airplanes. The form is used to warp flat sheets of balsa into a curved and twisted shape needed to produce efficient propeller blades. The cover photo shows the MKI version for a 7" x 22" prop form and template for a Limited Pennyplane class model.
![Pennyplane Prob Block][pennyplane_block]

[pennyplane_block]: https://github.com/bobm123/PropForm/blob/master/images/IMG_9927.jpg

The usual procedure involves carving a wooden block for forming. This script automates that part of the process by generation such a mold from design parameters.

Details on design and construction of propellers for various endurance classes of rubber band powered model airplanes can be found on several websites, such as  https://indoornewsandviews.files.wordpress.com/2012/10/inav_121_press.pdf
Note, some competitions require that you use commercially manufactured propellers, so these scripts might not be useful there.


### Mark II Version Features

The MKII version is an attempt to improve on these by first rotating the form so the blade lies flat.
![Mark II Block vs Mark I][MarkII_Block]

[MarkII_Block]: https://github.com/bobm123/PropForm/blob/master/images/MkIIBlockComparison10x15.png

As an option, the blade shape can be cutout to an approximation of the design given here:

https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19790015732.pdf


### Mark II Updates

Added the following features:
- Flaring capability. This moves the prop spar off center to allow more prop blade area ahead of spar
- Printer adjustments to minimize prop block height. Some manual adjustemnts are provided to optimize when automated adjustments are still too high, especially when using flaring part
- Printer bed size. If mold doe snot fit bed, it attempts to fit by rotating 45 degrees and trimming inboard corners.
- Wash out. Added washout in inches of pitch reduction, applied over outer 30% of blade
- Covering frame. Makes an oval covering frame that follows the twist of the pitch progression, useful for covered props like F1D
- Ventilation. Adds grooves to the surface to aid in drying of formed prop blades, based on Aero Martin's appraoch
- String grooves. Adds small groves around bottom corners to aid in wrapping with string hold-down for sheet balsa props. Uses width parameters for ventillation
- Spar pocket. Adds a groove for installing a spar below the blade. Set to 0.5mm for a reference groove, larger for accomodating a spar
- Added a Json file with example setups. Put in same directory, populates preset pulldwon. MErge with existing if needed


### OpenSCAD Version

The latest versions of OpenSCAD include an optimizer panel that allows you to change parameters without modifying code. 
![Using the Customizer] [using_the_customizer]

[using_the_customizer]: https://github.com/bobm123/PropForm/blob/master/images/CustomizerScreenshot.jpg

The development snapshots, such as OpenSCAD-2019.01.10 are available by scrolling down to the "Development Snapshots" area at http://www.openscad.org/downloads.html

The basic design parameters for a propeller are its diameter and pitch, or theoretical distance traveled in one revolution. The block width is also needed as this indirectly sets the blade's chord.

Additional options include whether the blades are flat plates or curved cross sections. Currently the script does not support other airfoil shapes, but that could be added. Finally, a parameter specifies the number of sections along the length of the blade. I suggest not increasing this too much (at least while adjusting the other parameters) as the script may become unresponsive. Values of about 50 seems like a good number here. 

Of course, other blade shapes can be used by printing a recatngular block and using it to form any shaped blanks. One common variation is to placed the blade centerline ahead of the form centerline slightly. This is sometime done so the thin blade material flexes slightly under high torque at the beginning of the motor run and possibly yields something like a variable pitch propeller.


### Larrabee Planforms

Describe the LarrabeePlanform.scad script.
![Larrabee planform for Different Pitch props][larrabbee_examples]

[larrabbee_examples]: https://github.com/bobm123/PropForm/blob/master/images/LarrabeePlanform.jpg


### Alternate Extruder Function for OpenSCAD

Motivation: to provide additional features for the native OpenSCAD linear_transform() operation whith specific requirements for how verticies are mapped between endpoint.
![Surface details][surface_details]

[surface_details]: https://github.com/bobm123/PropForm/blob/master/images/SurfaceDetails.jpg

