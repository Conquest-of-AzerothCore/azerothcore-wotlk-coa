# 0120. Two proof statuses computed by clause coverage

- Status: accepted
- Date: 2026-11-11

## Context

Clause coverage (`coverage.clause_coverage`) counted a ledger claim as proven when every label resolved to a
conformant verdict. A readback of a computed value (`CalcValue`, `ApplySpellMod`, a duration, a stat field) shows
the value is right, not that the path that acts uses it: High General's only proof was `effect_value 524617e0 =
100`, a readback of an effect the server dummies at load, while the code applied x1.5. The owner adopted on
2026-11-10 two statuses, "data conformant" (a readback) and "behaviour proven", with the behaviour-proven figure
reported to the owner, and on 2026-11-10 that coverage refuses verdicts of another build, alerts and proofs alike
(`owner-rulings-2026-11-10.md`, "External review" and "Alert precision"). The clause-spec prototype built the tables
(commit f48d2c8189, ADR 0101's classes of the round 10 checks in merge 90d75d6925, the `moving`/`threat` state reads
of e1257d5b58); ADR 0116 carries them over without the clause class and without consumption rows.

## Considered options

1. Let the translating agent mark each claim `data` or `behaviour`. Rejected: the status must be computed.
2. Classify by label text. Rejected: labels are free text; `passive_delta` labels read `spell_modifier` and `armor`
   alike.
3. A closed table from the verdict's `check`, with a closed metric table for the checks whose observed metric
   varies. Chosen.
4. Also promote readbacks through generated consumption rows (the prototype's K1/K2/K3). Left out: nothing writes a
   row without the prototype's uncommitted server mutant, and a reader with no writer only adds rules to document.

## Decision

- `coverage.EVIDENCE` maps every check the package emits to `data`, `behaviour`, by metric or linked; an unknown
  check fails the run (`EvidenceError`). `coverage.METRIC_EVIDENCE` maps observed metrics to `event` (behaviour),
  `readback` or `state` (data); an unknown or missing metric fails too. `compare.judge_behaviour` stamps the model's
  metric and the metric-delta contrast into the verdict detail; the ratio, leech, cast-stat, health-threshold and
  group-stack-cap models now carry their `metric` (`passive_delta` already did).
- Round 10 checks: the outcome checks (fixed count, internal cooldown, heal block, cast applies aura, cast gate,
  cast condition, cast combat, charge recharge, mount grant, aggro redirect, gap closer distance, absorb pierce
  ratio, metric ratio delta) are behaviour; `behaviour_party_stat_ratio` is by metric; `water_walk` is an event
  metric.
- A state read is behaviour when the check is a learned/unlearned contrast (`passive_delta`,
  `behaviour_party_stat_ratio`, or `behaviour_metric_delta` outside its `setup_only_after` condition mode) and the
  claim names the stat (`STATE_PROMISES`, English tooltip words, class-agnostic). A `checked by` label takes the
  evidence of what checks it; a verdict closed by rule is data.
- `clause_coverage(clauses, verdicts, build)` returns `ClauseCoverage` (proven, behaviour, data, total, unproven,
  per-claim evidence, `not_measured` labels) and refuses a non-empty verdict set holding a verdict of another build
  or none named; `write_coverage` refuses both sides the same way. `conformance.py coverage --clauses` prints both
  counts and, with `--fragment`, writes a fragment whose entries carry `evidence` and `spell_dbc_sha256`.

## Consequences

- Verdicts written before ADR 0118 carry no build and are refused by coverage; they must be compared again.
- `STATE_PROMISES` matches stat words, not the stat index: a claim naming Agility accepts any `stat` read of a
  learned contrast. The prototype's review found 6 of the 27 Templar state promotions under-powered by
  `passive_delta`'s 1-point floor and one (Bells of Light 801204 Intellect) resting on a value no game path reads
  (score.md §2.1, I6); the judges are corrected in the I8/I6 step, not by this table.
- Every new check or observed metric needs a table row before coverage runs; the unit tests list the package's check
  constants and the class files' metrics against the tables.
