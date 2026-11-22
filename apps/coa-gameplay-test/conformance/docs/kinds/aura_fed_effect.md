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
- `variant: "heal"` or `"heal_<suffix>"` (ADR 1033): `trials` per arm, the feed and effect cast at an ally set to 1
  health of a 2000000000 maximum before every trial; `chance_spell` (default `spell`) gives the ProcChance, one roll
  per feed cast. `aura` Effect[0] must be `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE` and `expected` must equal 1 plus its
  value / 100 (the figure f), else the entry is refused. Non-critical heals on the ally only: the 99% Welch-t interval
  of the fed to control mean ratio must lie wholly inside [1 + 0.9 f, 1 + 1.1 f] (G-19), and a second `effect_spell`
  cast right after each fed one (the `next` read) must be back at the control mean within
  `EffectDieSides[0] / control mean` (consumed once). Size `trials` before the run from the heal's measured spread; a
  `fixture` spell power narrows the dice share.

Sun Cleric: Spears of Glory 804629 (Radiant Flame 806060 feeding 807299, Dawnsear 554406 instant and +25%); Cultivate
Divinity 704920 (`heal` and `heal_cascade`: Radiant Cascade 500141 and Illumination 500143 feeding each other's +20%).
