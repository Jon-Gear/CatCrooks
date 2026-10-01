# Round loop

`GameLoopService` owns the round. Nothing else starts a wave, ends a round, or
transitions phases.

## Phases

| Phase | Duration | What happens |
|---|---|---|
| `INTRO` | ~2s | World ready, camera rig armed, navmesh active. |
| `WAVE_ANNOUNCE` | 5s | Wave number increments, banner shows, screen shake. |
| `WAVE_ACTIVE` | until cleared | Spawners emit enemies. Brothers fight. |
| `WAVE_CLEARED` | 0s | Wave-clear score bonus. HUD refresh. |
| `GAME_OVER` | ~5s | Death screen, lose track, then menu. |

Transitions:

```
INTRO ──intro_done──> WAVE_ANNOUNCE
WAVE_ANNOUNCE ──timer(5s)──> WAVE_ACTIVE
WAVE_ACTIVE ──all_enemies_dead──> WAVE_CLEARED
WAVE_CLEARED ──> WAVE_ANNOUNCE            (next wave, unless GAME_OVER pending)
WAVE_ACTIVE ──both_brothers_down──> GAME_OVER
WAVE_ANNOUNCE ──both_brothers_down──> GAME_OVER
```

## Wave announce

On entering `WAVE_ANNOUNCE`:

1. `GameState.wave_number += 1`
2. Banner shows `WAVE <n>` for the full 5s
3. `CameraService.request_shake(8.0, 1.0)`
4. HUD wave board refreshes

The 5-second pause and the wave board are load-bearing arcade rhythm — they give the
players a beat to collect ammo and reposition before the next wave. Keep them.

The original intro was a 10-second placeholder animation on boot. That is now ~2s.

## Wave active

`WaveService.begin_wave(n)`:

1. For each of the 4 spawners: `spawner.emit(n)`
2. Track total live enemies for this wave

A wave is cleared when the live count reaches zero. `WaveService` receives
`notify_enemy_died()` from `CombatService` — see `architecture.md` on why this is a
method call and not an animation method track.

## Wave cleared

1. `ScoreService` adds the wave-clear bonus (see `waves.md`)
2. HUD refreshes
3. `WAVE_CLEARED` → `WAVE_ANNOUNCE`

## Game over

Triggered only when **both brothers are down at the same time** (`RespawnService` owns
that rule — see `brothers.md`).

1. Both respawn radii deactivate — no revival from here
2. Lose track plays
3. ~5s beat, then the death screen appears
4. Death screen shows `final_score` and `waves survived`
5. Player returns to the menu

**The death screen is restored.** In the original the call was commented out and
`DeathScreen.tscn` was unreachable — the round always faded straight back to the menu,
so the score was recorded and never shown. Five seconds of a black screen was not the
plan.

## Scoring

| Event | Points |
|---|---|
| Enemy killed | 100 (flat, every type) |
| Wave cleared | 100 |

Flat per-kill is preserved. The wave-clear bonus is the one addition: it makes the
score reward surviving pressure, not only kill speed, so a run has an arc rather than a
single number.