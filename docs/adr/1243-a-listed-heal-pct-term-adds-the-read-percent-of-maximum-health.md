# 1243. A listed HEAL_PCT term adds the read percent of maximum health to the heal model

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor D-295 (lr1 tool note TN-4)
- Related: ADR 1239 (listed block value term, the same read-and-add pattern)

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

## Addendum: a superseded plain hit is closed only while its replacements hold

- Date: 2026-11-23
- Decided by: mentor D-288 and its conditions on the key (Sun Cleric 27, Justicar's Wrath 806980)

Context: the plain `806980 hit_mean` scenario casts every 2000 ms on one dummy and each landed hit re-applies 572067
(+10% spell damage taken, AscensionSunClericAbilities.cpp:342), so its hits mix one clean hit with debuffed ones by
design. Two `target_aura_gates` arms (`806980 hit_mean wrath_taken stacks 0` and `806980 hit_mean wrath_taken`) set
572067 at 0 and at 1 stack before every cast and replace it. The plain hit is generated from the class spell list,
and no class-file lever dropped a modelled hit (`hit_notes` applies only to an unmodelled rank).

Decision:
- Class-file key `superseded_hits`: `{spell (the rank), reason, replaced_by}`; `replaced_by` is a non-empty list of the
  replacing labels and may not name the hit itself; an entry without it is refused.
- `conformance.add_hit` writes the closed record an unmodelled rank with a "no check needed" note gets (check
  `unmodelled`, rule `closed: no check needed: <reason>`, no scenario), its model carrying `superseded_by`.
- `compare.judge_expectation` stamps `superseded_by` on that closed verdict; `compare.resolve_superseded` keeps it
  `closed` only when every replacing label is in the same comparison and `ok`, else `alert` naming each label's
  status (`missing` when absent).
- Finished classes may not use the key; using it needs a mentor ruling.

Consequences: the Sun Cleric 806980 hit scenarios (four parts) are no longer generated. Tests (`test_compare.py`):
the closed record without a scenario names its replacements; mutant without the key generates the plain hit as
before; entries without replacements, with an empty list, naming the hit itself or with a blank reason are refused;
the record stays closed with both replacements ok and alerts with one missing or one alert, unmeasured or tolerated.
Finished classes 15, 19, 19 --stack and 23 regenerate and audit byte-identical (lr3 report).

Addendum (lr4, mentor condition M-3): `conformance.superseded_hit` enforces the restriction in code. Outside class 27 an
entry needs a `ruling` field holding a non-blank text that names a mentor decision (`D-<number>`); without it the
generation raises `ValueError`. Class 27 needs no ruling. Tests (`test_compare.py`): a class other than 27 without a
ruling, with a blank one, one naming no decision or a non-text one is refused; class 27 without a ruling and another
class with one generate the closed record.
