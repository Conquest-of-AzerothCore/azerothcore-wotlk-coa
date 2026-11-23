# 0304. Pulled sentences join the parent tooltip's clauses in a first ledger

- Status: accepted
- Date: 2026-11-13
- Amends: ADR 0310 (the generator's clause and label rules). ADR 0310 stays in force otherwise.

## Context

A tooltip can pull in another spell's sentences through `@s:<spell>:<flags>@` markup. The player reads them as part
of the parent tooltip. The `ledger` command of ADR 0310 removed the markup from the words and gave the pulled
tokens' labels to the clause the markup joined, so a pulled sentence had no row: Frenzied Ghoul 707014's "Immune to
movement slowing effects." under Ghoul Frenzy 503740, Tundra Warriors 707421 under 92122. Owner ruling G-5
(2026-11-10): a pulled sentence counts only if its spell is not evaluated on its own, and then joins the parent
tooltip's clauses.

## Considered options

1. Keep the pulled tokens' labels on the clause that holds the markup and add the pulled sentences without labels.
   Rejected: that clause would carry values it does not state.
2. Add one entry per pulled clause, cut by the same rules, and give it the labels of its own tokens. Chosen.

## Decision

- A pulled spell's Description is cut by the clause rules, and each clause becomes an entry of the parent spell,
  after the clause holding the markup, in the pulled spell's exact words. Nested markups unfold the same way.
- A pulled spell in the class spell set (any rank of a class spell) adds no entry; its tokens stay with the clause
  that holds the markup. So does a markup the tooltip reader refuses.
- Labels follow the existing ordinal mapping: a pulled clause gets the labels of its own tokens, and the clause
  holding the markup keeps only its own.

## Consequences

- `generate` is unchanged: the class 19 scenarios, plain and `--stack`, are byte-identical.
- On class 19 the run gives 401 entries instead of 362, and still 187 exact `(spell, clause)` matches with the hand
  ledger, which has no pulled rows.
- On class 23 the run adds 19 entries over 9 spells. The committed `classes/necromancer_clauses.json` is not
  regenerated (ADR 0310: a ledger changes by fragments); its clauses that hold a markup still carry the pulled
  tokens' labels until a fragment moves them.
