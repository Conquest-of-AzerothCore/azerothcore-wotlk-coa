# Conformance dispatch rules

The single source of the rules for every agent dispatched on class conformance work, the controller included
([ADR 0657](../adr/0657-dispatch-rules-and-model-effort-are-mandatory-for-class-work.md)). A class's plan links this
file or copies it; it does not rewrite the rules. The guide is [class-conformance.md](class-conformance.md).

Measured reason (Necromancer retrospective, agents only, input = uncached + cache read + cache write): the night and
cycle 1 took 3,505 M input tokens (2,083.8 M and 1,421.5 M), against 12.4 to 46.9 M for each of
the seven merged-pair cycles c11 to c18 (c16 had no pair of its own and is counted in c17).

## Rules

00. **Verification** (top of every author brief): verify only through `verify_all.py` or `coa-verify` selections; never
    run a unit test, a test method or an ad-hoc judge script directly. The conformance pipeline commands
    (`conformance.py generate`, `compare`, `audit`, `prove`) are not direct runs: use them as the pair procedure does.
    The integrator rejects any report that cites a direct test run as evidence.
0. **Owner rule, top priority (token use is a primary constraint):** never resume an agent for a new task. A resume is
   only for a follow-up on the same task (a fix to its own report, a missing check), and only when cheaper than a fresh
   agent with a handoff file. One agent per task, ended when the task is done. The controller too: no exploratory
   reads, grep or head on reports, short messages.
1. Fresh agents only (no fork). The brief points to files; it does not paste them.
2. Big files (`behaviours.py`, `compare.py`, `CoAGameplayTest.cpp`, ledgers, generated scenarios, run logs, verdict
   JSON) are read by grep or line ranges, never whole. Run output goes to files, read by grep.
3. The full report goes to the named file; the agent returns at most 15 lines (reviewers 10).
4. Verification goes through `coa-verify` or `verify_all.py` selections only; never run judges, tests or scripts
   directly.
5. Never wait in the background, never sleep-poll. The dispatch is the agent's task: it ignores messages that do not
   come from its controller session.
6. Read only what the task needs: the files the dispatch names, by grep. Do not read whole briefs of other batches.
7. A brief never says "read X in full" for the growing files (night and morning briefs, the mentor's decision logs, the
   rulings): it quotes the two to five decision lines the task needs, or names the grep pattern.

## Model and effort by task

Each brief states its model and effort.

| Task | Model | Effort |
|---|---|---|
| Read-only work, grouping, tables, reasons | Haiku or Sonnet | low |
| Entries on existing kinds, resizing, text SQL, clean merges | Sonnet | as the brief states |
| New kind design, defect cause, server fixes, C++ conflicts | Opus | as the brief states |

## Cadence (the default for every class)

1. Every cycle starts with a written plan: the claims taken and the target final count. There is no clock and no end
   time: speed comes from ordering and grouping, not from deadlines.
2. Order inside a cycle: (a) ledger-only and audit fixes counted by re-audit, no runs; (b) claims riding existing
   kinds; (c) new kinds grouped by tool, one author per tool group; (d) harness C++ only after a G-39 note.
3. At every cycle's triage, status 3 or 4 only after two genuinely different designs failed (the second-agent rule) or
   a proven impossibility. More than 90 agent-minutes only flags a claim for a design review with the mentor; it never
   closes a claim by itself.
4. The bench never idles: the next cycle's read-only work (grouping, designs, tables) runs while the merged pair runs.
5. Two authors at most, fresh agents.
6. Checkpoint after each merged pair: count, delta, the next cycle's plan and the cost, to the mentor in one message,
   and a report written at that checkpoint. The controller compacts its context at each checkpoint.
7. A cycle that gains less than half its target: the next plan says why and changes the split.

## Cost record

At each checkpoint the cost is recorded with `python -B apps/coa-gameplay-test/conformance/conformance.py cost
--transcripts <dir> --since <iso> --out cost.json` (aggregates per role: agents, input, cache read, output,
agent-minutes; no prompts, paths, session ids or user names). The step is optional for a contributor without
transcripts: the checkpoint then shows "not recorded" and nothing is estimated.
