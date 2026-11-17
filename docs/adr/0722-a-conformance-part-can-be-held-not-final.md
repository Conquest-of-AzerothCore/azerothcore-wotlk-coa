# 0722. A conformance part can be held not final

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

The Witch Hunter c10 review (C-1) found a part whose fix was not yet reviewed, `new 246.1`. Its runs could still count
it, as a candidate or through a status 1 kept from the record, before the review ends. The decisions file had no way
to keep one part out of the count with a stated reason. Mentor decision D-184 (under O-12) approved a `held` field.

## Options

- Remove the part from the ledger until the review: loses its key, its record row and its runs.
- A ruling: rulings give status 2 to 5 and need owner grounds; a held part has no final status yet.
- A `held` field `{key: why}` that the tally checks first and that keeps the part not final.

## Decision

`decisions.json` takes `"held": {"new 246.1": "c10 C-1, fix not reviewed"}`. `tally.classify` checks `held` before
rulings, flips, candidates, counted and the record: a held key is "not final" with the basis `held` and the detail
`held: <why>`. The tally stops when a held key names no claim of the ledger, or when it is also listed under
`candidates` or `counted`. The tally lines (`HELD key why`), the status file and the checkpoint (`held`, `- Held:`)
list the held parts and their reasons.

## Consequences

- A held part recorded at status 1 is lost from the count until the hold is removed, and the checkpoint says why.
- Templar 19 and Necromancer 23 have no `held` in their decisions files: their tallies are unchanged.
- Seeded tests: a held status 1 record part must not count (the alerting mutant), a hold comes before a ruling, an
  unknown held key and a held key also a candidate or counted stop the tally, and the checkpoint lists the parts.
