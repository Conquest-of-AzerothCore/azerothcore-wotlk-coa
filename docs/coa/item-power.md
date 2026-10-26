# PvE Power and PvP Power

Two item stats that scale combat for players of level 60 and up. The client shows both on the character
sheet and caps each at 495 points; the server applies them with `PvePower.Enable` and `PvpPower.Enable`, both
on by default (`src/server/coa/conf/coa.conf.dist`).

## Where a point comes from

The server reads each item's PvE and PvP Power from the client's own `ItemAddon.dbc` (`DataDir/dbc`, fields 38
and 39 of a record), the numbers the character sheet shows, and sums them over a player's equipped, unbroken gear,
capped at 495. A value of 0 or above 1000 is not power. An item without one uses its equip spell named
`PvE Power (+N)` (spell id 101600 + N) or `PvP Power (+N)` (101700 + N) instead. If `ItemAddon.dbc` is missing the
log says so at startup and every item uses its spell.

The two sources disagree on many Bloodforged and PvP items, mostly at required level 60 and under, where the spell
holds half the client value; the file wins, so a level 60 twin gives what its tooltip says.

Bloodforged gear carries no PvE Power.

## What each point does

| Stat | Effect | Per point | Where |
| --- | --- | --- | --- |
| PvE Power | damage dealt to creatures | +0.05% | every map |
| PvE Power | damage taken from creatures | -0.05% | every map |
| PvE Power | healing and absorbs done | +0.02% | instances (dungeons and raids) |
| PvP Power | damage dealt to players | +0.05% | every map |
| PvP Power | damage dealt to and taken from creatures | +0.05% and -0.05% | High-Risk open world only |
| PvP Power | healing and absorbs done | +0.02% | War Mode and High-Risk open world, battlegrounds and arenas |

The multipliers and the 495 cap are the client's own (`Constants.lua`). The effects use exact basis points, so
the cap gives 24.75% damage and 9.9% healing. The two stats stack where they overlap, against creatures in the
High-Risk open world. Neither applies below level 60.

The maps each PvE Power effect covers are two constants in `AscensionPvePowerPolicy.h`: `DamageMaps` and
`HealingMaps`. To include or exclude a kind of map, change that line.

Code: `AscensionPvePower.cpp` and `AscensionPvpPower.cpp`.

## Tooltips

The client prints these lines with `%d`, which drops the fraction (0.9% reads 0%, the cap reads 24%):
`PVE_POWER_TOOLTIP1` to `3` and `PVP_POWER_TOOLTIP1`, `2`, `2_ALT`, `4` and `5`. `AscensionPowerTooltips.cpp`
sends them at login with `%g`, so 45 points read 2.25%, 2.25% and 0.9%. Only the text changes, not the maths.
A line can be tried in game before changing code: `.clientpush string <id> <KEY> <text>`.

## Tests

* `apps/coa-tests/pve_power` checks the marker mapping, the cap, the scaling and the map constants.
* `apps/coa-tests/item_power_table` checks loading `ItemAddon.dbc`: the two power fields, the 1000 limit, duplicate
  rows and rejected files.
* The gameplay scenarios `pvp-power-level60-client-value` (a level 60 twin gives its tooltip value, 42, where its
  spell holds 21), `pve-power-damage`, `pve-power-bloodforged-gives-none`,
  `pvp-power-creatures-high-risk-only`, `pve-pvp-power-stack-high-risk` and `pve-power-instance-shield` assert
  exact results on a base of 1000 (see `script_melee_damage_dealt` in the gameplay-test README). The shield
  scenario compares the same gear in the open world and in the Deadmines.
