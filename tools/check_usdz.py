#!/usr/bin/env python3
"""Verify a USDZ is one an iPhone will actually open, and holds the right shape.

Quick Look fails quietly: a malformed USDZ tends to show nothing rather than
an error, and by then the file is on a phone with no way to debug it. So the
checks run here instead.

  1. Package layout. USDZ is a zip with rules - stored (never deflated),
     each file's data 64-byte aligned, a USD layer first.
  2. USD's own usdz validators.
  3. Viewer-visible metadata: Y-up, millimetre scale, a default prim.
  4. Round trip against the source STL: same triangle count, same bounding
     box after the Z-up to Y-up swap, same surface area. Catches a converter
     that writes a valid file containing the wrong geometry.
"""

import sys
import zipfile

import numpy as np
from stl import mesh as stlmesh
from pxr import Usd, UsdGeom, UsdValidation

VALIDATORS = [
    "usdUtilsValidators:PackageEncapsulationValidator",
    "usdUtilsValidators:RootPackageValidator",
    "usdUtilsValidators:UsdzPackageValidator",
    "usdShadeValidators:ShaderSdrCompliance",
]


def tri_area(tris):
    a = tris[:, 1] - tris[:, 0]
    b = tris[:, 2] - tris[:, 0]
    return 0.5 * np.linalg.norm(np.cross(a, b), axis=1).sum()


def check(usdz_path, stl_path):
    problems = []

    z = zipfile.ZipFile(usdz_path)
    infos = z.infolist()
    if not infos:
        return ["%s: empty package" % usdz_path]
    if not infos[0].filename.endswith((".usdc", ".usda", ".usd")):
        problems.append("first zip entry is %s, must be a USD layer"
                        % infos[0].filename)
    for i in infos:
        if i.compress_type != zipfile.ZIP_STORED:
            problems.append("%s is compressed; usdz entries must be stored"
                            % i.filename)
        offset = i.header_offset + len(i.FileHeader())
        if offset % 64:
            problems.append("%s data starts at %d, not 64-byte aligned"
                            % (i.filename, offset))

    stage = Usd.Stage.Open(usdz_path)
    if stage is None:
        return problems + ["%s: could not open as a USD stage" % usdz_path]

    reg = UsdValidation.ValidationRegistry()
    for name in VALIDATORS:
        v = reg.GetOrLoadValidatorByName(name)
        if v is None:
            problems.append("validator %s unavailable" % name)
            continue
        for err in v.Validate(stage):
            problems.append("%s: %s" % (name, err.GetMessage()))

    up = UsdGeom.GetStageUpAxis(stage)
    if up != "Y":
        problems.append("upAxis is %s; Quick Look expects Y" % up)
    mpu = UsdGeom.GetStageMetersPerUnit(stage)
    if abs(mpu - 0.001) > 1e-9:
        problems.append("metersPerUnit is %s; model is in mm so it must be "
                        "0.001 or AR shows the wrong size" % mpu)
    if not stage.GetDefaultPrim():
        problems.append("no default prim; Quick Look needs one")

    meshes = [p for p in stage.Traverse() if UsdGeom.Mesh(p)]
    if len(meshes) != 1:
        problems.append("expected exactly 1 mesh, found %d" % len(meshes))
        return problems

    m = UsdGeom.Mesh(meshes[0])
    counts = np.array(m.GetFaceVertexCountsAttr().Get())
    pts = np.array(m.GetPointsAttr().Get(), dtype=np.float64)
    idx = np.array(m.GetFaceVertexIndicesAttr().Get())

    if counts.size and not (counts == 3).all():
        problems.append("mesh has non-triangular faces")

    src = stlmesh.Mesh.from_file(stl_path)
    src_tris = np.asarray(src.vectors, dtype=np.float64)

    if counts.size != len(src_tris):
        problems.append("triangle count %d != %d in the source STL"
                        % (counts.size, len(src_tris)))
        return problems

    got_tris = pts[idx].reshape(-1, 3, 3)

    # source is Z-up, package is Y-up as (x, z, -y): extents map X->X, Z->Y, Y->Z
    src_size = np.ptp(src_tris.reshape(-1, 3), axis=0)
    got_size = np.ptp(pts, axis=0)
    expect = np.array([src_size[0], src_size[2], src_size[1]])
    if not np.allclose(got_size, expect, atol=1e-3):
        problems.append("bounding box %s != expected %s"
                        % (np.round(got_size, 3), np.round(expect, 3)))

    a_src, a_got = tri_area(src_tris), tri_area(got_tris)
    if not np.isclose(a_src, a_got, rtol=1e-4):
        problems.append("surface area %.1f != %.1f in the source"
                        % (a_got, a_src))

    lo = pts.min(axis=0)
    if abs(lo[1]) > 1e-3:
        problems.append("base sits at y=%.3f, not on the ground plane" % lo[1])

    return problems


def main():
    if len(sys.argv) % 2 != 1 or len(sys.argv) < 3:
        sys.exit("usage: check_usdz.py <file.usdz> <source.stl> [...]")
    failed = False
    for usdz, stl in zip(sys.argv[1::2], sys.argv[2::2]):
        problems = check(usdz, stl)
        if problems:
            failed = True
            for p in problems:
                print("::error::%s: %s" % (usdz, p))
        else:
            print("%s: ok" % usdz)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
