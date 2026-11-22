# Ally arm (`metric_delta` `ally_arm`, ADR 1016)

`ally_arm` is an object of these keys, at least one:

- `allies`: 1 to 5 (default 1). Grouped ally players `ally`, `ally2` .. `ally5` (the class's player fixture,
  regeneration off with `disable_regeneration`), grouped right after the base steps. `measure_actor`, `target` and
  `fields.target` may name them.
- `ally_health`: `[value, maximum]`, set on every ally in both phases, ahead of the trigger.
- `ally_casts`: spells the caster casts at `ally` in both phases ahead of the trigger, 2000 ms after each (global
  cooldown). The caster's power at that point pays them.
- `control_wait`: `true`. The uncast before phase waits the entry's `wait_ms` before its reading (timed no-cast
  control). Only with `cast_in_before` false, the default gate timing and no strike, swings, `setup_only_after`,
  `setup_in_before`, `target_casts_before` or `enemy_casts_in_before`.
- `arms`: a list of `{actors, metric, fields?, before_expected, expected, tolerance, source}`. Each arm reads `metric`
  on every unit of `actors` (the caster, the allies, the dummy when the scenario has it) right after the main before
  and after readings, and judges the sums: `|sum - expected| <= tolerance`. Every value is stated with its `source`;
  no default tolerance. The metric needs a `METRIC_EVIDENCE` row that is not a readback.

Verdict: the main verdict, then alert when an arm is off, unmeasured when an arm read is missing. Without arms the
verdict is the plain one.

Named points: `check`, `phase_steps`, `fixtures`, `model`, `verdict`.

Example (Bless at an ally, a probe, not a counted entry):

```json
"target": "ally", "measure_actor": "ally", "cast_in_before": false, "disable_regeneration": true,
"metric": "health", "before_expected": 5000, "expected": 5500, "wait_ms": 10500,
"ally_arm": {"allies": 2, "ally_health": [5000, 10000], "control_wait": true, "arms": [
  {"actors": ["ally"], "metric": "aura", "fields": {"spell": 804247}, "before_expected": 0, "expected": 1,
   "tolerance": 0, "source": "Bless cast at the ally holds its aura there"}]}
```
