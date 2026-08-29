# CoolPad

A parametric laptop cooling pad, written in [OpenSCAD](https://openscad.org/),
version controlled, rendered to STL by CI on every push.

Built for an **ASUS ROG Zephyrus G14** (GA403, 2024 on). A fan in the
middle draws air in through the **left and right sides** and pushes it up
through a grille into the laptop's underside. The floor, front and rear are solid — the rear is
reserved for the hinge. See **[SPEC.md](SPEC.md)** for the design and its
open questions.

```
SPEC.md                       what the part is and why
src/coolpad.scad              the model, both parts
tools/stl2usdz.py             STL -> USDZ, for viewing on a phone
tools/check_usdz.py           verifies those USDZ files
.github/workflows/render.yml  CI: STLs + USDZ + previews on every push
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
- `coolpad-bottom.usdz`, `coolpad-top.usdz`, `coolpad-assembly.usdz` —
  the same geometry in a format iOS opens natively (see below)
- `preview-bottom.png`, `preview-top.png`, `preview-top-under.png`
- `preview-assembly.png` — exploded, showing how it goes together
- `preview-section.png` — cut in half; the one that shows the plenum gap
  under the fan

Open the repo on GitHub → **Actions** → the latest **Render** run. The run
summary lists the measured bounding boxes, and the artifact is at the bottom.

## Viewing it on an iPhone

iOS will not preview an STL, but it opens **USDZ** natively in Quick Look —
no app needed. From the run artifact:

1. Download the artifact zip in Safari.
2. Open it in **Files** and tap the zip to unpack it (Files unzips in place).
3. Tap a `.usdz`. It opens in Quick Look — drag to rotate and pinch to zoom.
4. Tap **AR** to place it in the room.

The files carry real-world scale (`metersPerUnit` 0.001, since the model is
in millimetres), so AR shows the pad at its true size — hold the phone over
your desk, or over the laptop, and the fit is directly checkable. They are
also Y-up and dropped onto the ground plane, which is what Quick Look
expects; `tools/check_usdz.py` enforces all of that in CI, because a
malformed USDZ shows nothing on the device rather than reporting an error.

`coolpad-assembly.usdz` is the one to look at first — it is the whole
product, assembled, fan included.

The PNGs remain the quickest glance, and the run summary carries the
measured dimensions.

### Rendering different dimensions without a commit

Actions → **Render** → **Run workflow**, then fill in any of `length`,
`width`, `height`. Blank fields keep the defaults from the `.scad` file.

## Parameters

All dimensions are millimetres. The headline ones:

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `length` | 311 | X, across the laptop (G14 GA403) |
| `width`  | 220 | Y, front to back |
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

# STL to USDZ for viewing on a phone, then verify the result
python3 tools/stl2usdz.py coolpad-top.stl coolpad-top.usdz
python3 tools/check_usdz.py coolpad-top.usdz coolpad-top.stl

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

Each half is 311 × 220 in plan, so this needs a **350 mm-class bed** (Bambu
H2D, Prusa XL). The parts are not split for printing — see SPEC.md §5 if
that assumption turns out to be wrong.

Both halves print open face up: the bottom as it comes out, the top rotated
180° so its plate is on the bed. No supports. The louvers bridge over their
short dimension.

The parts are joined with four M3 screws driven **from underneath**, so no
screw heads break the surface the laptop sits on. The rubber feet go in the
four corner recesses, clear of the screws.
