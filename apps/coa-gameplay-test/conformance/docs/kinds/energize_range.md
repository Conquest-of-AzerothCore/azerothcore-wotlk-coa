# Energize range (`behaviour_metric_delta`, `kind: "energize_range"`, ADR 0549)

`cast_spell` is cast `casts` times at the dummy (`caster_auras` and `target_auras` set before each cast, Runic Power set
to 0); the cumulative `energize_spell` energize total and count are read every 250 ms (`polls_per_cast` reads per
cast). An interval whose count rose by exactly one gives that event's amount; at least `minimum_events` such amounts
must be read, all inside `low`..`high`, with both ends seen. Soulfreeze 801724: 800344 rolls 30..80 per tick, 160 casts,
384 events.
