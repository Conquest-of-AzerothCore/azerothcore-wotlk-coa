# 1261. An avoided proc trigger can learn preconditions and hold attempt auras

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

Vengeance Is Mine 804822 procs on a dodge or a parry. The reference Felsworn cannot parry: Nether Disciple 560576
(APPLY_AURA 47 MOD_PARRY_PERCENT, whose handler calls SetCanParry(true), SpellAuraEffects.cpp:4870-4884) is not
learned, so a parry set by `set_combat_avoidance` lets the swing land and the avoided entry proves the dodge leg only.
Demonic Fortitude 805245 rolls only while Demonic Will 800209 or Hateforged Barrier 705129 is active
(AscensionFelswornEvents.cpp:44-45), and `procs.attempt_auras` was refused for any trigger but a cast.

## Decision

- `learn: [<spell>, ...]` in the avoided trigger (`proc_avoided.TRIGGER_FIELDS`): the caster learns the spells before
  the engage, in every part. Distinct positive ids other than the passive. An entry with a learn list is its own roll
  (`procs.same_roll`) and its label ends in `learn <spell>` (`procs.modifier_key`), so the entry without one keeps its
  label.
- `attempt_auras` is accepted for the avoided trigger: the auras are set on the caster in `proc_avoided.avoidance_steps`,
  before every engage and every swing interval, as a precondition fixture.
- Both are opt-in. No judge, tolerance, evidence class or closing key changes.

## Consequences

- An entry without the fields generates byte-identical scenarios: classes 15, 19, 19 --stack, 23 and 27 regenerate
  identical, and the Felsworn scenarios at the class head are unchanged.
- Felsworn: the parry leg of 804822 (`804822 proc_rate avoided learn 560576`, dodge 0, parry 100). 805245 waits for
  the aura-stack event metric (ADR 1254, provisional, not yet merged) to read its Felfury gain.
- Tests in `test_proc_avoided.py` (`AvoidedProcPreconditionTest`): the learn step before every engage, the refusals,
  the separate label, and the attempt aura set right after every avoidance step.
