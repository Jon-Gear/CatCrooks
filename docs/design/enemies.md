# Enemies

Three enemy types. Every one is defined by a behaviour list (`architecture.md`), not a
state class hierarchy.

## Shared

| | |
|---|---|
| Base speed | 225 px/s |
| Drop chance | 50%, common table |
| Extra resistance | 0.3 |
| Health bar | floating, follows the sprite |

**Every enemy is exactly 1/3 the brothers' speed.** A brother at full speed cannot be
caught by anything. Threat is projectiles, dashes, and being caught while standing still.

Each enemy definition carries a `TargetingRule` — `CLOSEST` or `FARTHEST`. This is data,
not per-enemy branching logic.

## The targeting split

This is deliberate and the single most important AI decision in the game:

| Enemy | Targets | Why |
|---|---|---|
| Imp | **farthest** living brother | melee; splits the pair up |
| Baller | **farthest** living brother | melee; dashes into the gap |
| Gunner | **closest** living brother | ranged; focuses pressure |

The two melee types ignore the brother standing next to them and go for the far one,
which pulls the brothers apart. The ranged type ignores the far one and shoots whoever is
nearer. Together they apply pressure from both ends. Do not "fix" this into consistency.

Dead brothers are skipped by targeting.

## Behaviour list

All three enemies share the same shape:

```
IDLE → SEEK → ATTACK → SEEK …
              ↓
            PAIN (interrupt, returns to SEEK)
              ↓
            DEATH (terminal)
```

Baller replaces `SEEK` with `SEEK` plus a heavier attack. Imp replaces `SEEK` with
`FLOCK`.

### Imp

| | |
|---|---|
| Health | 10 |
| Speed | 225 |
| Damage | 10 |
| Knockback | 20 |
| Attack range | 32.14 px |
| Hurtbox extents | (15.5, 23) |
| Hitbox extents | (10.2, 6.7) |
| Attack cooldown | 1.0s |
| Nav threshold | 4 |

Flocking (boids) toward the **closest** brother, while the targeting rule aggro's toward
the **farthest**:

| Weight | Value |
|---|---|
| Cohesion | 0.1 |
| Alignment | 0.25 |
| Separation | 0.45 |
| Seek | 0.25 |

Separation dominates, so a pack of Imps spreads out rather than stacking into one blob.
The lowest cohesion weight means they do not tightly ball up.

Attack: aims at the target, 0.6s animation, **hitbox live from 0.2s to 0.5s**. 1s
cooldown.

Ten health means one revolver pellet kills an Imp, while a gunner takes four. See
`tunables.md`.

The original had dead dash fields on this enemy (`dash_speed = 30`, `dash_duration = 3`,
`cooldown_duration = 5` in the script, overridden to 1 in the scene, with an empty
`attack()`). None of it fires. The remake has none of it.

### Gunner

| | |
|---|---|
| Health | 100 |
| Speed | 225 |
| Damage | 5 per bullet |
| Knockback | 1000 |
| Attack range | 300 px |
| Hurtbox extents | (45, 61) |
| No hitbox | melee-ranged hybrid: no contact damage |
| Emitter | spread, 3 pellets |
| Spread angle | 5° |
| `shot_delay` | 1.0s |
| Bullet speed | 225 |
| Nav threshold | 4 |

Starts in `SEEK` — it has no idle phase.

**Aim** raycasts 5 points around the target's hurtbox, inset by 5px, then faces the
target's handgun at it and fires continuously. The aim check is generous by design: it
only fires when it has a clear line.

While attacking, the gunner plays its **idle** animation. It does not have a firing
animation.

A 100-HP gunner with 300px range firing continuously is a wall, and it is the reason
waves get hard. Four revolver pellets to kill.

**Re-path interval: 0.5s** (the original used 2s, at which gunners spent most of their
life walking a stale path to a position the brothers had left). See `departures.md`.

### Baller

| | |
|---|---|
| Health | 50 |
| Speed | 225 |
| Damage | 10 |
| Knockback | 2500 |
| Attack range | 300 px |
| Hurtbox extents | (35.5, 46) |
| Hitbox | circle, radius 35 |
| Attack cooldown | 2.0s |
| Dash speed | **625 px/s** |
| Dash duration | 0.5s |
| Attack animation | 1.4s |

Attack: 2s cooldown, aims, then within a 1.4s animation starts the dash at 0.2s and ends
it at 1.1s. The dash is 625 px/s — nearly 3× the baller's own base speed and comparable to
a brother's 675 — and it closes a 300px gap fast.

The hitbox is live exactly during the dash (0.2s → 1.1s). In the original the hitbox was
enabled on attack *entry* and disabled on attack *exit* (~1.4s+), so it stayed dangerous
for about three times as long as the dash actually moved. See `departures.md`.

**The 625 figure is the design value.** The original's `dash_speed` was `25`, applied
twice — once as a normalized direction and once as a multiplier — producing 25 × 25 = 625.
A literal "fix" to the declared value would have made the dash slower than the baller's
own walking speed. The remake states 625 explicitly and records the bug as a squared
multiplier that happened to land on a good number. See `departures.md`.

## Navigation

Enemies path on a navmesh. There is always one — a missing nav region is a level
authoring error, not a runtime state (`level-authoring.md`).

`NavigationService` provides path requests. Enemies re-path every **0.5s**.

## Kill handling

On death, in order:

1. `ScoreService` adds 100 points (`round-loop.md`)
2. `LootService` rolls the drop table (`items-and-drops.md`)
3. `WaveService.notify_enemy_died()` decrements the live count
4. If the count reaches 0, the wave is cleared (`round-loop.md`)
5. Hit-stop if this was a killing blow (`combat.md`)
6. A `+100` point-effect floats at the corpse position
7. The entity is removed

All of this is code. In the original, step 3 was an `AnimationPlayer` method track on the
death animation. See `departures.md`.

## Not shipped

An `EnemyBoss` scene exists in the original with no script, no state machine, and test
textures. It never spawns. See `not-in-v1.md`.