# Cooldown clear time (`behaviour_metric_delta`, `kind: "cooldown_clear_time"`, Necromancer ADR 0046)

A fixed cooldown cut per minion event ("reduces the cooldown of Unholy Frenzy by 0.5 sec"), read through casts. The
minion (`raise_spell`, creature `minion_entry`) attacks the dummy with the caster; `observe_spell` (`cooldown_ms`, its
DBC recovery time) is cast, then `spell` is learned, with the game time and the minion's damage events read. From
`first_attempt_ms` to `last_attempt_ms` after the learn the spell is attempted every `attempt_step_ms`, each attempt
with the game time and the event count. The last refusal and the first cast bracket the cut per event,
`(cooldown_ms - elapsed) / events`; the bracket must lie inside the G-19 band of `expected_cut_ms`, and one wholly
outside it alerts. A first attempt already cast, no cast, or no event is unmeasured.

Necromancer: Study of Death 704721, Unholy Frenzy 805029 cut by 500 ms per Ghoul 50073 hit (claim 179.1).
