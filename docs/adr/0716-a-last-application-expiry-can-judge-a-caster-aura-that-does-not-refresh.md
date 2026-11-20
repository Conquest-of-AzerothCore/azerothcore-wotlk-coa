# 0716. A last-application expiry can judge a caster aura that does not refresh

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Torch the Wicked! 560226 (Witch Hunter): each damaging Flames of Sin 802850 hit grants a stack of 560227 (6 sec, a
caster aura), and "application of this effect does not refresh the duration". The handler raises the stack count with
`SetStackAmount`, which does not call `OnAuraApply`. `last_application_expiry` (ADR 0593) polls the dummy only and casts
its trigger once (c11-inq stop on claim 103.0). It also cannot tell a refresh from no refresh: a refresh counts as an
application, and timing from the last one passes either way. Mentor decision D-160 (c12 tool batch item 6).

## Options

- `caster`, `repeat` and `no_refresh` fields on the kind: read the caster, recast the trigger inside the duration,
  and judge one counted application with rising stacks, timed from it.
- A `duration_refresh` built-in kind: it reads a dummy aura from one cast pair, not stacks added without an apply.

## Decision

The first option in `kinds/last_application_expiry.py`. `no_refresh` requires `repeat`; more than one counted
application alerts (a refreshing or reapplying mutant), stacks below 2 are unmeasured.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the fields).
- Seeded tests: a refreshing mutant (three counted applications) alerts; stacks that never rise are unmeasured.
- Witch Hunter: `560226 behaviour_metric_delta no_refresh`.
