# Timer spacing arms (`behaviour_metric_delta`, `kind: "timer_spacing_arms"`, ADR 1195, provisional)

An internal timer ("Can occur only once per sec.") bracketed by two real hits spaced on either side of it. `spell` is
learned; each of two arms makes two real `hit_spell` casts, the second with the harness `cast` key `ignore_gcd`
(owner ruling O-17), `gaps[0]` ms (blocked arm, inside `[timer - 10%, timer)`) and `gaps[1]` ms (allowed arm, inside
`(timer, timer + 10%]`) after the first. The generator refuses gaps outside those bands.

- `variant: "cooldown_cut"`: each arm casts `cooldown_spell` and restores the charges of `hit_spell`; both hits are
  critical heals on the caster (`force_crit` fixture, `caster_health_pct` before each). The cut per proc is
  `|cut_spell Effect[cut_effect]|` from the DBC. The judge counts the whole cuts in
  `RecoveryTime - read - elapsed`, elapsed bounded below by the summed step `elapsed_ms` from the cooldown cast to the
  read and above by that sum plus `max_step_ms` per step; a window holding more than one whole count is unmeasured.
- `variant: "chain_copy"`: each arm seeds `seed_spell` on the primary dummy and hits it twice; the effect is the count
  of new `aura_spell` copies of the caster on `spares` spare dummies within `radius` yd.
- `variant: "chain_control"` (ADR 1213, provisional): `chain_copy` with a control arm before `spell` is learned:
  the same seed and two hits `gaps[1]` ms apart must give no new copy (else `alert`); its spacing must lie in the
  allowed band and its opening cast count 1 (else `unmeasured`); the later arms then count 2 and 3 opening casts.

Judge: every read present, each arm's measured spacing (`event_interval_min_ms` of the hits since the arm's opening
cast; critical heals only for `cooldown_cut`) inside its band, and two critical heals per `cooldown_cut` arm, else
unmeasured; then ok only for 1 effect in the blocked arm and 2 in the allowed arm. Sun Cleric: Hope 300349 (Daybreak
503624 cutting Conquest 800764) and Censure 300371 (Horusath Blast 572801 on a Chains of Light 806697 target).
