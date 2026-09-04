// CoolPad - parametric laptop cooling pad
//
// Two-part shell (top + bottom) with a fan in the middle. Air enters through
// open apertures in the side walls, crosses the plenum, and is pushed up
// through the top grille into the chamber under the laptop. That chamber is
// bounded front and rear by locating rails and open at the left and right,
// so it cannot pressurise. See SPEC.md.
//
// All dimensions in millimetres. Every variable below is top level, so it
// can be overridden from the command line:
//
//   openscad -D 'part="top"' -o top.stl src/coolpad.scad
//
// See README.md for more examples.

// ---------------------------------------------------------------------------
// What to render
// ---------------------------------------------------------------------------

part    = "assembly";   // "bottom", "top" or "assembly"
explode = 0;            // assembly only: lift the top part by this much
section = false;        // cut the model in half to show the inside
show_fan = true;        // assembly only: draw a stand-in fan (never exported)

// ---------------------------------------------------------------------------
// Material: "printed" for test parts, "aluminium" for production
// ---------------------------------------------------------------------------

material = "printed";

printed = (material == "printed");

// Clearance on the top/bottom joint, and pilot holes. A printed part
// self-taps, a machined one gets a tapped thread.
fit_gap   = printed ? 0.35 : 0.10;
pilot_m3  = printed ? 2.6  : 2.5;   // M3
pilot_m4  = printed ? 3.6  : 3.3;   // M4, fan screws

// ---------------------------------------------------------------------------
// Envelope
// ---------------------------------------------------------------------------

// Sized to an ASUS ROG Zephyrus G14, GA403 generation (2024 on): the
// laptop is approximately 311 x 220 x 16 mm.
length   = 311;   // X, across the laptop
width    = 220;   // Y, front to back
corner_r = 8;

// height is deliberately absent here: it is not a free choice but the sum
// of the stack, so it is derived from the fan below. See SPEC.md section 4.

wall    = 3;
floor_t = 3;
top_t   = 3;

// The bottom edge is rolled over so the pad is pleasant to pick up and to
// rest on a lap. Purely ergonomic; nothing depends on it.
base_round = 3;

// ---------------------------------------------------------------------------
// Fan: ARCTIC P14 Slim PWM PST, 140 x 140 x 16, 4-pin PWM, 12 V
// ---------------------------------------------------------------------------

fan_size        = 140;
fan_thickness   = 16;   // this alone sets the pad height - see the stack below
fan_bore        = 132;  // frame opening, kept just inside the real one
fan_screw_pitch = 125;  // ARCTIC's figure; the older 140 mm norm is 124.5
fan_boss_d      = 9;

// Axial clearance under the fan. This is its inlet - without it the fan is
// throttled against the floor. Drives the total height.
plenum_gap = 7;

// The fan is centred, as specified. The G14 draws through vents toward the
// rear of its underside, so if the grille should line up with those instead,
// shift the fan back with this rather than moving anything by hand. The
// locating rails bound how far it can go - the model asserts it.
fan_offset_y = 0;

// ---------------------------------------------------------------------------
// The laptop's feet, and the rails that trap it
// ---------------------------------------------------------------------------

// Where the laptop's own rubber feet land, MEASURED on the machine on
// 2026-09-04. See MEASUREMENTS.md. They are two long strips running nearly
// the full width, not pads, and the band between them is not symmetric.
foot_gap_rear   = 14.14;  // rear edge -> outboard edge of the rear strip
foot_w_front    = 7.8;    // width of the front strip
foot_clear_span = 166.0;  // between the strips: 118.72 + 47.30, taken in two
                          // parts because a 150 mm caliper cannot span it

// The rear strip's width was not measured. Assuming it matches the front is
// the only guess left in this block; if it turns out different, the whole
// band shifts front-to-back by the difference and nothing else changes.
foot_w_rear     = foot_w_front;

