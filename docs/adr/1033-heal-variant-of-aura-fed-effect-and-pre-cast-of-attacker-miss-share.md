# 1033. A heal variant of `aura_fed_effect` and a `pre_cast` sequence for `attacker_miss_share`

- Status: proposed (provisional number, numbered at merge; the next free shared number on the class branch, where
  1028 to 1032 are taken)
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
   treatment, else unmeasured). Only non-critical heals on the ally count (`spell_heal_count`, `spell_heal_total`).
   The figure f is the aura's Effect[0] value from the DBC; the aura must be `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE`,
   which multiplies the whole heal, spell power part included (`Unit::SpellHealingBonusDone`), and the generator
   refuses an `expected` other than 1 + f. The 99% Welch-t interval of the ratio of the mean fed heal to the mean
   control heal (`bonus.bonus_of`, the interval of `hit_ratio`) must lie wholly inside [1 + 0.9 f, 1 + 1.1 f], the
   G-19 band (mentor ruling D-183); an interval partly outside it alerts. The trials are fixed in the entry, sized
   before the run from earlier measurements of the heal's spread; a spell power fixture narrows the dice share. A
   second effect cast right after it must read the control mean again within the effect's dice spread: the aura is
   consumed once.
2. `attacker_miss_share` option `pre_cast`: spells cast at the first attacker, each followed by its cast time, before
   `cast_spell` in every treatment cycle. `settle_ms` and `cycle_ms` must cover the whole sequence. The aura read on
   every attacker at each cycle end is unchanged: a cycle without it makes the verdict unmeasured, never a miss sample.

## Consequences

- Absent by default: the generated scenarios of classes 15, 19 and 23 are unchanged (checked byte for byte before and
  after).
- Seeded tests in `kinds/test_aura_fed_effect.py` (ratio, consumed twice, missing aura, step shape; a sized heal
  at +20% is ok, +10%, +17%, +23% and none alert, an interval too wide for the band alerts, a wrong `expected` is
  refused) and
  `kinds/test_attacker_miss_share.py` (sequence order, short settle and cycle refused).
- Sun Cleric 704920 `fed_heal_illumination` (variant `heal`) and `fed_heal_cascade`, at spell power 20000 and 12
  trials per arm. No Sun Cleric entry uses `pre_cast` yet: the Herald of Dawn entry was left out until its casts can
  wait out pushback.
- The damage variant keeps the dice-spread band of ADR 1025: it separates a bonus from none, not from a bonus 10%
  off. Changing it is left to a separate decision.
