# 0009. Sunwalker doubles the value of Vow of Light once

- Status: accepted
- Date: 2026-11-22

## Context

Sunwalker 704934, Spell.dbc text: "Dealing melee damage now generates a stack of Sunwalker. In addition, the value of
Vow of Light is doubled." Its effect 1 is `SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_ALL_EFFECTS`, BasePoints 99 (+100%),
on class mask word 2 `0x20000000`. In family 33 of the server Spell.dbc only Vow of Light 807750 carries that flag.

Vow of Light 807547 copies a share of the direct healing and damage its holder takes to the nearest ally as 505197
(`AscensionSunClericEvents.cpp`). The share is `Amount(807750, 0, player)`, 10 without modifiers. The caster argument
came with #10006 (#9780, "Taking Vows raises Vow of Light's copied heal to 15%"): it applies every spell modifier on
807750, Sunwalker's +100% included. The script also multiplied the share by 2 while the caster had 704934, a rule
older than the caster argument, so Sunwalker doubled the value twice. Measured on batch 4 (build f9da39a93c31) with
an 1100 Light of the Naaru 41394 heal per phase: the cumulative copy read 110, then 550, a second copy of 440 (10% to
40%).

Spell modifiers on 807750 in the server Spell.dbc: Taking Vows 300331 (`SPELLMOD_EFFECT1` +5), Holy Giant 681337,
Sunwalker 704934 and Soul of Light 807964 (`SPELLMOD_ALL_EFFECTS` +100%), Dawn 807444 and 823780 (`SPELLMOD_EFFECT1`),
and 823764.

## Options

- Drop the script's x2 and keep the caster argument: the spell modifier doubles the value once, and Taking Vows keeps
  its +5.
- Keep the x2 and read 807750 without the caster: Taking Vows would lose its +5 again (#9780).

## Decision

The first option (mentor decision D-62, 2026-11-22). The share is `Amount(807750, 0, player)`, doubled by Fulfillment
as before.

## Consequences

- With Sunwalker the copied heal is 20%; without it, 10%.
- With Taking Vows as well, `Unit::ApplyEffectModifiers` applies `SPELLMOD_ALL_EFFECTS` before `SPELLMOD_EFFECT1`, so
  the value reads 10 x 2 + 5 = 25 (not measured; no claim covers the combination).
- No other class reads 704934, 807750 or 505197.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-sunwalker-doubles-vow-of-light.json`, a control without
  Sunwalker (ratio 0.10) and a Sunwalker arm (ratio 0.20). `sun-cleric-vow-of-light-taking-vows-9780.json` still holds
  15% with Taking Vows.
