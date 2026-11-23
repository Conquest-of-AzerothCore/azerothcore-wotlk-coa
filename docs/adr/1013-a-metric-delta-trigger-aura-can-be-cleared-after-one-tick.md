# 1013. A metric delta trigger aura can be cleared after one tick

- Status: proposed (draft, Witch Doctor cycle 10 task P; provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-21
- Builds on: ADR 0581 (kind modules), ADR 0582 (metric_delta options)

## Context

Berserking 705925: "Periodic damage dealt now has a $h% chance to increase the haste of your Serpent Wards by
$705926s1% for $705926d". The `ward_haste` entry reads the stack cap with Hex of Malice ticking every 3000 ms, which
refreshes the 15000 ms buff on every tick, so no reading bounds its duration. A metric_delta entry cannot stop a
periodic trigger after its first tick: `stop_shooting_after_ms` stops an auto-repeat shot by moving the caster, which
does not stop a periodic aura already on the target.

## Decision

`metric_delta_options/clear_trigger_after_ms.py`: after the treatment cast, read the trigger's periodic hits at the
target at the cast, at `quiet_ms` (none) and at `ms` (exactly one), stamp the game time and remove the trigger aura
from the target with harness `set_aura` 0 (a precondition fixture on the trigger, as `flat_chance_rate`
`stop_trigger_aura` and the 807450 `summon_lifetime` entry do); read the count again before the held and gone
readings. Any other count, a late clear or a missing read makes the verdict `unmeasured`, never `ok`. Evidence metric
`cleared_trigger_state`, a state with the promise words `for \$\d*d`, as `stop_shooting_after_ms` (ADR 1008).

## Consequences

The Berserking duration claim gets a behaviour route without an owner change (one scenario, about 27 s of game time).
No owner file changes; the `docs/behaviour-scenarios.md` list of metric_delta options gains one line at merge:
"[`clear_trigger_after_ms`](metric_delta_options/clear_trigger_after_ms.md): the trigger aura removed after one
periodic tick, so a buff that tick starts can expire unrefreshed (ADR 1013, provisional)".
