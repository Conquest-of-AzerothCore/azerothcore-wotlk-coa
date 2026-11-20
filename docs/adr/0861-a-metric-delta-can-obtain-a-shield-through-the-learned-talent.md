# 0861. A metric delta can obtain a shield through the learned talent

- Status: accepted
- Date: 2026-11-16

## Context

Witch Hunter has no Shield proficiency at the start (`ClassProficiencies` holds no 9116). The talent Pavise Crossbowman
681453 teaches it (`TalentProficiencies {15, 681453, 9116}`, hook in `AscensionWitchHunterDefenses.cpp:207-212`).
Pavise 520865 needs a shield (`EquippedItemClass 4`, subclass mask 64). The weapon-set machinery equips the set before
any learn and sets the weapon skill lines with `set_skill`, so it cannot show a shield that equips only after the talent.

## Options

- Put the shield in a weapon set (set before the learn, `set_skill` of skill 433): the proficiency would not be proven.
- Add a harness action for a shield: a harness change.
- An opt-in `metric_delta` option that adds and equips the shield inside the phases (mentor D-303, category A, D-293).

## Decision

`metric_delta` takes `shield_after_learn: {item, slot, rejected_before}`. With `rejected_before` the before phase's
equip is refused and the after phase's succeeds; the slot is read in each phase and judged.

## Consequences

- Test: `ShieldAfterLearnTests` (metric_delta_options/test_shield_after_learn.py), with mutants that alert (a shield
  equipped before the learn, no shield after).
- Only entries that set the option change; the Templar and Necromancer digests are unchanged.
