// CoolPad - parametric base plate
//
// All dimensions in millimetres.
// Every parameter below is a top-level variable, so it can be
// overridden from the command line without editing this file:
//
//   openscad -D 'length=200' -D 'height=12' -o out.stl src/coolpad.scad
//
// See README.md for more examples.

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

length = 168;   // X
width  = 188;   // Y
height = 20;    // Z

// Facet resolution. Low while previewing, higher for a final render:
//   openscad -D '$fn=128' ...
$fa = 1;
$fs = 0.4;

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

// The base is a placeholder: the actual part geometry is not decided yet.
// Add new features as separate modules and compose them here.
module base(l = length, w = width, h = height) {
    cube([l, w, h]);
}

base();
