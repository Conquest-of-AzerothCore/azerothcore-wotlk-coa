# 0052. A clause coverage ledger, and "checked by" rows resolving to a live verdict status

- Status: accepted; its reference to `docs/ledger-format.md` is superseded by ADR 0302
- Date: 2026-11-09

## Context

Round 10's clause audit (`claims-merged.json`) splits every Templar tooltip into 450 individually-provable
clauses (434 real claims, 16 `no_claim` label lines). Nothing in the repository yet turns that audit into a
pass/fail coverage number against an actual compare run, or a durable artifact other workstreams can add
proof to without colliding with each other.

Separately, `passives.py`'s `linked_reason` (used whenever a passive effect's own measurement is unmodelled
but is "checked by" a trigger/proc/behaviour entry elsewhere in `classes/templar.json`) read that entry's
`status` field as `entry.get('status', 'ok')` — a field almost no entry in `templar.json` actually sets, so it
silently defaulted to `ok` regardless of what that linked check's own, current verdict actually was. Round 8's
Scourgebane row is the concrete case: its `92111 proc_rate` procs entry regressed to `alert` in that round's
compare run, but every passive effect "checked by" it still reported "status ok" — a stale, effectively
fabricated status that would have let a real regression hide behind an unrelated effect's unmodelled note.

## Decision

### Clause ledger (`classes/templar_clauses.json`)

