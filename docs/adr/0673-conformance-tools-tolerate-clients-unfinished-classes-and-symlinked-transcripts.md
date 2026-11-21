# 0673. Conformance tools tolerate older MySQL clients, unfinished classes and symlinked transcripts

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Three small defects of the conformance tools stopped a Witch Hunter cycle: `scaffold.py` passed `--no-login-paths` to a
MySQL 8.0 client that refuses it, the digests step of `conformance.py cycle` ran `snapshots.py check` for the cycle's own
class although `snapshots.py` accepts only finished classes, and `conformance.py cost` did not see transcripts behind a
symlinked `subagents` directory.

## Options

- Drop `--no-login-paths` everywhere: weakens the defaults-file isolation for clients that support it.
- Detect support from the client's `--help` (the precedent of `apps/coa-world/world_data.py`), keeping the option when it
  is listed or when the help is unreadable.
- Make `snapshots.py` accept unfinished classes: it is the finished-class guard by design.
- Let the cost role sort prefer author, integrator and fix keywords over read-only: ADR 0656 fixes the order
  (independent reviewer, integrator, read-only, fix, else author) and has no author keywords.

## Decision

- `scaffold.local_select` adds `--no-login-paths` only when `mysql --help` lists it; an unreadable help keeps it.
- The cycle's digests step skips the own-class check (and `--write-digests`) when the class is not in
  `snapshots.GENERATIONS`, and writes a note line; the gate step is unchanged.
- `cost.transcripts` walks the transcripts directory following symlinks and visits each real directory once, so a link
  loop ends.
- The role sort of ADR 0656 is unchanged: a first prompt that says "read-only" about other files stays read-only by that
  ADR. A change of that order needs its own ADR that supersedes 0656.

## Consequences

- Seeded tests: `test_scaffold.py` (login path options), `test_cycle.py` (unfinished class digests), `test_cost.py`
  (symlinked directory and loop).
- No class data and no server code change.
