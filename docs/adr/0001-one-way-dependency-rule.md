# ADR-0001 — One-way dependency rule (Domain ← Application ← Presentation)

Status: **Accepted**

Deciders: Remake architecture (`docs/design/architecture.md`)

Ported from the original project's restructure decision (issue
Jon-Gear/FelonyFelines#14). The rule is unchanged; the target it was written against
is now `GameState`, not `AppState`.

Date: 2026-09-21 (original) · re-affirmed for the remake 2026-10-01

## Context

The original codebase was a flat namespace: `Global.gd` is punched through from ~78
call sites, entities reach siblings and globals by string path, and nothing records how
code should depend on what. Any change risks silently breaking a subsystem. The remake
needs a fixed, enforced dependency shape so that changing a lower layer never ripples
upward into scene code, and so future work lands predictably.

## Decision

The codebase is organized into five layers — Domain, Application, Infrastructure,
Presentation, Editor — and dependencies flow **one way only**: Domain is referenced by
all; Application references Domain only; Presentation references Application and Domain;
Infrastructure is referenced by Presentation when adapting external systems; Editor
references Presentation + Domain and is never referenced at runtime.

```
Domain ← Application ← Presentation
```

Concretely:

- Layer membership is the folder (GDScript has no namespaces); a script may only
  preload / `class_name`-reference symbols from layers it is allowed to see.
- A `presentation/` script must never `extends` an `application/` script; an
  `application/` service must never `preload()` a scene or touch `get_tree()`.
- Only `infrastructure/` may import third-party packages.
- Domain holds `Resource` and `RefCounted` only — never `extends Node`, never
  `get_node`, never `Input`, `AudioServer` or `DisplayServer`.

The full naming and layout rules are fixed in `docs/CONVENTIONS.md`.

## Consequences

- Finding where a responsibility lives no longer requires reading the whole
  project — it is implied by the folder.
- Lower layers stay migration-safe: changing Domain or Application never ripples
  into scene code.
- New code follows the rule by construction; reviewers stop teaching it per PR.
- Enforcement is convention-based today (folder + review), not machine-checked.