# ADR-0002 — HealthManager stays authoritative for its entity during the restructure

Status: **Superseded by the remake's design.** Do not implement.

Deciders: Remake architecture ([`docs/design/architecture.md`](../design/architecture.md))
and [`docs/design/combat.md`](../design/combat.md)

Superseded on: 2026-10-01
Superseded by: the domain-`Health` decision in
[`docs/design/architecture.md`](../design/architecture.md) (the `Health` type) and
[`docs/design/combat.md`](../design/combat.md) ("Health is domain"). Those specs, not
this ADR, are what to implement.

Deciders (original): restructure spec, issue Jon-Gear/FelonyFelines#14. Date of original
decision: 2026-09-21.

## Why this ADR is superseded

This decision was scoped to a **migration**: keep `HealthManager` authoritative while
the original was being restructured, and defer the flip to state-authoritative health.
The remake has no migration. There is no `HealthManager` node to preserve, no
intermediate step where two views of health have to be reconciled, and no reason to
accept a decision whose entire value was keeping the blast radius small.

Carrying it forward as **accepted** would actively mislead every later ticket: it would
tell you to build the node the remake deletes. It is kept here only so the history is
readable.

## What replaces it

**Health is a domain object, and `HealthManager` is retired.**

- `Health(current, max)` is a Domain type, listed alongside `HitResult` and `AmmoState`
  in `docs/design/architecture.md`.
- `CombatService` is the **only** writer. Domain and application own health; presentation
  reads it and asks services to change it.
- `Health` exposes `is_empty()`.

See the "Health is domain" section of
[`docs/design/combat.md`](../design/combat.md) — *"There is no `HealthManager` node"* —
and the `Health` row of the layer table in
[`docs/design/architecture.md`](../design/architecture.md).

## The original decision, for the record

Every combatant (players and enemies) carried a `HealthManager` node. It held current +
max health and silently acted as the authority for damage, death, and revive. The
split-screen, respawn, and death flows all read `health_manager.is_dead()` directly.
The target architecture said authoritative life facts should live in state
(`BrothersState`) and change through a `CombatService`. Flipping health to
state-authoritative in one step would have touched every entity, every death flow, and
the split-screen at the same time — a wide, risky blast radius with no seam.

So `HealthManager` **stayed authoritative for its entity's health** for the duration of
the restructure, reporting changes through `CombatService`, which reconciled them into
state. Reads such as `health_manager.is_dead()` in respawn, split-screen, death and
closest-player logic kept working until their owning flow was migrated.

None of that applies here. In the remake there is exactly one view of health, it lives
in Domain, and `CombatService` writes it — no duplication, no reconciliation, no
migration seam. This is one of the reasons the remake is a rewrite rather than a port.

## Consequences

- Down / revive rules are `RespawnService`'s (`docs/design/brothers.md`).
- Damage is applied in one place: `HitResolver.resolve()` returns a `HitResult`,
  `CombatService` applies it. See `docs/design/combat.md`.
- No node owns a second copy of health. Presentation never holds a health field it
  could drift from — that rule is restated in `docs/CONVENTIONS.md`.