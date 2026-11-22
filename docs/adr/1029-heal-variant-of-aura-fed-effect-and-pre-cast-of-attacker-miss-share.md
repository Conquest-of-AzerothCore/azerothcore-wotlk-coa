# 1029. A heal variant of `aura_fed_effect` and a `pre_cast` sequence for `attacker_miss_share`

- Status: proposed (provisional number, numbered at merge; the next free number after 1028 in the controller's
  sequence, 1028 is not in this branch)
- Date: 2026-11-22
- Builds on: [ADR 1019](1019-a-hit-chance-debuff-is-read-on-the-attackers-miss-share.md),
  [ADR 1025](1025-sequenced-casts-earn-a-proc-aura-and-space-hits-around-a-timer.md)

## Context

Sun Cleric chunk d7, mentor ruling D-173. Two claims had no route on the existing kinds:

- Cultivate Divinity 704920 (clauses 249 and 250): "Effectively healing with Radiant Cascade has a $h% chance to
  increase the healing of your next Illumination by $301293s1%" and its mirror. The roll is `roll_chance_i`
  (AscensionSunClericEvents.cpp:338), so `forced_roll` cannot force it; setting the proc aura would make the claim's own
  aura the subject; `aura_fed_effect` knew only the `instant` and `damage` variants.
- Herald of Dawn 804630 (clause 350): "reduces the target's chance to hit by $s1% for $d". The Solar Flare comes from
  Rapture followed by Dawnsear; `attacker_miss_share` casts one spell per cycle.

## Decision

Python only, opt-in, no harness change:

1. `aura_fed_effect` variant `heal`: the feed (`cast_until_aura`) and the effect spells are cast at an ally set to 1
   health of a 2000000000 maximum before every trial; the proc chance comes from `chance_spell` (default the entry's
   spell) with one roll per feed cast. The aura is read on the caster before the judged cast (0 in the control, 1 in the
   treatment, else unmeasured). Only non-critical heals on the ally count (`spell_heal_count`, `spell_heal_total`). The
   mean fed heal must be `expected` (from the DBC, never from the ratio) times the control mean within the effect's
   dice spread, and a second effect cast right after it must read the control mean again: the aura is consumed once.
2. `attacker_miss_share` option `pre_cast`: spells cast at the first attacker, each followed by its cast time, before
   `cast_spell` in every treatment cycle. `settle_ms` and `cycle_ms` must cover the whole sequence. The aura read on
   every attacker at each cycle end is unchanged: a cycle without it makes the verdict unmeasured, never a miss sample.

## Consequences

- Absent by default: the generated scenarios of classes 15, 19 and 23 are unchanged (checked byte for byte before and
  after).
- Seeded tests in `kinds/test_aura_fed_effect.py` (ratio, consumed twice, missing aura, step shape) and
  `kinds/test_attacker_miss_share.py` (sequence order, short settle and cycle refused).
- Sun Cleric 704920 `fed_heal_illumination` and `fed_heal_cascade`; 804630 `herald_miss`.
- The heal band is the dice spread, as for the damage variant: it separates a 20% bonus from none, not from 10%.
