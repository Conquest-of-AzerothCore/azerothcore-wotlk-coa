# 0310. A class's first clause ledger is generated from data by fixed rules

- Status: accepted
- Date: 2026-11-12
- Supersedes: ADR 0302's decision that no repository command builds a first ledger. The rest of ADR 0302 stays in
  force.

## Context

The Templar ledger came from an agent audit whose splitting instructions and conversion step were never committed
(ADR 0302). A new class, the Necromancer first, needs a ledger before its batches start. Writing it by hand again
costs an audit per class and gives a cut that no one can reproduce.

## Considered options

1. Hand-write each class's ledger by the rules of guide section 9.4. Rejected: not reproducible, and the cost repeats
   per class.
2. Generate the cut and the claims with a language model. Rejected: not deterministic, and its claims would be
   unchecked text.
3. Cut by fixed text rules, and take the labels from the value scenarios that `generate` writes. Chosen.

## Decision

- `conformance.py ledger --class N --out FILE [--dbc-dir DIR] [--text-basis SPELL=BASIS ...]` (`ledger.py`) writes the
  first ledger of a class. The rules are in `apps/coa-gameplay-test/conformance/docs/clause-ledger.md`, "Writing a
  first ledger".
- Clauses are cut at lines and sentences, and inside a sentence only where both sides state a value and the left side
  does not end with a function word.
- `no_claim` comes only from three fixed patterns: an empty tooltip, a level label line and a trainer-location
  `@ext` note. Owner rulings still add the others afterwards.
- Labels are the value scenario's labels of the clause's `$` tokens, matched by ordinal. The command declares no
  `claims` and adds no behaviour, proc or trigger labels.
- The basis of a streamed text is a judgement, so the command takes it as input and stops without it. The other
  `text_source` fields come from the SQL file and the commit that added it.
- The generator is used for first ledgers only. A generated ledger then changes by merged fragments and owner rulings,
  like the Templar ledger. The Templar ledger is not regenerated.

## Consequences

- A class's first ledger is reproducible: the same DBC set, SQL updates and class file give the same bytes.
- The cut is coarser and more regular than the Templar audit's: on class 19 it gives 362 entries, 187 of them with the
  exact `(spell, clause)` of a hand-ledger row, out of 452. Batch authors split clauses further and declare `claims`
  where a clause's labels do not cover each stated value.
- A spell whose value scenario raises `Unmodelled` gets clauses without labels, and the command lists it.
- `classes/necromancer_clauses.json` is the first ledger written this way.