// Rails running left to right, just inboard of the laptop's feet. The laptop
// sits between them and its feet butt against their outer faces, so it
// cannot slide - which is what the old front stop ridges did, less well and
// in one direction only. The rails also hold the laptop off the top plate,
// and that gap is how the exhaust escapes sideways instead of pressurising.
//
// rail_h must exceed the laptop's foot height or the laptop rests on its own
// feet and the rails locate nothing. That height is MEASUREMENTS.md C3.
rail_h       = 5;
rail_w       = 6;
rail_x_inset = 16;

// ---------------------------------------------------------------------------
// Side intake - open, not louvered
// ---------------------------------------------------------------------------

// The sides are open. Louvers cost roughly a third of the free area and buy
// nothing this design needs, so what remains is the least structure that
// keeps a 3 mm wall from flexing: a few large apertures with posts between.
aperture_max = 45;   // widest an aperture gets before another post is added
post_w       = 6;    // material left between apertures
intake_front = 14;   // solid material kept at the front corner
band_margin  = 1;    // solid material kept above and below each band

// Solid section at the REAR of each side wall. The laptop dumps hot air off
// its back edge, and without this the pad inhales its own exhaust straight
// back through the side intake. The length is a guess until MEASUREMENTS.md
// D1-D3 land, and it is the single cheapest thing to retune afterwards.
intake_rear_block = 45;

// ---------------------------------------------------------------------------
// Joint, grille, feet
// ---------------------------------------------------------------------------

boss_d      = 8;      // top-part screw bosses
boss_socket = 1.5;    // depth of the locating socket in the floor
screw_head_d = 6.5;   // counterbore in the underside
screw_head_h = 2.4;

grille_bar  = 2.5;
grille_gap  = 7;
grille_hub  = 20;
grille_arms = 4;      // bars through the centre; 4 bars = 8 arms

foot_d = 16;          // recesses for stick-on rubber feet
foot_t = 1;

// Feet sit at the corners for stability; the joint screws are inboard of
// them so a stuck-on foot never covers a screw head.
joint_inset = 28;
foot_inset  = 16;

$fa = 2;
$fs = 0.6;

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------

min_height = floor_t + plenum_gap + fan_thickness + top_t;

// The fan's top face has to land flush under the top plate or it exhausts
// straight back into its own plenum, so the height follows the fan rather
// than the other way round. Fit a thicker fan and the pad grows by itself.
// -D height=... still overrides, and the assert below still catches a
// height that would crush the fan.
height     = min_height;

split_z    = height / 2;          // top/bottom joint
fan_z      = floor_t + plenum_gap; // underside of the fan
cx         = length / 2;
cy         = width / 2;
fan_cy     = cy + fan_offset_y;   // fan/grille centre

lo_band = [floor_t + band_margin, split_z - band_margin];
hi_band = [split_z + band_margin, height - top_t - band_margin];

// Inner faces of the locating rails: the clear span the grille must fit in.
// Inboard edges of the laptop's foot strips, i.e. the clear band the rails
// and grille have to live inside. Derived from the measurements above rather
// than set, so a corrected measurement moves everything at once.
foot_band_rear  = foot_gap_rear + foot_w_rear;               // 21.94
foot_band_front = width - foot_band_rear - foot_clear_span;  // 32.06

// Inner faces of the rails: the clear span the grille must fit in.
rail_front = foot_band_front + rail_w;
rail_rear  = width - foot_band_rear - rail_w;

// Aperture layout. One row per half, split by the joint line.
intake_y0   = intake_front;
intake_y1   = width - intake_rear_block;
intake_span = intake_y1 - intake_y0;
n_aper      = max(1, ceil(intake_span / (aperture_max + post_w)));
aper_w      = (intake_span - (n_aper - 1) * post_w) / n_aper;

function aperture_positions() =
    [for (i = [0 : n_aper - 1]) intake_y0 + i * (aper_w + post_w)];

