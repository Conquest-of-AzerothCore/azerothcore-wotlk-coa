# Parried restore (`behaviour_metric_delta`, `kind: "parried_restore"`, ADR 0801, amended by ADR 0820 and ADR 0850)

A restore on parry, as a percent of the missing health and Rage. One aggressive, stationary attacker (`attacker_entry`,
default 36, `attacker_auras` set from itself, here Self Root Forever (No Visual) 42716 to keep it in front) melees the
caster after one engaging swing. Two arms of `cycles` cycles of `cycle_ms` each: the control with `spell` unlearned,
then the treatment with it learned. Every cycle sets the caster's dodge and parry to 0% and 100%
(`set_combat_avoidance`, a named precondition fixture of both arms), its health to `health` (`[value, maximum]`) and
its Rage to `rage` (raw), reads the health, maximum health, Rage and maximum Rage right after, then its baseline: the
swings and parried swings (`melee_attacks_taken` from the attacker, `victim_state` 3) and the cumulative events of
`heal_spell` and of `energize_spell` (Rage). It waits and reads the same counts, the health, maximum health and Rage.
Each arm reads the counts once more after its last cycle. Only the events between a cycle's baseline and its end
reads are its judged window (ADR 0850): a swing in the read and set gap before a baseline, or after the last cycle, is
counted and reported in the explanation, adds to its cycle's swing count, and a parried one passes only when the gap's
events number its parried swings and total the restore at the next cycle's set state or, when the previous window
took no swing, the previous one's; otherwise it alerts. Control gap events count as control events. A swing
read during a read sequence (events without a swing on one side, the swing on the other) is moved into its cycle and
named in the explanation (`split across a read sequence`). `cycle_ms` must be shorter than
`attacker_swing_ms`, so a cycle holds at most one swing, taken from the state read at its start.

The percent is `$s1` of `percent_spell` (EffectBasePoints[0] + 1, a fixed value). Two labels, `<spell>
behaviour_metric_delta <label_suffix>_health` and `_rage`. In each treatment cycle the events must number its
parried swings and total its parried swings times the percent of the missing value read at its start, truncated
(`missing * s1 // 100`); the control arm must have no event. A treatment cycle whose health (or Rage) at its end is
not its start plus its events took a foreign change (run 20261116-113712: about 18 health and 1 to 2 Rage lost every
6 to 9 s without a swing, source not identified) and is left out, counted in the explanation with the parried
swings it held. Only a cycle without a parried swing may be left out: an excluded cycle that held one is named in
the explanation and alerts (or is named in the unmeasured reason when too few parried swings stay judged), since its
restore cannot be told from the foreign change (ADR 0820). A missed swing
(neither parried nor a hit) is not judged. Two swings in a cycle, a moved maximum health, nothing missing at the
start, or an arm with fewer than `min_parried` judged parried swings leave the verdict unmeasured. The metric
`parried_restore_gain` is an event read (the module's own `METRIC_EVIDENCE` row).

Witch Hunter: Dark Riposte 503659 (`$504475s1` = 5): 574335 heals and 503659 energizes Rage, 40 cycles of 1000 ms
against a 2000 ms swing, health 400000 of 1000000, Rage 200.
