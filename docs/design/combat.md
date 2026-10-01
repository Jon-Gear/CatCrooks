# Combat

All damage in the game resolves in one place.

## Resolution order

1. A bullet collision (or a melee hitbox overlap) is detected by **presentation**.
2. Presentation calls `CombatService.report_hit(attacker, target)`.
3. `CombatService` calls `HitResolver.resolve(attacker, target) -> HitResult`. This is
   pure domain: it computes and returns, it does not apply.
4. `CombatService` applies the result — see below.
5. Presentation, observing the `HitResult`, spawns the hit effect and plays the damage
   sound.

## `HitResult`

```
HitResult:
  damage           float
  knockback        Vector2   direction × magnitude, applied to the target
  died             bool
  hitstop_seconds  float     0 unless this was a killing blow
```

Effects and sounds are presentation's job, driven off the result. Domain never knows
either existed.

## Applying a hit

```
target.health -= damage                       (clamped to [0, max])
target.knockback = (target.pos - attacker.pos).normalized() × knockback
if target.health == 0:
    target → DEATH behaviour
    hitstop_seconds = clamp(target.max_health / 500, 0.06, 0.20)
```

Knockback direction is always **away from the attacker**, for melee and bullets alike.
Bullet knockback uses the bullet's direction rather than the shooter's position.

## Health is domain

`Health(current, max)` lives on the domain entity. `CombatService` is the only writer.
There is no `HealthManager` node — see `architecture.md` and `brothers.md`.

## Death timing

**Death resolves immediately on any damage that zeroes health.**

The original only checked `is_dead()` inside the `Idle` / `Chase` / `Attack` physics
updates, so dying during a 0.3s `Pain` flinch meant the death transition happened one
state later — and the enemy count decrement rode on a death *animation* method track.
Death is now a single check at the point of application. See `departures.md`.

## Hit-stop

On a killing blow only:

| | |
|---|---|
| `Engine.time_scale` | `0.25` |
| Duration | `clamp(enemy_max_health / 500, 0.06, 0.20)` real seconds |

| Enemy | HP | Hit-stop |
|---|---|---|
| Imp | 10 | 0.06s |
| Baller | 50 | 0.10s |
| Gunner | 100 | 0.20s |

The idea is preserved from the original — a big kill should feel heavy. It is scoped
down hard: the original ran `time_scale = 0.5` for **2 real seconds on every enemy hit**,
so wiping a crowd of Imps with a minigun meant permanent half-speed. Now it is
proportional to what you actually killed, and only kills trigger it.

**Re-entrant**: one timer. A new freeze restarts it. The original raced multiple
timers — the first to finish restored `time_scale = 1.0` while others were still
pending.

## Friendly fire

Off. A bullet never damages a brother it was fired by; enemies do not damage other
enemies. This is a filter on attacker/target kind, checked in `CombatService`.

## Hurtboxes and hitboxes

| | Layer | Notes |
|---|---|---|
| Brother hurtbox | player hurtbox | offset (0, -27), above the sprite origin |
| Brother body | player body | capsule radius 5 |
| Enemy hurtbox | enemy hurtbox | per-enemy extents |
| Enemy melee hitbox | enemy hitbox | live only during the attack window |
| Player bullet | projectile | collides with enemy hurtboxes |
| Enemy bullet | projectile | collides with brother hurtboxes |

The original's brother hurtbox had a collision **mask of 0 by design** and relied on
Godot 3's symmetric area detection to work at all — a Godot 4 porting hazard. The remake
uses explicit layers and masks.

## Bullets

| | |
|---|---|
| Max distance | 2000 px |
| Collision shape | capsule, radius 3, height 12 |
| Speed | per weapon (`weapons.md`) |

Bullets die on: hitting a valid target, exceeding 2000px, or hitting a wall tile.

**Walls are normal collision.** The original tested only the tile cell *below* the
bullet, and only for raw tile id `0`, and only while overlapping a wall body — so fast
bullets could pass through walls and diagonal hits registered inconsistently. See
`departures.md`.

Projectiles are parented into a single projectiles container node, which the original
exposed on `Global`. In the remake that container is a scene-local node; presentation
finds it through the scene, not through `GameSession`.