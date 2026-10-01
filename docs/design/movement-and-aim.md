# Movement and aim

## The movement model

Velocity is not set directly. Each physics frame, current velocity is interpolated
10% of the way toward a target velocity.

```
FRICTION = 0.1     velocity decays 10% per physics frame
ACCEL    = 0.1     velocity approaches target 10% per physics frame
```

Resulting velocity:

```
actual_velocity = intended_velocity + knockback
```

- `intended_velocity` lerps toward the normalised input direction × `max_speed` at
  `ACCEL`
- `knockback` lerps toward zero at `FRICTION`
- `intended_velocity` lerps toward zero at `FRICTION + extra_resistance` when not
  actively driving (see below)

At `ACCEL = 0.1` it takes roughly **0.7 seconds to reach 99% of top speed**. This is
very floaty by design and it is the game's handling identity — preserve it.

`extra_resistance` (0.3 for brothers) applies only when the brother has released the
stick and is decelerating, so coasting stops faster than accelerating starts.

## Extra resistance detail

The original gated the extra resistance on a boolean (`is_extra_resistance_on`) set by
the state machine. In the remake: apply `extra_resistance` whenever `move_dir` is zero
and there is no active knockback. No state needed — the condition is already in the
input.

## The 3× speed ratio

Brothers move at 675 px/s. Every enemy moves at 225 px/s. Exactly 3×.

**This means an enemy can never catch a moving brother.** No enemy is a chase threat;
threat comes from projectiles, dashes, and ambushes from off-screen. This is load-bearing
for the power fantasy and is preserved deliberately.

## Facing and aim

The weapon aims **where the brother last moved**, snapped to 8 directions. There is no
independent aim input — no aim stick, no mouse aim.

```
move_dir (any angle)
    → snap to 8 directions
        → weapon faces that direction
            → the sprite faces the same direction
```

Snapping is clean 45° increments: moving up-right puts the brother facing up-right at
exactly 45°.

### Departure: flattening thresholds dropped

The original's `vec_to_dir` snapped to 8 directions *and then* zeroed the minor axis
whenever the major-to-minor axis ratio fell outside `0.558 … 1.793`. Shallow diagonals
were therefore flattened to cardinals — holding "up and slightly right" faced you
**straight up**.

That was an artifact of the old implementation, not a designed feel, and it makes
diagonal movement feel mushy. The remake snaps to true 8-way diagonals with no
flattening. See `departures.md`.

### Facing persists

When input goes to zero, the brother keeps his last facing direction. He does not
default to facing right or toward the enemy.

## Recoil is knockback

Every player shot applies **self-knockback along the facing direction, backwards**. Aim
is 8-way snapped from movement, so recoil always pushes along one of 8 axes.

| Weapon | Recoil |
|---|---|
| Revolver | 50 |
| Shotgun | 150 |
| Minigun | 400 |
| Axe | **-50** |

This is the mechanic that makes the minigun hard to hold and long-fire weapons
committing. Preserved with the shipped values.

The **axe** has negative recoil, so the swing pulls the brother *forward* along his
facing. Preserved — see `preserved-quirks.md`.

Recoil and knockback-on-hit are the same underlying field in the original
(`knockback_value` / `recoil`). Keep them separate in the data model for clarity even
though the values ship as-is.

## Enemy movement

Enemies also use the interpolation model, with `max_speed = 225`. They steer via navmesh
paths (`NavigationService`), re-pathing every **0.5s** (departure from the original's 2s —
see `departures.md`), and the Imp additionally applies boids steering (`enemies.md`).