# Camera — split-screen

One `SplitScreenCamera` node, added to the level scene, owns the entire rig: two
sub-viewports, two cameras, the compositor, and shake. The rest of the game asks it for
facts and for shake; nothing else touches cameras.

## Behaviour (the contract)

| | |
|---|---|
| Split threshold | 450 px separation |
| Seam | A diagonal through screen center, **perpendicular to the line between the brothers** |
| Which side | The brother whose `y` is smaller takes the top half |
| Seam thickness | 0 px at 450 px separation, ramping to 3 px at 900 px |
| Below threshold | One shared view, no seam |
| Brother down | The living brother fills the whole screen |
| Zoom | 1.2 on both cameras |

The seam **rotates as the brothers move**. That diagonal feel is the whole look of the
game and it is preserved exactly.

Camera positioning is also preserved exactly, including the parts that look odd:

```
camera1.position = brother1.position + offset
camera2.position = brother2.position - offset

offset = clamp(separation / 2, 0, max_separation)   # max_separation = 450
```

So each camera sits at its brother **plus or minus half the separation, clamped to
450**. When the brothers are far apart, each camera has slid ~225px past its own brother.
This is preserved because the resulting framing is what the game feels like. Do not
"fix" it to centre each brother — that was tried and rejected; it changes how the game
plays.

### The 10px offset

`camera2`'s position calculation adds **brother 1's** `visual_middle` offset rather than
brother 2's. It is a reference-frame bug that has been load-bearing for feel, and it is
protected by an ADR in the original repo. **Keep it.**

### Which half is which

The side is chosen by comparing the two brothers' `y` positions, not by a true
perpendicular bisector of the separation vector. These disagree when the brothers are
nearly level with each other: the shipped rule puts the seam along a horizontal line,
where a true perpendicular would cut diagonally.

Preserved, deliberately. A true perpendicular was considered and rejected — the
`y`-comparison version is what looked right.

## Implementation

One module. It is a presentation node plus an infrastructure adapter behind it.

```
SplitScreenCamera          (Node, added to the level scene)
├── Viewport1              (SubViewport)
│   └── Camera1            (Camera2D)
├── Viewport2              (SubViewport)
│   └── Camera2            (Camera2D)
└── Compositor             (ShaderMaterial drawing both viewport textures + the seam)
```

The seam is computed in the compositor from both brothers' **screen-space** positions:
build the half-plane perpendicular to the difference, choose the side by the `y`
comparison, discard inside. Nothing about the seam lives in the world, and the two
cameras never reference each other beyond the shared offset calculation above.

### What this replaces

The original implementation:

- shared a single `World2D` between both viewports and **masked** one half with a shader
- stitched the halves back together with a `TextureRect` using `flip_v = true` and
  `expand = true`
- had a `Shake` helper whose group-scan logic could never assign a camera and only
  worked because the rig explicitly called `set_camera`
- had a dormant `SplitScreenCamera.gd` wrapper whose `current_world_path` was never set

All four are gone. There is one module, it owns both cameras explicitly, and it consumes
two viewport textures rather than carving up the world. See `departures.md`.

## Shake

One shake system, applied to both cameras identically per frame:

```
offset = Vector2(random(-1, 1), random(-1, 1)) × intensity
```

Random on **both** axes across the full −1…1 range. The original used
`Vector2(randf(), randf())`, which is always positive and so drifts the view up and to
the right. See `departures.md`.

| Trigger | Intensity | Duration |
|---|---|---|
| Wave announce | 8.0 | 1.0s |
| Brother takes a hit | 4.0 | 0.5s |
| Any player weapon shot | 2.5 | 0.5s |

## How the rest of the game talks to it

`CameraService` (application) → `CameraFxAdapter` (infrastructure) → `SplitScreenCamera`
(presentation).

```
CameraService.request_shake(intensity, duration)
CameraService.brother_facts()   # positions + alive flags, for the seam
```

The camera never reaches into game state to find the brothers, and `GameSession` never
holds a camera. This is the seam ADR-0004 in the original repo describes.