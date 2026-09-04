# CoolPad — specification

Rev 0.4 — targeted at the GA403 G14, ARCTIC P14 Slim fan.

## 1. Product

A cooling pad for an **ASUS ROG Zephyrus G14**. The laptop rests on top; a
fan in the middle draws air in through the **left and right sides** and
pushes it up through a grille into the laptop's underside.

### Target laptop

Target is the **GA403** generation (2024 on): approximately
**311 × 220 × 16 mm**, ~1.5 kg. For reference, the earlier generations are
GA401 (2020–21) at 324 × 222 and GA402 (2022–23) at 312 × 227.

The pad matches the laptop footprint exactly, so the laptop's edges sit
flush with the pad's. `length` and `width` are parametric, so retargeting a
different generation is a `-D` override, not a redesign.

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
clearance, and asserts that the joint bosses clear the fan bosses.

## 3. Airflow

```
            laptop
     ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
     ═════╡ grille ╞═════        ← exhaust, up
   →      │  fan   │      ←
   →      └────────┘      ←      ← fan draws down-to-up
   →       plenum          ←     ← intake, left and right walls only
     ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
            desk (solid floor)
```

- **Intake: left and right walls only.** Louvered bands in those two walls,
  split across both parts by the joint line.
- **The floor is solid** — no bottom inlet.
- **The front and rear walls are solid.** The rear is additionally reserved
  for the hinge (§6) and carries the cable port.
- **The fan is an axial fan, so it needs axial clearance beneath it.** This
  is the driving dimension of the whole part: the fan cannot sit on the
  floor or it would be throttled. `plenum_gap` (default 7 mm) is that
  clearance, and it sets the height budget in §4.

### The intake is the restriction

Confining intake to two walls costs about a third of the available open
area. To claw some back, the louvers were opened up from 4.5 mm slots to
**6 mm slots on a 9 mm pitch** (a 3 mm land between slots).

The model computes and echoes the result on every render, and CI prints it
in the run summary:

```
intake free area = 4139 mm2 = 30% of the fan bore
```

**The move to a 140 mm fan made this worse, not better.** The louvers gained
a little area (the pad is 1 mm taller, so the bands are), but the fan's bore
grew from 113 to 132 mm, and the ratio fell from 39% to 30%. The fan can now
move more air than the walls can feed it, so the louvers, not the grille, are
firmly the limit. It is the first thing to attack if the pad underperforms.
The levers, in order of cheapness: widen the slots further, deepen the
louvered bands, or reopen the front wall. Reopening the front is the big one,
and it is off the table by spec, not by accident.

The same applies under the fan: at `plenum_gap` 7 mm the annulus feeding the
fan's inlet is about 2900 mm², so it is of the same order as the louvers.
Raising the gap costs height 1 mm for 1 mm.

## 4. Height budget

Total height is not a free choice — it is the sum of the stack:

```
floor_t       3      solid floor
plenum_gap    7      fan inlet clearance   ← drives the design
fan_thickness 16     ARCTIC P14 Slim, 140 x 140 x 16
top_t         3      top plate
------------------
height       29
```

`height` is **not a variable you set** — the model computes it from this sum.
Fit a different fan and the pad grows to suit, in one override:
`-D fan_thickness=25` gives a 38 mm pad with no second edit and no chance of
forgetting one.

The fan's top face therefore lands flush against the underside of the top
plate, so it exhausts into the grille without leaking back into the plenum.

`-D height=...` still overrides, for the odd experiment. Overriding it below
the minimum fails the render with an explicit message rather than producing
silently broken geometry.

## 5. Nominal dimensions

| Parameter | Default | Note |
| --------- | ------- | ---- |
| `length` (X) | 311 mm | across the laptop (GA403) |
| `width` (Y)  | 220 mm | front to back |
| `height` (Z) | 29 mm  | **computed**, not set — see §4 |
| `corner_r`   | 8 mm   | |
| `wall`, `floor_t`, `top_t` | 3 mm | |
| `fan_size`   | 140 mm | ARCTIC P14 Slim frame |
| `fan_thickness` | 16 mm | the P14 Slim's real thickness; sets the pad height |
| `fan_screw_pitch` | 125 mm | ARCTIC's figure; the older 140 mm norm is 124.5 |
| `fan_bore`   | 132 mm | frame opening, kept just inside the real one |
| `fan_offset_y` | 0 | shifts the fan and grille toward the rear — see §8 |
| `slot_w` / `slot_pitch` | 6 / 9 mm | louvers |
| `stop_l` / `stop_h` | 24 / 4 mm | front stop ridges |

