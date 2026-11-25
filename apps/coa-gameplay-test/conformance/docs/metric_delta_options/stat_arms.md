# Stat arms (`metric_delta` `stat_arms`, ADR 1295, provisional)

ADR 1295 has a provisional number and is renumbered at merge (guide 14.4).

Direction-only judgement for stat-dependent sentences that state no numeric figure (orchestrator decision D-38, e.g.
`"The tentacle gains health based on your Stamina."`, `"Increases your critical strike rating based on your parry and
dodge rating."`).

## Configuration

`stat_arms` is:

```json
{
  "mode": "passive" | "active_recast",
  "input": {"metric": "<stat metric>", "fields": {...}},
  "arms": [
    {"aura": 706305, "stacks": 1, "source": "..."},
    {"aura": 706305, "stacks": 2, "source": "..."}
  ],
  "unrelated": {
    "metric": "<unrelated stat metric>",
    "fields": {...},
    "aura": 486,
    "stacks": 1,
    "source": "..."
  },
  "wait_ms": 1000
}
```

- **No expected figure is configurable:** `metric_delta_spec` refuses `expected` and `before_expected` whenever
  `stat_arms` is present, and `stat_arms` refuses `expected_gain`, `expected_ratio`, `after_at_least`, `after_at_most`,
  `after_expiry_expected`, `phase_power` and any unknown key.
- **At least three input stat values:** `arms` requires at least 2 distinct `(aura, stacks)` fixture levels in addition
  to the baseline level 0 (`>= 3` total values).
- **Unrelated-stat control:** `unrelated` must name a different `(metric, fields)` than `input` and an aura not used by
  any arm.
- Allowed input/unrelated metrics: `stat`, `stat_exact`, `combat_rating`, `attack_power`, `ranged_attack_power`,
  `spell_power`, `max_health`, `armor`, `healing_power`. Neither may equal the judged output `(metric, fields)`.

## Modes

- `mode: "passive"`: plain learned contrast (`cast_in_before: true`). After the before reading (spell not learned), reads
  the input stat and unrelated stat at baseline, then for each arm applies its aura, waits `wait_ms`, reads the input
  stat and the output metric, and removes the aura; then repeats with the unrelated-stat aura. After learning `spell`
  and taking the after reading, repeats the same reads with `spell` learned. Judged values are the learned gains
  `gain[i] = learned[i] - control[i]` for `i = 0..K-1` and `gain_unrelated = learned_unrelated - control_unrelated`.
- `mode: "active_recast"`: cast-time snapshotted effects (`cast_in_before: false`). Reads baseline input and unrelated
  stats before the after phase's trigger cast (level 0), then after the after reading repeats for each arm and for the
  unrelated control: waits `expire_ms` (if positive), applies the fixture aura, waits `wait_ms`, reads the fixture
  stat(s), repeats the trigger cast block, reads the output metric, and removes the fixture aura. Judged values are the
  output readings `q[0..K-1]` and `q_unrelated`.

## Preconditions and judgement

- **Preconditions (`unmeasured` on failure, never `alert`):** every reading must be present; input stat values must
  strictly increase across all levels (`s[i+1] - s[i] > 0.5`) and, in `passive` mode, match between control and learned
  arms within `0.5`; the unrelated stat must rise by more than `0.5` when its aura is active (matching between arms in
  `passive` mode) while leaving the input stat within `0.5` of baseline.
- **Judgement (`ok` or `alert`):** strictly monotonic increase across all `>= 3` stat levels (`v[i+1] > v[i] + tol` for
  every step, and `v[0] >= -tol` in `passive` mode) AND unrelated-stat invariance (`abs(v_unrelated - v[0]) <= tol`).
  Asserts no slope and no ratio.

Named points: `FORBIDS_EXPECTED = True`, `parse`, `check`, `fixtures`, `model`, `verdict` (`ORDER = 44`, after
`void_on_cast_failure`).
