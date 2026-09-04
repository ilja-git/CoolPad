# What we still need measured

Everything here is about the **underside of the G14 (GA403)**. None of it is
published in a usable form — I looked: ASUS gives no dimensioned bottom-case
drawing, the service guides are photo-based, and the teardown sites block
automated reading. So it has to come off the real machine.

Fill in the **Value** column and commit this file. Nothing else is needed —
each number lands in a single parameter, listed under "Feeds".

---

## You do not need a ruler

Put a **bank card** flat on the laptop's underside and photograph the whole
underside straight down, from about arm's length, with the card in frame.

Every bank card is the ISO/IEC 7810 ID-1 size, **85.60 × 53.98 mm**, to a
tolerance far tighter than we need. That makes it a scale bar. From one such
photo I can measure everything in sections A and B myself, to about ±1 mm.

Rules for the photo, in order of how much they matter:

1. **Straight down.** Phone parallel to the laptop's base, not tilted. Tilt
   is the one error a scale bar cannot undo.
2. **Card flat on the same surface** as what is being measured — not on the
   desk beside the laptop, or it is at the wrong distance and scales wrong.
3. **Whole underside in frame**, all four corners visible.
4. Even light, no hard shadow across the vents.

A second photo from a **low angle across the surface**, card stood on edge,
gets me the foot heights in section C.

Drop the photos anywhere in the repo — GitHub's mobile site can upload
straight into a branch — or attach them in the session.

A tape measure or calipers beats the photo if you have one later. Calipers
are worth it for C3 only.

---

## Measured 2026-09-04 — the real machine

Photos and a Scaniverse scan are in `scan/` (gitignored — large binaries, and
not source; the numbers that matter belong here). Photo names say what each
one shows.

**The scan is not usable for measurement.** It is metrically scaled, but its
raw bounding box is 395 × 35 × 386 mm against a real 311 × 220 × 16, and even
trimming outliers the thickness axis reads 21–23 mm — the ~1 cm noise floor
of phone LiDAR. Keep it as a visual reference; the numbers come from the
calipers.

Throughout, **rear** is the hinge edge and **front** is the edge nearest the
user.

| Reading | What it measures | Feeds |
| ------- | ---------------- | ----- |
| 14.14 mm | Rear edge → outboard edge of the rear foot strip. The downward exhaust vent sits inside this band, and there appears to be a second exhaust on the rear face itself. | `foot_gap_rear`, §6.1 |
| 118.72 mm | Rear foot strip → the step in the bottom panel where the vented area ends. | clear span, part 1 |
| 47.87 mm | That step → the front foot strip. | clear span, part 2 |
| 47.30 mm | The same span measured again. | repeatability |
| 16.42 mm | Foot strip → the side, measured laterally, out to where the underside starts to slope away. The flat bearing area extends this far past the end of the strip. | `rail_x_inset` |
| 7.80 mm | Width of the front foot strip. It is sloped, so its **height** is still unmeasured. | `foot_w_front` |
| 154.32 mm | Not a measurement. The 150 mm caliper ran out of travel trying to span the two feet in one go — which is why the span was taken in two parts instead. | — |

### The number that matters: 166 mm between the feet

```
118.72  rear foot → step
+ 47.30  step → front foot      (the smaller of the two reads)
--------
 166.02  clear span between the foot strips
```

The two reads of the second leg differ by **0.57 mm**, which is the honest
repeatability of measuring a soft rubber strip by hand. The **smaller** value
is used deliberately: too small and the rails sit slightly inboard of the
feet, which costs nothing; too large and they land under a foot, which is the
failure the rails exist to avoid.

**This is 14 mm tighter than the 180 mm that was assumed**, and it moved the
design. See "What changed" below.

### Where that band sits, front to back

Measuring from the rear edge:

```
   0.00   rear edge
  14.14   rear foot strip starts          measured
      ?   rear foot strip width           NOT MEASURED - assumed 7.8, as the front
 166.02   clear span between the strips   measured (two-part)
   7.80   front foot strip width          measured
      ?   front foot strip → front edge   NOT MEASURED - falls out of the total
```

On the assumption that the rear strip matches the front at 7.8 mm, the clear
band runs from **21.9 mm to 188.0 mm** from the rear edge. Against a 220 mm
depth that puts its centre about **5 mm rearward** of the pad's own centre —
so a centred fan is very slightly forward of ideal, but only just.

### What changed in the model

| | Was | Now |
| --- | --- | --- |
| Clear span between feet | 180 mm (guess) | **166.0 mm** (measured) |
| Band symmetry | symmetric | **21.9 rear / 32.1 front** |
| `fan_offset_y` range | ±18 mm | **−5.9 to +16.1 mm** |

The grille is 132 mm and the two rails take 6 mm each, so 144 mm of the
166 mm span is spoken for, leaving 22 mm to share between the two ends. It
still fits.

