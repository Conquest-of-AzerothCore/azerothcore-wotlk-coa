# 0302. The clause ledger has no committed generator; its format lives in clause-ledger.md

- Status: accepted
- Date: 2026-11-12
- Supersedes: ADR 0052's sentence that a future audit revision reruns "the same generation step ... (documented in
  `docs/ledger-format.md`)". The rest of ADR 0052 stays in force.

## Context

ADR 0052 says that `templar_clauses.json` is produced once from a point-in-time `claims-merged.json` and that a
future audit revision reruns the same generation step, "documented in `docs/ledger-format.md`". That page was never
committed, at the repository root or under `apps/coa-gameplay-test/conformance/docs/`, and neither was the
conversion step: commit e32d5308b5 adds the ledger and no generator. The audit file `claims-merged.json` is not in the
repository either.

ADR 0052's counts, 450 clauses with 434 claims and 16 `no_claim` rows, are the ledger as e32d5308b5 added it
(2026-11-09). Since then rows have changed only by merged fragments and owner rulings: the ledger holds 452 entries,
435 claims and 17 `no_claim` rows, at b6529634cb and at bc391cd7bc.

## Considered options

1. Edit ADR 0052's sentence. Rejected: an accepted ADR is not rewritten.
2. Write `docs/ledger-format.md` now. Rejected: the format is already documented in
   `apps/coa-gameplay-test/conformance/docs/clause-ledger.md`, and a second page would drift from it.
3. Point to the pages that document the ledger and state that no generator exists. Chosen.

## Decision

- The ledger's format is `apps/coa-gameplay-test/conformance/docs/clause-ledger.md` ("File format", "Stated claims",
  "How a workstream contributes").
- How a class's first ledger is written, and the rules the Templar ledger applies, are in
  `docs/coa/class-conformance.md`, section 9.4.
- No repository command builds a first ledger. A generator is future work; until it exists, a new class writes its
  ledger by the rules of section 9.4 and changes it afterwards only by merged fragments and owner rulings.
- ADR 0052's status names this ADR for that sentence; its body stays as written.

## Consequences

- A reader of ADR 0052 is sent to pages that exist.
- Ledger counts are quoted at a named commit, because they change with every merged fragment.
