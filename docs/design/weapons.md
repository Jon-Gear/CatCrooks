# Weapons

Four weapons ship: three range, one melee. A fifth (`Stick`) exists in the original but
is unreachable — see `not-in-v1.md`.

All behaviour comes from two bases in the original (`BaseRangeWeapon`, `BaseMeleeWeapon`)
with no per-weapon scripts; every value is data. Keep it that way: a weapon is a
`WeaponDefinition` resource, not a script.

## Firing

A `BulletSpawner`-equivalent lives on each weapon:

| | |
|---|---|
| `shot_delay` | seconds between shots |
| `bullet_speed` | px/s |
| emitter | single or spread |

`shot_fired` is emitted per shot. `set_shooting(true)` fires immediately, then
continues on the interval; `set_shooting(false)` stops.

**Firing is automatic while the fire input is held.** There is no per-shot click
requirement for range weapons.

On every shot:

1. Play the shoot animation
2. Apply self-knockback: `-movement_direction × recoil` (`movement-and-aim.md`)
3. Consume one ammo
4. If ammo is now 0, stop firing
5. Play the shot sound
6. `CameraService.request_shake(2.5, 0.5)`

## Range weapons

### Revolver

| | |
|---|---|
| Ammo | 18 |
| Ammo per pack | 6 |
| `shot_delay` | 0.25s (4 shots/s) |
| Bullet speed | 600 |
| Damage | 25 |
| Knockback | 500 |
| Recoil | 50 |
| Emitter | single |
| Spread | ±1° |

The starting weapon, and the most common drop (27.8%).

### Shotgun

| | |
|---|---|
| Ammo | 20 |
| Ammo per pack | 10 |
| `shot_delay` | 1.0s |
| Bullet speed | 1200 |
| Damage | 25 per pellet |
| Knockback | 1000 |
| Recoil | 150 |
| Emitter | spread, 3 pellets |
| Spread angle | 5° |
| Recoil (scene override) | 150 |

3 pellets × 25 = up to 75 damage in one shot. Hits an Imp (10 HP) with two pellets to
spare.

Pellets fire at **+7.5°, +2.5°, −2.5°** — not centred, not symmetric. Preserved; see
`preserved-quirks.md`.

### Minigun

| | |
|---|---|
| Ammo | 500 |
| Ammo per pack | 100 |
| `shot_delay` | **0.1s** (10 shots/s) |
| Bullet speed | 800 |
| Damage | 25 |
| Knockback | 1500 |
| Recoil | 400 |
| Emitter | single |
| Spread | ±10° |

500 rounds × 25 damage at 10 shots/s = five seconds of one-button clearing, 1250 damage
before it runs dry. The 5.6% drop weight keeps it rare; when you get one, waves stop
mattering for a few seconds. Preserved with shipped values — see `tunables.md`.

**`shot_delay` is 0.1s and that is the design value.** In the original the scene value
was `0.01` and a runtime check silently raised it to `0.1001` because it was shorter
than the shoot animation, printing an error to the console. The remake states 0.1s
explicitly and has no such clamp. See `departures.md`.

### Melee: Axe

| | |
|---|---|
| Damage | 20 |
| Knockback | 2000 |
| Recoil | **-50** |

**No ammo.** Melee weapons never run out and are never skipped by weapon cycling.

The axe swings on the fire input and applies self-knockback of **-50**, which pushes the
brother *forward* along his facing instead of back. Preserved.

Axe knockback (2000) is nearly 3× a brother's top speed (675) — the swing launches you.
Preserved; absurd knockback is the melee payoff.

## Ammo

- Ammo is **finite** for range weapons and the medkit.
- The ammo counter hides at 0 or -1.
- Firing the last round **auto-switches** to the next weapon that has ammo and is not
  melee.
- Weapon cycling **skips** empty range weapons and empty medkits.
- Ammo does **not** regenerate between waves. Only drops and revives restore it.

Cycling is a **loop with a visited-count**, not recursion. The original recursed while
`ammo <= 0 && item_type != "MELEE"`, which stack-overflowed when every slot was empty.
See `departures.md`.

## Slots

**There is no slot limit.** The original declared `max_slot_size = 5` and never enforced
it; the field is deleted in the remake and inventory size is unbounded.

Picking up a weapon you already hold **merges** into the held weapon rather than taking
a new slot — see `items-and-drops.md`.

## Per-weapon input handling

| Input | Range | Melee |
|---|---|---|
| press | start firing | swing once |
| hold | continuous fire | — |
| release | stop firing | — |

The original refreshed the ammo bar on *every* input event. The remake refreshes on ammo
change and weapon switch only. See `departures.md`.