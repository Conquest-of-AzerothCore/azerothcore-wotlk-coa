# Ring sum (`metric_delta` `ring_sum`, ADR 0725)

`ring_sum` is `{"spell": hit spell, "share_pct": percent, "slots": ring size}`. The treatment phase must cast `spell`
more than `slots` times (setup casts and the trigger), so the oldest share leaves the ring. The scenario reads
`spell_damage_total` of `spell` on the entry's target before each of those casts and before the judged reading
(`<after> ring read N`). The judge takes each hit as the difference of two reads, its share as
`hit x share_pct / 100` truncated, and compares the increase of the judged metric (after minus before) exactly with the
sum of the last `slots` shares. The sum of every share must differ from it: otherwise, or when a cast dealt no damage,
the verdict is unmeasured. An increase equal to the sum of every share alerts. Absent, the scenario is unchanged.

An optional `"read": "max_health"` (ADR 0732) is for an entry whose metric is the caster's `max_health` without
fields (refused otherwise): the judge is the same, and the model names the evidence metric `ring_sum_max_health`, a
state the module declares itself (`METRIC_EVIDENCE` and `STATE_PROMISES` of the module, merged by
`coverage.metric_evidence()` and `state_promises()` through `metric_delta_options.option_rows`), promised by
`health|stack\w*`. Without `read` the metric keeps its own evidence class (`aura_amount`, a readback).

Named points: `fixtures` adds the reads; `verdict(verdict, run, model)`, called by
`metric_delta_options.option_verdict`, replaces the plain verdict (the entry's `expected` is the stated percent).

Witch Hunter: Blade of the Misbegotten 680530 `ring_sum` (four Dawn Blades 802024; the 524669 aura amount is the sum of
the last three 15% shares, the server's three-slot ring in `AscensionWitchHunterEvents.cpp:343-354`).
Blade of the Misbegotten 680530 `ring_max_health` (the same four Dawn Blades, read on the caster's maximum health;
524669 is aura 34 SPELL_AURA_MOD_INCREASE_HEALTH).
