# Server-fix brief

The template a conformance round uses to hand a suspected server defect to the agent that fixes it, and the rule
that brief must satisfy. Round workflows copy the template below into each fix item's prompt.

## Method rule (owner, 2026-11-11)

No server change whose only evidence is our own check. A server fix cites independent evidence: the tooltip text,
the Ascension logs, or an owner ruling (`owner-rulings-2026-11-10.md`, "Prototype score (G6) rulings"; ADR 0128).

- A conformance alert is a lead, not evidence. It names a clause and a measurement; the expected value it compares
  with must itself come from one of the three sources, quoted in the brief.
- A server change made so that a check passes, without such a source, is refused (the case that led to the rule:
  a Scourgebane strike chain added in round 10 so that a reading would pass, where the live logs show about one
  chained strike against the chain's about 64; prototype `mentor-review-g6.md`, "Owner report points").
- Without independent evidence the item is classified as an incorrect test or an uncertain expectation (the
  AGENTS.md defect sequence) and goes to the owner as a question, with both readings and what each would measure.
- The Ascension logs are read through `~/Projects/coa-log-history` (private): a brief cites the query and the
  figure, never raw log lines or player names. Logs that are silent on the point are not evidence for a change.
- Server fixes stay per class: never link one class's effects to another's.

## Template

```
Fix item: <spell name> [<spell id>] — "<the tooltip words of the clause>"

Check: <verdict label> <status>: measured <value> against expected <value> (<run report path>, both runs).

Independent evidence (at least one; the check above is not one):
- Tooltip: "<quoted Description[enUS] text>" (<spell id>, server DBC set /srv/coa/server-data/dbc), reading
  <the value it states>.
- Ascension logs: <coa-history query> -> <figure> (no raw lines, no names).
- Owner ruling: <file>#<section>, "<quoted decision>".

Expected behaviour derived from that evidence, not from the server code: <statement>.

Root cause: <file:line> (reproduced: <scenario or run>), or "not proven" (then no fix: owner question).

Classification: confirmed defect | already works | incorrect test | uncertain expectation.

Change: <per-class server change>, regression <scenario or test> that fails without it.
Verification: coa-verify --worktree <worktree> --ram --stages build,gameplay --scenario <paths> (twice), then
--stages source --base origin/main.
```

A brief missing the evidence block, or citing only the check, is returned to the round before any server edit.
