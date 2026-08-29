// CoolPad - parametric laptop cooling pad
//
// Two-part shell (top + bottom) with a fan in the middle. Air enters
// through louvers in the side walls, crosses the plenum, and is pushed up
// through the top grille into the laptop. See SPEC.md.
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

length   = 168;   // X
width    = 188;   // Y
height   = 28;    // Z, assembled. Derived in SPEC.md section 4.
corner_r = 8;

wall    = 3;
floor_t = 3;
top_t   = 3;

// ---------------------------------------------------------------------------
// Fan: 120 x 120 x 15 slim, standard 105 mm screw pitch
// ---------------------------------------------------------------------------

fan_size        = 120;
fan_thickness   = 15;
fan_bore        = 113;
fan_screw_pitch = 105;
fan_boss_d      = 9;

// Axial clearance under the fan. This is its inlet - without it the fan is
// throttled against the floor. Drives the total height.
plenum_gap = 7;

// ---------------------------------------------------------------------------
// Intake louvers
// ---------------------------------------------------------------------------

slot_w     = 4.5;
slot_pitch = 9;
slot_inset = 6;    // extra clearance past the corner radius

// ---------------------------------------------------------------------------
// Joint, grille, cable port, feet
// ---------------------------------------------------------------------------

boss_d      = 8;      // top-part screw bosses
boss_socket = 1.5;    // depth of the locating socket in the floor
screw_head_d = 6.5;   // counterbore in the underside
screw_head_h = 2.4;

grille_bar  = 2.5;
grille_gap  = 7;
grille_hub  = 20;
grille_arms = 4;      // bars through the centre; 4 bars = 8 arms

cable_w = 14;         // rear cable port, straddles the joint
cable_h = 8;

// Ridges along the front edge. The production part tilts on a hinge, which
// lets the laptop slide toward the user; these stop it.
stop_l = 24;
stop_h = 4;

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
split_z    = height / 2;          // top/bottom joint
fan_z      = floor_t + plenum_gap; // underside of the fan
cx         = length / 2;
cy         = width / 2;

assert(height >= min_height,
       str("height=", height, " is too small: floor_t + plenum_gap + ",
           "fan_thickness + top_t = ", min_height));
assert(fan_size + 4 <= min(length, width) - 2 * wall,
       "fan does not fit inside the walls");
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Rounded rectangle from (0,0) to (l,w).
module rrect(l, w, r, h) {
    hull() for (x = [r, l - r], y = [r, w - r])
        translate([x, y, 0]) cylinder(r = r, h = h);
}

module annulus(ro, ri, h) {
    difference() {
        cylinder(r = ro, h = h);
        translate([0, 0, -1]) cylinder(r = ri, h = h + 2);
    }
}

// Stadium-shaped slot: starts at the origin, extends +Y by d.
module slot(w, h, d) {
    hull() for (z = [-1, 1] * max(h - w, 0) / 2)
        translate([0, 0, z]) rotate([-90, 0, 0]) cylinder(d = w, h = d);
}

// Evenly spaced slot centres along a wall of length len.
function slot_positions(len) =
    let (m    = corner_r + slot_inset,
         span = len - 2 * m,
         n    = max(1, floor(span / slot_pitch)),
         used = n * slot_pitch,
         x0   = (len - used) / 2 + slot_pitch / 2)
    [for (i = [0 : n - 1]) x0 + i * slot_pitch];

// Louvered band around the left, right and front walls, between z0 and z1.
// The rear wall (y = width) is left solid for the hinge.
module intake_band(z0, z1) {
    h  = z1 - z0;
    zc = (z0 + z1) / 2;

    for (x = slot_positions(length))            // front, y = 0
        translate([x, -1, zc]) slot(slot_w, h, wall + 2);

    for (y = slot_positions(width))             // left, x = 0
        translate([-1, y, zc]) rotate([0, 0, -90]) slot(slot_w, h, wall + 2);

    for (y = slot_positions(width))             // right, x = length
        translate([length + 1, y, zc]) rotate([0, 0, 90]) slot(slot_w, h, wall + 2);
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
        [cx + dx * fan_screw_pitch / 2, cy + dy * fan_screw_pitch / 2]];

// Rear cable port, centred on the joint so each half carries a notch.
module cable_port() {
    translate([cx - cable_w / 2, width - wall - 1, split_z - cable_h / 2])
        cube([cable_w, wall + 2, cable_h]);
}

// ---------------------------------------------------------------------------
// Bottom: tray, solid floor, fan mounting, side intake
// ---------------------------------------------------------------------------

module bottom() {
    difference() {
        union() {
            difference() {
                rrect(length, width, corner_r, split_z);

                // cavity, open at the top
                translate([wall, wall, floor_t])
                    rrect(length - 2 * wall, width - 2 * wall,
                          max(corner_r - wall, 0.5), split_z);

                intake_band(floor_t + 1, split_z - 1);
                cable_port();
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
// Top: lid, exhaust grille, laptop stops, side intake
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

module laptop_stops() {
    for (x = [length * 0.3, length * 0.7])
        translate([x, wall + 4, height])
            intersection() {
                hull() for (dx = [-1, 1] * stop_l / 2)
                    translate([dx, 0, 0]) sphere(r = stop_h);
                // keep 1 mm buried in the plate so the union overlaps
                translate([-stop_l, -stop_h, -1])
                    cube([2 * stop_l, 2 * stop_h, stop_h + 1]);
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

            laptop_stops();
        }

        // exhaust grille
        translate([cx, cy, plate_z]) grille_openings();

        intake_band(split_z + 1, plate_z - 1);
        cable_port();

        for (p = joint_points())
            translate([p[0], p[1], floor_t - boss_socket - 1])
                cylinder(d = pilot_m3, h = plate_z - floor_t + boss_socket + 1);
    }
}

// ---------------------------------------------------------------------------
// Fan stand-in - preview only, never part of an exported part
// ---------------------------------------------------------------------------

module fan_mock() {
    translate([cx - fan_size / 2, cy - fan_size / 2, fan_z]) {
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
            // must clear the stop ridges too, or their tops survive the cut
            // as detached slivers
            cube([length + 2, cy + 1, height + explode + stop_h + 3]);
    }
} else {
    model();
}
