# 0583. Class conformance ADRs live in a per-class folder; shared ADRs and common rulings are numbered at merge

- Status: accepted
- Date: 2026-11-13

## Context

The Necromancer conformance work wrote its class fixes and their regressions as ADRs in `docs/adr/` next to the tool
decisions every class uses, from number blocks reserved per author before launch (`docs/coa/class-conformance.md`,
section on batch lessons). Two classes worked in parallel would draw from the same sequence, and a reader of the shared
sequence meets class-only fixes among the rules that bind every class. Five ADRs (0383, 0530, 0533, 0534, 0547) and
0561 held both a class fix and a tool rule. The Necromancer owner rulings shared one page with the common rules and
the Templar precedents. The mentor ruled on 2026-11-13 (contributor structure, rulings 1 to 3, and the 14:26 note):
shared ADRs keep their numbers until publication; mixed ADRs are split before publication; class ADRs move to a class
folder and are cited as "Necromancer ADR 00NN"; the Necromancer rulings move with them.

## Considered options

1. Keep one sequence and pre-allocated blocks per author. Rejected: numbers collide across classes and branches, and
   class fixes crowd the shared sequence.
2. One folder per class, numbered inside the folder; shared ADRs in `docs/adr/`, numbered at merge. Chosen.

## Decision

- A class's own conformance ADRs (its fixes, their regressions, its class-scoped method choices) live in
  `docs/adr/conformance/<class>/NNNN-<slug>.md`, numbered from 0001 inside the folder, with a `README.md` index and the
  class's owner rulings in `rulings.md`. The Necromancer's 32 are there, in the order of their old numbers.
- Prose cites a class ADR as "Necromancer ADR 00NN" with a relative link; a JSON string cites it as plain
  "Necromancer ADR 00NN".
- An ADR that holds a class fix and a tool rule is split before publication: the class half goes to the class folder,
  the tool half keeps its number in `docs/adr/`; each half names the other.
- Shared ADRs and common rulings (G-n) written on a class branch are provisional until merge: a PR's shared ADRs take
  the next free numbers just before merge, renumbered inside the PR. This retires the per-author number blocks for
  shared ADRs.
- `docs/coa/class-conformance-rulings.md` keeps only the rules that bind every class and the Templar precedents.

## Consequences

- Generated Necromancer scenarios carry the new citation strings; Templar output is unchanged (its class file cites no
  Necromancer ADR).
- Tool tests read a frozen copy of `necromancer.json` (ADR 0580), taken after the citation rewrite.
- A renumbering of shared ADRs at merge repeats the citation rewrite with the same mapping check and regenerates the
  Necromancer output in that commit.
- Gitignored verdict files under `.agents/plans` keep the old numbers; no tool reads them.
