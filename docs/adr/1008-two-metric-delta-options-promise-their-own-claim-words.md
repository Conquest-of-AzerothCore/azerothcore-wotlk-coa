# 1008. Two metric delta options promise their own claim words

- Status: proposed (draft for mentor D-479)
- Date: 2026-11-17
- Builds on: ADR 0616, ADR 1004, ADR 1005

## Context

Review C-1 of the Witch Hunter not-final pass: two measured parts resolve to `data` under `coverage.py`.
`verdict_evidence` counts a `behaviour_metric_delta` verdict on a state metric as behaviour only when the metric's
`STATE_PROMISES` words appear in the claim words (`promised_state`). 705531 "for $573266d" is judged by
`stop_shooting_after_ms` on `owned_creature_attack_time_ms` (words `haste|attack speed`), and 807284 "based on the
damage dealt." by `rage_per_damage` on `power` (Rage and cost words). Neither claim carries its metric's words, and
`promise_of` cannot name a claim of the same row. Mentor D-479 approved a narrow addition: an option module may declare
promise words for its own verdicts, applied only to entries using it and judged by the same `promised_state` test.

## Options considered

1. A coverage-side table keyed by option name, read from a new verdict detail field: edits `coverage.py` and
   `compare.py`.
2. The existing `evidence_metric` path (ADR 0616, used by `displacement` and `ring_sum`): the option's model names an
   option-owned metric, and the module declares its `METRIC_EVIDENCE` and `STATE_PROMISES` rows, which
   `coverage.metric_evidence()` and `state_promises()` already merge through `option_rows`.

## Decision

Option 2, with no `coverage.py` or `compare.py` edit (controller go, D-479):

- `stop_shooting_after_ms` stamps `stop_shooting_attack_time_ms`, a state promised by `for \$\d*d` (the tooltip's
  `for $d` duration words).
- `rage_per_damage` stamps `rage_per_damage`, a state promised by `based on the damage dealt`.

The promised-state rule is kept: the verdict still needs a learned or own-cast contrast and the words in the claim.
Only 705531 `hound_haste_duration` and 807284 `rage_per_damage` use these options.

The Witch Hunter 705531 expired window top moves from 5475 to 5495 ms. The measured expired reading came at 5461 ms
in both runs, 14 ms under the old top, less than one 25 ms harness step. 5495 ms keeps 34 ms. The aura starts at or
after the cast stamp, so any accepted expired reading under 5500 ms still sees a 5500 ms aura present, and the 10%
longer duration still fails (D-200). The scenario file is unchanged: the windows live in the manifest model only.
Bound: the cast stamp is taken two harness ticks before the read (behaviours.py:1752-1754, about 6 ms, more than the 5
ms spare under 5500 ms), so the window top alone does not fail a 5500 ms aura; it fails because the Auto Shot hit
lands at least 125 ms after the cast (projectile flight, Spell.cpp:2474-2476, DBC Speed 40), so the aura cannot start
before that and a 5500 ms aura is still present at any expired reading under 5495 ms.
This replaces the window figures stated in ADR 1005.

Provisional number, renumbered at merge (guide 14.4).

## Consequences

- Generated scenarios of classes 15, 19 and 23 are byte-identical. The class 15 manifest changes only in the two
  entries' models (`evidence_metric`, and the 705531 expired window).
- The class 15 audit over the end2 count of record and the nf-a2 pair changes only 276.1 and 383.1, from data to
  behaviour (317/5 to 319/3 behaviour/data, both runs).
- Seeded tests in `test_stop_shooting_after_ms.py` and `test_rage_per_damage.py` cover the claim words present
  (behaviour) and absent (data). Their mutants are the entry without the option, whose plain metric stamp stays
  data, and an alerting verdict, which never counts.
- A later option that needs claim words follows the same path. It uses an option-owned metric name, never an existing
  metric's row.
