# Tunables — global feel

Cross-cutting constants only. Per-entity and per-weapon values live in their own
system file (`enemies.md`, `weapons.md`, `brothers.md`).

All of it is data on a `GameFeel` resource, so the whole game's feel is tweakable
without touching code.

## Movement

| | Value | Note |
|---|---|---|
| `FRICTION` | 0.1 | velocity decays 10%/physics frame |
| `ACCEL` | 0.1 | velocity approaches target 10%/physics frame |
| Brother `max_speed` | 675 | 3× any enemy |
| Enemy `max_speed` | 225 | |
| `extra_resistance` | 0.3 | applies when decelerating, brothers and enemies |

At `ACCEL = 0.1` it takes ~0.7s to reach 99% of top speed. **This is the handling
identity of the game.** A lot of drift for an arcade shooter, and deliberate. Preserved
against a suggestion to raise it.

The **3× speed ratio** is load-bearing: enemies can never catch a moving brother, so
threat is projectiles and ambushes rather than chases. Preserved.

## Camera

| | Value |
|---|---|
| Split threshold | 450 px |
| Seam min thickness | 0 px (at threshold) |
| Seam max thickness | 3 px (at 900 px separation) |
| Zoom | 1.2 |
| Shake — wave announce | 8.0 / 1.0s |
| Shake — brother hit | 4.0 / 0.5s |
| Shake — any player shot | 2.5 / 0.5s |

The **seam thickness ramp** (0 → 3 px) is preserved as-is even though it reads as a bug.
See `preserved-quirks.md`.

## Hit-stop

| | Value |
|---|---|
| `time_scale` | 0.25 |
| Duration | `clamp(max_health / 500, 0.06, 0.20)` real seconds |
| Trigger | killing blow only |

One re-entrant timer. See `combat.md`.

## Waves

| | Value |
|---|---|
| Inter-wave pause | 5s |
| Intro | ~2s |
| Spawn count | `4 × wave_number`, uncapped |
| Spawn offset | ±75 px |
| Enemy drop chance | 50% |

## Respawn

| | Value |
|---|---|
| Circle radius | 64 |
| Revive time | 2.5s |
| Lives | none |

## Items

| | Value |
|---|---|
| Weapon despawn | 5s |
| Medkit despawn | 10s |
| Brother pickup radius | 40 |
| Item bob radius | 32 |
| Medkit heal | 20 |
| Weapon slot limit | none |

## Audio

| | Value |
|---|---|
| Pitch randomization | 0.8 – 1.5, all one-shots |
| Melee extra pitch range | 0.3 |

## Input defaults

Bindings are defaults, not requirements. The action *names* are the contract.

| Action | P1 | P2 |
|---|---|---|
| move / fire / prev weapon / next weapon | arrows + fire button | `WASD` + fire button |
| prev weapon | `,` | `Q` |
| next weapon | `.` | `E` |
| pause | `Escape` | `Escape` |

Gamepad: device 0 = P1, device 1 = P2.

## Values I flagged, and what was decided

| Value | Flag | Decision |
|---|---|---|
| Brother 675 vs enemy 225 | 3× — enemies can never catch you | **Keep.** Load-bearing power fantasy |
| `ACCEL` / `FRICTION` 0.1 | very floaty | **Keep.** Handling identity |
| Imp 10 HP vs gunner 100 HP | 1 vs 4 revolver pellets; a 10× disparity | **Keep** |
| `4 × wave_number`, uncapped | wave 10 = 40 enemies, ⅓ of them gunners | **Keep.** The arcade ramp |
| Gunner re-path every 2s | parked out of range, plinking forever | **Fixed** → 0.5s |
| Minigun 500 ammo @ 0.1s | 1250 damage, five seconds of one-button clearing | **Keep** |
| Medkit heals 20 of 100 | five to full heal; thin health pressure | **Keep** |
| Axe knockback 2000 | ~3× brother top speed; launches you | **Keep.** Melee payoff |
| Seam ramp 0 → 3 px | reads like an inverted lerp | **Keep.** Preserved quirk |
| Hit-stop 0.5× for 2s on every hit | constant half-speed with an automatic weapon | **Fixed** → 0.25× on kills only |

One of ten flagged values changed. The rest are the game.