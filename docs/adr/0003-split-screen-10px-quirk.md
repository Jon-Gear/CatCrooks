# ADR-0003 — Split-screen preserves the intentional 10 px camera-offset quirk

Status: **Accepted**

Deciders: Remake camera design (`docs/design/camera.md`)

Ported unchanged from the original project's restructure decision (issue
Jon-Gear/FelonyFelines#14). Date of original decision: 2026-09-21.

## Context

`camera_controller.gd:46` computes camera 2's target position with brother 1's
visual offset instead of brother 2's:

```
func get_player2_position():
	return player2.global_position + player1.player_visual_middle
```

`player_visual_middle` differs per brother: `Vector2(0, -50 + 10)` for brother 1
(player.gd:40) and `Vector2(0, -50)` for brother 2 (player.gd:45). The difference
is exactly 10 px. Brother 1 (red) reads higher up and brother 2 (blue) reads lower —
a small, deliberate-looking composition quirk. It looks intentional (red is
slightly taller on screen); it is shipped behavior, and the remake must not
change what the player sees.

## Decision

The split-screen **preserves the 10 px camera-offset quirk exactly** — the same reading
difference, whatever the geometry refactor looks like. It is recorded here so a future
reviewer does not "fix" it as a bug. A dedicated task can reverse it; no incidental task
may.

`docs/design/camera.md` restates this as a reference-frame bug that is load-bearing for
feel, and pairs it with the matching HUD offsets (`Visual middle Y` of -40 for brother 1
and -50 for brother 2).

## Consequences

- The quirk is a documented decision instead of a silent bug — reviewers know not to
  "fix" it.
- Camera geometry is a pure, unit-testable function of the brother facts, so the offset
  rule is encoded in one place and tested.
- A dedicated future task may reverse the quirk only with this ADR superseded.