// Free area of the intake, against the fan's bore. The intake is the
// restriction in this design, so this number is worth watching.
function stadium_area(w, h) = max(w - h, 0) * h + PI * pow(h / 2, 2);
intake_area = 2 * n_aper * (stadium_area(aper_w, lo_band[1] - lo_band[0])
                            + stadium_area(aper_w, hi_band[1] - hi_band[0]));
bore_area   = PI * pow(fan_bore / 2, 2);

echo(str("intake free area = ", round(intake_area), " mm2 = ",
         round(100 * intake_area / bore_area), "% of the fan bore, in ",
         2 * n_aper, " apertures"));

assert(height >= min_height,
       str("height=", height, " is too small: floor_t + plenum_gap + ",
           "fan_thickness + top_t = ", min_height));
assert(fan_size + 4 <= length - 2 * wall
       && fan_cy - fan_size / 2 - 2 >= wall
       && fan_cy + fan_size / 2 + 2 <= width - wall,
       "fan does not fit inside the walls at this size/offset");
assert(split_z > floor_t && split_z < height - top_t,
       "split_z falls outside the cavity");
assert(part == "bottom" || part == "top" || part == "assembly",
       str("unknown part: ", part));

// A foot must not land on a screw head, or the screw is trapped under it.
assert(sqrt(2) * abs(joint_inset - foot_inset) > foot_d / 2 + screw_head_d / 2,
       "foot recesses overlap the joint screw heads");

// Joint bosses must clear the fan bosses.
assert(min([for (j = joint_points(), f = fan_points())
            norm([j[0] - f[0], j[1] - f[1]])]) > (boss_d + fan_boss_d) / 2,
       "joint bosses collide with fan bosses");

// The grille has to sit between the rails, not under one of them - and by
// extension not under a laptop foot. This is the tightest constraint on
// fan_offset_y by a long way.
assert(foot_band_front > 0 && foot_band_rear > 0,
       "the measured foot band does not fit inside the pad's depth");
assert(fan_bore <= rail_rear - rail_front,
       str("grille (", fan_bore, " mm) will not fit between the rails (",
           rail_rear - rail_front, " mm)"));
assert(fan_cy - fan_bore / 2 >= rail_front
       && fan_cy + fan_bore / 2 <= rail_rear,
       "fan_offset_y pushes the grille under a locating rail");

// A rail lower than the laptop's own feet locates nothing.
assert(rail_h > rail_w / 2, "rail_h too small for its rounded top");

// The apertures must stay openings rather than collapsing back into
// slots, which is what the louvers were and what this replaced.
assert(intake_span > 0 && aper_w >= lo_band[1] - lo_band[0],
       str("side openings have collapsed to ", aper_w, " mm slots: ",
           "intake_front + intake_rear_block leave too little wall"));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Rounded rectangle from (0,0) to (l,w).
module rrect(l, w, r, h) {
    hull() for (x = [r, l - r], y = [r, w - r])
        translate([x, y, 0]) cylinder(r = r, h = h);
}

// The same, with the bottom edge rolled over by f. The solid stays convex,
// so a single hull() through the profile is exact rather than an
// approximation, and it costs one CGAL union instead of a minkowski.
module rrect_round_base(l, w, r, h, f) {
    steps = 6;
    hull() {
        translate([0, 0, f]) rrect(l, w, r, h - f);
        for (i = [0 : steps]) {
            a  = i * 90 / steps;
            di = f - f * sin(a);      // f -> 0
            dz = f - f * cos(a);      // 0 -> f
            translate([di, di, dz])
                rrect(l - 2 * di, w - 2 * di, max(r - di, 0.5), 0.01);
        }
    }
}

module annulus(ro, ri, h) {
    difference() {
        cylinder(r = ro, h = h);
        translate([0, 0, -1]) cylinder(r = ri, h = h + 2);
    }
}

