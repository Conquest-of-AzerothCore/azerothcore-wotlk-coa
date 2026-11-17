# 0037. A `closed` verdict status for evidence-backed no-check reasons

- Status: accepted
- Date: 2026-11-09

## Context

Round4's templar run reported 225 `unmodelled` verdicts as open work. Round5's `closed-statuses` item
investigated three groups inside that bucket and found 24 of them already settled with evidence, not missing
checks:

- 9 of the `effect_notes`-driven "no check needed" reclassifications (ADR 0034): a dead `EffectBasePoints` or an
  `HasAura()`-only read, proven by `grep` to be read by no CoA code, whose tooltip clause is already covered by a
  sibling effect's own `ok`/`alert` check.
- 2 mail-armor effects (aura 142, `SPELL_AURA_MOD_BASE_RESISTANCE_PCT`, in `passives.py`'s `OUT_OF_SCOPE` dict):
  the reference character never equips a mail item and the harness has no re-gear action, a structural tool-scope
  gap, not a missing claim.
- 13 `spell_power_cost` probe-skip targets: `Spell.dbc`'s `ManaCost`/`ManaCostPerlevel`/`ManaCostPercentage` are
  all 0 for every named target, a DBC-proven true not-applicable that an existing, already-tested check (`test_
  spell_power_cost_skips_targets_with_no_plain_cost`) already gets right — only its status label was wrong.

`unmodelled` was overloaded to mean both "a check is still missing here" and "no check is possible or needed,
already proven". `coverage.md`/`report.md`/`summary.md`'s status tables and `alerts.tsv` (`compare.py`'s
`NOT_ALERTS`) count every `unmodelled` verdict as the same open-work bucket, so the owner's dashboard overstated
remaining work by at least these 24 verdicts, and will keep doing so for every future class that hits the same
three code paths.

## Considered options

1. Leave the reason text as evidence inside `unmodelled` and have the owner's dashboard re-derive "closed" by
   parsing `explanation` for known prefixes. Rejected: pushes an extra text-matching dependency onto every reader
   of `verdicts.json` (the dashboard, future round items, this item's own tests) instead of the one place that
   already turns an `Expectation` into a `Verdict`.
2. Downgrade these 24 verdicts to `ok`. Rejected: there is no measured number behind them; claiming `ok` would be
   exactly the false-positive risk the task's own rules forbid ("an honest unmodelled beats a check that could
   give a false ok").
3. A new `closed` status, produced by a `CLOSED` marker prefix (`'closed: '`, the same style as `UNMODELLED`/
   `UNREADABLE`/`UNMEASURABLE`) checked in `compare.py`'s `judge_expectation` chokepoint before the existing
   `unmodelled` branch, so `STATUSES`/`NOT_ALERTS`-driven tables pick it up automatically. Chosen.

## Decision

- `hits.py` and `passives.py` each add `CLOSED = 'closed: '`, duplicated between the two modules the same way
  `UNMODELLED` already is (no shared-constants module exists today).
- `compare.py`'s `STATUSES` tuple gains `'closed'`; `NOT_ALERTS` gains `'closed'` so `alerts.tsv` stops listing
  closed verdicts as open work.
- `judge_expectation` checks `rule.startswith(CLOSED)` and returns `status='closed'` *before* the existing
  `check == 'unmodelled' or rule.startswith(UNMODELLED) or rule.startswith(UNMEASURABLE)` branch, since every
  closed expectation is still built with the literal `Expectation.check == 'unmodelled'` routing key (`passives.
  expect(...)` never changes) — only the `rule` prefix distinguishes a closed verdict from a genuinely open one.
- Three call sites in `passives.py` are updated to emit `CLOSED` instead of `UNMODELLED`, each gated by evidence
  already present in the surrounding logic, none widened beyond what round5 verified:
  - `classify()`'s `effect_notes` re-wrap: only when the note text starts with `'no check needed:'` (the other 7
    `effect_notes` reasons — "no own token", "reclassify:", "deferred:" — keep `UNMODELLED`).
  - `classify()`'s `OUT_OF_SCOPE` handling: a new `Closed` exception, raised only for `aura == 142`, checked
    before the general `aura in OUT_OF_SCOPE` branch so auras 59/122/110 keep `UNMODELLED` unchanged.
  - `plan_probes()`'s `spell_power_cost` zero-cost-target reason.
- A verdict is `closed` exactly when `Expectation.rule` starts with `'closed: '`, reachable only from these three
  gated call sites; no path that could otherwise produce `ok`/`alert`/`measured` is redirected into `closed`.

## Consequences

- `coverage.md`/`report.md`/`summary.md`'s status tables and `alerts.tsv` show open work (`unmodelled`) separately
  from settled-with-evidence work (`closed`) with no further code change, since they all iterate `STATUSES`/
  `NOT_ALERTS` generically.
- The round5 templar re-run reports `unmodelled: 201` / `closed: 24` (225 − 24) instead of an undifferentiated
  `unmodelled: 225`; regenerating that output is the responsibility of whichever round5 item runs the next full
  templar compare, not this one.
- Any future round or class that also wants to close a verdict without a check reuses this exact status name and
  `CLOSED` marker rather than inventing a new one (this is the first round5 item to define the mechanism; its
  sibling specs use "closed" only in prose, not as a `compare.py` status).
- The other three `OUT_OF_SCOPE` auras (59, 122, 110) are structurally the same kind of gap as mail armor and are
  plausible future `closed` candidates, but are not evidenced by this item and stay `unmodelled` until a future
  item closes them on their own evidence.
