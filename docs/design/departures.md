# Departures from the original

Where the remake **intentionally** differs from the shipped Godot 3.5 build. Every entry
is a bug fix or an implementation correction. Nothing here changes what the game *is*.

The rule that governs this file: if a change alters how the game plays, it belongs in
`preserved-quirks.md` instead. Only three entries below touch balance, and each is
labelled.

---

## Bugs fixed

### 1. Minigun fire rate was silently clamped

The scene declared `shot_delay = 0.01`. At load, a check compared it against the shoot
animation's length and **raised it to 0.1001**, printing an error to the console.

So the minigun fired at 10 shots/second while claiming 100, and the console filled with
errors every time the weapon loaded.

The remake states **`shot_delay = 0.1`** explicitly and has no runtime clamp. The
*resulting rate is identical* — the clamp was the effective value all along.

---

### 2. Baller dash speed was squared

```
dash_direction = direction.normalized() × dash_speed     # 25
apply_dash(dash_direction)
intended_velocity = dash_direction × dash_speed          # 25 × 25 = 625
```

`dash_speed` was applied twice. The result, 625 px/s, felt right.

The remake states **625 px/s** as the design value and documents the bug as a squared
multiplier that happened to land on a good number. A literal fix to `25` would have made
the dash slower than the baller's own 225 px/s walk speed.

**This preserves the feel exactly.** See `enemies.md`.

---

### 3. Baller hitbox outlived its dash

The hitbox was enabled on attack *entry* and disabled on attack *exit* — about 1.4
seconds. The dash itself lasted 0.5 seconds.

So the baller was dangerous for roughly three times as long as it was actually moving,
and you could be hit by an attack that had already finished.

The remake keeps the hitbox live **exactly during the dash**.

---

### 4. Weapon cycling could stack-overflow

`switch_to_next_weapon()` recursed while `ammo <= 0 && item_type != "MELEE"`. If every
slot was an empty range weapon or an empty medkit, it recursed forever and crashed.

The remake uses a **loop with a visited-count**. Same traversal, same skip rules, no
recursion.

---

### 5. Death resolved a state late

Death was only checked inside the Idle / Chase / Attack physics updates, so dying during
a 0.3s Pain flinch delayed the transition by up to 0.3 seconds.

Death is now checked **at the point of application** — `CombatService` compares health
to zero immediately.

---

### 6. Enemy removal was driven by an animation method track

`delete_enemy` was called from an `AnimationPlayer` **method track** on the death
animation. Consequences: the live-enemy count decremented on animation timing rather
than on death, and the next wave's timing depended on animation lengths.

Enemy removal is now **code** — `CombatService` → `WaveService.notify_enemy_died()`.
There are no method tracks anywhere in the remake.

---

### 7. The death screen was unreachable

`DeathScreen.tscn` was built and wired, but the call was commented out in
`base_world.gd`. The round always faded straight back to the menu, so the final score
was recorded and **never shown to the players**.

The death screen is restored. It shows the final score and waves survived.

---

### 8. The UI layer started the first wave

Wave 1 was started by `UILayer._ready()` calling into the world, while every subsequent
wave was started by the world. The equivalent call in the world was commented out.

`GameLoopService` owns all wave starts (`round-loop.md`).

---

### 9. Camera shake only worked by accident

`Shake`'s camera lookup scanned for a node in a group with conditions that could never
assign while both cameras were null. Shake functioned only because the camera rig
explicitly called `set_camera`.

Shake is now owned by the `SplitScreenCamera` module, which registers both cameras
directly. The dead group scan is deleted.

---

### 10. Shake drifted up and right

The per-frame offset was `Vector2(randf(), randf())`. Both components are **0…1** — never
negative — so the camera drifted toward the top-right quadrant and never back.

Now `Vector2(random(-1, 1), random(-1, 1))`, on both axes.

---

### 11. Bullet wall collision was a special case

A bullet tested only the tile cell **directly below** it, only for raw tile id `0`, and
only while overlapping a wall body. Fast bullets could pass through walls, and diagonal
hits registered inconsistently.

Walls are now **normal collision**.

---

### 12. The ammo bar refreshed on every input event

Any input event — including ordinary movement — updated the ammo counter. It refreshed
several times per second while walking.

Now it refreshes on **ammo change and weapon switch only**, via the weapon's
ammo-changed signal.

---

### 13. Health-gate logic was spread across a node and three states

A `HealthManager` node was authoritative for its entity while three state scripts each
checked `is_dead()` separately, and hurtbox enabling lived in the death path.

