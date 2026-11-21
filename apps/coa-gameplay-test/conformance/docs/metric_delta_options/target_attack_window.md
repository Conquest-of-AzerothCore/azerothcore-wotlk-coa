# Target attack window (`metric_delta` `target_attack_window`, ADR 1027)

`target_attack_window` is `{"engage_ms": n, "land_ms": n}`, for an entry whose trigger is cast at the dummy in the
treatment phase only (`gate_timing` `start`, `trigger_only_after`, no expiry read; the trigger's target is the dummy
or, for a self cast, the caster, ADR 1132, provisional) and whose reading is
`melee_attacks_taken` of the caster from the dummy (`fields` `{"target": "dummy"}`). At the start of the control phase
the dummy starts to melee the caster (the harness `creature_attack`: react state aggressive, `CreatureAI::AttackStart`)
and is given `engage_ms`; each judged reading then counts the dummy's swings at the caster over `wait_ms`, from a
snapshot taken at the start of the control window and `land_ms` after the treatment cast (`relative_to`). The dummy
keeps attacking between the phases. Absent, the scenario is unchanged.

Named points: `phase_steps` (the attack and the control window), `after_trigger_steps` (the treatment snapshot) and
`fixtures` (the relative reads).

Witch Doctor: Amphibimorph 500952 `frog_pacified` (at least 2 swings in the control window, 0 under the frog) and
Death Draught 602220 `draught_ignored` (a self cast: the dummy stops swinging at the feigning caster).
