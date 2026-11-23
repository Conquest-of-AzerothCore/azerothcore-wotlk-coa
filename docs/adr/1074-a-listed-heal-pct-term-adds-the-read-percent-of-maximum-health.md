# 1074. A listed HEAL_PCT term adds the read percent of maximum health to the heal model

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor D-295 (lr1 tool note TN-4)
- Related: ADR 1070 (listed block value term, the same read-and-add pattern)

## Context

Solar Prayer 806479: "instantly healing you for $s1% of your maximum health plus an additional ${$m2+0+$SP*1}".
Effect[0] is `SPELL_EFFECT_HEAL_PCT` (BasePoints 24 + DieSides 1 = 25), Effect[1] `SPELL_EFFECT_HEAL`. `hits.hit_kind`
knows `HEAL` (10) only, so the hit model priced Effect[1] alone (0.8 x 150 = 120) while the measured heal (477) holds
both: `Spell::EffectHealPct` (SpellEffects.cpp:2604-2621) heals `SpellHealingBonusDone(CountPctFromMaxHealth(25))`
into the same heal event as Effect[1]. `spell_bonus_data` 806479 is all zero, and the behaviour entries `heal_base`,
`heal_half_health` and `heal_sp` read 0.8 x (25% of maximum health + 150 + spell power): spell power stays on
Effect[1].

## Decision

- Class-file entry `heal_pct_terms`: `{spell, effect, source}` on the rank, opt-in per class; the effect must be
  `SPELL_EFFECT_HEAL_PCT` with a fixed value (DieSides 0 or 1, no points per level), and the percent is BasePoints +
  DieSides from the DBC.
- The rank's hit scenarios read the healed unit's `max_health` (`heal target max_health`: the caster, or the ally for
  an ally heal) after the hit reads; the label joins the model's `measurements`. A dual-target or non-heal model with
  an entry is refused.
- `hits.measured_hit_model` passes `floor(max_health x percent / 100)`, computed in float as
  `Unit::CountPctFromMaxHealth`, to `rank_hit`; `expected_hit` adds it as its own part under the same healing
  modifiers (`done`, floored per effect as the engine floors each effect's `SpellHealingBonusDone`). Displayed tokens
  are unchanged. A missing read is a missing measurement. The generation reference mean leaves the term out (the
  maximum health is not known before the run); its sigma, and so the cast count, is unchanged.

## Consequences

- Only the listed rank's hit scenarios change (one read and the rule text). Finished classes regenerate
  byte-identical (lr3 report).
- Tests (`test_hits.py`): a listed rank reads `max_health` and an unlisted one does not; the measured model rises by
  floor(447 x the heal modifiers) at 1788 maximum health; the plain mean alerts (mutant: term missing); no read
  raises the missing measurement; the truncation follows `CountPctFromMaxHealth`; a non-HEAL_PCT effect is refused.
- `SPELL_EFFECT_HEAL_PCT` with a rolled value, on a periodic or dual-target heal, or in a scripted hit model is not
  handled.
