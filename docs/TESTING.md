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
- The vendored copy in `addons/gut/` is **GUT 9.7.1**, taken verbatim from the upstream
  `v9.7.1` tag of `github.com/bitwes/Gut` — the release line maintained against Godot
  4.7. Upgrade by replacing that directory with a newer tag, not by editing it.
- Tests live in `tests/unit/`, one `test_*.gd` file per module under test. Each file
  extends the GUT base test node (path form, so it resolves without the editor having
  registered the global class name).
- A `.gutconfig.json` at the project root points GUT at `res://tests/unit` with the
  `test_` prefix, so the default run needs no arguments.

### Run from the editor

Enable the GUT editor plugin in `project.godot`. Open the GUT panel from the bottom
dock, confirm the directory is `res://tests/unit`, and press **Run**.

### Run from the command line

Headless, with no arguments needed — this is what CI runs:

```
godot --headless -s addons/gut/gut_cmdln.gd
```

`should_exit` in `.gutconfig.json` (the `-gexit` flag) makes the runner quit with a
non-zero status when a test fails.

Explicit flags override the config file:

```
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

> **A test file that fails to parse is skipped, not failed.** GUT reports
> `Failed to load script` and drops the file; if that was the only test file the run
> still exits zero. So a green exit code alone does not prove the suite ran — CI must
> also fail on `Failed to load script` or `Nothing was run` in the output.

## 2. The convention — assert behavior, never wiring

A good test:

1. **constructs** the input it needs (a plain dictionary, a fresh state object),
2. **invokes** the module under test (a pure helper or a service over state), and
3. **asserts** on the returned result or the resulting state delta.

A good test never asserts on node paths, autoloads, signal connections, scene
trees, or *which* internal method was called. If a rule can only be exercised by
standing up a scene, that is a sign the rule should be extracted into a module
the test can call directly.

There is one deliberate exception, `test_architecture_guards.gd`. The rules it holds —
no `Node` and no `get_tree()` anywhere in `domain/` or `application/`, no scene
preloaded into either, nothing `Node`-shaped or untyped reachable from a `GameSession`
member, and `GameSession` exposing `GameState` and `services` and nothing else — are
about the *shape* of the code, so there is no state to construct and no result to
assert. It reads the layer scripts as text and asserts on the declarations it finds. It
boots no scene, never touches the `GameSession` autoload singleton, and asserts no node
path. The reader it uses is itself covered by fixture tests in the same file, so a guard
that quietly stopped detecting anything fails the suite instead of passing it.

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

The first of them to land are `Health` and `GameState` — the two pieces of state every
later service is written against.

## 3. Test-only code does not ship

This is a requirement on the export presets, **not yet satisfied** — the remake has no
`export_presets.cfg` yet. When one is authored, every preset must carry an exclude
filter covering `tests/*` and `addons/gut/*`, so the suite and the test framework are
kept out of release builds.