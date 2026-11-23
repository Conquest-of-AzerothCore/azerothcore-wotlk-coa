# Aura windows (`behaviour_metric_delta`, `kind: "aura_window"`, ADR 0551)

A cast's aura on the dummy is polled over start and end windows given in game time, without and with the talent,
and each stamped duration is judged (Ice Barrage 501997's channel, Deathly Chill 805424).

`setup_casts` (ADR 1121, absent by default): a list of `{"spell", "target": "caster" | "dummy", "wait_ms"}` the caster
makes for real at the start of the treatment phase, before its global cooldown wait and the trigger, so the treatment
can be a cast state (a summoned field) rather than a learned talent; the spells are learned at the start.
`treatment_band_ms` (absent by default) judges the treatment duration inside that band instead of 5% of it; it must
be narrower than that 5%, for a claim whose stated value is the change (Graven Effigy 506635 `graven_cc`: +25% of a
10000 ms snare, 2 points of the base, 200 ms).
