# 1202. A heal variant of `aura_fed_effect` and a `pre_cast` sequence for `attacker_miss_share`

- Status: proposed (provisional number, numbered at merge; the next free shared number on the class branch, where
  1028 to 1032 are taken)
- Date: 2026-11-22
- Builds on: [ADR 1189](1189-a-hit-chance-debuff-is-read-on-the-attackers-miss-share.md),
  [ADR 1195](1195-sequenced-casts-earn-a-proc-aura-and-space-hits-around-a-timer.md)

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
2. `aura_fed_effect` damage option `sized` (mentor rulings D-183 and D-186, opt-in): the same judge for the
   `damage` variant. The figure f is the value of the aura effect `figure_effect` (default 0), which must be
   `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE`; that modifier multiplies the whole hit, spell power part included
   (`Unit::SpellDamageBonusDone`, Unit.cpp:9973), and the generator refuses an `expected` other than 1 + f. The 99%
   Welch-t interval of `bonus_of` must lie wholly inside [1 + 0.9 f, 1 + 1.1 f]. The entry fixes two sized counts:
   `min_hits`, the non-critical hits per arm at which the interval keeps a false alert within the residual (fewer is
   unmeasured, not judged), and `trials`, the casts per arm that keep an arm below `min_hits` within the residual.
   `consumed` is stated per entry: `true` when the tooltip says "next" or that the aura is consumed, which keeps the
   second-cast read of the heal variant; `false` judges no second cast. Sized entries run on the accelerated
   scenario cap, as the heal variant does. The heal variant shares the judge and keeps its floor of two heals.
3. `attacker_miss_share` option `pre_cast`: spells cast at the first attacker, each followed by its cast time, before
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
- An unsized damage entry keeps the dice-spread band of ADR 1195: it separates a bonus from none, not from a bonus
  10% off. `sized` is the opt-in that separates the figure from a bonus 10% off; no finished class has an
  `aura_fed_effect` entry, and the generated scenarios of classes 15, 19 (with `--stack`) and 23 are byte-identical
  before and after it.
- Seeded `sized` tests in `kinds/test_aura_fed_effect.py`: +25% ok; 1 + 0.5 f, 1 + 0.85 f, 1 + 1.15 f and none
  alert; an interval too wide for the band alerts; a second cast still fed alerts; an arm below `min_hits` is
  unmeasured; a wrong `expected`, a `figure_effect` off `SPELLMOD_DAMAGE`, a `min_hits` out of range, a missing
  `consumed` and a sized non-damage variant are refused.
- Sun Cleric 804629 `fed_damage` turns `sized` on (Effect[1] 25%, `consumed` true for "Your next Dawnsear"), at
  spell power 20000, 14 trials and `min_hits` 4, sized in the entry from the earlier pair's hits.
