# Aura expiry (`behaviour_metric_delta`, `kind: "aura_expiry"`, ADR 0485)

`kind: "aura_expiry"` (ADR 0485) reads how long a rolled minion aura lasts: the talent's roll is forced (the ADR
0482 mutant) while one raised minion attacks the dummy, then a -100% mutant stops every roll; every `poll_ms` the game
time (`game_time_ms`), the minions carrying `aura` and the minion's casts of `marker_spell`
(`owned_creature_spell_cast_count`) are read. The last cast and the first read without the aura bracket the duration in
game time; the verdict is `ok` when the bracket lies inside `expected_ms` +- `band_ms` (5% by default). A cast after the
switch alerts; no cast before it is `unmeasured`. Durations are judged on game-time stamps, never on the nominal waits:
each wait step costs about 10 to 17 ms of game time beyond its `ms` (ADR 0485).
