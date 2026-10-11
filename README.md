##  Propeller Form MKII

Scripts for making propellers for use in rubber powered model airplanes.

![Printed prop form with a balsa blade blank][hero_shot]

[hero_shot]: https://github.com/bobm123/PropForm/blob/master/images/IMG_6827.JPG

These OpenSCAD scripts generates a form for molding a propeller suitable for use on lightweight rubber band powered indoor model airplanes. The form is used to warp flat sheets of balsa into a curved and twisted shape needed to produce efficient propeller blades. The script can also generate a matching flat template for cutting the blade blanks.

The photo below shows the MKI version for a 7" x 22" prop form and template for a Limited Pennyplane class model.
![Pennyplane Prob Block][pennyplane_block]

[pennyplane_block]: https://github.com/bobm123/PropForm/blob/master/images/IMG_9927.jpg

The usual procedure involves carving a wooden block for forming. This script automates that part of the process by generation such a mold from design parameters.

Details on design and construction of propellers for various endurance classes of rubber band powered model airplanes can be found on several websites, such as  https://indoornewsandviews.files.wordpress.com/2012/10/inav_121_press.pdf
Note, some competitions require that you use commercially manufactured propellers, so these scripts might not be useful there.


### Mark II Version Features

The MKII version is an attempt to improve on these by first rotating the form so the blade lies flat. How far it rotates is set by `Rotation_Multiplier`. Besides making the block shorter and easier to print, laying the blade flatter keeps the base outline close to the curved blade surface, so the printed outline is a better guide to the size of blank you need. A value of 1.5 works well across the props tested; much above that and the blade starts to be clipped by `Max height in`.

As an option, the blade shape can be cutout to an approximation of a Larrabee planform, described below.

A flat template for cutting blade blanks can be generated alongside the block, or on its own, using the `parts` option. It carries small alignment holes at the root and tip that line up with the spar groove in the block.


### OpenSCAD Version

The latest versions of OpenSCAD include an optimizer panel that allows you to change parameters without modifying code. 
![Using the Customizer] [using_the_customizer]

[using_the_customizer]: https://github.com/bobm123/PropForm/blob/master/images/CustomizerScreenshot.jpg

The development snapshots, such as OpenSCAD-2019.01.10 are available by scrolling down to the "Development Snapshots" area at http://www.openscad.org/downloads.html

The basic design parameters for a propeller are its diameter and pitch, or theoretical distance traveled in one revolution. The block width is also needed as this indirectly sets the blade's chord.

Additional options include whether the blades are flat plates or curved cross sections. Currently the script does not support other airfoil shapes, but that could be added. Finally, a parameter specifies the number of sections along the length of the blade. I suggest not increasing this too much (at least while adjusting the other parameters) as the script may become unresponsive. Values of about 50 seems like a good number here. 

Of course, other blade shapes can be used by printing a recatngular block and using it to form any shaped blanks. One common variation is to placed the blade centerline ahead of the form centerline slightly. This is sometime done so the thin blade material flexes slightly under high torque at the beginning of the motor run and possibly yields something like a variable pitch propeller.


### Larrabee Planforms

![Larrabee planform for Different Pitch props][larrabbee_examples]

[larrabbee_examples]: https://github.com/bobm123/PropForm/blob/master/images/LarrabeePlanform.jpg

Setting the `larrabee` option cuts the block to a blade outline rather than leaving it a plain rectangle. The shape comes from a line of work that starts with E. Eugene Larrabee's "Design of Propellers for Motorsoarers" (NASA CP-2085, 1979), a copy of which is in [docs](docs/19790015732.pdf).

Larrabee's paper is about propellers of *minimum induced loss*: given a disc loading, air density, shaft speed, flight speed and blade count, it works out the radial circulation distribution that wastes the least energy, following Betz, Prandtl and Goldstein. The result that matters here is the chord distribution. Because the required circulation has to be carried at a sensible lift coefficient, the blade comes out with what the paper calls "the typical wide root chord - narrow tip chord geometry of a propeller matched to a low advance ratio". That is the broad, round shape these forms produce, and it is quite different from the parallel or elliptical outlines often used.

The full method needs an iterative calculation. Reg Boor published a BASIC program for it in *Aeromodeller*, October 1990, and John Barker later worked out exact outlines for a range of pitch ratios. Sergio Montes then gave a simplified construction in the March/April 2007 *Winding Stooge*, a scan of which is in [docs](docs/Scan20260922_0087.png), and that is what `LarrabeePlanformSpline.scad` implements:

1. Pick the maximum chord `Cmax` and the pitch ratio P/D.
2. Read off where the maximum chord falls. Montes gives this as a curve; the script fits it with `CmaxPosition()`, a quadratic in P/D. For P/D = 1.25 it puts the widest point at r/R = 0.42, matching the article's worked example of about 0.43.
3. Draw a circle of radius `Cmax/2` at the hub and at the maximum chord station, and one of `Cmax/6` at the tip.
4. Join them with curves tangent to the circles.

The script replaces the french curve of step 4 with a Hermite spline through the same control points, which gives the same outline but lets it be generated for any P/D. The circles themselves are still in the source as commented-out geometry if you want to see the construction. `root_fraction` sets how wide the blade is where it meets the hub.

Montes is honest that this is an approximation, and that there is no definitive proof the planform beats the alternatives, though many Coupe flyers prefer it. The same caution applies here.


### Printing and Post Processing

![Mark II Block vs Mark I][MarkII_Block]

[MarkII_Block]: https://github.com/bobm123/PropForm/blob/master/images/MkIIBlockComparison10x15.png

Print the block with the blade surface facing up, which is how the script orients it. Supports are not usually needed once the block has been rotated flat.

The surface finish matters more here than on most prints, because every layer line is reproduced in the balsa when the blade is formed against it. Two things help:

**Adaptive layer height.** Most current slicers (PrusaSlicer, OrcaSlicer, Cura and others) can vary layer height across the model, using thin layers where the surface is shallow and thicker ones where it is steep. The blade surface is close to horizontal over much of its area, which is exactly the case where fixed layers leave wide, visible steps, so this is worth turning on.

![Adaptive layers in the slicer][adaptive_layers]

[adaptive_layers]: https://github.com/bobm123/PropForm/blob/master/images/AdaptiveLayers.png

The slicer preview above is coloured by layer height. The blade surface runs green where the layers have been made thin to follow the shallow curve, while the thicker layers near the base of the block show warmer. The template is on the bed alongside the block, which is what the `parts` option set to "Block and template" produces.

**Filling the layer lines.** Even with adaptive layers some stepping remains. Spot filler or glazing putty, thinned a little and wiped across the surface with a finger or a flexible blade, fills the valleys without building up on the high spots. Let it dry, sand back with fine paper until the plastic shows through on the ridges, and repeat if needed. The aim is a continuous surface, not a thick coat. A coat of sanding sealer or primer afterwards gives a harder surface that survives repeated forming.

Work gently near the trailing edge, where the block runs thin and is easy to round over.


### Alternate Extruder Function for OpenSCAD

Motivation: to provide additional features for the native OpenSCAD linear_transform() operation whith specific requirements for how verticies are mapped between endpoint.
![Surface details][surface_details]

[surface_details]: https://github.com/bobm123/PropForm/blob/master/images/SurfaceDetails.jpg

