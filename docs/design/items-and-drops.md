# Items and drops

## Items

| Item | Kind | Notes |
|---|---|---|
| Revolver | range | ammo 18, pack 6 |
| Shotgun | range | ammo 20, pack 10 |
| Minigun | range | ammo 500, pack 100 |
| Axe | melee | no ammo |
| Medkit | medkit | heals, consumed on use |

## Drop table

On death, each enemy independently rolls to drop anything:

```
if random_int(0, 99) < 50:      # 50% of kills drop something
    roll the weighted table below
```

Weights, and their resulting probability:

| Item | Weight | Probability |
|---|---|---|
| Medkit | 5 | 27.8% |
| Revolver | 5 | 27.8% |
| Axe | 4 | 22.2% |
| Shotgun | 3 | 16.7% |
| Minigun | 1 | 5.6% |
| **Total** | **18** | **100%** |

The original normalized weights to at most 100 tickets and promoted positive fractions
to a minimum of 1 ticket, leaving zeros at zero. Keep the normalization on `DropTable`
as pure domain code — it is testable and it is the reason the probabilities above are
exact rather than floating-point approximations.

Every enemy has the same 50% drop chance and the same table. There is no per-enemy loot
tiering.

Dropped items spawn at the corpse's position in the items container.

## Ground items

| | |
|---|---|
| Despawn time (weapons) | 5s |
| Despawn time (medkits) | 10s |
| Item bob radius | 32 |
| Brother pickup radius | 40 |

Weapons on the ground vanish after 5 seconds — pick them up fast. Medkits linger twice
as long.

The despawn timer starts when the item is not in an inventory, and cancels if picked up.

## Picking up

Walking a brother over an item picks it up, if he does not already hold that item:

```
WeaponService.add(item)
play pickup sound
free the pickup node
```

| | |
|---|---|
| Brother pickup area | radius 40 |
| Item pickup range | radius 32 (drives the bobbing animation) |

## Merging duplicates

Picking up a weapon you already hold **adds its ammo to the held copy** and frees the
pickup. It does **not** take a new slot.

| Pickup | Effect on the held weapon |
|---|---|
| Revolver | +6 ammo |
| Shotgun | +10 ammo |
| Minigun | +100 ammo |
| Medkit | +1 (stack, consumed on use) |

So a second minigun is +100 rounds rather than a second minigun, and a fourth revolver
is +6 rather than a duplicate slot. This is why slot count never grows in practice, and
it is the original behaviour — preserved.

## The medkit

| | |
|---|---|
| Heal amount | 20 |
| Ammo (uses) | 1 |
| Uses per pack | +1 |

A medkit is a consumable that sits in the weapon list alongside guns.

Using it:

1. If the brother is at **full health**, the use is **refused** — a "denied" sound plays
   and the medkit is **not consumed**.
2. Otherwise heal 20, consume one use, play an "eat" sound.

Refusing at full health rather than wasting the medkit is deliberate.

Healing is a flat 20 against 100 max health, so a full heal from zero takes five
medkits. The level ships with four pre-placed and the drop weight is 27.8%, so health
pressure is thin by design. Preserved — see `tunables.md`.