# 0128. Server fixes cite independent evidence, never only our own check

- Status: accepted
- Date: 2026-11-11

## Context

Round 10 briefs told agents that "a new check that shows the server breaks the tooltip is a server defect: fix the
server" (the round 10 workflow preamble; quoted in ADR 0054). In round 10 the Scourgebane strike chain was added to
the server (822b1f5a74) so that the check's reading would pass, while the live logs show about one chained strike
where a chain would give about 64 (prototype `mentor-review-g6.md`, "Owner report points"). The owner ruled on
2026-11-11: no server change whose only evidence is our own check; a server fix cites independent evidence, the
tooltip text, the Ascension logs or an owner ruling (`owner-rulings-2026-11-10.md`, "Prototype score (G6)
rulings").

## Considered options

1. Keep the round 10 sentence and rely on review. Rejected: the review accepted the Scourgebane chain.
2. Write the rule into the conformance docs and give round workflows one brief template whose evidence block a fix
   item cannot leave empty. Chosen.

## Decision

- `apps/coa-gameplay-test/conformance/docs/fix-brief.md` states the rule and the server-fix brief template: the
  check, then at least one independent source (quoted tooltip text from the server DBC set, an Ascension log query
  and figure without raw lines or names, or an owner ruling with its file and section), the expected behaviour
  derived from it, the proven root cause, the AGENTS.md classification, a per-class change and its regression.
- Without independent evidence an item is an incorrect test or an uncertain expectation and goes to the owner.
- The conformance README states the rule and links the template.

## Consequences

- Round workflows copy the template into each fix item instead of the round 10 sentence; that sentence no longer
  applies.
- A check whose expected value is right but unsupported by the three sources cannot drive a server change until the
  owner rules.