The offset range is no longer symmetric, because the band is not: it sits
about 5 mm rearward of the pad's centre. **That asymmetry is in our favour.**
The vents are toward the rear, so rearward is the direction we want to move,
and there is 16 mm of it — nearly as much as the 18 mm the symmetric guess
promised. It is forward travel that has almost vanished, and nothing wants to
go that way. Verified against the model: `fan_offset_y=16` renders, `17`
fails; `-5` renders, `-6` fails.

### Still outstanding

- **Foot strip height.** Sets `rail_h`, which must exceed it or the laptop
  rests on its own feet and the rails locate nothing. The strips are sloped,
  so this is awkward — a sheet of paper or a feeler gauge slid under the
  laptop until it stops would answer it well enough.
- **Rear foot strip width**, currently assumed equal to the front at 7.8 mm.
  If it is different, the band shifts front-to-back by the difference.
- **Overall depth**, still taken as 220 mm.

### What the straight-down photos settle on their own

The bottom intake is a **single large perforated field**, not two openings —
so one circular grille is the right shape. It spans most of the width and a
broad band of the depth, so a 132 mm grille overlaps it heavily even before
any offset. The fan-alignment worry (§8.2) is much smaller than feared.

There are **two long rubber foot strips**, front and rear, running nearly the
full width — strips, not pads, which is exactly what the locating rails were
designed around.

## A. Footprint — confirms what is already assumed

| # | Measurement | Feeds | Need | Value |
| - | ----------- | ----- | ---- | ----- |
| A1 | Overall width, left edge to right edge | `length` = 311 | ±2 mm | |
| A2 | Overall depth, front edge to rear edge | `width` = 220 | ±2 mm | |

If these come back more than ~3 mm off, everything downstream shifts, so
they are worth the ten seconds even though we think we know them.

## B. Bottom intake vents — the one that matters most

The fan is centred. The G14 draws through vents toward the **rear** of its
underside, so a centred grille may be blowing at solid plastic. This is open
question §8.2 and the largest single risk in the design.

| # | Measurement | Feeds | Need | Value |
| - | ----------- | ----- | ---- | ----- |
| B1 | Rear edge → **rear** boundary of the vent opening | `fan_offset_y` | ±3 mm | |
| B2 | Rear edge → **front** boundary of the vent opening | `fan_offset_y` | ±3 mm | |
| B3 | Vent opening width, left to right | grille sizing | ±3 mm | |
| B4 | Left edge → left boundary of the vent opening | centring | ±3 mm | |
| B5 | Is it one opening or two separate ones? | grille layout | — | |

If there are two openings, give B1–B4 for each. Two vents astride the
centreline is the normal ASUS pattern and would change the grille from one
circle to something else.

## C. The laptop's own feet — sets what the pad's top plate can do

Feet matter twice: one sitting on the grille blocks part of it, and their
height is the gap the pad's exhaust must cross to reach the vents. You have
already said they cost roughly 20 mm at the front and rear — these numbers
pin that down.

| # | Measurement | Feeds | Need | Value |
| - | ----------- | ----- | ---- | ----- |
| C1 | How many feet, and are they long strips or separate pads? | grille + stop ridges | — | |
| C2 | For each: distance from the rear edge, and from the left edge | clear band | ±2 mm | |
| C3 | For each: length × width, and **height above the case** | standoff gap | ±0.5 mm | |
| C4 | Clear distance between front and rear feet | max fan size | ±2 mm | |

C3's height is the one worth calipers, and it now has a second job. The
pad's locating rails have to stand **taller than the laptop's feet** or the
laptop rests on its own feet and the rails locate nothing. `rail_h` is set
to 5 mm on a guess; C3 is the number that confirms or breaks it.

It also decides whether the exhaust reaches the vents or spills sideways,
and it is small enough that a photo will not resolve it well.

## D. Exhaust vents — recirculation check

The pad draws in through its **left and right walls**. If the G14 blows its
hot exhaust out low on those same sides, the pad will drink its own hot air
and the whole thing is worse than useless.

| # | Measurement | Feeds | Need | Value |
| - | ----------- | ----- | ---- | ----- |
| D1 | Where does the laptop exhaust? Rear, left, right, or a mix | intake wall choice | — | |
| D2 | For any side exhaust: its height above the desk when the laptop sits on the pad | louver band placement | ±3 mm | |
| D3 | Rear edge → the side exhaust vents, front and rear boundary | louver placement | ±5 mm | |

This is not currently an open question in SPEC.md, and it should be. If D1
says the G14 exhausts sideways at the rear, the fix is cheap while the
louvers are still parametric — pull them forward, away from the exhaust —
and expensive after a part exists.

---

## What happens with each answer

| Answers | Result |
| ------- | ------ |
| B1, B2 | `-D fan_offset_y=<n>`, one number, re-render. |
| B3, B5 | Confirms one circular grille is right, or forces a rethink. |
| C1–C3 | Whether the grille needs to dodge a foot; the real standoff gap. |
| C4 | The hard ceiling on fan size — see the fan note in SPEC.md §7. |
| D1–D3 | Whether the side louvers stay where they are. |

None of these block the parts of the design that are settled. They block
committing to a **test print**, which is the expensive mistake.
