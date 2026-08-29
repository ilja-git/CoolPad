#!/usr/bin/env python3
"""Convert an STL to USDZ, for viewing on an iPhone.

iOS opens USDZ natively in Quick Look - tap the file and it renders, with an
AR mode that places it in the room. Nothing else in this pipeline is viewable
on a phone, so this is how the part gets checked.

Two things have to be right or the AR view is useless:

  * Units. OpenSCAD works in millimetres; USD records a metersPerUnit scale.
    Setting it to 0.001 makes Quick Look show the pad at its true size, so
    holding a phone over the desk tells you whether it actually fits.
  * Up axis. The model is Z-up, Quick Look expects Y-up. The rotation is
    baked into the points here rather than left as a transform, so there is
    nothing for a viewer to interpret differently.

The model is also centred horizontally and dropped onto y=0, so AR placement
puts it on the floor/table rather than half-buried or floating.
"""

import argparse
import os
import sys
import tempfile

import numpy as np
from stl import mesh as stlmesh
from pxr import Usd, UsdGeom, UsdShade, Sdf, Gf, UsdUtils, Vt


def build_stage(stl_path, usd_path, name):
    m = stlmesh.Mesh.from_file(stl_path)

    # (n, 3, 3) triangle corners, and one normal per facet
    tris = np.asarray(m.vectors, dtype=np.float64)
    normals = np.asarray(m.normals, dtype=np.float64)

    lengths = np.linalg.norm(normals, axis=1, keepdims=True)
    # a degenerate facet has a zero normal; leave it rather than divide by zero
    normals = np.divide(normals, lengths, out=np.zeros_like(normals),
                        where=lengths > 0)

    pts = tris.reshape(-1, 3)

    # centre in X/Y, sit the base on Z=0, then map Z-up -> Y-up as (x, z, -y)
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    centre = np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]])
    pts = pts - centre

    to_y_up = lambda a: np.column_stack([a[:, 0], a[:, 2], -a[:, 1]])
    pts = to_y_up(pts)
    normals = to_y_up(normals)

    stage = Usd.Stage.CreateNew(usd_path)
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    UsdGeom.SetStageMetersPerUnit(stage, 0.001)          # model is in mm

    root = UsdGeom.Xform.Define(stage, "/" + name)
    stage.SetDefaultPrim(root.GetPrim())
    gprim = UsdGeom.Mesh.Define(stage, "/{}/geom".format(name))

    n_tris = len(tris)
    gprim.CreatePointsAttr(Vt.Vec3fArray.FromNumpy(pts.astype(np.float32)))
    gprim.CreateFaceVertexCountsAttr(Vt.IntArray.FromNumpy(
        np.full(n_tris, 3, dtype=np.int32)))
    gprim.CreateFaceVertexIndicesAttr(Vt.IntArray.FromNumpy(
        np.arange(n_tris * 3, dtype=np.int32)))

    # One normal per facet. Keeps the hard edges of a machined part crisp
    # instead of letting a viewer smooth them into mush.
    gprim.CreateNormalsAttr(Vt.Vec3fArray.FromNumpy(normals.astype(np.float32)))
    gprim.SetNormalsInterpolation(UsdGeom.Tokens.uniform)
    gprim.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)

    lo, hi = pts.min(axis=0), pts.max(axis=0)
    gprim.CreateExtentAttr(Vt.Vec3fArray.FromNumpy(
        np.array([lo, hi], dtype=np.float32)))

    # plain aluminium-ish surface, so it does not render as flat grey clay
    mat = UsdShade.Material.Define(stage, "/{}/mat".format(name))
    shader = UsdShade.Shader.Define(stage, "/{}/mat/surface".format(name))
    shader.CreateIdAttr("UsdPreviewSurface")
    shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(
        Gf.Vec3f(0.72, 0.74, 0.78))
    shader.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(0.6)
    shader.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(0.4)
    mat.CreateSurfaceOutput().ConnectToSource(
        shader.ConnectableAPI(), "surface")
    UsdShade.MaterialBindingAPI.Apply(gprim.GetPrim())
    UsdShade.MaterialBindingAPI(gprim).Bind(mat)

    stage.GetRootLayer().Save()
    return n_tris


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl")
    ap.add_argument("usdz")
    ap.add_argument("--name", default=None,
                    help="prim name; defaults to the output file's stem")
    args = ap.parse_args()

    name = args.name or os.path.splitext(os.path.basename(args.usdz))[0]
    name = "".join(c if c.isalnum() else "_" for c in name)
    if not name or name[0].isdigit():
        name = "model_" + name

    with tempfile.TemporaryDirectory() as tmp:
        usd_path = os.path.join(tmp, name + ".usdc")
        n_tris = build_stage(args.stl, usd_path, name)
        if not UsdUtils.CreateNewUsdzPackage(Sdf.AssetPath(usd_path),
                                             args.usdz):
            sys.exit("failed to write {}".format(args.usdz))

    print("{} -> {} ({} triangles)".format(args.stl, args.usdz, n_tris))


if __name__ == "__main__":
    main()
