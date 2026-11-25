# Power term direction (`behaviour_metric_delta`, `kind: "power_term_direction"`, ADR 1192 and 1269, provisional)

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

Options (ADR 1269; without them the scenario, model and verdict text stay byte-identical):

- `power_metric`: `agility` (the power aura carries `SPELL_AURA_MOD_STAT` of Agility, read `stat` 1) or `max_health`
  (aura 34 or 133, read `max_health`). The stat and the attack power are read before and after each arm; a high arm
  that does not read above its low arm before or after, a stat that moved inside an arm, or an attack power that is
  not the same in all eight reads is `unmeasured` (a moved fixture voids the run, never alerts; mentor D-94
  condition 4). The texts name the stat.
- `power_stacks` (default 1) and `power_companions` (`[{"spell", "stacks", "source"}]`): the power aura's stacks and
  auras set with it in the high arms and removed with it, to hold another input equal (the attack power that
  Agility gives).
- `hit_spell`: the spell whose non-critical damage on the dummy is read (default `cast_spell`).
- `cast_power`: the caster's power of the cast spell's type is set to this value before each cast (refused below its
  flat cost).
- `sample: "absorb"` with `strike_spell` and `refill_spell`: `cast_spell` effect 0 is `SPELL_AURA_SCHOOL_ABSORB`, cast
  on the caster. Before each cast the previous barrier is cleared (`set_aura` 0) and `refill_spell` (learned, cast with
  `ignore_gcd`) refills the caster; after the cast the aura's presence is read, a passive striker (creature entry 36)
  casts `strike_spell` at the caster once, the presence is read again, and the strike's `spell_absorb_total` and
  `spell_log_count` are read. A sample is the absorbed amount of a strike when the barrier was up after the cast,
  gone after the strike and the strike logged once; the model metric is `spell_absorb_total`. The strike must exceed
  the largest barrier (state the margin in the entry); an unbroken barrier is no sample. It proves the direction only,
  not that the barrier absorbs damage.

Sun Cleric: Sun's Gift 680656 on Horusath Blast 572801, Attack Power 980 35785, beeg spellpen 823764 in every arm
(mentor D-106: direction only; the server's 0.25 x AP is unsourced and not judged).

Felsworn (ADR 1269): Felcaked Blades 574145 and Felblade 574146 on Sargeron Smite 802060, Twin Slice 801901 (read on
808303) and Fel Fireball 801312, +300 Agility with the attack power held equal; Pure Hatred 803478 on Hateforged
Barrier 707527 with Infernal Constitution 805256, Ray of Pain 54416 and Full Heal 17683.
