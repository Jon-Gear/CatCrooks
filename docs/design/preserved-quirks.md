# Preserved quirks

**These are deliberate. Do not fix them.** Each one survived review because it is either
load-bearing for how the game feels, or it is simply what the game looks like. If a
future contributor sees one of these and "corrects" it, the game changes.

---

## 1. Axe recoil is negative (−50)

`recoil = -50` means the axe swing pushes the brother **forward** along his facing
instead of back.

Every other weapon shoves you backwards. The axe pulls you in. It reads as a bug and it
is a bug — the value was probably copied from a base class default of `-50` — but the
result is a melee swing that lunges you into the swing, which is good, and it is
distinctive.

Confirmed kept.

---

## 2. Shotgun pellets are asymmetric (+7.5°, +2.5°, −2.5°)

Three pellets, spread at 5°, fire at **+7.5° / +2.5° / −2.5°** relative to aim — not
centred, and not symmetric around the aim direction. The pattern walks off to one side.

A centred symmetric spread was considered and rejected: the asymmetric pattern is the
shotgun's signature and it makes the weapon feel like it has a lead.

Confirmed kept.

---

## 3. Seam thickness ramps 0 → 3 px

The split-screen divider is **0 px thick at exactly the 450 px threshold**, growing to
3 px at 900 px separation. So the seam is invisible the moment it appears and thickest
when the brothers are furthest apart — the opposite of what you'd design on purpose.

It reads like an inverted lerp. It is kept because the game has always looked like this
and the diagonal is the point (`camera.md`).

Confirmed kept.

---

## 4. Death resolves one state late during a flinch

A brother or enemy that takes lethal damage **during a Pain flinch animation** does not
process the death until the flinch ends.

This is a bug. The original only checked for death inside the Idle / Chase / Attack
physics updates, so a 0.3s flinch delayed the death transition — and the enemy count
decrement rode on the death *animation* method track on top of that.

Why keep it: it is not perceptible. The flinch is 0.3s and the death animation plays
immediately after. Fixing it correctly (checking death at the point of application) is
what the remake does anyway — see `departures.md` — so this quirk is *recorded here as
history* rather than reproduced as a defect.

Confirmed kept, effectively resolved.

---

## 5. Seam side is chosen by comparing `y`, not by true geometry

The seam is perpendicular to the line between the brothers, but **which half each brother
gets is decided by comparing their `y` positions**, not by a true perpendicular bisector.

These disagree when the brothers are nearly level: the `y` rule puts the seam along a
horizontal line, where a true perpendicular would cut diagonally.

Confirmed kept. It is what looked right (`camera.md`).

---

## 6. Cameras are offset by half the separation, not centred

Each camera sits at its brother **± half the separation**, clamped to 450 px. So when the
brothers separate, each camera slides ~225 px *past* its own brother, and the framing
drifts with the gap.

Centring each camera on its own brother was tried and rejected — it changes how the game
plays. Preserved exactly (`camera.md`).

---

## 7. The 10 px camera offset

`camera2`'s position calculation adds **brother 1's** visual-middle offset instead of
brother 2's. A reference-frame bug. Protected by an ADR in the original repo, because
removing it visibly shifts the second view.

Keep.

---

## 8. Brothers are exactly 3× enemy speed

675 vs 225. Enemies cannot catch a moving brother. Not a pursuit game — a shooting game
with melee that punishes standing still.

The temptation will be to close the gap so enemies feel threatening. Don't. The power
fantasy is the point (`tunables.md`).

---

## 9. Movement is very floaty

`ACCEL = 0.1` — 10% of the way to target velocity per physics frame, ~0.7s to top
speed. For an arcade shooter that is an enormous amount of drift.

It is the handling identity. Everything in the game is tuned around this: the recoil
knockback, the enemy speeds, the 0.5s re-path interval. Tightening it would require
retuning all of it.

Preserved.

---

## 10. Health is flat 100; the medkit heals a flat 20

Five medkits to full heal from zero, against a drop weight of 27.8% and four pre-placed
in the level. Health pressure is thin.

A percentage heal was considered and rejected — the flat number is easier to reason about
and the game is not a survival game, it is a shooting game. Preserved.

---

## 11. Imp targets the farthest brother; gunner targets the closest

The melee types ignore the brother standing next to them and charge the far one, which
pulls the pair apart. The ranged type ignores the far one and shoots the near one, which
concentrates pressure.

This looks arbitrary and is not — it is the main tactical texture of the game. Making
targeting consistent across all three types would remove it entirely.

Preserved (`enemies.md`).

---

## 12. The minigun is overpowered

500 rounds, 25 damage, 10 shots/second. Five seconds of one-button clearing, 1250 damage
before it empties.

The 5.6% drop weight keeps it rare. When you get one, waves stop mattering for a few
seconds — and that spike is part of the power fantasy. Preserved with shipped values.

---

## 13. Axe knockback is nearly 3× brother top speed

2000 against 675. The swing launches you across the screen.

This is the melee payoff and it is very satisfying. Preserved.

---

## 14. Flat 100 points per kill, no per-type scoring

Every enemy is worth 100 points. No combo, no headshot bonus, no pickup value.

The wave-clear bonus (100) is the only addition. Beyond that, richer scoring was
considered and declined — the score is a rough measure of how far you got, not a skill
expression. Preserved.

---

## 15. There are no lives

A downed brother revives for free whenever the other is alive, indefinitely. One brother
can carry an entire run while the other is permanently useless.

A revive budget was considered and rejected: it converts the co-op rescue mechanic into
an economy, and the rescue is the reason the mechanic exists. Preserved.

---

## 16. No footstep sound

Running produces visual dust and nothing else. The footstep sound node exists in the
original and is empty.

The dust is the only movement feedback in the game and it works. Do not add footsteps.