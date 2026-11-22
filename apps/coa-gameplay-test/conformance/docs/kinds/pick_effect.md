# Pick effect (`behaviour_metric_delta`, `kind: "pick_effect"`, ADR 1163, provisional)

A real cast applies one aura of a set at random ("applies a random empowerment"), and each aura has its own stated
effect. Every trial removes all `picks` auras from the caster (`set_aura` with 0 stacks), reads the judged states,
makes a real cast of `cast_spell` at the caster (mana `cast_power`, cooldown reset, its CasterAuraSpell set, waiting
its cast time plus 1600 ms, or `wait_ms` when longer), then reads which pick auras are on the caster and the same
states again. `control_trials` trials run before `spell` is learned, `trials` (at least 20) after it. The
fixture's weapon skills are set with `refresh_stats` (ADR 1180, provisional), so the stat fields the first trial
reads are current: `Player::SetSkill` alone leaves the melee and ranged critical strike chance at the value of the
skill before the fixture, and the first aura that recomputes them would move them by more than its own amount.

Each pick is `{aura, label_suffix, quote, reads}`, one verdict `<spell> behaviour_metric_delta <label_suffix>` each.
A read is `{metric, fields, ratio | gain, tolerance}` with `metric` one of `cast_speed_multiplier`,
`attack_time_ms`, `spell_crit_chance`, `melee_crit_chance`, `spell_healing_taken` and `melee_damage_taken` (the
dummy, added to the scenario, is its attacker): the after read over the before read (`ratio`) or less it (`gain`)
within `tolerance`. The change must be more than twice the tolerance away from no change.

Verdict of a pick: alert when a control trial leaves any pick aura, when a trial after the learn leaves other than
exactly one, when a trial that left this pick misses the stated change of one of its reads, or when a trial that left
another pick changes one of them; unmeasured when no trial picked it (with four picks and 48 trials, 0.75^48 =
1e-6); otherwise ok. The verdict stamps the metric `pick_effect` (readback, gated by `CONTRAST_PROOF`, learned
contrast) with the promise word `empower`: an ok verdict is behaviour evidence for a clause that names the
empowerment, directly or through `promise_of`.

Witch Doctor: Loa's Blessing 705848 `pick_haste` (Ferocity of Bethekk 802207: cast speed, main-hand and ranged attack
time / 1.03), `pick_healing` (Vitality of Sseratus 802208: healing taken x 1.03), `pick_crit` (Cunning of Quetz'lun
802215: spell and melee critical strike chance + 3) and `pick_physical` (Touch of Torta 802216: melee damage taken x
0.97), claims 172.0 to 175.0.
