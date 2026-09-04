# CoolPad

A parametric laptop cooling pad, written in [OpenSCAD](https://openscad.org/),
version controlled, rendered to STL by CI on every push.

Built for an **ASUS ROG Zephyrus G14** (GA403, 2024 on). A fan in the middle
draws air in through the **open left and right sides** and pushes it up
through a grille into a chamber under the laptop. The laptop is trapped
between two locating rails and held clear of the top plate, so the chamber
vents sideways and cannot pressurise. The floor and front are solid; so is
the rear, and the rear of each side wall, so the pad does not inhale the
laptop's own exhaust. See **[SPEC.md](SPEC.md)** for the design and its open
questions, and **[MEASUREMENTS.md](MEASUREMENTS.md)** for what it is waiting
on.

```
SPEC.md                       what the part is and why
src/coolpad.scad              the model, both parts
tools/build.sh                builds everything; CI runs this same script
tools/stl2usdz.py             STL -> USDZ, for viewing on a phone
tools/check_usdz.py           verifies those USDZ files
tools/summarise.py            measured bounding boxes, for the run summary
.github/workflows/render.yml  CI: calls tools/build.sh on every push
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

You do not need anything installed. Every push runs the **Render** workflow
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
| `height` | 29  | Z of the shell, **computed** — see below |
| `fan_size` / `fan_thickness` | 140 / 16 | ARCTIC P14 Slim PWM PST |
| `plenum_gap` | 7 | fan inlet clearance under the fan |
| `fan_offset_y` | 0 | shifts the fan/grille toward the rear; **±18 mm max** |
| `laptop_foot_band` | 20 | where the laptop's own feet land — **unmeasured** |
| `rail_h` / `rail_w` | 5 / 6 | locating rails on the top surface |
| `intake_rear_block` | 45 | solid rear side-wall, so hot air is not re-inhaled |
| `base_round` | 3 | rolled bottom edge, for handling |
| `material` | `"printed"` | or `"aluminium"`: changes fits and hole sizes |

`height` is not a free choice, and not a variable you set: the model computes
it as `floor_t + plenum_gap + fan_thickness + top_t`. Change the fan and the
pad resizes itself. You can still force it with `-D height=`, and setting it
below the minimum fails the render with a message telling you that minimum,
rather than quietly producing a pad that crushes the fan.

The model asserts several other things it would otherwise be easy to break
by overriding — that the fan fits inside the walls, that the rubber feet do
not land on the screw heads, and that the joint bosses clear the fan bosses.

## Building it locally

### Toolchain

Fedora:

```sh
sudo dnf install openscad

# only needed on a headless box: OpenSCAD wants a display to write a PNG
sudo dnf install xorg-x11-server-Xvfb

# the USDZ tools. Fedora's system python is externally managed, so use a venv
python3 -m venv .venv
.venv/bin/pip install usd-core numpy-stl
```

Debian/Ubuntu: `sudo apt install openscad xvfb`, then the same venv step.

### One command

```sh
tools/build.sh                              # everything, into out/
tools/build.sh --python .venv/bin/python    # USDZ deps living in a venv
```

CI runs this same script, so a local build and a CI build are the same
build: the same manifold gate, the same camera angles, the same USDZ
checks. Expect a couple of minutes — most of it is the five full CGAL
renders behind the PNGs.

```sh
tools/build.sh --no-png            # skip the previews; much faster
tools/build.sh --no-usdz           # skip USDZ and its Python deps
tools/build.sh -D 'length=200'     # override a model variable
tools/build.sh --help
```

`tools/summarise.py --out out --intake build/intake.txt` prints the measured
bounding boxes — the same table CI puts in the run summary.

The previews render greyscale on white, via `tools/colorscheme-mono.json`.
OpenSCAD 2021.01 has no user path for colour schemes and ignores `color()`
under `--render`, so the file has to sit beside the shipped ones. The build
installs it for you where it can; if it cannot, it says so and falls back to
the stock colours rather than pretending:

```sh
sudo cp tools/colorscheme-mono.json \
        /usr/share/openscad/color-schemes/render/coolpad-mono.json
```

### Or drive OpenSCAD directly

```sh
# the two printable parts
openscad -D 'part="bottom"' -o coolpad-bottom.stl src/coolpad.scad
openscad -D 'part="top"'    -o coolpad-top.stl    src/coolpad.scad

# override a dimension
openscad -D 'part="top"' -D 'length=200' -o top.stl src/coolpad.scad

# machined version instead of printed (tighter fits, tapped holes)
openscad -D 'part="top"' -D 'material="aluminium"' -o top.stl src/coolpad.scad

# a different fan. The pad's height follows it on its own - there is no
# second number to remember.
openscad -D 'part="top"' -D 'fan_thickness=25' -o top.stl src/coolpad.scad

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
```

Notes on `-D`:

- String values need inner quotes: `-D 'part="top"'`.
- It takes an OpenSCAD expression, so arithmetic works: `-D 'length=168*2'`.
- Quote the whole argument. `$fn` in particular must be quoted or the shell
  will eat it.
- It only overrides *top-level* variables. Module parameters are not
  reachable this way.

## Viewing the output on Fedora

All of these are in Fedora's own repositories — no third-party repos needed.

| Tool | Install | Good for |
| ---- | ------- | -------- |
| **F3D** | `sudo dnf install f3d` | The quick look, and the one to reach for first. Opens instantly: `f3d out/coolpad-top.stl`. Keys: `x`/`y`/`z` axis views, `e` edges, `s` surface, `r` raytracing if built with it. |
| **PrusaSlicer** | `sudo dnf install prusa-slicer` | The check that actually matters. It tells you whether the part fits your bed, flags non-manifold errors in its own words, and previews the real print. |
| **admesh** | `sudo dnf install admesh` | `admesh out/coolpad-top.stl` — a terminal report on manifoldness and mesh health, no GUI. |
| **MeshLab** | `sudo dnf install meshlab` | Mesh forensics: measuring, cross sections, chasing down bad triangles. |
| **FreeCAD** | `sudo dnf install freecad` | When you want to measure between features properly rather than eyeball it. |
| **Blender** | `sudo dnf install blender` | Heavy, but it is the one thing here that also opens the `.usdz` files. |

F3D plus PrusaSlicer covers this project: F3D to see it, PrusaSlicer to
answer "will this print on my machine". OpenSCAD's own GUI is a viewer too —
open `src/coolpad.scad`, press F6 for a full render, and orbit.

## Printing the test parts

Each half is 311 × 220 in plan, so this needs a **350 mm-class bed** (Bambu
H2D, Prusa XL). The parts are not split for printing — see SPEC.md §5 if
that assumption turns out to be wrong.

Both halves print open face up: the bottom as it comes out, the top rotated
180° so its plate is on the bed. No supports. The side apertures bridge over
their short dimension, and the locating rails print as shallow domes with
the plate on the bed.

The parts are joined with four M3 screws driven **from underneath**, so no
screw heads break the surface the laptop sits on. The pad's own rubber feet
go in the four corner recesses, clear of the screws.
