# 0657. Dispatch rules and model and effort are mandatory for class work

- Status: accepted
- Date: 2026-11-14

## Context

The Necromancer rules (never resume an agent for a new task, fresh agents with file-pointing briefs, ranged reads, reports
to files, verification through `verify_all.py` only) lived in the class's plan folder and were copied by hand. They are
class-neutral. The retrospective measured the effect: the night and cycle 1 took about 3,505 M agent input tokens
(2,083.8 M and 1,421.5 M), against 12.4 to 46.9 M for each of the cycles c11 to c18 that followed the rules. The model and
effort of an agent were not part of the rules: Opus ran 101 of the 120 agents.

## Options

- Keep the rules in each class's plan and copy them: they drift, and a new contributor never sees them.
- State them only in the guide: the guide is a long document and a brief cannot point to a short file.
- One short file, linked from the guide as mandatory, copied or linked by a class plan.

## Decision

`docs/coa/conformance-dispatch-rules.md` is the single source: rules 00 and 0-7, a model and effort table, the cadence,
and the cost record. Its table: read-only work, grouping, tables and reasons are Haiku or Sonnet at low effort; entries
on existing kinds, resizing, text SQL and clean merges are Sonnet; new kind design, defect cause, server fixes and C++
conflicts are Opus. Each brief states its model and effort. The controller compacts at each checkpoint, and the cost is
recorded with `conformance.py cost` (ADR 0656), or the checkpoint shows "not recorded". The guide (sections 9.0 and
9.8) links the file as mandatory. A class plan links it and does not rewrite a rule.

## Consequences

- Section 14.6 of the guide keeps its own list; the dispatch-rules file is the source if they differ, and 14.6 is to be
  reduced to a link when next edited.
- A class that wants a different rule writes an ADR superseding this one.
- No code change.
