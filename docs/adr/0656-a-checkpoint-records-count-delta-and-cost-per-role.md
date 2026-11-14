# 0656. A checkpoint records the count, the delta and the cost per role

- Status: accepted
- Date: 2026-11-14

## Context

The Necromancer retrospective computed the run's cost for the first time after the fact, from the controller, mentor and
subagent transcripts: 5,020.7 M agent input over 120 agents, of which the night and cycle 1 took about 3,505 M against
12.4 to 46.9 M per late cycle. The per-cycle and per-role split existed only in scratch scripts, so no checkpoint could
show that a cycle had become expensive. The guide (section 10) says its costs come from working records that are not in
the repository.

## Options

- Keep the scratch scripts per class: each contributor rewrites the method, and the role rule drifts.
- Record cost in the checkpoint from the transcripts, by a repository tool with a required path argument.
- Read the transcripts from `~/.claude` by default: a default path exposes home paths and sessions, and ties the tool to
  one agent product layout.

## Decision

A checkpoint records the final count, the delta and the cost per role. The cost comes from `conformance.py cost
--transcripts <dir> --since <iso> [--until <iso>] --out cost.json` (`cost.py`):

- `--transcripts` is required and has no default.
- One usage per message id (the last line carrying it), synthetic messages skipped, ids deduplicated across files;
  input = uncached + cache read + cache write.
- The role (`author`, `integrator`, `read-only`, `fix`) comes from the agent's first prompt and its description, by the
  rule order of the retrospective: an independent reviewer prompt, then integrator keywords, then read-only, then fix,
  else author. Controller sessions are one `main` bucket.
- The output holds aggregates only: per role the agent count, input, cache read, output and agent-minutes. No prompt,
  file path, session id or user name is written, here or in a checkpoint.

The step is optional for a contributor without transcripts: the checkpoint shows "not recorded" and no figure is
estimated. On the Necromancer transcripts the tool reproduces the retrospective's per-role agent counts, agent-minutes
and tokens.

## Consequences

- Test: `test_cost.py` on a small synthetic transcript fixture (`fixtures/cost/`); no real transcript is committed.
- `conformance.py` gains a `cost` subcommand; no class data and no server code change.
- The checkpoint file of `conformance.py cycle` (ADR 0655) carries the cost block when it was recorded.
