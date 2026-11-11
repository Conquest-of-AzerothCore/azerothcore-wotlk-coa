# Investigating reported defects

Follow this sequence within the task's authorized scope:
**Report → inspect effective data → establish expected behavior → reproduce → minimal fix → verification → PR.**

- Treat the report as evidence to investigate. For spells and quests, inspect effective DBC/SQL data, acquisition
  and the execution path using the inspector and mechanic map. Derive expectations independently of the current
  implementation and use a metric that can distinguish correct behavior from the reported failure.
- Before changing gameplay, classify the finding as **confirmed defect**, **already works**, **incorrect test**,
  or **uncertain expectation**. Correct a faulty test; preserve evidence of working behavior; keep unresolved
  expectations explicit. Apply a gameplay fix only to an established defect.
- An audit report ("no script or aura handler") is not a defect by itself: native spell modifiers, stat auras or
  another handler may already deliver the tooltip. Trace the spell to the value the server actually uses.
- Fix only what the report describes. Record similar problems found along the way as observations, not changes.
- Add a focused regression for the fix and verify that it passes through `tools/verify_all.py`. Do not rebuild
  or run the pre-fix tree or `main` to show the regression failing, or to rerun tests the change did not add or
  touch. State when runtime verification is unavailable (an `unavailable` gameplay stage); explain the missing
  prerequisites and complete the remaining stages. Report their actual scope.
- Review the final diff. Continue to a PR when publication is part of the requested workflow; a local edit alone
  does not authorize a push or PR. Use the `coa-development` skill's issue queue workflow for an explicitly
  requested issue queue.
- In existing task/PR results, summarize available time from investigation start to verified outcome, observed
  regressions, flaky checks (different outcomes with unchanged inputs), and required human corrections.
  Mark unavailable measurements as unknown; do not infer zero or create separate tracking files for routine work.
