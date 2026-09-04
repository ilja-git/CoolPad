# CoolPad — specification

Rev 0.5 — the pad becomes a chamber, not a plate.

Rev 0.5 changes the concept, not just the numbers. The top surface is no
longer a flat plate with a hole in it: the laptop is trapped between two
locating rails, held clear of the plate, and the fan blows into the chamber
that makes. Sections 3 and 6 carry the change. Much of it is deliberately
**not modelled yet** — see [MEASUREMENTS.md](MEASUREMENTS.md).

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

Seen from the front, across the pad:

```
              laptop underside
       ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔
   ←   ░░░░ chamber under laptop ░░░░   →   air leaves sideways
       ═════════╡ grille ╞═════════
                │   fan  │
   →            └────────┘            ←
   →             plenum               ←   intake: sides OPEN
       ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
                  desk
```

Seen from the side, front to rear — this is the part that is new:

```
   front                                                   rear
     ┌────┐                                      ┌────┐
     │rail│      chamber over the grille         │rail│   ← pad's rails
   ══╧════╧══════════════════════════════════════╧════╧══  top plate
   ░░░░░░░░  open side intake  ░░░░░░░░░│ SOLID BLOCK │   side wall
   ═══════════════════════════════════════════════════════
     ▲                                              ▲
     laptop's front foot                laptop's rear foot
                                                    ▲
                                    laptop's hot air comes down here
```

- **Intake: left and right walls, open.** Not louvers. Large apertures with
  the minimum posts a 3 mm wall needs. Louvers cost about a third of the free
  area and bought nothing this design wants.
- **The rear of each side wall is solid** (`intake_rear_block`). The laptop
  dumps hot air off its back edge; without this block the pad inhales its own
  exhaust. This costs intake area on purpose.
- **The floor is solid.** No bottom inlet.
- **The front wall is solid.** So is the rear — reserved for the hinge (§6)
  and for getting the laptop's hot air away (§6.1).
- **The fan needs axial clearance beneath it.** It cannot sit on the floor or
  it is throttled. `plenum_gap` (7 mm) is that clearance and it sets §4.

### The chamber, and why it is open at the sides

The laptop does not lie on the top plate. Two rails run left-to-right just
inboard of its own rubber feet, and it sits between them:

```
LAPTOP FOOT │ RAIL │  open chamber, fan below  │ RAIL │ LAPTOP FOOT
```

The rails do three jobs at once:

1. **Locate.** The laptop's feet butt against their outer faces, so it cannot
   slide — in both directions, which the old front-only stop ridges could not
   manage.
2. **Lift.** They hold the laptop off the plate, and that gap is the chamber.
3. **Separate.** They divide cool supply from the hot region at the rear.

The chamber is **deliberately open at the left and right**. The fan can then
never pressurise it: surplus air spills out of the sides. The alternative —
a sealed chamber — would stall the fan the moment the laptop's vents could
not swallow everything it delivered.

That escaping air is somewhat warmed by the laptop's underside, and some of
it will find its way back to the intake. **This is accepted and not solved.**
The recirculation actually worth blocking is the hot exhaust off the back
edge, which is what `intake_rear_block` is for.

### The intake is still the restriction

The model computes and echoes the free area on every render, and CI prints
it in the run summary:

```
intake free area = 5124 mm2 = 37% of the fan bore, in 8 apertures
```

The history is worth keeping, because it shows what each decision cost:

| | Free area | % of bore |
| --- | --- | --- |
| Louvers, 120 mm fan | 3887 mm² | 39% |
| Louvers, 140 mm fan | 4139 mm² | 30% |
| **Open sides, 140 mm fan, rear blocked** | **5124 mm²** | **37%** |

Going to a 140 mm fan cost nine points, because the bore grew from 113 to
132 mm while the louvers barely moved. Opening the sides won seven of them
back — **and it did that while also giving up 45 mm of each side wall** to
`intake_rear_block`. Without the block it would be past 45%.

That trade is worth stating plainly, because it is the one real decision in
this section: **blocking the rear costs roughly eight points of intake area
and is still worth it.** Feeding the fan hot air it has already used is a
worse failure than feeding it slightly less air.

