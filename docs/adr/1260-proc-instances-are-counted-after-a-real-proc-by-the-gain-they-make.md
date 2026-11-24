# 1260. Proc instances are counted after a real proc by the gain they make

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

Vengeance Is Mine 804822 gives a chance on a dodge or a parry to make the next 10 instances of Twin Slice damage deal
more damage and generate 1 Felfury each. The handler casts 807163 on the caster; its apply sets script value 807163 to
10 (AscensionFelswornAuras.cpp:84-85), and every direct Twin Slice damage instance while it is held gains 1 Felfury and
decrements the value, removing the aura at the last (AscensionFelswornAbilities.cpp:375-384). Mentor D-67 (controller
go, 2026-11-23): 807163 is the subject's product, so the treatment obtains it by the real route (804822 learned and a
dodge that procs it), and `aura_script_value` is a readback that may guard but is not judged.

Options considered: `set_aura` of 807163 then casts (refused by D-67 without a failed real route); counting boosted
damage (needs a damage model per hit); counting the Felfury gained while the aura is held.

## Decision

- Behaviour kind `avoided_proc_instances` (module `kinds/avoided_proc_instances.py`, ADR 0581 hooks; doc
  `docs/kinds/avoided_proc_instances.md`). A control arm casts `cast_spell` at a striker `casts` times before the
  passive is learned; the passive is learned; `proc_windows` dodge windows (the `proc_avoided` strikers, dodge 100)
  obtain the proc; then the same casts, each after the stack aura is set to 0, Energy set to the cast cost and the
  swings no longer avoided (dodge and parry 0).
- Two expectations on `behaviour_metric_delta`: `gain_per_instance` = the extra stacks (treatment less the control's
  own gain per cast) over the hits of the casts after which the proc aura is still held, expected 1 (the tooltip's
  "generate 1 Felfury"); `instances` = the summed extra over that measured gain, expected the tooltip's count, with the
  aura held after a cast exactly while the counted instances are below it.
- Void: no proc when the casts start, a new application during the casts (apply count), an expiry by duration, a
  control gain that varies, no held cast. The script value is read and reported only.

## Consequences

- Additive module; no finished-class scenario changes.
- The two expectations separate a wrong count from a wrong gain: a 9- or 11-instance server alerts on `instances`
  only, a 2-Felfury server on `gain_per_instance` only (tests `AvoidedProcInstancesTests`).
- The +30% damage of the instances (807163 Effect[0]) is the existing effect_value label, not read here.
