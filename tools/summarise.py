#!/usr/bin/env python3
"""Print a Markdown summary of a build.

An --autocenter --viewall preview has no scale reference: a 168 mm pad and
a 1680 mm pad look identical. So report the measured bounding boxes next to
the images, along with the intake free area the model echoes.

CI appends this to $GITHUB_STEP_SUMMARY; locally it just prints.
"""

import argparse
import glob
import os
import struct
import sys


def vertices(path):
    """Yield (x, y, z) from an STL, ASCII or binary."""
    with open(path, "rb") as fh:
        head = fh.read(5)
        if head == b"solid":                      # ASCII, as OpenSCAD writes
            fh.seek(0)
            for line in fh:
                if line.strip().startswith(b"vertex"):
                    yield tuple(map(float, line.split()[1:4]))
            return
        fh.seek(80)
        (count,) = struct.unpack("<I", fh.read(4))
        for _ in range(count):
            data = struct.unpack("<12fH", fh.read(50))
            for i in (3, 6, 9):
                yield data[i:i + 3]


def bbox(path):
    pts = list(vertices(path))
    if not pts:
        return None
    return [max(p[i] for p in pts) - min(p[i] for p in pts) for i in range(3)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out", help="directory holding the STLs")
    ap.add_argument("--intake", help="file holding the echoed intake area")
    ap.add_argument("--overrides", default="", help="the -D arguments used")
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(args.out, "*.stl")))
    if not files:
        print(f"No STLs in `{args.out}`.")
        return 0

    print("### CoolPad\n")
    print("| part | X (mm) | Y (mm) | Z (mm) |")
    print("| ---- | ------ | ------ | ------ |")
    for f in files:
        d = bbox(f)
        name = os.path.basename(f).replace("coolpad-", "").replace(".stl", "")
        if "do-not-print" in name:
            name = name.replace("-do-not-print", "") + " *"
        if d is None:
            print(f"| {name} | ? | ? | ? |")
        else:
            print(f"| {name} | {d[0]:g} | {d[1]:g} | {d[2]:g} |")

    ov = args.overrides.strip()
    print(f"\nOverrides: `{ov}`" if ov else "\nOverrides: none (file defaults)")

    if args.intake:
        try:
            with open(args.intake) as fh:
                intake = fh.read().strip()
            if intake:
                print(f"\nIntake: {intake}.")
        except OSError:
            pass

    print("\nThe top part's Z includes the locating rails.")
    print("\n`assembly *` is overlapping bodies plus a stand-in fan — for "
          "looking at, never for slicing.")
    print("\nSTLs, USDZ and previews are in the artifact below.")
    print("\nOn an iPhone: download the artifact, unzip it in Files, then tap "
          "a `.usdz` - it opens in Quick Look, and the AR button shows it at "
          "real size. Pushing a tag skips all of that: a release attaches "
          "each file on its own URL, so a `.usdz` is one tap in Safari.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