37% remains a genuine restriction. The remaining levers, cheapest first:
deepen the bands by cutting `band_margin`, shorten `intake_rear_block` once
D1–D3 say how much is actually needed, or reopen the front wall — which is
off the table by spec, not by accident.

The same applies under the fan: at `plenum_gap` 7 mm the annulus feeding the
fan's inlet is about 2900 mm², so it is now the *smaller* of the two and may
have become the binding one. Raising the gap costs height 1 mm for 1 mm.

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
| `laptop_foot_band` | 20 mm | strip at the front and rear where the laptop's own feet land; **unmeasured** |
| `aperture_max` / `post_w` | 45 / 6 mm | side openings and the posts between |
| `intake_front` | 14 mm | solid wall kept at the front corner |
| `intake_rear_block` | 45 mm | solid rear wall, anti-recirculation; **a guess** |
| `laptop_foot_band` | 20 mm | where the laptop's feet land; **unmeasured** |
| `rail_h` / `rail_w` | 5 / 6 mm | locating rails; `rail_h` **must** exceed the laptop's foot height |
| `base_round` | 3 mm | rolled bottom edge, for handling |

`height` is the **shell** height. The top part's bounding box is larger in
both directions: its screw bosses hang down to 1.5 mm and its rails stand
5 mm proud of the plate. The CI run summary prints measured bounding boxes,
so expect **14.5** for the tray and **32.5** for the lid.

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
slide toward the user. Rev 0.4 handled that with two stop ridges along the
front edge. Rev 0.5 does it better with the locating rails of §3, which
catch the laptop in both directions and do two other jobs besides. The stop
ridges are gone.

**The hinge and the rear exhaust now want the same wall.** §6.1 needs the
rear open; the hinge wants it solid. Whichever is designed first constrains
the other, and the exhaust is the one that affects whether the pad works.

## 6.1 Rear exhaust and lap use — specified, not modelled

The laptop vents hot air downward off its back edge, inboard of its rear
foot. That air lands in the pad's rear region, and if nothing is done with
it, it sits there and gets drawn back in.

The intent:

- **Take the hot air rearward and slightly upward**, out of the back of the
  pad, so it leaves over the top of whatever is behind rather than pooling.
- **Roll and angle the rear underside upward** at the trailing edge. Two
  reasons, both real: it is more comfortable against the legs when the pad
  is used on a lap, and it aims the hot air away from them rather than down
  onto them.
- **Keep it separated from the intake** the whole way. `intake_rear_block`
  is the first half of that; a physical divider between the rear region and
  the plenum is the second, and is not modelled.

**None of this is in the model**, because every dimension it needs is
unmeasured: where the laptop's vents actually are, how far inboard of the
rear foot, and how much clearance the rear foot leaves. MEASUREMENTS.md
C2, C3 and D1–D3 are exactly the numbers this waits on.

What *is* in the model is `base_round`, which rolls the whole bottom edge by
3 mm. That covers the handling half of the requirement. The angled rear ramp
is the part still to come.

### Powering it, and the parts to buy

The chain, corrected — the step-up cables on the market are **USB-A male**,
so a USB-C-to-USB-A adapter is a required part, not an optional one:

```
laptop USB-C port
  └─ USB-C male → USB-A female adapter   ← the angled part goes here
       └─ USB-A male → 12 V step-up cable
            └─ 4-pin fan
```

The cable is not built into the shell. It comes out through a side opening
and can be run out of either side, since both are open.

Two notes on the adapter:

- It is the same part sold for plugging USB-A sticks into a USB-C laptop —
  search *USB-C to USB-A female adapter* or *USB-C OTG adapter*, ~€5. Buy a
  branded one: it has to present host-mode correctly, and the cheapest
  no-name ones do not always.
- **Put the right angle here**, not in the shell. An angled adapter at the
  laptop, or an angled USB-C cable feeding a straight adapter, is a €5 part;
  fitting an angled connector inside a 29 mm shell is not.

