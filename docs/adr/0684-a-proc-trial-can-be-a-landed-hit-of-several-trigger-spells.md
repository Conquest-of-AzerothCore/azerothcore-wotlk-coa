# 0684. A proc trial can be a landed hit of several trigger spells

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

A `cast` proc entry counts its trials as the damage events of the one trigger spell on the dummy
(`procs.trials_step`). Dusk Blade 802258 casts its off-hand strike 803502 through Effect[1] 142
(`SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE`); the strike is Shadow, melee class, and the `spell_proc` rows of Anguish
504742 and Lightbringer 680538 (`rev_20260908_07_witch_hunter_completion.sql:17, 26`) carry
`PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS` and `PROC_ATTR_TRIGGERED_CAN_PROC`, so each cast with an off hand rolls the
proc twice. The counted pair measured 0.0983 against 5% and 0.2967 against 15% (review I-3, mentor D-55 and D-58).

## Options

- `trial_readings` with `adds`: meant for a text that leaves the trials open, judged per reading with an owner question
  when they disagree, and its added counts keep the baseline casts.
- `trials_per_attempt`: a fixed count per cast, wrong when one strike misses or is dodged.
- An optional `trigger_spells` list whose landed hits are each one trial.

## Decision

- A `cast` proc entry may list `trigger_spells` (the trigger spell first, then at least one other, each once) with
  `trigger_spells_source`. A trial is one landed hit (`spell_damage_count` on the dummy) of any listed spell: the
  single reading sums the counts, and a cast baseline reads each added spell too
  (`<aura> proc baseline trials <spell>`, `model.baseline.added_trials`), which `compare` takes out with the trigger's
  own baseline trials.
- The scenario contract names the strikes that roll the proc and carries `trigger_spells_source`, with the residual
  failure probability. The rule text says "one trial per landed hit of any listed spell".
- Refused: a non-`cast` trigger, an ally target, `trial_casts`, `trial_readings`, a list not led by the trigger spell
  or without a second spell, a repeated spell, a missing source.
- Witch Hunter: Anguish 504742 and Lightbringer 680538 list [802258, 803502].

## Consequences

- Seeded tests in `test_procs.py`: both strikes counted with the baseline taken out (ok), a seeded mutant counting the
  first spell only alerts, the Witch Hunter scenarios and contracts, every refused shape, and an entry without the
  field unchanged.
- Entries without `trigger_spells` generate the same steps, model and contract: Templar (19) and Necromancer (23)
  stay byte-identical.
- The trial sizing still counts casts, so each cast gives about two trials: the parts are larger than needed, and
  the residual failure probability is the 99% interval's.
