# 0420. Additive percent reads and a removal control for a permanent immunity

- Status: accepted
- Date: 2026-11-13

## Context

Two Necromancer B3 claims need a judge or a control the tool did not have.

- Chilling Presence 300958: "Increases critical strike chance of all party and raid members by $s1%. Does not stack
  with similar effects." Aura 290 SPELL_AURA_MOD_CRIT_PCT adds 3 percent points to a crit chance (5.25 becomes 8.25).
  `party_stat_ratio` judges the ally's after reading over its before reading against a factor, and
  `group_stack_cap` multiplies the baseline by (1 + percent / 100), so neither can state "+3 points".
- Lich Form 500981: "While Undead, you are immune to fear, sleep, and charm effects." The aura is permanent
  (DurationIndex 21). The `immunity` kind proves its control by waiting for the aura to expire and refuses an aura
  without a finite duration.

## Considered options

1. Express the crit gain as a factor computed from a measured baseline. Rejected: the factor would depend on the
   reference character's base crit, an expectation derived from the run itself.
2. Read the claim through `metric_delta` on the caster only. Rejected: the clause names every party and raid member,
   and `metric_delta` reads no grouped ally.
3. Add an additive relation to both judges, and let the immunity control remove a permanent aura. Chosen.

## Decision

- `party_stat_ratio` and `group_stack_cap` take `relation: "additive"`: the ally's gain (after less before) must equal
  `expected` points within `PARTY_STAT_RATIO_TOLERANCE`, the out-of-radius ally's gain must be 0; the stack cap expects
  the baseline plus the own percent alone, and the baseline plus the strongest percent, not their sum, with both
  passives. Any other relation is refused when the scenario is generated, and `group_stack_cap` refuses it with
  swings. Without the field the model carries no `relation` and every existing scenario is byte-identical
  (`generate --class 19`, `--stack`).
- `immunity` takes `remove_control: true` for a permanent aura: after the with-reads the caster's aura is removed with
  `set_aura` 0 stacks, the scenario waits the cast margin, reads the aura (`expired`, must be absent) and repeats the
  casts as the control. A finite aura with `remove_control` and a permanent one without it are refused.

## Consequences

- Chilling Presence reads the grouped ally's melee crit chance, and the caster's Frost spell crit chance with
  Electrifying Aura 560568 (spell_group 2000181, the same aura 290 area effect at +3%) as the stack-cap partner.
- Lich Form's fear and sleep immunities use the removal control; its charm immunity uses `charm_immunity`, which
  already needs no expiry.
- Tests: `AdditiveRelationTests` and `PermanentImmunityTests` in `test_behaviours.py`; a multiplied or summed reading
  and a missing removal are the mutants that must alert or be refused.
