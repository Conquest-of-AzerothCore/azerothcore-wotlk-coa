# 0970. A cast leech ratio can add a second strike to the damage

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 322.0 (Dusk Blade 802258, "Heals for $574334s1% of damage dealt.", $574334s1 = 25) has no
measured label. Dusk Blade strikes with both weapons: the main-hand hit is 802258 and its Effect[1] 142 triggers the
off-hand strike 803502. `cast_leech_ratio` reads the cast spell's damage only, so the heal 574335, which the server
casts on each of the two hits (AscensionWitchHunterAbilities.cpp:289-296), would be judged against the main hand
alone.

## Options

- A new kind for multi-strike leeches: a second judge for a single extra read.
- Pointing `cast_spell` at 803502: it is not castable on its own, and the main hand would be lost.
- An opt-in `damage_also_spell` on `cast_leech_ratio` (mentor line T23, D-334).

## Decision

`damage_also_spell`. The expectation is the tooltip's plain sense: X% of the damage of a both-weapon strike, main
hand plus off hand. The server code is cited only as where the amount is computed, not as the expectation's source.
The scenario adds one `spell_damage_total` read of the named spell on the dummy, labelled `<prefix> damage also`;
`behaviour_leech_ratio_verdict` adds it to the damage only when the model carries `damage_also_label`, and names
both reads in the explanation. A missing read gives the kind's missing-measurement verdict, never ok. The option refuses `auras`, which would
need a control read of the second strike too. Without the option, the scenario, model and verdict are unchanged.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: the second read follows the cast and carries the model's label; main plus off-hand damage with a
  25% heal is ok; the mutant healing the main hand only alerts; a missing second read is reported as missing and never ok; the option with
  `auras` is refused.
- The band stays the kind's: the judge compares delta = heal - damage with the expected delta and reads ok within
  max(1, 0.5% of |expected delta|) on the healing scale (1.47 heal points at 391 damage), tolerated within 5% of
  |expected delta|. The two per-hit truncations lose at most 1.5 at 25%.
