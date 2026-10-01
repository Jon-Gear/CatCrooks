# Level authoring

Plain Godot 4 editor. No custom level editor. You make the map.

## What you place

### Tiles

Four tile layers in the original. Keep the separation of concerns:

| Layer | Purpose |
|---|---|
| Ground | Floor |
| Path | Walkable variation, decorative |
| GroundYellow | Decorative variation |
| Plants | Decorative, non-colliding |
| **Walls** | **Blocking.** Solid for movement, blocks bullets |
| **Navigation** | **Navmesh source.** Invisible |

Walls block both movement and bullets. The navmesh must cover every walkable cell — see
the checklist below.

### Prefabs

| Object | Count | Notes |
|---|---|---|
| `EnemySpawner` | **4** | One per level. Emits `wave_number` enemies per wave |
| `ItemPickup` (pre-placed) | as listed below | Starting loadout |

### Starting items

The shipped level opens with:

| Item | Count |
|---|---|
| Revolver | 2 |
| Axe | 2 |
| Minigun | 1 |
| Medkit | 4 |

This is a **balance fact, not decoration**. It decides whether wave 1 (4 Imps) is
survivable, and it determines the early ammo economy. Preserve it exactly.

## Navmesh is required

There is always a navmesh. Paint the `Navigation` tile layer to cover every walkable
cell, then bake the `NavigationPolygon` in the Godot editor.

A missing nav region is a level authoring error, not a runtime state.

This is worth stating because the original had a level with **no navmesh at all** — its
path queries returned straight lines, so enemies walked through walls. There is no
`Level_1` in the remake; one broken level taught nothing worth carrying forward.

Enemies re-path every 0.5s (`enemies.md`).

## Spawners

| | |
|---|---|
| Count per level | 4 |
| Selection | Uniform random from {Imp, Gunner, Baller} |
| Offset | Uniform inside ±75 px around the spawner point |
| Emission | `wave_number` enemies, all at wave start |

Place them spread across the map — near corners and behind cover — so the brothers have
to rotate rather than hold one chokepoint. The ±75px offset means spawns never stack
exactly.

## The checklist

Before a level ships:

- [ ] Every walkable cell is covered by the `Navigation` tile layer
- [ ] The `NavigationPolygon` is baked
- [ ] `Walls` tiles block movement
- [ ] `Walls` tiles block bullets
- [ ] Bullets are despawned by wall collision, not by a special-case tile test
- [ ] Exactly 4 `EnemySpawner` instances, spread out
- [ ] Pre-placed starting items match the list above
- [ ] Both brother spawn points are clear of walls and away from spawners
- [ ] Spawners are not inside walls
- [ ] The arena is open enough that the brothers can separate past 450 px — otherwise
      split-screen never engages

That last one matters: the split-screen threshold is 450 px, so a cramped arena means the
signature camera never triggers.

## Brother spawns

Two spawn points, one per brother, clear of hazards. The original placed them with
per-brother HUD offsets so their health bars and ammo counters don't collide when they
overlap:

| | Brother 1 | Brother 2 |
|---|---|---|
| Visual middle Y | -40 | -50 |

Preserve those offsets (`brothers.md`, `ui.md`).

## Scope

One level ships. The original's `Level_2` is the playable one; `Level_1` was broken and
is not carried forward.

The levels are hand-built and hand-placed. There is no procedural generation, no
level editor tool, and no level format to design — the editor scene *is* the level.