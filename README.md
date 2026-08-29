# CoolPad

Parametric 3D models written in [OpenSCAD](https://openscad.org/), version
controlled, rendered to STL by CI on every push.

```
src/coolpad.scad            the model
.github/workflows/render.yml CI: STL + PNG preview on every push
```

The current geometry is a **placeholder** — a plain rectangular base. The real
part geometry is still to be decided.

## Parameters

All dimensions are millimetres.

| Variable | Default | Meaning |
| -------- | ------- | ------- |
| `length` | 168     | X       |
| `width`  | 188     | Y       |
| `height` | 20      | Z       |

They are top-level variables, so `-D` on the command line overrides them
without editing the file.

## Getting the output

You do not need OpenSCAD installed to see a result. Every push runs the
**Render** workflow, which uploads an artifact named `coolpad-<sha>`
containing:

- `coolpad.stl` — the mesh, for slicing/printing
- `preview.png` — a rendered image, since iOS cannot preview an STL

Open the repo on GitHub → **Actions** → the latest **Render** run → the
artifact is at the bottom of the run summary.

### Rendering with different dimensions, without a commit

Actions → **Render** → **Run workflow**, then fill in any of `length`,
`width`, `height`. Blank fields keep the defaults from the `.scad` file.
The values are passed straight through as `-D` overrides.

## Running it locally

```sh
# STL with the defaults from the file
openscad -o coolpad.stl src/coolpad.scad

# Override a single dimension
openscad -D 'height=12' -o coolpad.stl src/coolpad.scad

# Override several at once
openscad -D 'length=200' -D 'width=150' -D 'height=8' \
         -o coolpad.stl src/coolpad.scad

# PNG preview instead of a mesh; the format comes from the -o extension.
# --render does a full render rather than the fast preview, so the image
# matches the geometry that gets exported.
openscad --render --autocenter --viewall --imgsize=1600,1200 \
         -o preview.png src/coolpad.scad

# Smoother curves for a final render (irrelevant for the current cube,
# but it is what you will want once there are rounded features)
openscad -D '$fn=128' -o coolpad.stl src/coolpad.scad
```

Notes on `-D`:

- It takes an OpenSCAD expression, so it can do arithmetic:
  `-D 'length=168*2'`.
- Quote the argument. `$fn` in particular must be quoted or the shell
  will eat it.
- It only overrides *top-level* variables. Module parameters are not
  reachable this way.

## Adding geometry

Put new features in their own module in `src/coolpad.scad` and compose them
in the call at the bottom of the file. Keep anything you might want to tweak
from the command line as a top-level variable.
