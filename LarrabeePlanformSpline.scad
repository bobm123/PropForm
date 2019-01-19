
// Approximate position of maximum Chord as a fucntion of Pd.
function CmaxPosition(Pd) = -0.07291667*Pd*Pd + 0.44166667*Pd - 0.01875;

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

    c0 = [[0,Cmax/20], [cp,0], [cp,Cmax/2], [cp,0]];
    c1 = [[cp,Cmax/2], [cp,0], [dia,0], [0,-(Cmax)]];
    c2 = [[dia,0],[0,-(Cmax)], [cp,-Cmax/2], [-cp,0]];
    c3 = [[cp,-Cmax/2], [-cp,0], [0,-Cmax/20], [-cp,0]];

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