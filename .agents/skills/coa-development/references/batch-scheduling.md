# Batch scheduling

How to schedule a selected issue queue. [issue-queue](issue-queue.md) keeps every ownership, branch, review,
commit, push, PR and closure rule; this file changes only selection display, ordering and parallelism. Adapted
from lostmind84's coa-server-guide (`skills/coa-fix-issues-batch`, `skills/coa-triage`, `agents/coa-triage.md`).

## Show the table before choosing

With no issue numbers, topic or explicit `all`, show a batch table and wait for the user's choice; do not
silently start every open issue.

- With the guide installed (`COA_SERVER_GUIDE` set), run `python "$COA_SERVER_GUIDE/scripts/coa-triage-table.py"`
  (`--refresh` only on request or a demonstrably stale cache) and print its table unchanged.
- Otherwise build one Markdown table from paginated issue metadata: `Batch | Total | Why it matters | Proof |
  Assigned`. Group deterministically, first match wins: spell audit reports by class, crashes, class label,
  class named at the start of the title, then theme (resources; summons and pets; talents and specs; items, bank
  and vanity; quests, world and creatures; systems and modes; client UI; unsorted). `Total` is a count, not issue
  numbers. `Proof` names the harness from the proof ladder in `SKILL.md`.
- Select by content, not by a class label alone: a class label often names the reporter's class.

## Ledger and lanes

Keep a compact ledger in the conversation: `number | lane | shared cause | proof | owner | status`. Rank from
metadata only; do not claim or deep-read the whole queue. Confirm or change the lane after the issue's full read.

1. **Fast disposition** — a merged PR already fixes it, exact duplicate, clearly invalid, or calibrated evidence
   that the behavior is not obtainable. Absence from this fork's database alone is never proof.
2. **Source-only** — docs, tooling, a test correction, or a fix whose contract is fully settled by source and data
   and needs no runtime proof.
3. **Shared runtime proof** — confirmed fixes provable by the same scenarios. Group by root cause and test
   surface, not by class or keyword.
4. **Individual runtime or client proof** — one-off mechanics or client-only symptoms.
5. **Unclear or blocked** — missing expectation, conflicting evidence, ownership conflict, unavailable
   prerequisite. Record the concrete blocker and move on.

Drain lanes 1 and 2 first, prepare lane 3 while lane 4 is investigated in parallel, and return to lane 5 only when
new evidence removes its blocker. A user-specified order or a demonstrated dependency wins.

## Time boxes

- Initial read of a claimed issue: about two minutes, enough for expected result, likely cause, proof type and
  ownership risk. Otherwise mark it `unclear` and defer the deep read.
- A shared source investigation: about ten minutes before deciding whether it has a grounded next step.
- Reproduction: the reported scenario plus one or two variants, then write the result down.
- Do not spend gameplay time disproving what source tracing or calibrated acquisition evidence settles, and do not
  rediscover a shared root cause per issue: link the reports and give one agent the shared investigation.

## Parallelism

- Parallelize read-only triage, source tracing and isolated source fixes, each implementer in its own worktree.
- Serialize everything that mutates shared state: the build directory, `verify_all.py` gameplay stages, databases,
  server slots, client lab instances.
- Build and verify once per ready cohort, not once per file or per issue. Attribute a result to a fix only when
  the tested tree contained it, and record the tested commit.
- Investigators write findings to `.agents/plans/<batch>/<issue>.md` and return at most 15 lines; the controller
  owns claims, classification, commits, pushes, PRs and issue comments.

## Decisions in auto mode

`auto` replaces routine questions with recorded decisions. Write each one as it is taken to
`.agents/plans/<batch>/decisions.md`: the question that would have been asked, the option chosen, the reason, and
whether it is reversible. The file is gitignored: summarize it in the final report and copy the relevant entries
into the PR body.

- Interpretation of missing server logic, or a change against an explicit maintainer decision: change nothing,
  classify as needing a maintainer decision, list it in the PR as examined but not fixed.
- A value only a community snapshot provides: use it only when exactly one calibrated source gives it, the
  installed DBC, DB and code lack it, and the user has approved the choice (`.agents/rules/general.md`); name
  source and snapshot date in the commit and PR. Without approval, mark the issue blocked, record the question
  for the final report and continue the batch. With no single calibrated source, treat it as an interpretation
  question.
- Anything else: take the option you would recommend, or the most conservative one.

Hard stops end the run with a report instead of waiting mid-run: a red preflight that cannot be fixed, a resource
owned by someone else, and anything marked "ask the user first".

## Measuring

Track wall time for triage, source work, build and runtime proof, review and external waits. Compare batches only
when start and end points and proof scope match; fewer tool calls alone are not a measured speed-up.
