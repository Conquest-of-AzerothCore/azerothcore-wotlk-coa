# `clear_trigger_after_ms` (metric_delta option, ADR 1013, provisional)

`"clear_trigger_after_ms": {"ms": N, "quiet_ms": Q, "spell": S, "target": UNIT}` lets an aura that one periodic tick
of the trigger starts run to its end without being refreshed by later ticks. Right after the treatment cast of `S`
the option reads the periodic hits of `S` at `UNIT` (`spell_damage_count` with `periodic`), again `Q` ms after the
cast (no tick yet) and `N` ms after it (exactly one tick), with the game time, then removes `S` from `UNIT` (harness
`set_aura` 0, a precondition fixture on the trigger, never on the claim). The count is read again right before the
after and the expired readings.

The entry uses `gate_timing: "start"`, `trigger_only_after`, `expiry_wait_ms` and `game_time` with an expired window;
`S` is its `trigger_spell` and `UNIT` its `target`, and the after window starts after `N`. The before phase, which
casts no trigger, repeats the setup casts so the measured creature exists in both phases. The metric delta's verdict
stands, and becomes `unmeasured` when a tick landed before `Q`, not exactly one tick landed between `Q` and `N`, a
tick landed after the clear, the clear came more than `N` + 25 ms of game time after the cast, or a read is missing.
The measured aura therefore began between `Q` and `N` + 25 ms after the cast. The game_time windows must hold the
G-19 band from both ends of that interval: the held window at or after `N` + 25 + the band's low edge, the gone
window at or before `Q` + the band's high edge.

Witch Doctor: Berserking 705925 (`ward_haste_lasts`, "for $705926d"): Hex of Malice 801693 ticks every 3000 ms, `Q`
2950, `N` 3200; one forced tick hastes the Serpent Ward for 15000 ms, held at 17600 ms (window 17500 to 17750) and gone
at 18600 ms (window 18450 to 18700).

Evidence (ADR 1013): the model names the evidence metric `cleared_trigger_state`, a state the module
declares with its promise words `for \$\d*d` (the tooltip's duration), merged into `coverage.metric_evidence()` and
`state_promises()` through `metric_delta_options.option_rows`, the `stop_shooting_after_ms` mechanism (ADR 1008).
Coverage's unchanged `promised_state` counts the verdict as behaviour only for a claim with those words; the haste
words alone stay data.
