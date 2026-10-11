
// Root chord as a fraction of Cmax (was 1/10). File scope so the
// half chord function below uses the same value as the outline.
root_fraction = 1/8;

// Approximate position of maximum Chord as a fucntion of Pd.
function CmaxPosition(Pd) = -0.07291667*Pd*Pd + 0.44166667*Pd - 0.01875;

// Half the chord at radius fraction f along the blade, for callers that need
// the plan form as a width function rather than an outline. Samples the same
// upper edge segments the polygon is built from (c0 then c1) and interpolates
// between the two samples that straddle the requested station.
function planform_halfchord(dia, Pd, Cmax, f) =
    let (pts = planform_upper(dia, Pd, Cmax),
         x = dia * f)
    planform_lookup(pts, x);

// The upper edge as [x, y] samples, root to tip. Sampled far more finely than
// the outline polygon needs: the lookup below interpolates between these, and
// near the tip the curve falls away steeply enough that coarse samples would
// cut the corner off.
Ufine = [for (i=[0:0.005:1.0005]) [1,i,i*i,i*i*i]];

function planform_upper(dia, Pd, Cmax) =
    let (cp = dia * CmaxPosition(Pd),
         rf = root_fraction,
         c0 = [[0,Cmax*rf/2], [cp,0], [cp,Cmax/2], [cp,0]],
         c1 = [[cp,Cmax/2], [cp,0], [dia,0], [0,-(Cmax)]])
    concat([for (p = Ufine*Hinv*c0) p], [for (p = Ufine*Hinv*c1) p]);

// Largest y at x over the sample list. More than one segment can straddle x
// where samples bunch together, so taking the maximum keeps the outline on
// the outside of the curve. Returns 0 past the tip, where the chord runs out.
function planform_lookup(pts, x) =
    max([for (i = [0:len(pts)-2])
            let (x0 = pts[i][0], x1 = pts[i+1][0])
            (min(x0,x1) <= x && x <= max(x0,x1) && abs(x1-x0) > 1e-9)
                ? pts[i][1] + (pts[i+1][1]-pts[i][1])*(x-x0)/(x1-x0)
                : 0]);

Hinv = [
    [1.,0.,0.,0.],
    [0.,1.,0.,0.],
    [-3.,-2.,3.,-1.],
    [ 2.,1.,-2.,1.]
];

U = [for (i=[0:.05:1.05]) [1,i,i*i,i*i*i]];

Chord = 2.25;
linear_extrude(.1) {
    translate([0, Chord*0.0, 0]) larrabee_planform (5, 1.0, Chord);
    translate([0, Chord*1.5, 0]) larrabee_planform (5, 1.5, Chord);
    translate([0, Chord*3.0, 0]) larrabee_planform (5, 2.0, Chord);
    translate([0, Chord*4.5, 0]) larrabee_planform (5, 2.5, Chord);
}


module larrabee_planform(dia, Pd, Cmax) {

    cp = dia * CmaxPosition(Pd);

    c0 = [[0,Cmax*root_fraction/2], [cp,0], [cp,Cmax/2], [cp,0]];
    c1 = [[cp,Cmax/2], [cp,0], [dia,0], [0,-(Cmax)]];
    c2 = [[dia,0],[0,-(Cmax)], [cp,-Cmax/2], [-cp,0]];
    c3 = [[cp,-Cmax/2], [-cp,0], [0,-Cmax*root_fraction/2], [-cp,0]];

    path = [c0, c1, c2, c3];
    /*
    color("Blue") {
        translate([cp,0]) circle(Cmax/2, $fn=48);
        translate([dia-Cmax/6,0]) circle(Cmax/6, $fn=48);
    }
    */
    
    polygon([for(c = path) for (p = U*Hinv*c) p]);
/*
    for (c = path) {
        coef = Hinv*c;
        for (p = U*coef) {
            translate(p) circle(.05);
        }
    }
*/
}