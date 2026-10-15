# mod-portable-sawmill

The sawmill a Woodworker carries, as opposed to the sawmill places that
`mod-woodworking` answers.

Woodworking's five Refine spells want a sawmill. Two things in the realm supply
one on demand, and both of them place a gameobject through the ordinary summon
path:

| Source | Spell | Gameobject | Lifetime |
| --- | --- | --- | --- |
| item `1777064` "Portable Sawmill" | `9931368` Summon Portable Sawmill | `2201004` Portable Sawmill | 5 minutes |
| Tinker ability | `804707` Build: Portable Sawmill | `2201005` Compact Portable Sawmill | 2 minutes |
| (no item ships with it) | `9931369` Summon Compact Portable Sawmill | `2201005` Compact Portable Sawmill | 5 minutes |

The Lumber Axe stands on both Book of Artisans shelves (creatures `57500` and
`57524`). The portable sawmill item is the realm's own and is not on sale in this
repository, so the road to a sawmill that needs nothing bought is the Tinker
ability `804707`.

The spells themselves, read from the client's own `Spell.dbc` with
[`apps/coa-dbc`](../../apps/coa-dbc/README.md):

| Spell | Calls the object | Build | Cooldown | Object lifetime | Reach |
| --- | --- | --- | --- | --- | --- |
| `9931368` Summon Portable Sawmill | `2201004` | 10 s | 1 hour | 5 minutes | 5 yd, `Interact Range` |
| `804707` Build: Portable Sawmill | `2201005` | 10 s | 20 minutes | 2 minutes | self |
| `9931369` Summon Compact Portable Sawmill | `2201005` | 10 s | 1 hour | 5 minutes | 5 yd, `Interact Range` |

Each of them is two effects: `SPELL_EFFECT_TRANS_DOOR` (50) at effect 0 with the
gameobject in `EffectMiscValue[0]`, and `SPELL_EFFECT_SUMMON` (28) at effect 1
with creature `289612` in `EffectMiscValue[1]` - the lumberjack who works the
bench, in the same fifteen lines. A sawmill is therefore planted at the
destination the client sends, which for a player is the ground under their own
feet, and it is a ten-second build rather than an instant one: a cast in
progress when the player moves is interrupted, and the object never appears.

## Why the module exists

Before these rows existed, `2201004` was **not in the database at all**. The
shop item cast a summon for a gameobject the server had never heard of, so using
it produced no error, no message and no sawmill - it simply cost money.
`2201005` did exist, but as a guess: named "Portable Sawmill", display `1248`
(`PeasantLumber01`), size 1.0.

Both templates are recoveries, not inventions. They come from the live client
caches, which store the gameobject templates every realm's client has seen -
`gameobjectcache.wdb` in the archived realm dumps, and the same rows in the
datamine's own cache dump. Across every cache held, exactly two templates carry
the woodworking focus `1653`:

| Entry | Name | Display | Scale | Focus | Reach |
| --- | --- | --- | --- | --- | --- |
| `2201004` | Portable Sawmill | `1015620` | 1.0 | 1653 | 50 |
| `2201005` | Compact Portable Sawmill | `1015620` | 0.5 | 1653 | 50 |

`1015620` is
`world\expansion05\doodads\human\doodads\6hu_lumbermill_workbench02_nocollision.m2`,
which the installed client carries. `1653` is what `SpellFocusObject.dbc` names
"Sawmill", and it is the focus field every Refine recipe carries, so the chain
is closed by construction: the item summons the entry the recipes look for.

## What it does not do

It does not decide where a sawmill counts. That is `mod-woodworking`, which
accepts a sawmill placed through this module *and* the twenty spots the client's
own map addon marks. This half is only the object.

## The report

The module logs the chain at startup, because its failure mode is silence:

```
module.portablesawmill  Summon Portable Sawmill (spell 9931368) places gameobject 2201004: display 1015620, focus 1653, reach 50 yards, scale 1.
module.portablesawmill  item 1777064 (Portable Sawmill) ready: summons gameobject 2201004.
```

Any of the three ways the chain can break - a missing template, a summon spell
that points somewhere else, an item that casts a different spell - is an
`ERROR` line naming the entry and what was expected, instead of an item that
quietly does nothing.

## Verified

`apps/coa-gameplay-test/scenarios/woodworking-refine-sawmill.json` places a
Portable Sawmill through the item's own use handler and then refines at it, away
from every marked sawmill place, and checks that the object is there within 20
yards and that the cast pays a plank. It passes against this module:

| Assertion | Observed |
| --- | --- |
| Refine is refused 411 yards from the nearest marked place | `SpawnCastFailed` 102, no plank produced |
| The same cast at the Eastvale marked place, nothing placed | accepted, one Forestwood Plank |
| The Portable Sawmill item placed gameobject `2201004` | one object within 20 yards |
| Refine at the placed sawmill, away from every marked place | accepted, a second plank |

The build's ten seconds matter to the test as much as to the player: the first
draft of the scenario asserted two seconds after the use and saw nothing,
because the second half of the cast - the part that places the object - had not
yet run.
