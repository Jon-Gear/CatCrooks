# Architecture

The original game's structural problems caused most of its bugs. This document
prescribes the remake's boundaries. The behaviour described in the other files is the
spec; this file describes where that behaviour lives.

## Layers

Five layers. `Domain ← Application ← Presentation` is a strict one-way dependency:
domain knows nothing about application, application knows nothing about presentation.

### `domain/` — pure data and rules

`Resource` and `RefCounted` only. **No `extends Node`. No `get_node`. No scene
lookups. No `Input`, no `AudioServer`, no `DisplayServer`.** This is the one
load-bearing rule of the whole architecture: it is what makes the layers real instead
of aspirational, and it is what makes the game logic testable without booting a scene.

Types:

| Type | Holds |
|---|---|
| `ItemDefinition` | id, display name, kind (range / melee / medkit), despawn time |
| `WeaponDefinition` | fire config, damage, knockback, recoil, ammo, spread params |
| `EnemyDefinition` | health, speed, behaviour list, targeting rule, nav params |
| `DropTable` | id → weight map, with weighted pick and normalization |
| `WaveSchedule` | enemies-per-wave formula, inter-wave delay |
| `DamageSpec` | damage value, knockback value |
| `AmmoState` | current, max, pack amount |
| `Health` | current, max, `is_empty()` |
| `HitResult` | damage, knockback vector, died, hit-stop duration |
| `GameFeel` | cross-cutting constants (see `tunables.md`) |

`HitResolver` lives here: `resolve(attacker, target) -> HitResult`. Pure — it computes
and returns, it does not apply.

### `application/` — the services that decide

Orchestrates domain objects. Holds no Node references either.

| Service | Decides |
|---|---|
| `GameLoopService` | Round phases and transitions (`round-loop.md`) |
| `WaveService` | Wave numbers, spawning, alive counts (`waves.md`) |
| `CombatService` | Applies `HitResult`s, hit-stop, kill handling (`combat.md`) |
| `LootService` | Drop rolls, pickup, weapon merging (`items-and-drops.md`) |
| `RespawnService` | Down / revive rules (`brothers.md`) |
| `WeaponService` | Slots, cycling, firing requests (`weapons.md`) |
| `ScoreService` | Points, wave bonus, final score |
| `NavigationService` | Navmesh queries, path requests (`enemies.md`) |
| `CameraService` | Split-screen facts, shake requests (`camera.md`) |

Anything platform-shaped is reached through a **port** (an interface the application
declares, infrastructure implements) rather than directly.

### `presentation/` — everything Godot-the-scene

Player, enemy and item scenes and their scripts. HUD, split-screen rig, menus.

Presentation **reads** application state and **asks** services for decisions. It never
writes domain data directly: a scene does not set `weapon.ammo = 0`, it calls
`WeaponService.consume_ammo(...)`.

### `infrastructure/` — the platform adapters

The only layer permitted to touch engine platform APIs.

| Adapter | Does |
|---|---|
| `InputAdapter` | `Input` → per-frame `PlayerIntent` (`movement-and-aim.md`) |
| `AudioAdapter` | Cues → buses, pitch randomization (`audio.md`) |
| `CameraFxAdapter` | Split-screen rig, shake (`camera.md`) |
| `SceneChanger` | Fades, scene transitions |

### `editor/` — authoring support

Plain Godot editor. The level author paints tiles and places prefabs by hand
(`level-authoring.md`). This layer holds only documentation of placeable object types
and their properties, plus optional validation tooling. **No custom level editor.**

## `GameSession` — the app-lifetime session

An **autoload**. Same lifecycle as the original's `Global`, but it is not `Global`.

`GameSession` holds two things and nothing else:

- **`GameState`** — the round aggregate data
- **`services`** — the service instances, reachable as `GameSession.services.combat`,
  `GameSession.services.waves`, and so on

**The hard rule: `GameSession` may not expose or accept a `Node`.** No `entity_world`,
no `players`, no `misc`, no `get_node`, no "register your scene here". Presentation
nodes register themselves with the scene, never with the session.

If any `GameSession` member needs to be a `Node`, that is a signal the logic lives in
the wrong layer. This single rule is what prevents the remake from growing a god-object
the way `Global` did.

### `GameState`

A plain mutable `RefCounted`. **One per app session**, not one per round — a round
reset is the method `reset_round()`, so every service holding a reference stays valid
across rounds.

Holds round aggregates only:

```
wave_number      int      starts at 0, first wave is 1
points           int
wave_survived    int
final_score      int
alive_brothers   int      2 → 0
```

Per-entity data is **not** here. A brother's health, a weapon's ammo, an enemy's
position — those live on the domain entity objects that services own. `GameState` is
the scoreboard, not the model.

## Two structural rules that fix whole bug classes

### Enemy removal is code, never animation

The original called `delete_enemy` from an `AnimationPlayer` **method track** on the
death animation. Timing depended on an animation's length, so death resolved late and
the next wave's timing depended on animation data.

In the remake, death is: `CombatService` → `EnemyDefinition.behaviours` → `DEATH`
behavior → `WaveService.notify_enemy_died()`. No method tracks anywhere in the codebase.

### Behaviour lists, not state class hierarchies

The original had a `State` subclass per entity per state — `IdleImp`, `ChaseImp`,
`AttackImp`, `Pain`, `Death`, plus parallel copies for gunner and baller. Three enemies,
five identical state shapes, fifteen classes.

In the remake an enemy definition declares an ordered **list of behaviours**. Each
behaviour has a kind, entry/exit conditions, and per-behaviour parameters. One generic
runner drives the list. Imp, gunner and baller are three small definitions, not three
codebases.

Behaviour kinds used by this game:

| Kind | Purpose |
|---|---|
| `IDLE` | Wait, or transition on a condition |
| `SEEK` | Move along a navmesh path to a target |
| `FLOCK` | Boids steering toward a target |
| `RANGED_ATTACK` | Aim, then fire on an interval |
| `MELEE_ATTACK` | Telegraph, activate hitbox, recover |
| `DASH_ATTACK` | Telegraph, dash with a hitbox, recover |
| `PAIN` | Interrupt; flinch; return to previous |
| `DEATH` | Terminal; award score; roll drop |

Transitions are conditions on the behaviour list: `on: sibling_down`, `on: cooldown_elapsed`,
`on: timer_elapsed(0.6)`, `on: health_is_zero`. Targeting is data — a
`TargetingRule` (`CLOSEST` / `FARTHEST`) on the definition, not branching logic per enemy.

## Dependency example

An enemy getting shot is exactly this, and nothing else:

1. A bullet's collision reaches a target. Presentation detects it and calls
   `GameSession.services.combat.report_hit(attacker, target)`.
2. `CombatService` calls `HitResolver.resolve(attacker, target)` — pure domain, returns
   a `HitResult`.
3. `CombatService` applies the result: subtracts health via the target's `Health`,
   sets its knockback, requests hit-stop, and if health hit zero advances the
   behaviour list to `DEATH`.
4. Presentation, observing the `HitResult`, spawns the hit effect and plays the sound.

Effects and sounds are **presentation's** job, driven off the result. Domain never
knows either existed.

## Testing surface

Because domain and application hold no Nodes, this is testable without a scene:
`DropTable` weighted picks and normalization, `HitResolver` damage and knockback
vectors, wave count formulas, ammo cycling, `GameState` transitions, `EnemyDefinition`
behaviour transitions. The original had a GUT harness with two unit tests; this should
be a real suite covering the domain and application layers.