One thing to watch: a USB-C port fitted with an A-female adapter offers 5 V
with no negotiation, and a conservative port may allocate only 0.5–0.9 A.
A boost cable rated 0.4 A at 12 V pulls roughly 1.1 A at 5 V *at full load* —
the P14 Slim draws nowhere near its rating, so this should not bite, but it
is the thing to suspect if the fan stutters or the port drops out.

**Buy a cable with a step-up ("boost") circuit in it.** The trap is that
plenty of USB-C-to-fan cables are dumb passthrough and deliver 5 V, which
§8's analysis rules out. The listing has to say *12 V step-up*, *boost*, or
*12 V output*. Ready-made USB-to-4-pin 12 V step-up cables run about €7–10.

Two things to check before ordering:

- **Current rating.** Some of these boost cables are rated 0.4 A at 12 V,
  i.e. 4.8 W. The P14 Slim is well inside that; the Air Slimmer 140 draws
  3.24 W, which is inside it but not by much. Anything with a headline
  "dual fan" rating has more room.
- **There is no motherboard here, so nothing generates a PWM signal.** With
  the PWM pin unconnected the fan runs flat out, which will be louder than
  wanted. Either buy a boost cable with an **inline speed dial** — they
  exist and are the cheapest fix — or add a small PWM generator module.
  This is a genuine requirement, not a nicety, and it is easy to forget
  until the pad is assembled and screaming.

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

### How big a fan can this take?

Two ceilings, and the lower one is not the pad:

1. **The walls.** `width` 220 less two 3 mm walls leaves 214 mm.
2. **The laptop's own feet.** They stand on the top plate, and a foot parked
   on the grille blocks it and makes the laptop rock. At an assumed 20 mm
   front and rear (`laptop_foot_band`, unmeasured — MEASUREMENTS.md C4) the
   clear band is **180 mm**. The model now asserts the grille fits inside it.

So 180 mm is the ceiling, and a 140 mm frame with its 132 mm bore sits well
inside it. That leaves room on paper — but there is nothing to put in it:

| Size | Slimmest current option | Pad height it forces |
| ---- | ----------------------- | -------------------- |
| 120 mm | 15 mm (ARCTIC P12 Slim) | 28 mm |
| 140 mm | **15.5 mm** (SilverStone Air Slimmer 140) | 28.5 mm |
| 180 mm | ~18 mm, but discontinued (SilverStone FM182) | 31 mm |
| 180–200 mm | 20–30 mm, current stock | 33–43 mm |

Above 140 mm the slim market simply stops. Going bigger means roughly
doubling the pad's height, which defeats the point.

There is a third ceiling that has not been measured and may bind before
either of these: **the laptop's actual vent opening** (MEASUREMENTS.md B3).
A grille larger than the vents it feeds buys nothing.

### A better fan than the one specified

The **SilverStone Air Slimmer 140 (SST-AS140B)** beats the P14 Slim on every
axis that matters here:

| | ARCTIC P14 Slim | SilverStone Air Slimmer 140 |
| --- | --- | --- |
| Size | 140 × 140 × 16 | 140 × 140 × **15.5** |
| Airflow | 47 CFM | **82 CFM** |
| Static pressure | 1.31 mmH₂O | **2.0 mmH₂O** |
| Speed | 120–1800 rpm | 0–1700 rpm |
| Power | 12 V, 4-pin PWM | 12 V, 4-pin PWM, 3.24 W |
| Price | ~€10–13 | ~€20–30 |

Static pressure is the number to weigh, not airflow: §3 says the intake is
only 30% of the bore, so the fan spends its life pulling against a
restriction. 2.0 mmH₂O against 1.31 is a 50% improvement exactly where the
design is weakest. It is also 0.5 mm thinner, which the derived height picks
up for free — the pad would become 28.5 mm.

Switching is a three-line change (`fan_thickness = 15.5`, and the comment),
so it is not worth doing until one is actually ordered.

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

The measurements several of these wait on are collected in
**[MEASUREMENTS.md](MEASUREMENTS.md)**.

