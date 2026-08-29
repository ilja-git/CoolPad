# CoolPad

A parametric laptop cooling pad, written in [OpenSCAD](https://openscad.org/),
version controlled, rendered to STL by CI on every push.

Built for an **ASUS ROG Zephyrus G14**. A fan in the middle draws air in
through the **left and right sides** and pushes it up through a grille into
the laptop's underside. The floor, front and rear are solid — the rear is
reserved for the hinge. See **[SPEC.md](SPEC.md)** for the design and its
open questions.

```
SPEC.md                       what the part is and why
src/coolpad.scad              the model, both parts
.github/workflows/render.yml  CI: STLs + previews on every push
```

## The two parts

| `part=` | Output | What it is |
| ------- | ------ | ---------- |
| `bottom` | `coolpad-bottom.stl` | tray: solid floor, fan mounts, side intake |
| `top`    | `coolpad-top.stl`    | lid: laptop surface, exhaust grille, side intake |
| `assembly` | previews only | both parts plus a stand-in fan |

`assembly` is for looking at, not for printing — it is two overlapping
solids and a fan that is not part of either.

## Getting the output

You do not need OpenSCAD installed. Every push runs the **Render** workflow
and uploads an artifact named `coolpad-<sha>`:

- `coolpad-bottom.stl`, `coolpad-top.stl` — the printable parts
- `preview-bottom.png`, `preview-top.png`, `preview-top-under.png`
- `preview-assembly.png` — exploded, showing how it goes together
- `preview-section.png` — cut in half; the one that shows the plenum gap
  under the fan

Open the repo on GitHub → **Actions** → the latest **Render** run. The run
summary lists the measured bounding boxes, and the artifact is at the bottom.

Since iOS cannot preview an STL, the PNGs are the way to check the result
from a phone.

### Rendering different dimensions without a commit

Actions → **Render** → **Run workflow**, then fill in any of `length`,
`width`, `height`. Blank fields keep the defaults from the `.scad` file.

## Parameters

All dimensions are millimetres. The headline ones:

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `length` | 312 | X, across the laptop (G14 footprint) |
| `width`  | 227 | Y, front to back |
| `height` | 28  | Z of the shell, **derived** — see below |
| `fan_size` / `fan_thickness` | 120 / 15 | slim 120 mm fan |
| `plenum_gap` | 7 | fan inlet clearance under the fan |
| `fan_offset_y` | 0 | shifts the fan/grille toward the rear |
| `material` | `"printed"` | or `"aluminium"`: changes fits and hole sizes |

`height` is not a free choice: it is `floor_t + plenum_gap + fan_thickness +
top_t`. Setting it lower fails the render with a message telling you the
minimum, rather than quietly producing a pad that crushes the fan.

The model asserts several other things it would otherwise be easy to break
by overriding — that the fan fits inside the walls, that the rubber feet do
not land on the screw heads, and that the joint bosses clear the fan bosses.

## Running it locally

```sh
# the two printable parts
openscad -D 'part="bottom"' -o coolpad-bottom.stl src/coolpad.scad
openscad -D 'part="top"'    -o coolpad-top.stl    src/coolpad.scad

# override a dimension
openscad -D 'part="top"' -D 'length=200' -o top.stl src/coolpad.scad

# machined version instead of printed (tighter fits, tapped holes)
openscad -D 'part="top"' -D 'material="aluminium"' -o top.stl src/coolpad.scad

# exploded preview. --render does a full render, so the image matches the
# exported geometry. The separation has to clear the top plate or it hides
# the fan.
openscad --render --autocenter --viewall --imgsize=1600,1200 \
         --camera=0,0,0,68,0,25,0 \
         -D 'part="assembly"' -D 'explode=110' -o preview.png src/coolpad.scad

# cutaway showing the plenum
openscad --render --autocenter --viewall --imgsize=1600,1200 \
         --camera=0,0,0,72,0,12,0 \
         -D 'part="assembly"' -D 'section=true' -o section.png src/coolpad.scad

# a different fan changes the pad's height, so let height follow it
openscad -D 'part="top"' -D 'fan_thickness=25' -D 'height=38' \
         -o top.stl src/coolpad.scad
```

Notes on `-D`:

- String values need inner quotes: `-D 'part="top"'`.
- It takes an OpenSCAD expression, so arithmetic works: `-D 'length=168*2'`.
- Quote the whole argument. `$fn` in particular must be quoted or the shell
  will eat it.
- It only overrides *top-level* variables. Module parameters are not
  reachable this way.

## Printing the test parts

**At the G14 footprint neither half fits a 220 or 256 mm bed** — they need a
350 mm-class printer. See SPEC.md §5 and open question 1; this is the one
thing blocking a physical prototype.

Both halves print open face up: the bottom as it comes out, the top rotated
180° so its plate is on the bed. No supports. The louvers bridge over their
short dimension.

The parts are joined with four M3 screws driven **from underneath**, so no
screw heads break the surface the laptop sits on. The rubber feet go in the
four corner recesses, clear of the screws.