- Generated once from `claims-merged.json`: one entry per clause, `{"spell", "clause", "labels", "kind":
  "claim"|"no_claim", "reason"}` (`reason` only on the 16 `no_claim` entries, carrying the audit's own note).
  `labels` is carried over as-is from the audit (empty for most `missing`/`partial` clauses today — filled in
  by the per-workstream ledger fragments in `round10/ledger/<key>.json` the task brief describes, merged by the
  integrator; this file is not hand-edited by a workstream).
- `coverage.py` gains `clause_coverage(clauses, verdicts)`: a claim is proven when it has at least one label
  and every label's live verdict status is in `CONFORMANT` (`ok`, `tolerated`, `closed`, ADR 0051); a claim
  with no labels, or any label missing from or not-conformant in the live verdicts, is unproven. `no_claim`
  entries are excluded from both the proven and total counts. `clause_coverage_lines` prints `proven of total
  (X%)` and lists every unproven clause with its tooltip words (the `clause` field) and current labels.
- Wired into the CLI as `conformance.py coverage --clauses classes/templar_clauses.json` (alongside the
  existing `--before`/`--after` spell-level coverage report); it reads `--after`'s `verdicts.json` for the live
  statuses, so the number always reflects the same compare run being reported on, never a cached one.
- `clause_coverage`'s label lookup is ordinal-tolerant (`coverage.resolved_labels`): `claims-merged.json` writes
  a label like `92111 effect_value 801832e1`, but the real `Verdict.label` a `compare` run produces for an
  effect-value/aura-amount/max-stacks/effect-radius/spell-duration token is that base plus a trailing
  `" #<ordinal>"` (`values.py`'s positional disambiguator, needed when a spell repeats the same token). Without
  this, every such clause looked up its *exact* audit-written string, found nothing in a real `verdicts.json`,
  and was reported `unproven` regardless of the underlying verdict's status — found by checking spell 92111's
  own clauses (whose `proc_rate`-labelled clause matched and proved fine, but whose two `effect_value`-labelled
  clauses did not) against a real `compare` run in this step. A clause label without a trailing ordinal now
  expands to every verdict label in the run that starts with `"<label> #"` followed by digits, and needs all of
  them (not just one) conformant, since each is a separate occurrence of the same clause in the tooltip; a
  label that already carries its own `" #<ordinal>"` is matched exactly, unexpanded.

### Live "checked by" status

- `linked_reason` (and `classify`/`passive_effects` above it) take an optional `verdicts: dict[label, status]`
  mapping. When given, a "checked by `<kind>` entry... (verdict `"<label>"` (status `<live>`))" row looks up
  `<live>` from that mapping; when a label is absent from it, or no mapping was given at all (e.g. a caller
  with no compare run, such as a scaffold-only read or today's unit tests), it falls back to the previous
  `entry.get('status', 'ok')` reading, now clearly a last resort rather than the normal path.
- `sheets.py`'s `sheet()` is the one production caller with a compare run available (`--verdicts <dir>`); it
  now builds the full `{label: status}` map from that run's `verdicts.json` and passes it through, so a
  generated sheet's "checked by" text always matches that same run's own verdicts, never a hand-written or
  stale field.
- This fixes the *text*, but `passive_scenario` runs at `generate` time, before any compare run exists, so the
  `rule`/explanation it bakes into `manifest.json` is always generated with `verdicts=None` and is replayed
  unchanged by every later `compare`. The actual `Verdict.status` for these rows was therefore always the
  literal `'unmodelled'`, regardless of the referenced check's live outcome — which is also what let a
  conformant "checked by" row sit in the `unmodelled` bucket of `coverage.py`'s per-status tally (`## Verdicts
  per status`) and of `clause_coverage`, understating how much is actually proven.
- `compare.py` gains `resolve_linked_statuses(verdicts)`, run once over the full verdict list at the end of
  `evaluate()` (so every other verdict for the same compare run, including the referenced trigger/proc/
  behaviour entry's own verdict, already exists). For a row whose `check == 'unmodelled'` and whose
  explanation contains `"checked by"`, it re-reads the label(s) quoted before `(status ...)`, looks up each
  one's current status in this same run's verdicts, rewrites the quoted status to that live value (so the
  displayed text is correct even though it was baked at generate time), and — when every referenced label's
  live status is in `CONFORMANT` — replaces the row's own status with `'closed'`, so it stops counting as
  `unmodelled` anywhere a clause, a coverage tally or a clause ledger label reads it. A referenced label that
  is itself not conformant (or missing from this run) leaves the row `'unmodelled'`, surfacing the same
  regression the referenced row itself already reports, rather than papering over it.
- A clause-ledger fragment's `labels` can therefore reference either the underlying proc/trigger/behaviour
  verdict label directly, or the passive effect's own "checked by" label (`"<rank_id> e<effect>"`): both are
  now equally valid, since the proxy label carries the same live `CONFORMANT` status as the verdict it stands
  in for.

## Considered options for the live status

1. Keep reading `entry.get('status')` but require every class-file author to keep it in sync by hand.
   Rejected: this is exactly what produced the Scourgebane false "ok"; a derived fact duplicated by hand in a
   second file will drift.
2. Look the live verdict up by label from the same compare run, falling back only when none is available.
   Chosen: the status becomes impossible to desynchronize from the run it is reported alongside.

## Consequences

- A regression in a trigger/proc/behaviour entry that other effects cite as their only proof now shows up in
  every one of those "checked by" rows, in the same compare run, instead of being masked by a stale or
  nonexistent recorded field.
- The clause ledger's own proof check reads `Verdict.label`/`Verdict.status` directly from `verdicts.json`, so
  it was never exposed to the `linked_reason` text bug by itself; but before `resolve_linked_statuses` it was
  exposed to the separate `'unmodelled'`-forever bug above, for any clause whose label happens to be a
  "checked by" row rather than the verdict it points at. `resolve_linked_statuses` fixes that path too, since
  it rewrites the row's own `Verdict.status`, not just text a human reads.
- `coverage.py`'s existing "## Verdicts per status" tally (unrelated to the clause ledger) also stops
  overcounting `unmodelled` for every conformant "checked by" row, for the same reason.
- `templar_clauses.json` is produced once from a point-in-time `claims-merged.json`; a future audit revision
  needs the same generation step rerun (documented in `docs/ledger-format.md`), not a hand-edit of the ledger.
