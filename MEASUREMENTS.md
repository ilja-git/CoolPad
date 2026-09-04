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
