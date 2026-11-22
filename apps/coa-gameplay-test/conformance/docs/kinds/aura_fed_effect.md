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

Sun Cleric: Spears of Glory 804629 (Radiant Flame 806060 feeding 807299, Dawnsear 554406 instant and +25%, the
+25% sized with `figure_effect` 1, `min_hits` 4, 14 trials and `consumed`); Cultivate
Divinity 704920 (`heal` and `heal_cascade`: Radiant Cascade 500141 and Illumination 500143 feeding each other's +20%).

## Window variant (`variant: "window"`, ADR 1052, provisional)

Judges an earned aura's stated duration through the effect it enables, on both sides of it. Fields: `feed_spell`,
`aura`, `effect_spell`, `every_ms` (at least the 1600 ms global cooldown wait), `residual_target`, `feed_power`,
`effect_power`, `trials` (per side), `min_judged` (the least judged trials per side, fixed before the run),
`held_ms` and `gone_ms` (the judged cast's delay after the stop), optional `caster_auras` and `quote_spell` (a
spell whose tooltip the entry's tooltip embeds, `@s:N:`). Each trial cancels the aura, relearns the entry's spell
(the proc talent), feeds with `cast_until_aura` until the aura is on, then unlearns the talent at once (the running
channel keeps ticking and `Chance()` rolls only while the talent is held, `AscensionSunCleric.cpp:199`), waits
4500 ms for the channel to end, relearns the talent and casts `effect_spell` at its delay. The clock is the stop:
`CastUntilAura` checks the aura on every world update, so the grant is 0 to 25 ms old there. The judged read is the
cast itself 300 ms in: instant (casting 0) at `held_ms`, its normal cast (casting 1) at `gone_ms`; the ages must lie
in 0.9 to 0.965 and 1.04 to 1.1 of the DBC duration, else that side is unmeasured. A trial is void when the talent is
not known at its start or after the relearn, the feed did not grant once, the aura is gone right after the unlearn,
the channel still runs, a tick or a re-application follows the relearn, or the cast did not go off; fewer than
`min_judged` judged trials on a side is unmeasured. `max_casts` assumes one tick per feed (conservative).

Calibration reads rb7 (2026-11-22, throwaway probes, never counted): 9981 ms of 10000 left at the stop in 6 of 6
trials; 807299 sends no SPELL_GO (so no event dating); `set_moving` does not stop Radiant Flame; a 1600 ms feed gives
two ticks per cast.

Sun Cleric: Spears of Glory 804629 (ledger row 364, claim 1, "Your next Dawnsear within $d is instant cast", quoted
from 807299): `fed_window`, Dawnsear 554406 at 9300 and 10700 ms, 6 trials and at least 5 judged per side.
