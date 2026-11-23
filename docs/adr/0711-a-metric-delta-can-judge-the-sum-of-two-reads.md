# 0711. A metric delta can judge the sum of two reads

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Owner ruling O-24 (Witch Hunter Purity & Wickedness 680544): a Torchlight hit on a stacked target deals exactly one
helper, Holyflame 681415 or Shadowstrike 681524. Each helper is one `spell_damage_count` read; "exactly one" is a
statement about their sum, which no generated read could express, so the claim kept no label (c11-fix). Mentor
decision D-167 (c12 tool batch item 1).

## Options

- A `metric_delta` option module `fields_sum` that adds a second read of the same metric and judges the sum.
- A new harness metric summing several spells: harness C++ for what two existing reads already give.
- Two entries, one per helper: each alone cannot tell one helper from two.

## Decision

The option module `metric_delta_options/fields_sum.py`: the fields of the second read; a read labelled
`<reading> sum part` follows each judged reading, and a new named point `option_run` (called by
`compare.behaviour_metric_delta_verdict` before the judge) replaces each reading by the sum. A missing part leaves the
reading missing.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the option); without the option
  `option_run` returns the run unchanged.
- Seeded tests: a second helper (sum 2) and no helper (sum 0) alert; a helper read only in the part counts.
- Witch Hunter: `680544 behaviour_metric_delta one_helper` (sum 0 without the talent, 1 with it).
