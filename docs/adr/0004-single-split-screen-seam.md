# ADR-0004 — One split-screen module behind one brother-facts seam

Status: **Accepted**

Deciders: Remake camera design (`docs/design/camera.md`), and the structural departures
in `docs/design/departures.md`

Ported from the original project's restructure decision (issue
Jon-Gear/FelonyFelines#14). The decision is unchanged; the module it produces is named
`SplitScreenCamera` in the remake — the same name the original's *dormant wrapper* had,
but here it is the real module, not a wrapper. Date of original decision: 2026-09-21.

## Context

The original's dynamic split-screen rig was hand-wired and had two setup paths. Two
cameras + a shader lived in `SplitScreenCamera.tscn`, but `SplitScreenCamera.gd` was a
no-op wrapper whose `current_world_path` was never set anywhere, so if someone did set
it the controller's `setup()` would run twice. The actual work happened in
`camera_controller.gd`, which bounced between scene paths (`$ViewportContainer/Viewport1`,
…), the global `"camera"` group, `Global.brother_1/2` and player internals
(`player_visual_middle`, `health_manager.is_dead()`). Four leak edges ran to `Global`,
`Shake`, and both player subtrees. Standing up a second world scene meant re-wiring the
same six-file handshake; a new brother type broke the rig.

The original also masked one half of a shared `World2D` with a shader and stitched the
halves back together with a `flip_v` `TextureRect`.

## Decision

The split-screen is collapsed into **one deep module behind a small seam**. The seam
exposes the facts the module needs per brother: position, visual offset, and alive. No
`Global.brother_1/2`, no player internals, no `"camera"` group handshake.

- The seam is `CameraService` (application) → `CameraFxAdapter` (infrastructure) →
  `SplitScreenCamera` (presentation), per `docs/design/camera.md`.
- Camera shake is an internal detail of the module, reached through
  `CameraService.request_shake(intensity, duration)` rather than a group scan, so camera
  transforms are owned in one place.
- Camera geometry is a pure core: midpoint cameras, split line, dead-brother
  fallback, clamping to `max_separation`, and the 10 px quirk of ADR-0003 are
  preserved and unit-testable headlessly.
- Real player nodes in production and fakes in tests both satisfy the seam (adapter
  pattern).
- The seam is computed in **screen space**: the compositor builds the half-plane
  perpendicular to the difference between the brothers' screen positions, chooses the
  side by the `y` comparison, and discards inside. The two viewports consume separate
  textures rather than carving up a shared world.

## Consequences

- One interface for every future world scene instead of a 6-file hand-wiring; a new
  brother type no longer breaks the camera rig.
- The 10 px quirk lives in exactly one place to fix (under ADR-0003's rules).
- Deletes dead code: the wrapper that never ran, the shared-`World2D` masking, the
  `flip_v` composite, and the group-scan shake logic (`Shake.gd`) whose condition was
  inverted.
- There is exactly one way to set up the split-screen.