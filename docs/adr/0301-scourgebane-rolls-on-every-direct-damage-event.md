# 0301. Scourgebane rolls on every direct-damage event, and a strike never chains

- Status: accepted
- Date: 2026-11-12
- Decision by: the owner, follow-up ruling of 2026-11-11 (method-study/owner-rulings-2026-11-10.md, "Lean package
  follow-up rulings, 2026-11-11")
- Supersedes: the summary "20% per weapon hit, as the live logs show" in ADR 0130's Context and the same words in
  `docs/coa/templar-completion.md`. The rest of ADR 0130 stays in force.

## Context

ADR 0130 records the owner's ruling that a Scourgebane strike 801832 never triggers Scourgebane 92111 again. Its
Context summarises that ruling as "20% per weapon hit, as the live logs show", and `docs/coa/templar-completion.md`
repeats the words. The question that ruling answered had itself said "per weapon hit". In a follow-up ruling of the
same day the owner stated that this wording was wrong and that the ruling meant only "no chain":

- the tooltip governs: "Direct damage dealt now has a $520007h% chance to strike an enemy with Scourgebane"
  (`$520007h` is 520007 `ProcChance` 20);
- weapon hits and direct-damage abilities roll the chance;
- a Scourgebane strike never triggers another;
- this is the server after 193fd28acb, with nothing to change.

ADR 0130's own Consequences already say that abilities' direct damage still rolls the chance
(`AscensionTemplarEvents.cpp`, case 92111/520007: `damage && !periodic`; the strike 801832 itself is refused by the
reentrancy guard and the `Derived()` exclusion, as ADR 0130's Decision says). Only the summary sentence was stale.

## Considered options

1. Edit ADR 0130's sentence. Rejected: an accepted ADR is not rewritten.
2. Record the corrected reading in a superseding ADR and correct the current documentation. Chosen.

## Decision

- Scourgebane's chance is 20% per direct-damage event: weapon hits and direct-damage abilities roll it, periodic
  damage does not, and a Scourgebane strike never chains.
- ADR 0130's status names this ADR for its summary sentence; its body stays as written.
- `docs/coa/templar-completion.md` states the corrected reading.
- No server, class-file or scenario change: the server, the `most_procs_per_trigger` entry and the regression
  `templar-scourgebane-strike-never-retriggers` of ADR 0130 already match it.

## Consequences

- The per-trigger check of ADR 0130 still covers auto attacks only; it proves "no chain" on weapon hits and does not
  measure the abilities' roll.
- A later class that reads a "Direct damage dealt" proc cites this ADR, not ADR 0130's summary, for the scope of the
  roll.
