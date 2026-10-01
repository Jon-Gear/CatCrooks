# Felony Felines — Design Document

A spec for rebuilding Felony Felines in a **clean Godot 4 project**. The game is a
2D top-down local co-op arcade shooter: two brothers fight endless waves of enemies,
picking up weapons and medkits between fights.

This document describes the game as it **should be built**. Gameplay is a faithful
reproduction of the original 2021-era build (Godot 3.5), with a small, deliberate
set of corrections to bugs and implementation mistakes. Everything else —
including a handful of odd-looking numbers — is preserved on purpose and listed in
`preserved-quirks.md`.

## The core loop

1. Two brothers spawn in a walled arena. Red is player 1, blue is player 2.
2. A wave of enemies spawns from four spawner points.
3. The brothers shoot the wave down. Enemies drop weapons and medkits when killed.
4. When the last enemy dies, a 5-second pause, then the next wave — bigger.
5. A brother who takes lethal damage goes **down** instead of dying. The other brother
   can revive him within 2.5 seconds, restoring full health. If both are down at the
   same moment, the round ends.
6. Score accumulates. The round ends only when both brothers are down simultaneously.

The loop is a survival ramp: wave *N* spawns `4 × N` enemies, uncapped.

## Round loop state chart

The game is a loop of explicit phases. `GameLoopService` owns this and nothing else
starts a wave.

| Phase | Entry action | Exit condition | Duration |
|---|---|---|---|
| `INTRO` | World ready. Camera rig armed. | Intro animation completes | ~2s |
| `WAVE_ANNOUNCE` | Wave counter increments. Banner shows "WAVE *N*". Screen shake (8.0, 1.0s). | Banner timer expires | 5s |
| `WAVE_ACTIVE` | Spawners emit `wave_num` enemies each. | All spawned enemies dead **and** live count reaches 0 | until cleared |
| `WAVE_CLEARED` | Score adds wave-clear bonus. HUD refreshes. | Immediately | 0s |
| `GAME_OVER` | Both brothers down. Lose track plays. Death screen shows final score and waves survived. | Player returns to menu | ~5s |

`WAVE_CLEARED` → `WAVE_ANNOUNCE` for the next wave. `WAVE_ACTIVE` → `GAME_OVER` if
both brothers go down. Only `GameLoopService` drives transitions — in the original, the
UI layer started wave 1 and an enemy's death *animation* triggered the next wave, which
is why both are now explicit.

## Systems

| File | Covers |
|---|---|
| [`architecture.md`](architecture.md) | Layering, `GameSession`, services, data. **Read first.** |
| [`round-loop.md`](round-loop.md) | Phases above, wave pacing, game over |
| [`brothers.md`](brothers.md) | The two playable cats, health, going down, reviving |
| [`movement-and-aim.md`](movement-and-aim.md) | Movement model, 8-way facing, recoil knockback |
| [`combat.md`](combat.md) | Damage, knockback, hit-stop, hurtboxes, resolution order |
| [`weapons.md`](weapons.md) | Revolver, shotgun, minigun, axe, firing, ammo |
| [`items-and-drops.md`](items-and-drops.md) | Loot table, ground items, pickup rules, merging |
| [`enemies.md`](enemies.md) | Imp, gunner, baller, AI personalities, targeting |
| [`waves.md`](waves.md) | Wave counts, spawners, scaling |
| [`camera.md`](camera.md) | Split-screen rig, diagonal seam, shake |
| [`ui.md`](ui.md) | Wave board, health bars, ammo counter, pause |
| [`audio.md`](audio.md) | Every sound cue and when it fires |
| [`tunables.md`](tunables.md) | Global feel constants, cross-cutting |
| [`level-authoring.md`](level-authoring.md) | Tiles, navmesh, spawners, starting items |
| [`preserved-quirks.md`](preserved-quirks.md) | **Deliberate.** Do not "fix" these. |
| [`departures.md`](departures.md) | Where the remake intentionally differs |
| [`not-in-v1.md`](not-in-v1.md) | Prototypes and unimplemented ideas, with reasons |

Each file is self-contained. Tuning tables live **inline in the system they belong to**,
so a single file is the complete source for its system. The only exception is
`tunables.md`, which holds values that genuinely cut across systems.

## Conventions used throughout

- **Brother** — one of the two playable cats. Never "player"; the original also has a
  `PlayerNPC` actor that is not a brother.
- **Wave** — a round of enemies. Wave number starts at 1.
- **Down** — a brother at zero health who can still be revived. Not "dead".
- **Hit-stop** — the global brief slow-motion on a killing blow.
- Godot 4 idioms throughout. No `setget`, no `KinematicBody2D`, no `Navigation2D`.
- Numbers quoted without a source are **the values to implement**.