#!/usr/bin/env bash
#
# Build every CoolPad artifact: printable STLs, PNG previews, USDZ.
#
# CI runs this same script, so what you get locally is what CI gets. Build
# steps belong here, not in .github/workflows/render.yml.
#
#   tools/build.sh                        everything, into out/
#   tools/build.sh --no-usdz              skip USDZ (and its Python deps)
#   tools/build.sh -D 'length=200'        override a model variable
#
# See README.md for setting up the toolchain.

set -euo pipefail

cd "$(dirname "$0")/.."

SCAD=src/coolpad.scad
OUT=out
BUILD=build
DO_PNG=1
DO_USDZ=1
PY=python3
EXTRA=()

usage() {
    sed -n '3,13p' "$0" | sed 's/^# \?//'
    cat <<'USAGE'

Options:
  --out DIR       where the artifacts go        (default: out)
  --build DIR     scratch, not for publishing   (default: build)
  --no-png        skip the preview renders
  --no-usdz       skip USDZ conversion and its checks
  --python BIN    interpreter holding usd-core and numpy-stl
  -D VAR=VALUE    passed to OpenSCAD; repeatable
  -h, --help      this
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --out)      OUT="$2"; shift 2 ;;
        --build)    BUILD="$2"; shift 2 ;;
        --no-png)   DO_PNG=0; shift ;;
        --no-usdz)  DO_USDZ=0; shift ;;
        --python)   PY="$2"; shift 2 ;;
        -D)         EXTRA+=(-D "$2"); shift 2 ;;
        -D*)        EXTRA+=("$1"); shift ;;
        -h|--help)  usage; exit 0 ;;
        --)         shift; EXTRA+=("$@"); break ;;
        *)          echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# GitHub picks these up as annotations; locally they are just messages.
err() {
    if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$*"; else echo "error: $*" >&2; fi
}
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# Toolchain
# ---------------------------------------------------------------------------

if ! command -v openscad >/dev/null; then
    err "openscad not found. Fedora: sudo dnf install openscad"
    exit 1
fi

# OpenSCAD needs a display to write a PNG, though not to write an STL.
OSCAD=(openscad)
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null; then
    OSCAD=(xvfb-run -a openscad)
elif [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$DO_PNG" = 1 ]; then
    err "no display and no xvfb-run, so PNG export will fail.
     Fedora: sudo dnf install xorg-x11-server-Xvfb   (or pass --no-png)"
    exit 1
fi

if [ "$DO_USDZ" = 1 ] && ! "$PY" -c 'import pxr, stl' 2>/dev/null; then
    err "$PY is missing usd-core and/or numpy-stl.
     python3 -m venv .venv && .venv/bin/pip install usd-core numpy-stl
     then: tools/build.sh --python .venv/bin/python   (or pass --no-usdz)"
    exit 1
fi

mkdir -p "$OUT" "$BUILD"
log="$BUILD/openscad.log"

if [ ${#EXTRA[@]} -eq 0 ]; then
    echo "Overrides: none (file defaults)"
else
    echo "Overrides: ${EXTRA[*]}"
fi

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

render() {
    local target="$1"; shift
    echo "--- $target"
    if ! "${OSCAD[@]}" "${EXTRA[@]}" "$@" -o "$target" "$SCAD" 2>&1 | tee "$log"; then
        err "openscad failed for $target"
        return 1
    fi
    if [ ! -s "$target" ]; then
        err "$target is empty or missing"
        return 1
    fi
}

# A part someone will print. OpenSCAD only *warns* about bad geometry and
# still exits 0, so a broken, unprintable STL would sail through unnoticed.
# The assembly mesh deliberately does not go through here: it is several
# separate bodies, for looking at.
render_part() {
    render "$@" || return 1
    if grep -qi "not be a valid 2-manifold" "$log"; then
        err "$1 is not a valid 2-manifold and cannot be printed"
        return 1
    fi
}

step "Printable parts"
render_part "$OUT/coolpad-bottom.stl" -D 'part="bottom"'
render_part "$OUT/coolpad-top.stl"    -D 'part="top"'

# Assembled mesh, for viewing only - never printed, so no manifold gate.
# Kept out of $OUT as an STL so it cannot be mistaken for something to
# slice; it ships as USDZ instead.
step "Assembly mesh"
render "$BUILD/assembly.stl" -D 'part="assembly"'

if [ "$DO_PNG" = 1 ]; then
    step "Previews"
    # --render forces a full CGAL render, so the images match the geometry
    # exported above rather than the faster preview approximation.
    preview=(--render --autocenter --viewall --imgsize=1600,1200
             --colorscheme=Tomorrow)

    render "$OUT/preview-bottom.png"    "${preview[@]}" -D 'part="bottom"'
    render "$OUT/preview-top.png"       "${preview[@]}" -D 'part="top"'
    # the underside is where the top part's real geometry is
    render "$OUT/preview-top-under.png" "${preview[@]}" \
        --camera=0,0,0,125,0,25,0 -D 'part="top"'
    # the top plate hides the fan unless the parts are well separated and
    # the camera is low enough to see into the gap
    render "$OUT/preview-assembly.png"  "${preview[@]}" \
        --camera=0,0,0,68,0,25,0 -D 'part="assembly"' -D 'explode=110'
    # edge-on half cut: the only view showing the plenum gap under the fan,
    # which is what sets the pad's height
    render "$OUT/preview-section.png"   "${preview[@]}" \
        --camera=0,0,0,72,0,12,0 -D 'part="assembly"' -D 'section=true'
fi

# The model echoes the louver free area on every render; it is the
# restriction in this design, so keep it where the summary can find it.
grep -o 'intake free area = [^"]*' "$log" | tail -1 > "$BUILD/intake.txt" || true

# ---------------------------------------------------------------------------
# USDZ - iOS opens these natively in Quick Look, including AR at true size.
# It is the only output that can be reviewed on a phone, so it is checked as
# strictly as the printable parts: a bad USDZ fails silently on the device.
# ---------------------------------------------------------------------------

if [ "$DO_USDZ" = 1 ]; then
    step "USDZ"
    "$PY" tools/stl2usdz.py "$OUT/coolpad-bottom.stl" "$OUT/coolpad-bottom.usdz"
    "$PY" tools/stl2usdz.py "$OUT/coolpad-top.stl"    "$OUT/coolpad-top.usdz"
    "$PY" tools/stl2usdz.py "$BUILD/assembly.stl"     "$OUT/coolpad-assembly.usdz" \
        --name coolpad_assembly
    "$PY" tools/check_usdz.py \
        "$OUT/coolpad-bottom.usdz"   "$OUT/coolpad-bottom.stl" \
        "$OUT/coolpad-top.usdz"      "$OUT/coolpad-top.stl" \
        "$OUT/coolpad-assembly.usdz" "$BUILD/assembly.stl"
fi

step "Built into $OUT/"
ls -lh "$OUT"
