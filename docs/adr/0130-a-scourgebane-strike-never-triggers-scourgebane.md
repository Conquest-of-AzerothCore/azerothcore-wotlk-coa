# 0130. A Scourgebane strike never triggers Scourgebane; proc entries can count procs per trigger

- Status: accepted; the "20% per weapon hit" summary of its Context is superseded by ADR 0301
- Date: 2026-11-11

## Context

Scourgebane 92111 reads "Direct damage dealt now has a $520007h% chance to strike an enemy with Scourgebane"
(`$520007h` is 520007 `ProcChance` 20). The strike 801832 is itself direct damage, so the text can be read both
ways. Round 4 (`624426dbe5`) kept the reading "every direct damage event, Scourgebane strikes included" from
same-millisecond groups in the Ascension logs; round 10 then made the server chain (`822b1f5a74`: 801832 exempted
from the reentrancy guard and from the `Derived()` exclusion in `AscensionTemplarEvents.cpp`) so that the summed rate
of that reading would pass, and capped the chain at 8 strikes (`59cac10ecd`). No ADR recorded the chain reading; the
cap stood as a ruling line in `docs/coa/templar-completion.md`.

The prototype's K4 diagnosis (`.agents/plans/class-conformance-3/prototype/k4-report.md`) showed that the summed
rate (strikes over swings plus strikes) gives 0.20 for a 20% chain and for a 25% server without one alike, that the
chaining server gave 2 to 4 strikes on 77 of 1540 one-swing trials, and that after 1229 isolated melee swings in the
Ascension logs 263 gave a strike on the swing's target and 1 a second one, where a chain gives about 64. A player
report of 2026-11-07 says "Scourgebane does not proc off itself." The owner ruled on 2026-11-11
(`owner-rulings-2026-11-10.md`, "Prototype score (G6) rulings"): revert `822b1f5a74`; a Scourgebane strike never
triggers another one (20% per weapon hit, as the live logs show); the check counts strikes per swing.

## Considered options

1. Keep the summed rate and only revert the server. Rejected: that rate cannot tell a chain from a higher chance.
2. Count swings with at least one strike. Rejected alone: it passes a chaining server (0.2045 in K4).
3. Read the counts around every swing and judge both the multiplicity and the rate of one-hit swings. Chosen.

## Decision

- Server: `AscensionTemplarEvents.cpp` is back to its state before `822b1f5a74` for Scourgebane: the reentrancy
  guard and the `Derived()` exclusion refuse 801832 for every aura of the switch. The 8-strike cap
  (`MaxScourgebaneStrikesPerChain`, `TemplarState::scourgebaneDepth`) is removed: it was read only when the chain
  exemption held, so no reachable path reaches it.
- Tool (class-agnostic): a `procs` entry with an `attack` trigger may state `most_procs_per_trigger` with its citation
  in `most_procs_per_trigger_source`. Each auto attack is then its own trigger, read before and after; the judge keeps
  triggers with exactly one landed main-hand hit, alerts when any gives more procs than the limit, and otherwise
  judges one-hit triggers with a proc over one-hit triggers by the Wilson rule. Such an entry has no `trial_readings`.
- Templar class file: Scourgebane states `most_procs_per_trigger` 1, citing the ruling, the log count and the player
  report; its "Scourgebane strikes included" reading is removed.
- Regression: `templar-scourgebane-chain-cap` becomes `templar-scourgebane-strike-never-retriggers`: the chance is
  forced to 100% through Pure Focus and every landed swing gives exactly 1 strike (the chaining server gave 8).
- The round 4 ruling is withdrawn for Scourgebane only; Lightkeeper and Condemnation keep "each damage tick".

## Consequences

- Scourgebane yields about 20 strikes per 100 weapon hits instead of about 25.
- Per-trigger parts read two counts per swing: 13 parts of 197 swings for 20%, as before.
- Abilities' direct damage still rolls the chance in the server (`Check()` case 92111/520007); the per-trigger check
  covers auto attacks only.