Health is now a **domain** object, mutated only by `CombatService`, with death checked in
one place. No `HealthManager` node.

---

### 14. The dormant split-screen wrapper

`SplitScreenCamera.gd` was a wrapper whose `current_world_path` was never set — it did
nothing. Collapsed into one module (`camera.md`).

---

### 15. Brother hurtboxes relied on Godot 3's symmetric area detection

The brother hurtbox had a collision **mask of 0** and worked only because Godot 3 area
detection was symmetric. This is a Godot 4 porting hazard, not a design.

Explicit layers and masks throughout.

---

## Balance changes

Three entries, out of ten flagged values. Everything else stayed (`tunables.md`).

### 16. Gunners re-path every 0.5s, not 2s

At 2s, a gunner spent most of its life walking a stale path to a position the brothers
had already left. Combined with a 300 px attack range, they parked outside effective
threat and plinked indefinitely.

0.5s lets them commit to a charge instead of drifting. The navmesh is now required on
every level (`level-authoring.md`), so this is safe.

### 17. Hit-stop: 0.25× on kills only, proportional to HP

The original ran `time_scale = 0.5` for **2 real seconds on every enemy hit**. Shooting
a crowd of Imps with the minigun meant permanent half-speed. Overlapping freezes raced,
and the first timer to finish restored normal speed while others were pending.

Now: `time_scale = 0.25`, **killing blows only**, duration
`clamp(max_health / 500, 0.06, 0.20)` seconds, one re-entrant timer.

A 10 HP Imp gives a 0.06s tick; a 100 HP gunner gives a 0.20s thump. The juice is
proportional to what you earned it on.

### 18. Wave-clear score bonus

Score was a flat 100 per kill and nothing else, so it measured kill speed only. Added
**+100 per wave cleared**, so the score rewards surviving pressure. Flat per-kill
scoring is otherwise unchanged.

---

## Structural departures

Not bug fixes — architecture (`architecture.md`).

- **`Global` autoload replaced by `GameSession`.** Same app-lifetime lifecycle, but it
  holds only `GameState` and services. It may not expose or accept a `Node`. No scene
  node registry, no `get_node`, no "register your scene here".
- **Score and wave state moved off a global singleton onto `GameState`.** Round
  aggregates only, on a plain `RefCounted`, one per app session, reset per round via a
  method rather than by reallocation.
- **Damage resolution centralised.** `HitResolver` (pure domain) returns a `HitResult`;
  `CombatService` applies it; presentation reacts to the result. Effects and sounds
  never reach domain.
- **Enemy behaviour lists replace per-enemy state class hierarchies.** Three enemies went
  from fifteen state classes to three definitions.
- **Input goes through `InputAdapter` → `PlayerIntent`.** No scene script calls
  `Input.is_action_pressed()`.
- **Split-screen is one module.** Viewport pair, cameras, compositor and shake in one
  `SplitScreenCamera` node, replacing shared-`World2D` masking, a `flip_v` `TextureRect`
  composite, a dormant wrapper and a broken shake lookup.
- **Definitions are Resources.** Weapons, enemies, drop tables and wave schedules are
  data, not scripts.

---

## Removed as dead code

Present in the original, no behavioural effect, not carried forward:

- Newgrounds SDK autoload and both score-post calls — **removed entirely**
- `DeathScreen` duplicate, orphaned `.gd.uid` stubs for deleted scripts
- `Stick.tscn` — a complete weapon, in no drop table and no level
- `EnemyBoss.tscn` — no script, no state machine, test textures, never spawns
- `PlayerNPC` — fully implemented, placed in no level
- `max_slot_size = 5` — declared, never enforced. Inventory is unbounded, and the field
  is deleted rather than activated.
- `reparent` input action (R) — bound, never handled
- `frame_freeze` call in the player hit path — commented out
- A dead `all_dead` signal connection to a method that does not exist
- Console print noise on every hit
- Unused `EnemySpawner.imp_counter`
- Dead dash fields on the Imp (`dash_speed`, `dash_duration`, unused `cooldown_duration`)
  and an empty `EnemyImp.attack()`
- Scratch and test scenes (`test folder/`, `test 3D folder/`, `debug levels/`)

## Also dropped

- **Newgrounds score posting.** Removed from scope entirely.
- **The second level.** `Level_1` was broken — no navmesh, a reference to a deleted
  scene, and a case-mismatched script path. Nothing to carry forward; one level ships.