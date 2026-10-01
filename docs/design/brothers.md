# Brothers

Two playable cats. Brother 1 is red (player 1), brother 2 is blue (player 2).

They are **brothers**, not "players" — the original also had a `PlayerNPC` AI actor
that is not a brother, and `Global` called every node under `players` a "player" which
made both ambiguous.

## Stats

| | Brother |
|---|---|
| Max health | 100 |
| Max speed | 675 px/s |
| Extra resistance | 0.3 |
| Hurtbox offset | (0, -27) from origin |
| Collision shape | capsule, radius 5 |

Both brothers are identical except for colour and input device.

**675 vs the enemies' 225 is exactly 3×.** Enemies cannot catch a moving brother. This
is load-bearing for the power fantasy and is preserved on purpose — see
`preserved-quirks.md`.

## Input

Actions are named per brother. Bindings are defaults; remap freely.

| Action | P1 default | P2 default |
|---|---|---|
| move left / right / up / down | arrow keys | `W` `A` `S` `D` |
| fire | (fire button) | (fire button) |
| previous weapon | `,` | `Q` |
| next weapon | `.` | `E` |
| pause | `Escape` (shared) | `Escape` (shared) |

Gamepads: **device 0 is P1, device 1 is P2.** Left stick moves, right trigger / RB
fires, shoulders cycle weapons.

The action *names* matter (they are the seam between keyboard and gamepad). The specific
keys do not.

An `InputAdapter` reads `Input` and produces a per-frame `PlayerIntent`:

```
PlayerIntent:
  move_dir          Vector2   normalized, zero if no input
  fire_held         bool
  cycle_requested   int       -1 previous, 0 none, +1 next
  pause_requested   bool
```

No scene script ever calls `Input.is_action_pressed()`. See `movement-and-aim.md`.

## Health

Health is a **domain** object — `Health(current, max)` on the brother's domain entity.
There is no `HealthManager` node in the remake. `CombatService` is the only thing that
mutates it; the HUD reads it.

The original had a `HealthManager` node authoritative for its entity, which meant health
changes, hurtbox enabling, and death-gating were spread across a node and three state
scripts. Retiring it removes ~15 of the original's quirks at the root.

Healing restores to max and is clamped.

## Going down

At zero health a brother **goes down**. He does not die. On going down:

1. Fire stops
2. Ammo counter hides
3. Health bar hides
4. He stops colliding as a brother (body layer removed)
5. Weapon manager hides
6. **The respawn circle activates** — see below
7. `RespawnService.notify_brother_down()` fires

If the *other* brother is also down at this moment, the round ends. Otherwise he can be
revived.

## Reviving

| | |
|---|---|
| Respawn circle radius | 64 |
| Revive time | 2.5s |
| Revived by | the **other** brother only |
| On revive | full health, back to idle |

The downed brother cannot revive himself. The other brother must stand within the
circle. If he leaves, the timer pauses and holds its progress — walking away does not
reset it. On timeout: circle deactivates, the brother is revived at full health.

The circle shows a radial progress wheel.

### There are no lives

No life count. No credits. A downed brother revives for free whenever the other brother
is alive, and the round ends only when both are down *simultaneously*.

The consequence is that one brother can carry an entire run while the other is
permanently useless. That is the original design and it is preserved: the co-op rescue
fantasy is the point of the mechanic, and adding a revive budget would convert it into an
economy.