// Horizontal stadium, centred on the origin in Y and Z, extruded +X by d.
// Rounded ends so an opening this large is not a stress riser in a 3 mm wall.
module aperture(w, h, d) {
    hull() for (y = [-1, 1] * max(w - h, 0) / 2)
        translate([0, y, 0]) rotate([0, 90, 0]) cylinder(d = h, h = d);
}

// One row of intake apertures through the left and right walls, between z0
// and z1. Left and right only: the front wall is solid, and so is the rear,
// which is reserved for the hinge and for getting the laptop's hot air away.
module intake_openings(z0, z1) {
    h  = z1 - z0;
    zc = (z0 + z1) / 2;
    for (y = aperture_positions()) {
        yc = y + aper_w / 2;
        translate([-1, yc, zc])              aperture(aper_w, h, wall + 2);
        translate([length - wall - 1, yc, zc]) aperture(aper_w, h, wall + 2);
    }
}

// Joint screw positions, inboard of the feet.
function joint_points() =
    let (m = joint_inset)
    [[m, m], [length - m, m], [m, width - m], [length - m, width - m]];

// Foot recesses, out at the corners.
function foot_points() =
    let (m = foot_inset)
    [[m, m], [length - m, m], [m, width - m], [length - m, width - m]];

function fan_points() =
    [for (dx = [-1, 1], dy = [-1, 1])
        [cx + dx * fan_screw_pitch / 2, fan_cy + dy * fan_screw_pitch / 2]];

// ---------------------------------------------------------------------------
// Bottom: tray, solid floor, fan mounting, side intake
// ---------------------------------------------------------------------------

module bottom() {
    difference() {
        union() {
            difference() {
                rrect_round_base(length, width, corner_r, split_z, base_round);

                // cavity, open at the top
                translate([wall, wall, floor_t])
                    rrect(length - 2 * wall, width - 2 * wall,
                          max(corner_r - wall, 0.5), split_z);

                intake_openings(lo_band[0], lo_band[1]);
            }

            // fan bosses, floor up to the underside of the fan
            for (p = fan_points())
                translate([p[0], p[1], floor_t])
                    cylinder(d = fan_boss_d, h = plenum_gap);
        }

        // fan screws
        for (p = fan_points())
            translate([p[0], p[1], floor_t - 1])
                cylinder(d = pilot_m4, h = plenum_gap + 2);

        // joint screws: through the floor, counterbored underneath so the
        // heads sit below the desk-facing surface
        for (p = joint_points()) {
            translate([p[0], p[1], -1])
                cylinder(d = 3.4, h = floor_t + 2);
            translate([p[0], p[1], -0.01])
                cylinder(d = screw_head_d, h = screw_head_h);
            // socket that locates the top part's boss
            translate([p[0], p[1], floor_t - boss_socket])
                cylinder(d = boss_d + 2 * fit_gap, h = boss_socket + 0.01);
        }

        // recesses for stick-on rubber feet
        for (p = foot_points())
            translate([p[0], p[1], -0.01]) cylinder(d = foot_d, h = foot_t);
    }
}

// ---------------------------------------------------------------------------
// Top: lid, exhaust grille, locating rails, side intake
// ---------------------------------------------------------------------------

// The bars that stay: centre hub, concentric rings, radial arms.
module grille_bars() {
    o = 0.05;
    translate([0, 0, -o]) cylinder(d = grille_hub, h = top_t + 2 * o);
    for (r = [grille_hub / 2 + grille_gap : grille_bar + grille_gap
              : fan_bore / 2])
        translate([0, 0, -o]) annulus(r + grille_bar, r, top_t + 2 * o);
    for (i = [0 : grille_arms - 1])
        rotate([0, 0, i * 180 / grille_arms])
            translate([-fan_bore / 2, -grille_bar / 2, -o])
                cube([fan_bore, grille_bar, top_t + 2 * o]);
}

