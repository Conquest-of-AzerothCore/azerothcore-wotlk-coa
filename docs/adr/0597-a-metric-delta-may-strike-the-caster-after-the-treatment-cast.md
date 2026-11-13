# 0597. A metric delta may strike the caster after the treatment cast

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0361, ADR 0582

## Context

Gravebound Champion 805049 "redirects $805050s3% of all damage the caster takes to themselves" (claim 353.2, "to
themselves") needs the Champion's own health read in both phases, so the Champion must exist in both, while only the
treatment phase may be struck. The `metric_delta` `strike` (ADR 0361) strikes the caster in both phases, or a creature
of the caster in the treatment phase only (`owned_entry`), and the option points of ADR 0582 (`phase_steps`,
`setup_cast_steps`) all come before the trigger cast that summons the Champion.

## Options

1. Extend the `strike` field with an after-phase-only mode at the caster (a `MetricDeltaSpec` change).
2. A `metric_delta` option module `after_trigger_strike` with a fourth named point after the trigger cast.

## Decision

Option 2. `metric_delta_options.option_after_trigger_steps(spec, after)` is called right after the trigger cast in
each phase. `metric_delta_options/after_trigger_strike.py` (`{"spell", "delay_ms", "count", "wait_ms"}`) returns, in
the treatment phase only, a wait of `delay_ms` and `count` casts of `spell` by the striker at the caster, `wait_ms`
apart, and adds the striker creature (the `strike` fixture). An entry with both `strike` and `after_trigger_strike`
is refused.

## Consequences

- Gravebound Champion: the Champion's health gain is judged with `expected_gain` (pilot: -556 / -557 against -550).
- Spellbound Champion 807811 (claim 358.2) reads -489 / -490 on its Champion for an 1100 strike; the claim states the
  redirection, not an amount, and the Champion's mitigation is not derived, so no entry uses that read yet.
- Templar scenarios are unchanged (no Templar entry sets the option).
