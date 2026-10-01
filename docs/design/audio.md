# Audio

Every sound the game plays, and what fires it. The audio assets themselves are reused
from the original; this file specifies the cues.

## Pitch randomization

Every one-shot plays with:

```
pitch_scale = random(0.8, 1.5)
```

This is the single most important audio rule. It is why the original's small sample set
doesn't sound repetitive — every gunshot is a slightly different gunshot. Keep it on all
one-shots. Loops and music do not get it.

## Cues

### Combat

| Cue | Fires when |
|---|---|
| Damage (hit) | Any entity takes damage |
| Death (enemy) | An enemy dies |
| Attack (melee) | An enemy begins a melee or dash attack |

### Weapons

| Cue | Fires when |
|---|---|
| Shot — revolver | Revolver fires |
| Shot — shotgun | Shotgun fires |
| Shot — minigun | Minigun fires |
| Swoosh | Axe swings |

Melee swooshes have an extra pitch range of 0.3 on top of the global randomization.

### Items

| Cue | Fires when |
|---|---|
| Item drop | A weapon item enters the world (on spawn) |
| Pickup | A brother picks anything up |
| Eat | A medkit is successfully used |
| Denied | A medkit is used at full health |

### Player

| Cue | Fires when |
|---|---|
| Damage | A brother takes damage |
| Death | A brother goes down |

### World

| Cue | Fires when |
|---|---|
| Lose track | Both brothers are down |

## Deliberate absences

Two cues exist in the original's sound nodes but never play. Do not wire them up:

- **Footsteps** — there is no footstep *sound*. Running produces visual dust only
  (spawned from animation method tracks on `Run` / `Accel` / `Decel` across player and
  enemy scenes). The sound node is empty.
- **Pain** — the node exists and nothing plays it. Hits play `Damage` instead.

The dust is worth keeping: it is the only feedback the movement model gets.

## Structure

```
AudioAdapter (infrastructure)     # the only layer touching AudioServer
  play(cue_name)
  play_music(track_name)
```

Called by presentation in response to game events. Domain and application never name a
sound. `AudioAdapter` owns the pitch randomization and the bus layout, so no call site
has to remember it.

## Music

One track: the lose track, on `GAME_OVER`. There is no gameplay music in the original.
Do not add any — see `not-in-v1.md`.