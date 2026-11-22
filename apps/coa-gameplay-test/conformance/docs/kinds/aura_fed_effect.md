# Aura fed effect (`behaviour_metric_delta`, `kind: "aura_fed_effect"`, ADR 1025, provisional)

The effect of a proc-granted aura, with the aura earned for real instead of set by the harness. Control trials cancel
`aura` and cast `effect_spell`; treatment trials run the harness step `cast_until_aura` (owner ruling O-17): `feed_spell`
every `every_ms` ms until `aura` is on the caster, at most `max_casts` casts, then wait out the feed's duration and
cast `effect_spell`. `max_casts` is computed, not written: the miss chance per feed cast is
`(1 - ProcChance(spell))^ticks`, ticks = duration / amplitude of the feed's effect 0, plus one with
`SPELL_ATTR5_EXTRA_INITIAL_PERIOD`, and the cap keeps the chance of an unfed trial at most `residual_target` per pair
(two runs, `trials` feeds each). `every_ms` must exceed the feed's duration and the global cooldown.

Every trial reads `aura` right before the judged cast: 0 in the control, 1 in the treatment, else the run is unmeasured
(a feed that reached its cap is never ok).

- `variant: "instant"`: one trial per arm; `casting` 300 ms after the cast reads 1 in the control and must read 0
  (`expected` 0) in the treatment, and `spell_go_count` of `effect_spell` read after the cast must rise by 1 per
  trial: a fed cast that did not go off alerts, a control one makes the run unmeasured.
- `variant: "damage"`: `trials` per arm, non-critical hits only; the mean fed hit must be `expected` times the control
  mean within `expected * EffectDieSides[0] / control mean`.
- `variant: "damage"` with `sized: true` (ADR 1033, opt-in; absent, the band above is unchanged): `aura`
  Effect[`figure_effect`] (default 0) must be `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE` and `expected` must equal 1 plus
  its value / 100 (the figure f), else the entry is refused. The 99% Welch-t interval of the fed to control mean hit
  ratio must lie wholly inside [1 + 0.9 f, 1 + 1.1 f] (G-19); an arm with fewer than `min_hits` non-critical hits
  (2 to `trials`) makes the run unmeasured. `consumed` is required: `true` when the tooltip says "next" or that the
  aura is consumed, which adds a second `effect_spell` cast right after each fed one that must be back at the control
  mean within `EffectDieSides[0] / control mean`; `false` judges no second cast. Size `min_hits` (the hit count whose
  interval keeps a false alert at the residual) and `trials` (the cast count that keeps an arm below `min_hits` at the
  residual) before the run and state the sizing in the entry; a `fixture` spell power narrows the dice share
  (`Unit::SpellDamageBonusDone`, Unit.cpp:9973, multiplies the whole hit). Sized entries run on the accelerated
  scenario cap.
- `variant: "heal"` or `"heal_<suffix>"` (ADR 1033): `trials` per arm, the feed and effect cast at an ally set to 1
  health of a 2000000000 maximum before every trial; `chance_spell` (default `spell`) gives the ProcChance, one roll
  per feed cast. `aura` Effect[0] must be `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE` and `expected` must equal 1 plus its
  value / 100 (the figure f), else the entry is refused. Non-critical heals on the ally only: the 99% Welch-t interval
  of the fed to control mean ratio must lie wholly inside [1 + 0.9 f, 1 + 1.1 f] (G-19), and a second `effect_spell`
  cast right after each fed one (the `next` read) must be back at the control mean within
  `EffectDieSides[0] / control mean` (consumed once). Size `trials` before the run from the heal's measured spread; a
  `fixture` spell power narrows the dice share.

- `variant: "cooldown"` (ADR 1037, opt-in): a real `effect_spell` cast (cooldown from `CategoryRecoveryTime`) is
  followed by the feed every `every_ms` until `aura`; the cooldown read right after the aura is the reset, judged only
  when at most two feed casts went off (`spell_go_count` of the feed); control trials read the natural cooldown at the
  same times. The effect cooldown is then reset as a fixture and the effect is cast (A), read 500 ms later
  (`cooldown_ms`, readback) and cast again (B): B goes off in the treatment and is refused in the control, and a third
  cast (C) is refused. `trials` must keep a run without a judged reset trial at most `residual_target` per pair;
  `expected` is 0.
  `evidence_metric: "cast_failure"` (opt-in, cooldown variant only) stamps the verdict with `cast_failure`, the
  recast reads, instead of the readback `cooldown_ms`; without it the stamp is unchanged.
- `variant: "cooldown_reset_recast"` (ADR 1037 addendum, opt-in): every trial resets the effect cooldown as a
  fixture, casts the effect for real (primer) and reads `cooldown_ms` after the global cooldown; treatment trials then
  feed until `aura`, control trials cast no feed. After the global cooldown the effect is cast again (R): R goes off
  (`cast_failure` 0, `spell_go_count` +1 over the primer) in the treatment and is refused with
  `SPELL_FAILED_NOT_READY` in the control. Only treatment trials whose aura came at the first feed cast are judged (a
  selection on the aura timing, never on R). A refused feed cast or a primer read not natural within 10% voids the
  run (unmeasured); the control's refusal of R is the judged read. The verdict is stamped `cast_failure`. `trials`
  must keep a run without a selected trial at most `residual_target` per pair (15 at ProcChance 40 and 0.001).
- `variant: "heal_rate"` or `"heal_rate_<suffix>"` (ADR 1065, opt-in): a proc rate per feed heal, no control arm.
  `feed_target` is `ally` or `self`; each of `rolls` rolls sets the feed target to 1 health of a 2000000000 maximum,
  cancels `aura` on the caster, casts `feed_spell` once at the target and, after the cast time + 500 ms, reads `aura`
  on the caster and `spell_heal_count` of the feed on the target. A heal count not exactly +1 per roll, a last feed
  cast failure other than 0, or (ally) an effective feed heal on the full-health caster voids the run. The Wilson
  interval at `residual_z(residual_target)` must lie inside the G-20 band (`procs.rate_band`) around ProcChance of
  `chance_spell`; wholly outside alerts, straddling is unmeasured with the needed roll count (`residual_sizing`,
  `min_detectable`). `haste_aura` (opt-in) sets a casting-speed-only aura (`SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK`,
  no proc, family or class mask, else refused) before the rolls, reads the feed's cast time and casts with
  `ignore_gcd`; the roll step shrinks to the hasted cast time + 500 ms.

Sun Cleric: Dawn's Arrival 503690 (`cooldown` with `evidence_metric`, label `fed_cooldown`;
`cooldown_reset_recast`, label `fed_reset`); Spears of Glory 804629 (Radiant Flame 806060 feeding 807299,
Dawnsear 554406 instant and +25%, the
+25% sized with `figure_effect` 1, `min_hits` 4, 14 trials and `consumed`); Cultivate
Divinity 704920 (`heal` and `heal_cascade`: Radiant Cascade 500141 and Illumination 500143 feeding each other's +20%;
`heal_rate_*` self and ally rate arms of both tiers, with and without Fast Cast 50336).
