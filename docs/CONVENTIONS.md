# Naming and layout conventions

> The codebase is organized into **five layers** — Domain, Application, Infrastructure,
> Presentation, Editor. This document fixes the layout and the per-layer naming
> conventions. It is the naming contract every script must follow.

Status: **accepted** · companion to `docs/design/architecture.md`,
`docs/GLOSSARY.md`, and [ADR-0001](adr/0001-one-way-dependency-rule.md).

Ported from the original project's conventions doc, re-pointed at the remake's
architecture. Two things changed materially in the port: the layers no longer live
under a `src/` parent, and the original's `resources/` configuration tree and
`AppConfig` / `Catalog` vocabulary are gone — see §4.

---

## 0. Superseded decisions

[ADR-0002](adr/0002-healthmanager-authoritative.md) (`HealthManager` stays authoritative
for its entity) is **superseded and must not be implemented.** It was a migration
decision, scoped to restructuring the original project. The remake has no migration:
health is the domain object `Health(current, max)`, `CombatService` is its only writer,
and there is no `HealthManager` node. The reasoning is in
`docs/design/combat.md` ("Health is domain") and the layer table in
`docs/design/architecture.md`.

A node that holds its own copy of health is therefore a bug, not a migration step. The
one-line rule: **one fact, one owner.** A brother's health lives in `Health`; a weapon's
ammo lives in `AmmoState`; the round's score lives in `GameState`. Presentation reads
these and asks a service to change them — it never keeps a second copy.

## 1. The layout

```
project.godot
docs/
  GLOSSARY.md      ← domain glossary (brother, wave, drop, split-screen, fire, …)
  CONVENTIONS.md   ← this file
  TESTING.md       ← test framework and the assert-behavior convention
  adr/             ← recorded architecture decisions (ADR-xxxx-*.md)
  design/          ← the system specs
domain/            ← game data concepts, facts, configuration vocabulary
application/       ← gameplay rules (services over GameState)
infrastructure/    ← adapters around external systems (audio, camera FX, input, save)
presentation/      ← scenes, nodes, UI, input, entities (Godot glue)
editor/            ← authoring / debug tooling
assets/            ← shipped art and audio
sounds/            ← shipped sound effects, grouped by audio-spec cue category
```

| Layer | Folder | Responsibility | What goes here |
|---|---|---|---|
| **Domain** | `domain/` | Game data concepts | `GameState` + sub-states, definitions (`Resource` scripts), `Health`, `AmmoState`, `HitResolver`, `HitResult`, enums |
| **Application** | `application/` | Gameplay rules | `RefCounted` services (`GameLoopService`, `WaveService`, `CombatService`, `LootService`, `RespawnService`, `WeaponService`, `ScoreService`, `NavigationService`, `CameraService`), and the **ports** the infrastructure layer implements |
| **Infrastructure** | `infrastructure/` | External-system adapters | `AudioAdapter`, `CameraFxAdapter`, `InputAdapter`, `SceneChanger` |
| **Presentation** | `presentation/` | Scene / UI code | `GameSession`, scene controllers, entity nodes, the split-screen module, UI, input plumbing |
| **Editor** | `editor/` | Authoring / debug tooling | `@tool` validation, optional editor tooling. Never referenced at runtime |

### Dependency rule

Dependencies flow **one way only** — a layer never reaches "up" into a layer above
it:

```
Domain ← Application ← Presentation
```

- **Domain** is referenced by all; it references nothing outside itself.
- **Application** references Domain only; never nodes, scenes, or `get_tree()`.
- **Presentation** references Application and Domain (and Infrastructure adapters).
- **Infrastructure** is referenced by Presentation when adapting external systems;
  it is the only layer allowed to import third-party packages.
- **Editor** references Presentation + Domain; it is **never referenced at runtime**.

A script that lives in `presentation/` never `extends` a script in `application/`;
a service in `application/` never `preload()`s a scene or touches `get_tree()`.

---

## 2. GDScript file and class naming (all layers)

GDScript has no namespaces: **layer membership is the folder**. Conventions:

- File name: `snake_case.gd` matching the class (`game_session.gd`, `flow_controller.gd`).
- `class_name`: PascalCase, globally unique. When the same natural name would
  appear in two layers, prefix it with the role (`GameState` in Domain vs
  `CombatService` in Application).
- A script in `domain/` must not depend on scripts in other layers. A script
  may only `preload()` / `class_name`-reference symbols from layers it is allowed
  to see (see dependency rule).

---

## 3. Per-layer conventions

### Domain (`domain/`) — **facts**

Fields and state are `snake_case` (`is_empty`, `wave_number`); classes
are PascalCase. State classes hold their behavior in methods (`begin()`,
`advance(...)`, `mark_done(...)`, `reset()`) — not just passive data bags.

