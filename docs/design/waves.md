# Waves

## The formula

```
enemies_this_wave = spawner_count × wave_number
```

With 4 spawners, wave *N* spawns **4 × N** enemies:

| Wave | Enemies |
|---|---|
| 1 | 4 |
| 2 | 8 |
| 5 | 20 |
| 10 | 40 |
| 20 | 80 |

**Uncapped, and linear.** There is no ceiling, no per-type weighting, and no enemy stat
scaling. Difficulty is a wall, not a curve — and that is preserved.

## Composition

Each spawner picks **uniformly at random** from the three enemy types. So at wave 10,
roughly ⅓ of 40 enemies are 100-HP gunners with 300px range firing continuously, and ⅓
are 10-HP Imps that die to one pellet. The gunners are the difficulty.

No wave composition is authored. No difficulty curve exists. This is the original
behaviour, unchanged.

## Spawners

| | |
|---|---|
| Count | 4 per level |
| Selection | uniform random from {Imp, Gunner, Baller} |
| Spawn offset | uniform inside a 75 × 75 box around the spawner point |
| Nav threshold | per enemy type |

Spawn points are placed by hand in the level (`level-authoring.md`). The random ±75px
offset means spawns never stack exactly, and gives the brothers a moment of warning.

## Pacing

| | |
|---|---|
| Intro | ~2s |
| Wave announce (banner + shake) | 5s |
| Wave active | until cleared |
| Between waves | 5s, via `WAVE_ANNOUNCE` |

The 5-second gap is load-bearing arcade rhythm — it's the beat in which players
reposition and scavenge ammo. Keep it.

Screen shake on wave announce: intensity 8.0, duration 1.0s.

## Clearing

A wave is cleared when the live enemy count reaches zero. The count decrements when an
enemy dies, reported by `CombatService` to `WaveService`.

Nothing spawns continuously during a wave — every enemy for wave *N* is emitted at wave
start. Killing everything ends the wave; there is no trickle.

## What is *not* here

There is no soft cap on concurrently alive enemies and no per-wave HP scaling. Both were
considered and both were rejected: the original's linear-uncapped ramp is the arcade
shape, and adding a cap would change the character of the run. See `departures.md` for
the full list of what did change.

`WaveSchedule` is a domain resource — the formula is data, and
`WaveService.enemies_for_wave(n)` is pure and testable.