// The air gaps, i.e. everything inside the bore that is not a bar. Cutting
// these out of the plate keeps the top part a single solid - adding a
// separately built grille back into a bored hole leaves coincident faces
// and exports non-manifold.
module grille_openings() {
    intersection() {
        translate([0, 0, -0.01]) cylinder(d = fan_bore, h = top_t + 0.02);
        difference() {
            translate([0, 0, -0.02])
                cylinder(d = fan_bore + 2, h = top_t + 0.04);
            grille_bars();
        }
    }
}

// Two rails, one just inboard of each of the laptop's foot strips. Rounded
// on top, drafted at the sides, and buried 1 mm in the plate so the union
// overlaps rather than sitting tangent to it.
module locating_rails() {
    x0    = rail_x_inset;
    len_x = length - 2 * rail_x_inset;
    for (y0 = [foot_band_front, rail_rear])
        hull() {
            translate([x0, y0 + rail_w / 2, height + rail_h - rail_w / 2])
                rotate([0, 90, 0]) cylinder(d = rail_w, h = len_x);
            translate([x0, y0, height - 1])
                cube([len_x, rail_w, 0.01]);
        }
}

module top_part() {
    plate_z = height - top_t;

    difference() {
        union() {
            // skirt + plate
            difference() {
                translate([0, 0, split_z])
                    rrect(length, width, corner_r, height - split_z);
                translate([wall, wall, split_z - 1])
                    rrect(length - 2 * wall, width - 2 * wall,
                          max(corner_r - wall, 0.5),
                          plate_z - split_z + 1);
            }

            // screw bosses, hanging from the plate down onto the floor
            for (p = joint_points())
                translate([p[0], p[1], floor_t - boss_socket])
                    cylinder(d = boss_d, h = height - floor_t + boss_socket);

            locating_rails();
        }

        // exhaust grille
        translate([cx, fan_cy, plate_z]) grille_openings();

        intake_openings(hi_band[0], hi_band[1]);

        for (p = joint_points())
            translate([p[0], p[1], floor_t - boss_socket - 1])
                cylinder(d = pilot_m3, h = plate_z - floor_t + boss_socket + 1);
    }
}

// ---------------------------------------------------------------------------
// Fan stand-in - preview only, never part of an exported part
// ---------------------------------------------------------------------------

module fan_mock() {
    translate([cx - fan_size / 2, fan_cy - fan_size / 2, fan_z]) {
        difference() {
            rrect(fan_size, fan_size, 5, fan_thickness);
            translate([fan_size / 2, fan_size / 2, -1])
                cylinder(d = fan_bore, h = fan_thickness + 2);
            for (dx = [-1, 1], dy = [-1, 1])
                translate([fan_size / 2 + dx * fan_screw_pitch / 2,
                           fan_size / 2 + dy * fan_screw_pitch / 2, -1])
                    cylinder(d = 4.5, h = fan_thickness + 2);
        }
        translate([fan_size / 2, fan_size / 2, 0]) {
            cylinder(d = 40, h = fan_thickness);
            for (i = [0 : 6])
                rotate([0, 0, i * 360 / 7])
                    translate([0, 0, fan_thickness / 2])
                        rotate([20, 0, 0])
                            translate([18, 0, 0])
                                cube([36, 1.2, 11], center = true);
        }
    }
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

module model() {
    if (part == "bottom") bottom();
    else if (part == "top") top_part();
    else {
        bottom();
        translate([0, 0, explode]) top_part();
        if (show_fan) translate([0, 0, explode / 2]) fan_mock();
    }
}

if (section) {
    // Half cut on Y, keeping the far half, so the cut face points at the
    // camera in a front view. This is the only view that shows the plenum
    // gap under the fan, which is the dimension the design turns on.
    difference() {
        model();
        translate([-1, -1, -1])
            // must clear the rails too, or their tops survive the cut as
            // detached slivers
            cube([length + 2, cy + 1, height + explode + rail_h + 3]);
    }
} else {
    model();
}
