# Aura fed effect (`behaviour_metric_delta`, `kind: "aura_fed_effect"`, ADR 1195, provisional)

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
- `variant: "damage"` with `sized: true` (ADR 1202, opt-in; absent, the band above is unchanged): `aura`
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
- `variant: "heal"` or `"heal_<suffix>"` (ADR 1202): `trials` per arm, the feed and effect cast at an ally set to 1
  health of a 2000000000 maximum before every trial; `chance_spell` (default `spell`) gives the ProcChance, one roll
  per feed cast. `aura` Effect[0] must be `ADD_PCT_MODIFIER` on `SPELLMOD_DAMAGE` and `expected` must equal 1 plus its
  value / 100 (the figure f), else the entry is refused. Non-critical heals on the ally only: the 99% Welch-t interval
  of the fed to control mean ratio must lie wholly inside [1 + 0.9 f, 1 + 1.1 f] (G-19), and a second `effect_spell`
  cast right after each fed one (the `next` read) must be back at the control mean within
  `EffectDieSides[0] / control mean` (consumed once). Size `trials` before the run from the heal's measured spread; a
  `fixture` spell power narrows the dice share.

- `variant: "cooldown"` (ADR 1206, opt-in): a real `effect_spell` cast (cooldown from `CategoryRecoveryTime`) is
  followed by the feed every `every_ms` until `aura`; the cooldown read right after the aura is the reset, judged only
  when at most two feed casts went off (`spell_go_count` of the feed); control trials read the natural cooldown at the
  same times. The effect cooldown is then reset as a fixture and the effect is cast (A), read 500 ms later
  (`cooldown_ms`, readback) and cast again (B): B goes off in the treatment and is refused in the control, and a third
  cast (C) is refused. `trials` must keep a run without a judged reset trial at most `residual_target` per pair;
  `expected` is 0.
  `evidence_metric: "cast_failure"` (opt-in, cooldown variant only) stamps the verdict with `cast_failure`, the
  recast reads, instead of the readback `cooldown_ms`; without it the stamp is unchanged.
  `evidence_metric: "aura_fed_instant_casting"` (opt-in, instant variant only, ADR 1241, provisional) stamps the
  verdict with that metric and the contrast `aura_fed`: casting 1 in the control arm (aura cancelled) against casting 0
  in the fed arm, both read 300 ms after the cast and both judged. The kind's `METRIC_EVIDENCE` (state),
  `CONTRAST_PROOF` and `STATE_PROMISES` (`instant`) rows make an ok verdict behaviour on a clause that says "instant"
  and data otherwise; judging and the ok are unchanged, and without the option the stamp stays `casting`.
- `variant: "cooldown_reset_recast"` (ADR 1206 addendum, opt-in): every trial resets the effect cooldown as a
  fixture, casts the effect for real (primer) and reads `cooldown_ms` after the global cooldown; treatment trials then
  feed until `aura`, control trials cast no feed. After the global cooldown the effect is cast again (R): R goes off
  (`cast_failure` 0, `spell_go_count` +1 over the primer) in the treatment and is refused with
  `SPELL_FAILED_NOT_READY` in the control. Only treatment trials whose aura came at the first feed cast are judged (a
  selection on the aura timing, never on R). A refused feed cast or a primer read not natural within 10% voids the
  run (unmeasured); the control's refusal of R is the judged read. The verdict is stamped `cast_failure`. `trials`
  must keep a run without a selected trial at most `residual_target` per pair (15 at ProcChance 40 and 0.001).
- `variant: "heal_rate"` or `"heal_rate_<suffix>"` (ADR 1235, opt-in): a proc rate per feed heal, no control arm.
  `feed_target` is `ally` or `self`, set once to 1 health of a 2000000000 maximum; each of `rolls` rolls cancels
  `aura` on the caster, casts `feed_spell` once at the target and, after the cast time + 500 ms, reads `aura` on the
  caster. At the end, `spell_heal_count` of the feed on the target must equal the rolls, its effective healing must
  equal its healing, the last feed cast failure must be 0 and (ally) the feed must not heal the full-health caster
  effectively, else the run is void (unmeasured). The Wilson interval at `residual_z(residual_target)` must lie
  inside the G-20 band (`procs.rate_band`) around ProcChance of `chance_spell`; wholly outside alerts, straddling is
  unmeasured with the needed roll count (`residual_sizing`, `min_detectable`). `haste_aura` (opt-in) sets a
  casting-speed-only aura (`SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK`, no proc, family or class mask, else refused)
  before the rolls, reads it at the start and end (1, else void), reads the feed's cast time and casts with
  `ignore_gcd`; the roll step shrinks to the hasted cast time + 500 ms. A roll is 5 steps: at most about 1900 rolls
  fit the 10000-step scenario limit.
