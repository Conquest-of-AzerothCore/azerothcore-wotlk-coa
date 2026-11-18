# `rage_per_damage` (metric_delta option, ADR 1004, provisional)

`"rage_per_damage": {"spell": S, "target": UNIT, "min_damage_ratio": R}` judges that a spell's Rage follows the damage
it deals. The entry reads the caster's Rage (`metric: "power"`, `fields: {"power": 1}`), reset by `phase_power` at the
start of both phases with `disable_regeneration`, casts `S` (its `trigger_spell`) in both phases, raises the damage of
the after phase through `after_auras`, and states a `tolerance`.

Right before each Rage reading the option reads `S`'s logged damage at `UNIT` (cumulative `spell_damage_total`,
`spell_damage_count` and the critical `spell_damage_count`), and the caster's `max_power` for Rage before the after
reading. Each phase must land exactly one non-critical hit, both must deal damage, the after phase must deal at least `R`
times the before phase's damage and its Rage must stay under the cap; otherwise the verdict is `unmeasured`. The judged
value is (Rage / damage of the after phase) / (Rage / damage of the before phase): `ok` within 1 +- `tolerance`, else
`alert`; a before phase with damage and no Rage alerts. The verdict replaces the metric delta's.

Witch Hunter: Heartseeking Bolt 807284 ("Generates Rage based on the damage dealt."), QA Test +1000 AP 10031 in the after
phase, Reduce Critical Strike Chance 64481 in both, `min_damage_ratio` 1.5, `tolerance` 0.05.

Evidence (ADR 1008, provisional): the model names the evidence metric `rage_per_damage`, a state the module declares
with its promise words `based on the damage dealt` (merged into `coverage.metric_evidence()` and `state_promises()`
through `metric_delta_options.option_rows`). Coverage's unchanged `promised_state` counts the verdict as behaviour
only for a claim with those words; "Generates Rage" alone stays data.