1. **Print bed** — assumed to take a 311 × 220 part. Worth confirming
   against the actual machine before committing to a test print, since
   nothing in the model is split.
2. **Fan alignment.** The fan is centred, as specified. The G14 draws
   through vents toward the **rear** of its underside, so a centred grille
   may not sit under them. `fan_offset_y` shifts the fan and grille back in
   one override once the vent positions are measured.

   **It has less room than you would think, and rev 0.5 tightened it.** The
   grille must now clear the locating rails, not just the laptop's feet, so
   the offset maxes out at **±18 mm** — down from ±24. The model asserts it:
   `fan_offset_y=18` renders, `19` fails. If the vents turn out to sit
   further back than 18 mm off centre, a single round grille cannot reach
   them, and the answer is a smaller fan, a non-circular grille, or
   accepting partial coverage. Worth knowing before the measurement comes
   back rather than after.

   Measurements needed: **MEASUREMENTS.md** B1–B5.
3. ~~**Fan.**~~ **Settled:** ARCTIC P14 Slim PWM PST, 140 × 140 × 16. The
   model is built around it and the height follows from it.
4. **Power — now the sharp one.** The fan is **12 V**; USB is 5 V. This
   decides the cable port: a barrel jack, a USB-C receptacle plus a
   converter, or the current bare 14 × 8 mm slot for a pass-through lead.
   Nothing else in the design blocks on it, but the port cannot be
   finalised until it is chosen. See below for why 5 V is not the answer.

### Why not just run it on 5 V

It would spin. ARCTIC publishes start voltages of 3.9 V for the P12 PWM and
3.3 V for the P12 Pro, so 5 V clears the threshold with margin, and these
fans are widely reported to keep turning down to ~3 V once started. Starting
is not the problem.

The problem is the fan laws. Speed runs roughly with voltage, and:

```
airflow          ∝ rpm         5/12 →  ~40%
static pressure  ∝ rpm²        5/12 →  ~17%
```

So 5 V costs 60% of the airflow and **83% of the static pressure**.

That ratio is why this pad in particular cannot afford it. §3 puts the
intake at 30% of the fan bore: this fan does not run in free air, it runs
against a restriction, and pulling air through a restriction is exactly what
static pressure buys. Losing five-sixths of it means the delivered airflow
falls by considerably more than the 60% the first line suggests. A 5 V pad
would not be a slower version of this design — it would be a different and
much worse one.

Three ways out, best first:

1. **5 V → 12 V boost converter**, a few euro. Works from any USB source
   with no negotiation at all, so it cannot be defeated by a charger that
   does not implement the right PD profile. Most robust option, and the
   cheapest.
2. **USB-C PD trigger at 12 V.** Full performance when it works — but 12 V
   is an *optional* PD voltage (the fixed steps are 5, 9, 15, 20 V), so it
   is charger-dependent. Also unlikely to work off the laptop's own port,
   which generally sources 5 V only.
3. **PD trigger at 9 V.** Near-universally supported. ~75% speed and ~56%
   pressure — a real compromise, but a defensible and quiet one.

If the fan is ever run at 5 V for a test, leave the PWM pin **unconnected**.
The P14 Slim stops below 9% duty, and a floating PWM line runs it flat out,
which is what you want when the supply is already the limit.
5. **The laptop's own feet.** Assumed at 20 mm front and rear
   (`laptop_foot_band`) and asserted against, but not measured. It matters
   twice: a foot on the grille blocks it, and the feet set the standoff gap
   the exhaust must cross to reach the vents. Not published in any usable
   form. Measurements needed: **MEASUREMENTS.md** C1–C4.

   Also unrecorded until now: **recirculation.** The pad breathes through
   its left and right walls. If the G14 exhausts hot air low on those same
   sides, the pad drinks its own exhaust. MEASUREMENTS.md D1–D3.
6. **Seam.** The butt joint is not airtight. Minor for a low-pressure fan;
   a gasket groove can be added if the leak matters.
7. **Stop ridges.** 4 mm proud. The right height depends on the hinge
   angle, so revisit when the tilt is fixed.