- Identity uses **wrapped value types**, never bare strings, in signatures:
  `WeaponId`, `EnemyTypeId` (expose `_to_string()`, `==`, and equality against the
  raw value).
- Definitions are data `Resource`s: stable `id` + `display_name`, per-definition
  data, rule (strategy) arrays, and scene/variant references where a definition
  maps to scene content.
- Global discrete facts live in a case-insensitive flag set
  (`has_flag / set_flag / clear_flag`).

### Application (`application/`) — **rules**

Same `snake_case` field style. Methods are **verb phrases** (`prepare_selectable`,
`advance_wave`, `evaluate`, `complete_current_step`).

- Services are plain `RefCounted`, constructor-injected with `GameState` (+ config).
- Methods fall into *prepare/select/query* families where a feature presents
  choices; mutation is the service's job — never return a result enum and let the
  caller mutate.
- Deterministic: same `GameState` + same inputs → same result (except explicit RNG,
  injected or internally owned).

### Presentation (`presentation/`) — **Godot glue**

Godot node conventions: `@export` for inspector-editable fields, `@onready` for
node references, `_ready()` / `_process()` / `_physics_process()` lifecycle, and
signals named for what happened (`shot_fired`, `brother_down`, `all_down`).

- Entity scripts are **adapters over the domain**: they own physics, animation,
  `Camera2D`, inputs, and visuals; authoritative life/spawn/damage/ammo facts live
  in domain objects and are changed through services. **They never hold a second copy
  of a fact the domain owns** — this is the concrete form of §0.
- Movement helpers (`move_and_slide`, knockback) are the one acceptable piece of
  game logic on a node: it is physics, which only lives at this layer.
- Views (Controls) never mutate state directly — they call services or flow methods.
- Signals cross the seam *upward* (entity → controller → flow); never use them for
  service-to-service chatter.

### Infrastructure (`infrastructure/`) — **adapters**

Adapter singletons per external system expose a small, **game-shaped** interface,
never the library's types (`play(cue_name)` behind `AudioAdapter`, not
`AudioServer.play(...)`). Only this layer may import third-party packages. It is
reached from presentation, or from application through a declared **port**.

### Editor (`editor/`) — **tooling**

Every editor file guards runtime sections with `if Engine.is_editor_hint():` or
lives in an `EditorPlugin`. It is never referenced at runtime. There is **no custom
level editor** — levels are hand-built in the Godot editor
([`design/level-authoring.md`](design/level-authoring.md)).

---

## 4. Definitions (`Resource` assets)

Weapons, enemies, items, drop tables and wave schedules are **data**, not scripts.

- Definitions live under `application/`'s domain side as `Resource` scripts and their
  instances sit alongside, named `kebab-case.tres`. The asset files land with the
  tickets that author them.
- A definition carries a stable `id` + `display_name`; IDs are case-insensitive, and
  service signatures use the wrapped-ID types from Domain, never bare strings.
- `EnemyDefinition.behaviours` is an ordered **list**, not a state class hierarchy —
  see [`design/architecture.md`](design/architecture.md) and ADR-0001's consequences.

The original project's `resources/` configuration tree, its `AppConfig` root resource,
its `Catalog` lookup collections and its editor **normalize-IDs pass** are **not**
carried forward. They were scaffolding for a migration that this remake does not
perform. Add them back only with an ADR.

## 5. Scenes

There is **one level** and it is hand-built and hand-placed: the editor scene *is* the
level. There is no procedural generation, no level format, and no level editor. Before
a level ships, it must pass the checklist in `docs/design/level-authoring.md`.

The round-loop phase owner (`GameLoopService`) decides what runs next; nothing else
starts a wave.

## 6. Other rules

- Always validate required constructor dependencies (`assert` in debug) and
  missing required configuration (`push_error` with a message that says exactly
  what is missing).
- Signals are used for crossing the seam upward only, never service-to-service
  chatter.
- "Is this a fact/concept, an enum, or a config asset?" → **Domain**. "Is this a
  rule/workflow that orchestrates state?" → **Application**. "Does it touch a
  scene, node, physics body, UI, or third-party system?" → **Presentation /
  Infrastructure**. "Does it only help author/debug?" → **Editor**.
- Tests live outside the source layers in `tests/`, and assert behavior only —
  construct state, invoke a module, assert the result; never assert wiring. See
  `docs/TESTING.md`.
- Assets are **nearest-filtered**. `rendering/textures/canvas_textures/default_texture_filter`
  is pinned to `0` (Nearest) in `project.godot`, because every texture in the original
  was imported with `flags/filter=false` and Godot 4 removed that per-texture flag.
  Do not raise it: linear filtering is what puts seams between tiles. Mipmaps stay off
  for the same reason.