# 0610. A hooked or unread value token follows its measuring label

- Status: accepted
- Date: 2026-11-13

## Context

Three Necromancer value labels state a value no data read can measure, while a behaviour entry measures it:
561353 effect_value #1 ($h%, a ProcChance with no no-combat metric; measured by `561353 behaviour_metric_delta
reset_rate`), 806086 aura_amplitude_ms #1 ($807640t2, the amplitude of a spell never applied as an aura; measured by
`806086 behaviour_metric_delta fuse`) and 706472 effect_value e0 #1 ($s1%, replaced by a DoEffectCalcAmount hook;
measured by `706472 behaviour_metric_delta spell_power_factor`). `resolve_linked_statuses` already closed passive
"checked by" links, but a failing measuring label left the link unmodelled.

## Decision

A class file's `value_links` lists `{label, checked_by, arithmetic}`. `apply_value_links` (compare.py) rewrites an
unmodelled or not_measured verdict of a listed label into a "checked by value link" explanation with the
arithmetic, and `resolve_linked_statuses` closes it when every measuring label is conformant in the same comparison
and alerts it when one alerts. Other links keep their behaviour. Generated scenarios do not change.

## Consequences

- A value label closes only through a measuring label judged in the same comparison, and fails with it.
- Seeded tests: test_compare.py `ApplyValueLinksTest`.
