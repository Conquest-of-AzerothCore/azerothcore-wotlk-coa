# 0424. A stack-cap state read proves a no-stack clause

- Status: accepted
- Date: 2026-11-13

## Context

Chilling Presence 300958: "Does not stack with similar effects." Its `group_stack_cap` entry reads the caster's live
Frost spell crit chance (a state read) with neither spell, with 300958 and with Electrifying Aura 560568 of the same
spell_group learned too: 3.2817, 6.2817, 6.2817 (B3 side b, pairs prove-2 to final4). Coverage counted the verdict as
data, because a state read is behaviour only when the clause words name the stat (`STATE_PROMISES`), and this clause
names none (question Q-b3b-4). The mentor ruled (2026-11-13, G-21 point 2) that a state read can prove "does not
stack" when it reads the consumed value after one and after two or more real applications on one build, the second
from the similar source, and asked for a general rule in the tool mapping, not a per-row exception.

## Decision

`coverage.promised_state` treats a `behaviour_group_stack_cap` verdict as promised when its clause carries the no-stack
words (`NO_STACK_WORDS`, "does not stack" / "do not stack"). The judge already reads the consumed value after the own
spell alone and after the partner (the similar spell) too, and alerts on a summed reading.

## Consequences

- Every `group_stack_cap` state verdict on a no-stack clause counts as behaviour; on any other clause it stays data.
- Tests: `NoStackStatePromiseTest` (test_coverage.py) for both clauses and the unproven summed reading; the summed
  reading alerting is `AdditiveRelationTests.test_summed_crit_chances_alert` (test_behaviours.py).
