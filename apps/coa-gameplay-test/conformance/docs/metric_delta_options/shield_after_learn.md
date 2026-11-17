# Shield after learn (`metric_delta` `shield_after_learn`, ADR 0861)

`shield_after_learn` is `{item, slot, rejected_before}`. The scenario adds the shield item to the caster and equips it
into `slot` inside each phase's cast steps, after the base steps and without any `set_skill` of the shield skill:
- `rejected_before` true: the before phase's equip is sent with `rejected` (the harness requires the item not to be
  equipped), the gate (the talent that teaches the shield proficiency) is learned between the phases, and the after
  phase's equip must succeed.
- `rejected_before` false: the shield is equipped once, in the before phase, for entries whose gate or setup learns
  the talent first.

Each phase reads the slot (`<spell> shield before`, `<spell> shield after`, metric `equipped_item`). The verdict is
`alert` when the shield is equipped before while `rejected_before` is true, or is not in the slot after; a missing read
is `unmeasured`.

Named points: `parse`, `phase_steps`, `model`, `verdict`.

Witch Hunter: Pavise Crossbowman 681453 (`TalentProficiencies {15, 681453, 9116}`) and Dead and Gone 705524, parts
222.0, 223.0, 271.0 and 272.0.
