# CoolPad — specification

Rev 0.1 — first buildable revision. Supersedes the placeholder cube.

## 1. Product

A laptop cooling pad. The laptop rests on top; a fan in the middle draws air
in through the **sides** and pushes it up through a grille into the laptop's
underside.

## 2. Assembly

Two parts, joined into a closed shell:

| Part     | File               | Function |
| -------- | ------------------ | -------- |
| `bottom` | `coolpad-bottom.stl` | Tray: floor, fan mounting, side intake, screw access |
| `top`    | `coolpad-top.stl`    | Lid: laptop bearing surface, exhaust grille, side intake |

The assembled shell is **hollow**. That cavity is the plenum: it is the air
path from the side intakes to the fan inlet, so it must stay clear.

Joint: flat butt at mid-height (`split_z = height/2`), four M3 screws driven
**from underneath** into bosses that hang from the top part. Screw heads are
therefore on the underside — the laptop-bearing surface stays unbroken. The
boss tips land in shallow sockets in the floor, which register the two parts
against each other, so no separate dowels are needed.

The screws sit inboard (`joint_inset` 28 mm) of the rubber-foot recesses
(`foot_inset` 16 mm), so a stuck-on foot never covers a screw head and the
pad can be opened without peeling its feet off. The model asserts this
clearance, and asserts that the joint bosses clear the fan bosses. Moving
the screws inboard does trade away some clamping right at the corners; if
the seam gaps there on the first print, the fix is more screws, not a
bigger inset.

## 3. Airflow

```
        laptop
   ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
   ══╡ grille ╞══        ← exhaust, up
  →  │  fan   │  ←
  →  └────────┘  ←       ← fan draws down-to-up
  →   plenum     ←       ← intake, from the sides
   ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
        desk (solid floor)
```

- **Intake: sides only.** The floor is solid — no bottom inlet. Intake is a
  louvered band around the left, right and front walls, split across both
  parts by the joint line.
- **The rear wall is deliberately solid**, reserved for the hinge (§6) and
  the cable port.
- **The fan is an axial fan, so it needs axial clearance beneath it.** This
  is the driving dimension of the whole part: the fan cannot sit on the
  floor or it would be throttled. `plenum_gap` (default 7 mm) is that
  clearance, and it sets the height budget in §4.

### Known restriction

Intake free area is roughly 50% of the fan bore area. The intake is the
limiting restriction in this design, not the grille. It can be opened up by
extending the louvered band into the rear wall, which is being held back
until the hinge is placed. Flagged rather than fixed.

## 4. Height budget

Total height is not a free choice — it is the sum of the stack:

```
floor_t       3      solid floor
plenum_gap    7      fan inlet clearance   ← drives the design
fan_thickness 15     120 x 120 x 15 slim fan
top_t         3      top plate
------------------
height       28
```

The fan's top face therefore lands flush against the underside of the top
plate, so it exhausts into the grille without leaking back into the plenum.

`height` is asserted against this sum in the model. Overriding it below the
minimum fails the render with an explicit message rather than producing
silently broken geometry.

## 5. Nominal dimensions

| Parameter | Default | Note |
| --------- | ------- | ---- |
| `length` (X) | 168 mm | |
| `width` (Y)  | 188 mm | |
| `height` (Z) | 28 mm  | derived from §4, was 20 |
| `corner_r`   | 8 mm   | |
| `wall`, `floor_t`, `top_t` | 3 mm | |
| `fan_size`   | 120 mm | standard 120 mm frame |
| `fan_thickness` | 15 mm | slim; 25 mm is the common thickness, 15 mm keeps the pad low |
| `fan_screw_pitch` | 105 mm | standard for a 120 mm fan |
| `fan_bore`   | 113 mm | |
| `stop_l` / `stop_h` | 24 / 4 mm | front stop ridges |

`height` is the **shell** height. The stop ridges stand 4 mm proud of the
top plate, so the top part's true bounding box is 32 mm tall, and the
assembled pad is 32 mm over the desk before stick-on feet. The CI run
summary prints measured bounding boxes, so expect 28 for the bottom-to-top
shell and 32 including the stops.

**Footprint is print-bed constrained, not laptop constrained.** 168 × 188
fits a 220 × 220 bed whole. A pad covering a full laptop footprint (~350 mm
wide) cannot be printed in one piece on a hobby printer, so the test parts
would have to be split and joined. This revision sits under the centre and
rear of the laptop instead. If the aluminium production part should be
full-width, that is a deliberate divergence between test and production
geometry and needs deciding — see §8.

## 6. Hinge — not in this revision

The end product tilts on a hinge. This revision is **flat and fixed**. To
keep the hinge addable without a redesign, the rear wall carries no intake
louvers and no other features except the cable port; it is left as clear
material for hinge bosses.

Consequence of the future tilt, handled now: a tilted pad lets the laptop
slide toward the user, so the top plate carries two **stop ridges** along the
front edge.

## 7. Material

Test parts are 3D printed; production parts are aluminium. The model carries
a `material` switch that changes fits and hole sizes:

| | `printed` | `aluminium` |
| --- | --- | --- |
| Screw holes | self-tapping pilot | tapped M3 / M4 |
| Joint clearance | 0.35 mm | 0.10 mm |

Not encoded in the model, but required for the aluminium part:

- Internal vertical corners need a radius ≥ the cutter radius (assume 3 mm
  for a 6 mm end mill). The current internal corners are `corner_r - wall` =
  5 mm, which clears this.
- No internal undercuts anywhere; every feature is reachable from above or
  below. This is why the joint is a plain butt joint rather than a tongue
  and groove.

Print orientation for the test parts: both halves print **open face up** —
bottom as-is, top rotated 180° so its plate is on the bed. No supports
needed; the intake louvers are bridged over their short dimension.

## 8. Open questions

1. **Footprint.** Keep 168 × 188 (printable whole), or go full laptop width
   for the aluminium part and accept that test prints are split?
2. **Fan.** 120 × 15 assumed. Confirm the actual fan, since its thickness
   sets the pad's height directly.
3. **Power.** A rear cable port is modelled as a plain 14 × 8 mm slot for a
   fan lead. If this should take a USB-C jack or an inline switch instead,
   the port needs resizing to the chosen part.
4. **Seam.** The butt joint is not airtight. Minor for a low-pressure fan;
   a gasket groove can be added if the leak matters.
5. **Stop ridges.** 4 mm proud, at 30% and 70% of the width. Fine for a
   flat pad; the right height depends on the hinge angle, so revisit them
   when the tilt is fixed.