`height` is the **shell** height. The top part's bounding box is larger in
both directions: its screw bosses hang down to 1.5 mm and its stop ridges
stand 4 mm proud of the plate. The CI run summary prints measured bounding
boxes, so expect **14.5** for the tray and **31.5** for the lid.

### Print size

Each half is 311 × 220 in plan, so a test print needs a **350 mm-class bed**
(Bambu H2D, Prusa XL). It does not fit a 220, 250 or 256 mm machine.

The parts are **not** split for printing: the printer is assumed big enough.
If that turns out to be wrong, splitting each half across the short axis
with a bolted lap joint is the fallback, and it is easier to add than to
design around now.

## 6. Hinge — not in this revision

The end product tilts on a hinge. This revision is **flat and fixed**. To
keep the hinge addable without a redesign, the rear wall carries no
louvers and no other features except the cable port; it is left as clear
material for hinge bosses.

Consequence of the future tilt, handled now: a tilted pad lets the laptop
slide toward the user, so the top plate carries two **stop ridges** along
the front edge.

### The fan

**ARCTIC P14 Slim PWM PST**: 140 × 140 × 16 mm, fluid dynamic bearing,
120–1800 rpm PWM, 47 cfm, 1.31 mmH₂O static pressure, 130 g, mounting holes
⌀4.3 mm on a 125 mm pitch.

Two consequences worth carrying forward:

- **It is 12 V.** A USB-A port gives 5 V, and USB-C gives 5 V unless
  something negotiates higher. Powering this from a laptop port is not a
  detail to leave to the end — see §8.
- **PST means two connectors** on the lead: a 4-pin socket and a 4-pin
  daisy-chain plug, each roughly 10.5 × 6.5 mm. The 14 × 8 mm cable port
  passes them one at a time, which works but is snug.

Its 1.31 mmH₂O static pressure is the number that makes the restriction in
§3 tolerable: this is a pressure-optimised fan, not a free-air one.

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
needed; the louvers are bridged over their short dimension.

### Top plate stiffness

A 3 mm plate now spans 311 mm. In aluminium that is fine under a ~1.5 kg
laptop whose weight lands mostly over the perimeter and the grille. In PLA
it is marginal and the plate may bow visibly. If the first print flexes,
the fix is ribs on the underside running **left to right**, along the
airflow rather than across it. Not modelled yet — flagged rather than
guessed at.

## 8. Open questions

1. **Print bed** — assumed to take a 311 × 220 part. Worth confirming
   against the actual machine before committing to a test print, since
   nothing in the model is split.
2. **Fan alignment.** The fan is centred, as specified. The G14 draws
   through vents toward the **rear** of its underside, so a centred grille
   may not sit under them. `fan_offset_y` shifts the fan and grille back in
   one override once the vent positions are measured.
3. ~~**Fan.**~~ **Settled:** ARCTIC P14 Slim PWM PST, 140 × 140 × 16. The
   model is built around it and the height follows from it.
4. **Power — now the sharp one.** The fan is **12 V**; USB is 5 V. Either
   accept reduced speed on 5 V (a 12 V fan usually spins, slowly, and may
   not start reliably), add a USB-C PD trigger board to pull 12 V, or use a
   separate 12 V supply. This decides the cable port: a barrel jack, a
   USB-C receptacle and a trigger board, or the current bare 14 × 8 mm slot
   for a pass-through lead. Nothing else in the design blocks on it, but the
   port cannot be finalised until it is chosen.
5. **The laptop's own feet.** Where the G14's rubber feet land on the top
   plate is unmeasured. It matters twice: a foot sitting on the grille
   blocks part of it, and the feet set the standoff gap through which the
   pad's exhaust reaches the laptop's vents. Not published in any usable
   form — measure the real machine.
6. **Seam.** The butt joint is not airtight. Minor for a low-pressure fan;
   a gasket groove can be added if the leak matters.
7. **Stop ridges.** 4 mm proud. The right height depends on the hinge
   angle, so revisit when the tilt is fixed.
