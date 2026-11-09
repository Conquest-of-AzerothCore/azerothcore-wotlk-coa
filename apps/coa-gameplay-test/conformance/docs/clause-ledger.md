# Clause ledger and clause coverage

A clause ledger (`classes/<name>_clauses.json`) is the per-class list every tooltip clause reduces to, used to
report how many are actually proven by the current measurements rather than how many spells have *some*
verdict.

## File format

A JSON array. Each entry is one clause:

```json
{"spell": 92111, "clause": "dealing an additional $801832s2% Weapon damage", "labels": ["92111 effect_value 801832e1 #0"],
 "kind": "claim"}
```

- `spell`: the spell id the clause's tooltip belongs to.
- `clause`: the exact clause text, as split out by the class's clause audit (so it can be traced back to that
  audit and to the tooltip itself).
- `labels`: the `Verdict.label` values (from `verdicts.json`, e.g. `write_verdicts`'s output) whose status
  proves this clause. Empty until a workstream's fragment (below) supplies them. A label may be a passive
  effect's own "checked by ..." label rather than the verdict it points at: `compare.resolve_linked_statuses`
  (ADR 0052) gives that label the same live `ok`/`tolerated`/`closed`/`alert` status as the thing it is
  checked by, so either label proves the clause equally.
- `kind`: `"claim"` for a clause with a gameplay meaning to prove, or `"no_claim"` for a line that carries no
  mechanic (a level-gate label, an empty tooltip, flavour/acquisition text). A `"no_claim"` entry also carries
  `"reason"`, the audit's note explaining why.

## How a workstream contributes

A workstream other than the one that owns and merges the ledger never edits `classes/<name>_clauses.json`
directly. It writes its own fragment, an array of:

```json
{"spell": 92111, "clause": "<exact clause text from the clause audit>", "labels": ["<verdict label>", "..."],
 "kind": "claim"}
```

The integrator merges these fragments into the ledger by matching on `(spell, clause)` and replacing that
entry's `labels` (a `kind: "no_claim"` entry is never produced by a fragment; only the ledger's initial
generation from the clause audit sets it).

## Coverage

`coverage.clause_coverage(clauses, verdicts)` returns `(proven, total, unproven)`:

- `total` counts only `kind: "claim"` entries (`no_claim` entries are never part of the denominator).
- A claim is **proven** when it has at least one label and every one of its labels' live verdict status (from
  the `verdicts` list passed in — always the same compare run being reported on) is `ok`, `tolerated` or
  `closed` (`compare.CONFORMANT`). A claim with no labels yet, or any label whose live status is anything else
  (including a label that is simply absent from this run's verdicts), is unproven.
- A label may omit the trailing `" #<ordinal>"` that `values.py` appends when a spell has several tokens of
  the same effect/spell/kind (`92111 effect_value 801832e1`, not `92111 effect_value 801832e1 #1`) — the audit
  (`claims-merged.json`) writes labels this way since it cannot predict the ordinal a future generate run will
  assign. `resolved_labels(label, statuses)` expands such a label to every verdict label in this run that
  starts with `"<label> #"` followed by digits; the clause needs every one of those matches present and
  conformant (not just one), since each is a distinct occurrence of the same clause in the tooltip. A label
  that already ends in `" #<ordinal>"` is matched exactly, never expanded.
- `unproven` is the list of clause entries that did not qualify, for printing with their tooltip words.

Run it from the command line together with the ordinary before/after coverage report:

```
python conformance.py coverage --before <dir> --after <dir> --clauses classes/templar_clauses.json
```

This prints `clauses proven: N of M (P%)` followed by every unproven clause's spell id, text and current
labels, read from `--after`'s `verdicts.json` — so the number always matches the run being reported on, never
a cached or hand-recorded count.
