# 1222. A metric delta strikes a second time to read a next-attack state

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-22

## Context

Light of the Sun 704941 grants 707843 on a parry: "increases your chance to parry the next attack by 30%". The
`metric_delta` entries force the caster's parry to 100% and strike once; every further strike at 100% is parried and
re-applies the aura, so a plain second strike cannot tell consumption from a refresh (Sun Cleric ledger row 279).

## Options

- A second strike through `strike.count`: parried again at 100%, it refreshes the aura.
- A harness read of the aura's charges: 707843 has no charges, and it is harness C++.
- A `metric_delta` option that strikes once more with a spell no table avoids, after a read of the state it meets.

## Decision

The opt-in `metric_delta` option `second_strike` (`{spell, present, wait_ms?}`, wait 300 ms by default), Python only,
default off, on an entry with a `strike`, its spell other than the strike's. Through the named point
`after_trigger_steps`, after each trigger cast it reads the entry's metric in the treatment phase (must equal
`present`), then sets the caster's dodge and parry to 0% (replacing the `caster_avoidance` step before that cast) and
the striker casts `spell` at the caster. Its damage logs (`spell_log_count`, the striker as caster) are read right
after the before reading and right after the after reading. A present read other than `present`, or a phase without
exactly one landed second strike, makes the verdict
`unmeasured`; it never produces `ok` or `alert` and adds no counted label.

## Consequences

- Test: `SecondStrikeTests` (metric_delta_options/test_second_strike.py), with the kept-state mutant that alerts.
- Page: docs/metric_delta_options/second_strike.md.
- Only entries that set the option change; finished-class scenario digests are unchanged.
