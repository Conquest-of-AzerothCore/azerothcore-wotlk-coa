# 0598. Conformance contributors own their class; the owner owns the shared tool, harness and engine

- Status: accepted
- Date: 2026-11-13

## Context

Class conformance is opening to contributors who each take one class. The Templar and Necromancer work showed which
files one class's work touches and which every class depends on: the tool core, the gameplay harness, the engine,
the fixtures, the shared ADRs and rulings. Without a written split, a contributor's change to a shared file reaches
every class unreviewed, and two contributors collide on the same shared numbers. The contributor-structure plan
(requirement 7) and the mentor's rulings (2026-11-13) ask for the split, a way to propose changes to the owner's part,
the PR-time numbering rule, and the residual risks in the guide.

## Considered options

1. No written split; review decides each time. Rejected: the cost falls at review, after the work.
2. A split by file, in the contributor guide, checked against the files the source suites protect. Chosen.

## Decision

- `docs/coa/class-conformance.md` section 14 lists what a contributor owns (its class file and ledger, its C++, its
  `pending_db_*` SQL, its ADR folder and rulings, its snapshot digests, new kind and option modules with their tests)
  and what the owner owns (the tool core, the harness, the engine, `tools/check_source.py`, the fixtures, the shared
  ADRs and G-rulings, other classes' snapshots, the finished-class list).
- A change to an owner file is proposed as a shared ADR draft with a provisional number plus the section 7 fix note
  or the 9.7 tool note, to the mentor or, without one, to the owner; it lands with its ADR.
- A PR's shared ADRs take the next free numbers just before merge, renumbered inside the PR (ADR 0583).
- The guide states the agent rules and the cadence every conformance session follows, the cross-class guard tests,
  and the residual risks.

## Consequences

- A contributor can tell from the path whether a change needs a proposal.
- The list must follow the source suites: a new shared file or suite updates section 14 in the same commit.