- `heal_rate` pooled (`parts` > 1, ADR 1235, opt-in, the kind's `POOLED_JUDGE`): `parts` identical scenarios of
  `rolls` each, `spare_parts` (1 or more) fixed before the run, and `(parts - spare_parts) * rolls` must reach the
  band's roll count or the entry is refused. A part with any void or missing read is excluded whole; the kept parts'
  rolls pool into one Wilson interval, judged as above, and fewer pooled rolls than the band needs is unmeasured. A
  pooled hasted entry names `haste_agreement`, the step 1 agreement that justifies the haste aura, in its contract.
- `variant: "damage_rate"` or `"damage_rate_<suffix>"` (ADR 1245, opt-in): the `heal_rate` judge, sizing and pooling
  for a damage feed with a cooldown, no control arm. `feed_target` is `dummy` (one stationary dummy at the feed's cast
  distance); the feed needs a SCHOOL_DAMAGE effect and no travel, and `haste_aura` is refused. Each of `rolls` rolls
  cancels `aura` on the caster, sets the feed power, resets the feed's cooldown (`reset_cooldown`), casts it at the
  dummy with `ignore_gcd` and, after the cast time + 500 ms, reads `aura` on the caster. At the end `spell_go_count` of
  the feed and its `spell_damage_count` on the dummy must equal the rolls, the last feed cast failure must be 0 and the
  dummy must read `alive` 1 with `health` above 0, else the part is void (excluded whole when pooled). A roll is 6
  steps: at most about 1600 rolls fit the 10000-step scenario limit. `learn_talent: false` (single part, ADR 1245
  addendum) is the control arm: the talent is unlearned, the judge is `ok` only with 0 grants of `aura` over `rolls`
  rolls, any grant alerts.

Sun Cleric: Dawn's Arrival 503690 (`cooldown` with `evidence_metric`, label `fed_cooldown`;
`cooldown_reset_recast`, label `fed_reset`; `damage_rate_dawnbreak_pooled`, label `rate_dawnbreak_pooled`);
Spears of Glory 804629 (Radiant Flame 806060 feeding 807299,
Dawnsear 554406 instant and +25%, the
+25% sized with `figure_effect` 1, `min_hits` 4, 14 trials and `consumed`); Cultivate
Divinity 704920 (`heal` and `heal_cascade`: Radiant Cascade 500141 and Illumination 500143 feeding each other's +20%;
`heal_rate_*` self and ally rate arms of both tiers, with and without Fast Cast 50336, and the hasted
`_pooled` arms sized for the G-20 band: 17 parts of 1900 rolls at 40%, 12 at 20%, one spare each).

## Window variant (`variant: "window"`, ADR 1221, provisional)

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

Evidence: the verdict carries the metric `aura_fed_window_casting` with the contrast `aura_window` (aura held against
aura gone), declared in the kind's `METRIC_EVIDENCE`, `CONTRAST_PROOF` and `STATE_PROMISES` rows; an ok verdict is
behaviour on a clause that says "within" and data otherwise (ADR 1221 addendum).

Calibration reads rb7 (2026-11-22, throwaway probes, never counted): 9981 ms of 10000 left at the stop in 6 of 6
trials; 807299 sends no SPELL_GO (so no event dating); `set_moving` does not stop Radiant Flame; a 1600 ms feed gives
two ticks per cast.

Sun Cleric: Spears of Glory 804629 (ledger row 364, claim 1, "Your next Dawnsear within $d is instant cast", quoted
from 807299): `fed_window`, Dawnsear 554406 at 9300 and 10700 ms, 6 trials and at least 5 judged per side.
