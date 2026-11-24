# 1184. Four harness metrics take their evidence rows

- Status: proposed
- Date: 2026-11-21

## Context

The harness (`src/server/coa/CoAGameplayTest.cpp`) and `run.py` already produce four metrics that
`coverage.METRIC_EVIDENCE` does not class: `armor_reduced_damage`, `script_melee_damage_dealt`,
`spell_done_crit_chance_scripted` and `block_value`. A class file entry that reads one of them fails the cross-class
guard `test_cross_class_guard_every_metric_of_the_class_checks_has_an_evidence_class`, so the Sun Cleric b1a and b2a
authors kept those entries out of the class file (ADR 0120: a new metric needs its row first).

What each read observes:

- `armor_reduced_damage`: `Unit::CalcArmorReducedDamage(attacker, target, 1000, info)` on a probe amount of 1000. No
  hit is dealt.
- `script_melee_damage_dealt`: `ScriptMgr::ModifyMeleeDamage(attacker, dealer, 1000)` on a probe amount. No hit is
  dealt.
- `spell_done_crit_chance_scripted`: `Unit::SpellDoneCritChance` passed through `ScriptMgr::OnSpellCritChance` on a
  probe `Spell` that is never cast.
- `block_value`: `Player::GetShieldBlockValue()`, the value the melee block path takes as the blocked amount
  (`Unit.cpp`, `damageInfo->blocked` and `damageInfo->blocked_amount`), as `block_chance` reads the player's block
  field.

## Options

- Class all four as readback.
- Class the three probe reads as readback, the same class as `melee_damage_done`, `script_spell_damage_taken` and
  `spell_done_crit_chance`, and `block_value` as a state with a `STATE_PROMISES` row, as `block_chance` and the other
  player stat reads (`attack_power`, `armor`).
- Add a `CONTRAST_PROOF` row for `spell_done_crit_chance_scripted`, as ADR 0691 did for `spell_done_crit_chance`.

## Decision

`armor_reduced_damage`, `script_melee_damage_dealt` and `spell_done_crit_chance_scripted` are `READBACK`: each is a
computation on a probe that no acting path consumed. `block_value` is `STATE` with the promise words `block value`;
a learned-contrast read proves a clause that promises block value, and never a block-chance clause (review I-1).
No `CONTRAST_PROOF` row for `spell_done_crit_chance_scripted`: a learned-contrast read of it stays data. Such a row
is a later, separate proposal
(controller decision, mentor D-33).

No existing row changes.

## Consequences

- Tests (`test_coverage.py`, `EvidenceStatusTest`): `test_the_armor_script_melee_and_scripted_crit_probes_are_readbacks`
  and `test_a_block_value_is_a_state_read_where_the_clause_promises_block_value`; each asserts the row's class,
  alerts when the row is mutated to another class, and raises without the row. The block-value test also keeps a
  block-chance clause at data.
- Generation is not touched: the finished classes' snapshot digests are unchanged.
- Number provisional: shared ADRs are numbered at merge.
