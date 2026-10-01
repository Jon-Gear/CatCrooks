# UI

Four elements. Per-brother health and ammo float **over the sprite** — that is the
co-op readability, and it is the thing split-screen exists to support.

## Wave board

Top-left, single label, three lines:

```
WAVE:  <n>
POINTS: <n>
LEFT: <n>
```

`WAVE` is the current wave number, `POINTS` the score, `LEFT` the enemies remaining in
the current wave.

Refreshed on: wave announce, enemy death, pickup. Not per-frame.

## Wave banner

Centered, appears on wave announce for the full 5s:

```
WAVE 3
```

This is the one addition to the original UI. The 5-second pre-wave pause is a real
phase (`round-loop.md`), and 5 seconds of nothing happening is dead air without it.

## Health bar

One per brother, floating above the sprite, always visible while alive.

- Shows current / max health
- Gradient tint by health level
- Elastic tween on change
- Twinkle animation

Hides when the brother goes down, reappears on revive.

Per-brother screen offsets differ so the bars don't collide when the brothers overlap:

| | Brother 1 | Brother 2 |
|---|---|---|
| Health bar Y | -75 | -85 |
| Weapon icon Y | +30 | +16 |
| Visual middle Y | -40 | -50 |

Health is read from the domain `Health` object; the HUD observes, it never writes.

## Ammo counter

One per brother, floating near the weapon icon.

- Shows the numeric count
- **Hides at 0 or -1 ammo**

Hides when the brother goes down, reappears on revive.

Refreshes on **ammo change and weapon switch only**. The original refreshed on every
single input event, which meant the counter updated several times per second during
ordinary movement. See `departures.md`.

A bound to the weapon's ammo-changed signal — subscribe on equip, unsubscribe on
unequip. The original disconnected and reconnected this around every weapon switch;
keep the subscription in `WeaponService` so presentation does not manage it.

## Pause

| | |
|---|---|
| Toggle | `Escape` (shared by both brothers) |
| Effect | `get_tree().paused = true` |
| Contents | A "Continue" button |

No separate menu, no options, no restart. One button, unpause.

## Menus

**Title.** Logo sprite, idle animation. **Any key press** fades to the level.

**Death screen.** Shows `final_score` and `waves survived`, then returns to the menu.

The death screen exists in the original but was unreachable — the round always faded
straight back to the menu, so the score was recorded and never shown. It is restored.
See `departures.md`.

## What is not here

No per-brother score, no combo counter, no damage numbers, no minimap, no objective
text, no weapon wheel. None of it existed and none of it is added.