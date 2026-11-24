# Fed charge casts (`behaviour_metric_delta`, `kind: "fed_charge_casts"`, ADR 1272 and 1275, provisional)

The cast time cut of a proc-granted aura that lasts a stated number of casts ("Your next 3 Fel Fireballs have a $s1%
reduced cast time"), with the aura earned by a real feed instead of set by the harness (mentor D-67, D-97).

Fields: `spell` (the proc talent), `name`, `quote`, `quote_spell` (the aura whose tooltip the talent embeds with
`@s:N:`, which must say "next `charges`" and "`$sN%` reduced cast time"), `feed_spell`, `aura`, `effect_spell`,
`charges`, `every_ms`, `residual_target`, `feed_power`, `effect_power`, `trials`, `min_judged` (the least judged
trials, a minimum, not a vote), `poll_ms` (1 to 100), optional `cut_effect` (default 0) and `label_suffix`.

`aura` Effect[`cut_effect`] must be `ADD_PCT_MODIFIER` on `SPELLMOD_CASTING_TIME` with a negative value, else the
entry is refused; the figure f is minus that value (`EffectBasePoints` + 1, the tooltip's `$s`), and the base cast
time comes from the effect spell's `CastingTimeIndex` (CastingTimes.dbc). Bands: cut casts within
`[cast * (1 - 1.1 f/100), cast * (1 - 0.9 f/100)]`, the uncut cast within `[0.9 cast, 1.1 cast]`.

Each trial:
1. cancels `aura`, unlearns `spell`, reads the cast speed multiplier, and times one control cast of `effect_spell`
   (no talent, no aura): it must lie in the uncut band, else the trial is void;
2. learns `spell` and runs `cast_until_aura` with `feed_spell` every `every_ms` ms, at most `max_casts` casts
   (`ceil(ln(residual_target / (2 * trials)) / ln(1 - ProcChance))`, one roll per feed cast, conservative);
3. reads `game_time_ms` at the stop (`fed at`), unlearns `spell`, so no later tick grants `aura` again or resets its charges, then reads `aura`
   present, `spell` unknown, the application count, `aura_amount` of Effect[`cut_effect`] and the used-charge
   script value, and the cast speed multiplier again;
4. casts `effect_spell` `charges + 1` times with `ignore_gcd`, one per slot (the uncut band's last poll + 100 ms);
   each cast reads `aura` and the cast count before it, is stamped by `game_time_ms` right before and after the cast
   step, and is polled every `poll_ms` from 50 ms before its band to 50 ms past it, each poll a cast count between
   two `game_time_ms` stamps. The cast time lies after the last pending poll's first stamp minus the sent stamp and at
   or before the first completed poll's last stamp minus the start stamp. Generation refuses an entry whose nominal
   slots put the last cast past 0.9 of the aura's duration; at run time the last cast's start stamp minus `fed at`
   must stay below 0.9 of the duration (the aura is granted at or before `fed at`), else the trial is void, so an
   uncut last cast is not the natural expiry (review fw-rbaf I-1: the slots drift by about one tick each).

A trial is void when the cast speed multiplier is not 1, the control cast ran with the aura or outside the uncut
band, the talent is not known before the feed or still known after the unlearn, the feed did not grant exactly once,
`aura` is gone right after the unlearn, `aura` is applied again after the stop, a cast did not go off, or the last
cast started 0.9 of the aura's duration or later after `fed at`.

Placement of a bracket against its band: inside (wholly in it), outside (wholly beyond it) or straddling. Two
expectations share the scenario:
- `<spell> behaviour_metric_delta <suffix> charges`: the first `charges` casts inside the cut band and the next one
  inside the uncut band;
- `<spell> behaviour_metric_delta <suffix> cut`: the first `charges` casts inside the cut band and `aura_amount`
  equal to the DBC value at the grant.

Any judged trial with a cast outside its band (or, for `cut`, a wrong amount) is an alert, whatever the number of
judged trials. Otherwise fewer than `min_judged` judged trials, or a straddling bracket, is unmeasured. The verdict
is stamped with the `spell_cast_count` metric (an event row), so an ok verdict is behaviour.

An alert is diagnosed before any server fix: the unlearn at the stop is itself a candidate cause (D-97).

Felsworn: Felforged 300490 (Felforged 806104 fed by Bane of Chaos 704368, Fel Fireball 801312, 3 charges, cut 30%:
1005 to 1095 ms; uncut 1350 to 1650 ms), label suffix `felforged_fed`.
