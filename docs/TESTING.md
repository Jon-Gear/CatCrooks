# Testing conventions

> Tests live outside the source layers in `tests/`, run under **GUT** (Godot Unit Test),
> and assert **behavior only**. This is the reference pattern every later ticket
> follows: *construct state, invoke a module, assert the result.*

Status: **accepted** · companion to `docs/design/architecture.md`,
`docs/CONVENTIONS.md`, and [ADR-0001](adr/0001-one-way-dependency-rule.md).

Ported from the original project's testing doc. The **convention** (§2) carried over
unchanged and is the part that matters. The **harness** (§1) is restated for Godot 4
and is not yet wired up — see the note at the end of §1.

---

## 1. Harness

- Framework: **GUT**, on its Godot 4 line. It is dev-only tooling: the one sanctioned
  third-party package outside Infrastructure (ADR-0001), and it never ships (see §3).
- Tests live in `tests/unit/`, one `test_*.gd` file per module under test. Each file
  extends the GUT base test node (path form, so it resolves without the editor having
  registered the global class name).
- A `.gutconfig.json` at the project root points GUT at `res://tests/unit` with the
  `test_` prefix, so the default run needs no arguments.

### Run from the editor

Enable the GUT editor plugin in `project.godot`. Open the GUT panel from the bottom
dock, confirm the directory is `res://tests/unit`, and press **Run**.

### Run from the command line

```
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

Omit the `-g*` flags to fall back to `.gutconfig.json`:

```
godot -s addons/gut/gut_cmdln.gd
```

`-gexit` makes the runner quit with a non-zero status on failure, which is what a
CI step should check.

> **Not yet in this repository.** `addons/gut/`, `tests/`, `.gutconfig.json` and the
> editor plugin entry all land with the first ticket that writes a test. The original's
> Godot 3 harness (`GUT 7.4.3`, two unit tests) was **not** ported — the framework is
> re-vendored on the Godot 4 line rather than upgraded in place. Until then there is
> nothing to run, and no test-only exclusions exist in the export presets.

## 2. The convention — assert behavior, never wiring

A good test:

1. **constructs** the input it needs (a plain dictionary, a fresh state object),
2. **invokes** the module under test (a pure helper or a service over state), and
3. **asserts** on the returned result or the resulting state delta.

A good test never asserts on node paths, autoloads, signal connections, scene
trees, or *which* internal method was called. If a rule can only be exercised by
standing up a scene, that is a sign the rule should be extracted into a module
the test can call directly.

Two reference shapes from the original's suite, which had exactly these two tests. Note
that the *helpers* are named for the original's domain and are **not** carried forward —
only the shape of the test is:

- `test_id_utils.gd` — calls a pure `normalize(name)` and asserts the returned string.
- `test_drop_weights.gd` — calls `DropWeights.normalize(weights)` and asserts the
  returned table, including that the input is left untouched.

The remake's actual targets are named in `docs/design/architecture.md` under **Testing
surface**: `DropTable` weighted picks and normalization, `HitResolver` damage and
knockback vectors, wave count formulas, ammo cycling, `GameState` transitions, and
`EnemyDefinition` behaviour transitions. All of them are pure — no nodes, no
`get_tree()`, no autoloads. That is what makes them testable headlessly, and it is
the payoff of [ADR-0001](adr/0001-one-way-dependency-rule.md).

## 3. Test-only code does not ship

This is a requirement on the export presets, **not yet satisfied** — the remake has no
`export_presets.cfg` yet. When one is authored, every preset must carry an exclude
filter covering `tests/*` and `addons/gut/*`, so the suite and the test framework are
kept out of release builds.