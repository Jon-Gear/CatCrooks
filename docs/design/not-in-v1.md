# Not in v1

Things that exist in the original repo, or are described in its README, and are
deliberately **not** part of this design. Listed so a later reader knows they were
considered rather than missed.

---

## Prototypes that were never in the game

### `EnemyBoss` scene

`src/entities/enemies/EnemyBoss/EnemyBoss.tscn` — no script, no state machine, a Minigun
in a weapon manager, and textures from a test folder. It has never spawned.

A boss is a substantial design problem (phases, arena changes, a health UI) and the game
has no answer for it. Revisit as a feature, not a port.

### `PlayerNPC`

`src/entities/players/npc/PlayerNPC.gd` — fully implemented, with its own state machine,
and placed in no level.

There is no AI-controlled brother in this game. Local co-op is two humans.

### `Stick`

`src/entities/items/weapons/melee/stick/Stick.tscn` — a complete melee weapon with
inherited stats. It is in no drop table and no level, so it is unreachable.

Two melee weapons is already the right amount for the drop table to stay readable.

### `DeathScreen` duplicate scenes and orphan `.uid` stubs

Godot 4 migration artifacts — `.uid` files whose scripts were deleted. No behaviour.

---

## Level 1

Broken, and not carried forward:

- No navigation tiles, so path queries returned straight lines and enemies walked through
  walls
- References `res://deleted enemies/player.tscn`, a scene that no longer exists
- Case-mismatched script paths (`Player.tscn` vs `player.tscn`), which only resolved on
  case-insensitive filesystems

One level ships (`level-authoring.md`).

---

## README ideas — never implemented

The original repo's README describes a set of environment objects and enemy variants
that **do not exist in code at all**. Recorded here as known-unbuilt, not as backlog.

| Idea | Description |
|---|---|
| Booster | A temporary speed or damage buff |
| Heal area | A zone that regenerates health |
| Damage area | A zone that deals damage over time |
| Rage area | A zone that increases aggression or damage |
| Equipment booster / dampener | Modifiers to a brother's handling |
| Enemy variants | Enemy versions of the brothers |
| Explosive enemies | Enemies that detonate on death |
| Adaptive gunner | A gunner that changes behaviour as the wave progresses |
| Adaptive ball | A baller that changes behaviour as the wave progresses |

None of these have tuning, art, or behaviour. If any of them are wanted, they need
design from scratch — this document does not carry them.

---

## Deliberately out of scope

| | |
|---|---|
| **Newgrounds** | Score posting removed entirely (`departures.md`) |
| **Audio assets** | Reused from the original; cue list in `audio.md` |
| **Environment art** | Levels are hand-built; player, enemy and weapon art is reused as-is |
| **Gameplay music** | There is none. Do not add any |
| **A custom level editor** | Plain Godot editor. `editor/` holds documentation and validation only |
| **More levels** | One ships |
| **Difficulty settings** | No options menu exists |
| **Restart from a death screen** | Death screen shows the score and returns to the menu |
| **Mobile / touch** | Keyboard and gamepad only |
| **Online play** | Local co-op only |

---

## Known risks in the port

Godot 3.5 → 4.x conversion hazards, flagged so they are checked rather than discovered:

- **Tile collision.** The original read raw tile ids to decide what blocks bullets. The
  remake uses normal collision (`departures.md` #11), but every wall-adjacent tile in the
  level must be checked for stray collision polygons.
- **Area detection.** Godot 3's symmetric area detection made mask-0 hurtboxes work.
  Godot 4 does not. Explicit masks throughout (`departures.md` #15).
- **`setget` → properties.** Not used anywhere in the remake.
- **Physics interpolation.** The movement model is per-physics-frame interpolation
  (`movement-and-aim.md`). Do not move it to `_process` or add interpolation — the feel
  depends on the frame it runs on.
- **Signal connections.** `hurtbox.area_entered` was connected in code in the original;
  scene-tree connections are used instead.