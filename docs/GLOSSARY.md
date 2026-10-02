# Glossary — FelonyFelines domain vocabulary

> The shared understanding of the game's domain: the words the code, the issues,
> and the agents must agree on. New terms join the table below when they become
> load-bearing. The glossary is *behavior-neutral* shorthand; the code is the truth.

Ported from the original project's `CONTEXT.md`. The "home" column now names the
remake's types and layers rather than the original restructure's targets.

## The game in one paragraph

FelonyFelines is a local co-op action game. Two cat brothers ("brothers") face
enemy waves spawned by the world, pick up weapons and medkits, and use a dynamic
split-screen that splits once the brothers get far apart (with a deliberate 10 px
camera-offset quirk preserved). Points accumulate per wave; the round ends when
both brothers are down.

## Canonical terms

| Term | Definition | Original references | Home in the remake |
|---|---|---|---|
| **brother** | One of the two playable cats. Brother 1 (red) and brother 2 (blue). They are identical except for colour and input device. Not to be confused with `PlayerNPC`. | `Global.brother_1` / `Global.brother_2`, `HealthManager`, `Respawn` radius, `base_world.all_players_dead()` | **Domain:** a domain entity carrying `Health`. **Application:** `RespawnService`. **Presentation:** the brother scene node |
| **wave** | A round of enemies. The wave number starts at 1; wave *N* spawns `4 × N` enemies, uncapped. | `Global.wave_num`, `Global.enemy_count`, `Global.points`, `base_world.update_wave()`, `UILayer.update_board()` | **Domain:** `GameState.wave_number` / `.points` / `.wave_survived`; `WaveSchedule`. **Application:** `WaveService`, `GameLoopService` |
| **drop** | An item a killed enemy can leave, rolled by weight. Drop weights live in one table and drive a weighted pick on enemy death. | `Global.ITEM_DROP_WEIGHTS`, `GeneralStates/Death.gd`, `ItemPickup` | **Domain:** `DropTable` (pure, with normalization). **Application:** `LootService` |
| **split-screen** | The dynamic two-viewport camera rig. Reads each brother's position, visual offset, and alive state; splits once separation exceeds 450 px; falls back to one view when a brother is down. Preserves the intentional 10 px camera-offset quirk — see [ADR-0003](adr/0003-split-screen-10px-quirk.md). | `camera_controller.gd`, `SplitScreenCamera.gd` (dormant wrapper), `split_screen_2d.gdshader`, `Shake` | **Application:** `CameraService`. **Infrastructure:** `CameraFxAdapter`. **Presentation:** one `SplitScreenCamera` module — [ADR-0004](adr/0004-single-split-screen-seam.md) |
| **fire** | The gunplay mechanic: a firing rate, bullet count, speed, and spread. Weapons *fire* bullets; the same machinery covers brother and enemy weapons. | `BulletSpawner`, `BulletEmitterSingle`, `BulletEmitterSpread`, `BaseRangeWeapon` | **Domain:** fire config on `WeaponDefinition` (spread and count as data). **Application:** `WeaponService` |
| **world** | A level scene: the container holding entity buckets (brothers, enemies, projectiles, items, spawners) and the navigation. | `base_world.gd`, `LaunchScene.tscn`, `NavigationTileMap.tscn` | **Presentation:** scene controllers and entity buckets, local to the level scene. `GameSession` holds **no** scene node |
| **round / all down** | End condition. Both brothers are down at once; the death screen shows final score and waves survived. | `Global.player_died()`, `base_world.all_players_dead()`, `Menu` / `DeathScreen` | **Application:** `GameLoopService` phases, `ScoreService`. **Domain:** `GameState.alive_brothers` |
| **down / revive** | A brother that takes lethal damage goes **down** instead of dying outright; the respawn radius governs revival, and reviving restores full health. "Down", never "dead". | `HealthManager`, `player.respawn_player()`, `Respawn` component | **Domain:** `Health.is_empty()`. **Application:** `CombatService` applies damage, `RespawnService` owns down / revive. **No `HealthManager` node** — [ADR-0002](adr/0002-healthmanager-authoritative.md) is superseded |
| **ammo** | Per-weapon magazine count. Finite ammo. | `WeaponManager`, `Ammo_Bar`, `ammo_changed` | **Domain:** `AmmoState` (current, max, pack). **Application:** `WeaponService` |
| **definition** | The data `Resource` behind a gameplay concept: a stable id, a display name, and the numbers the services read. Weapons, enemies, items, drop tables and wave schedules are definitions, not scripts. | none — a remake concept | **Domain:** `ItemDefinition`, `WeaponDefinition`, `EnemyDefinition`, `DropTable`, `WaveSchedule` |

## Anti-terms

| Don't say | Because |
|---|---|
| "player" (as a *role* in issues) | There are *players* and there was a `PlayerNPC` AI actor; "brother" names the playable pair. The original's `Global` called every node under `players` a "player". Prefer **brother** for the red/blue pair — but "player 1" / "player 2" stay correct for the *input device* mapping, which is what `design/brothers.md` means by it. |
| "dead" (for a downed brother) | A brother at zero health is **down**, and can still be revived. Only an enemy is dead. |
| "health manager" | Retired — see the **down / revive** row above and [ADR-0002](adr/0002-healthmanager-authoritative.md), which is superseded. |
| "splitscreen" vs "split screen" | The canonical term is **split-screen** (hyphenated), and the module node is `SplitScreenCamera`. |
| "global" / `Global` | The original's autoload god-object. It is `GameSession` now, and it holds only `GameState` plus services — never a `Node`. |

## Where domain knowledge lives

- `docs/GLOSSARY.md` (this file) — the glossary of load-bearing terms.
- `docs/adr/` — recorded decisions that close off alternatives.
- `docs/CONVENTIONS.md` — per-layer naming and layout rules that encode the domain
  vocabulary into new code.
- `docs/design/` — the system specs each file describes.
- The code itself — the source of truth for *how* the game behaves today.