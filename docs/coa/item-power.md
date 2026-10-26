# PvE Power and PvP Power

Two item stats that scale combat for players of level 60 and up. The client shows both on the character
sheet and caps each at 495 points; the server applies them with `PvePower.Enable` and `PvpPower.Enable`, both
on by default (`src/server/coa/conf/coa.conf.dist`).

## Where a point comes from

An item carries its power as an equip spell named `PvE Power (+N)` (spell id 101600 + N) or `PvP Power (+N)`
(101700 + N), N from 0 to 99. The server sums the marker spells on a player's equipped, unbroken gear and caps
the total at 495. The character sheet reads the same numbers from the client's own `ItemAddon.dbc`. Where the two
disagree the sheet shows the client's value and the server applies its marker. Values above 99 cannot be one
marker spell and exist only in the client data.

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
* The gameplay scenarios `pve-power-damage`, `pve-power-bloodforged-gives-none`,
  `pvp-power-creatures-high-risk-only`, `pve-pvp-power-stack-high-risk` and `pve-power-instance-shield` assert
  exact results on a base of 1000 (see `script_melee_damage_dealt` in the gameplay-test README). The shield
  scenario compares the same gear in the open world and in the Deadmines.
