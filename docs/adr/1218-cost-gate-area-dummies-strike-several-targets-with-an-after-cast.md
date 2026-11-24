# 1218. A cost gate's after cast can strike several dummies

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Solar Nova 681433 (ledger row 179, claim 1): "Reduces the cooldown of your Solar Invocation spells by
$/1000;524858s1 sec for each target struck." The class code casts 524858 (1000 ms on each Solar Invocation spell) once
per offensive hit of Solar Nova (`AscensionClassMechanics26To32.cpp:54-77`). The `cost_gate` entry `cd_conquest` strikes
one dummy and proves the 1 s; the per-target multiplication rested on `cd_refund_*` readings of `cooldown_ms`, a
readback. Mentor ruling D-216.

## Options

- Read `cooldown_ms` after a strike of several targets: a readback, not behaviour (coverage refuses it as proof).
- A new kind for per-target cooldown cuts: duplicates the cost gate's three arms.
- An opt-in `area_dummies` list on `cost_gate`, reusing the `metric_delta` option's fixture: the after cast strikes the
  dummy and its copies, and the gate's existing `without`/`with`/`beyond` attempts judge the summed cut.

## Decision

The third option. `cost_gate_spec` parses `area_dummies` with the option's own parser and refuses it unless the gate is a
cooldown gate whose `after_casts` all target the dummy, with no `resets`. The scenario calls the option's `fixtures`
(copies of the dummy at the listed distances). The entry states the whole cut in `reduction`; the arms are unchanged.

## Consequences

- Absent by default: no entry of a finished class writes it, the finished classes regenerate byte-identical.
- Seeded tests (`metric_delta_options/test_area_dummies.py`): the creatures and the after-cast target; the default
  keeps one dummy; refusals; three targets pass and the two-target and four-target mutants alert.
- The placement of the copies inside the after cast's radius is the entry's statement; a copy outside it makes the
  `with` arm refused, an alert the reviewer reads against the radius entry of the spell.
