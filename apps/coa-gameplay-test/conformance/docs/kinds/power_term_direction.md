# Power term direction (`behaviour_metric_delta`, `kind: "power_term_direction"`, ADR 1022, provisional)

A passive whose tooltip says a spell's damage gains a term "scaling with your attack power" and states no figure. The
judge proves the direction only: the gain exists, grows with attack power and belongs to the passive.

`cast_spell` is learned and cast at the dummy `casts` times in each of four arms, in this order: `control low` (base
attack power, `talent` not learned), `control high` (the attack power aura `power_aura` set), `learned high` (`talent`
learned), `learned low` (the aura removed). Before every cast the mana is set to the class file's `base_mana` when the
spell costs a percentage of it, the `attempt_auras` are set and the spell's cooldown is reset; `cast_wait_ms` follows
each cast. The caster's `attack_power` is read before each arm, and the non-critical damage total and count of the
spell on the dummy (`spell_damage_total`, `spell_damage_count`, `critical: false`) after every cast: each cast whose
count rose by one is one sample.

The verdict:

- a missing read is `unmeasured`; an aura that did not raise the attack power in both pairs is `unmeasured`;
- fewer than 10 samples in an arm is `insufficient_trials`;
- the control growth `control high - control low` with |z| (Welch) at or above the two-sided Student t quantile of
  a 0.05% per-run level (`1 - sqrt(0.999)`) at the control arms' Welch-Satterthwaite degrees of freedom alerts (3.83
  at 36 degrees of freedom, z 3.48 at infinite freedom): the damage changes with attack power without the passive;
- the interaction `(learned high - control high) - (learned low - control low)` with z (Welch standard error over
  the four arms) below the one-sided 99.9% Student t quantile at its Welch-Satterthwaite degrees of freedom alerts:
  the passive adds no damage that grows with attack power;
- otherwise `ok`, worded "direction only: no figure judged", with the means, the attack powers, the growths, each z
  and its quantile with the degrees of freedom in the text.

Every judged verdict ends with "fixture: <power aura name> <id> set by harness set_aura on the caster for the high
arms", followed by each `attempt_auras` spell with its stacks. The contract states both levels: the control check's
false alert is 0.05% per run and 0.1% per pair (D-197); a false pass needs the interaction above its quantile in both
runs, at most 0.1% per run (mentor D-127; the quantile is `stack.student_t_quantile`).

Entry fields: `spell`, `name`, `quote`, `talent`, `cast_spell`, `power_aura` (a spell with aura 99
`SPELL_AURA_MOD_ATTACK_POWER`), `power_aura_source`, `casts` (at least 10), `cast_wait_ms`, optional `attempt_auras`
(`[{"spell", "stacks", "source"}]`) and `label_suffix` (default `power_direction`). An entry with `expected`,
`expected_gain`, `coefficient` or `tolerance`, or a quote holding a digit, `$` or `%`, is refused: a figure goes to
`stat_gain` or `hit_ratio` with its own proof.

Sun Cleric: Sun's Gift 680656 on Horusath Blast 572801, Attack Power 980 35785, beeg spellpen 823764 in every arm
(mentor D-106: direction only; the server's 0.25 x AP is unsourced and not judged).
