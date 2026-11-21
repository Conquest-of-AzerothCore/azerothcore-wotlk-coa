# 1112. The dummy can cast at the caster as an ordinary cast

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 1110 (untriggered creature casts)

## Context

Fool's Play 681007 "and replicates their spells back on them": the clone casts back the spells its target casts, through
a hook that skips triggered casts and needs a damaging, script-free spell cast by the target. `target_casts` makes the
dummy cast at itself, triggered, so nothing in `metric_delta` could make the Fool's Play target cast at the caster in
a way the hook sees (tool note T-e, cycle 6).

## Decision

- `metric_delta` option module `dummy_casts_at_caster`: `{"spell", "casts", "gap_ms", "lead_ms"}` (1 to 20 casts at
  least 1000 ms apart). In each phase the dummy casts `spell` at the caster with `triggered: false` (ADR 1110):
  `lead_ms` after each trigger cast (named point `after_trigger_steps`), or, in a before phase that does not cast the
  trigger, at the point of the cast (`phase_steps`). The trigger must target the dummy.

## Consequences

- Witch Doctor: `681007 mirror` (Damage 100 (TEST) 2653 cast 8 times; the clone's hits on the dummy, 0 without the
  clone, 4 to 8 with it).
- New module only; classes 19 (with and without `--stack`) and 23 generate byte-identical output.
