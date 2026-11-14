# 0548. A condition contrast proves a condition claim

- Status: accepted
- Date: 2026-11-13

## Context

Death and Ice 560012 states "While a Skeletal Mage is active the critical strike chance of your Undead minions is now
increased by $523613s2%." The ledger splits it into the condition claim "While a Skeletal Mage is active" (106.0) and
the effect claim. The `mage` entry reads the live Ghoul's crit chance with the talent known in both phases, without and
with a Skeletal Mage raised (`setup_only_after`, the condition contrast): 5, then 15. The audit counted a state read as
behaviour only in a learned contrast, so the condition claim stayed data although the read is exactly the condition
the claim states. The controller asked for the smallest extension.

## Decision

- `coverage.promised_state` accepts a `behaviour_metric_delta` state read in the condition contrast when the claim's
  words start with a condition word (`coverage.CONDITION_WORDS`: while, whenever, as long as).
- Nothing else changes: an effect claim still needs its promised words and a learned contrast; a readback metric
  (aura_amount and the like) stays data in any contrast; event metrics were behaviour already.
- No scenario changes (Templar and Necromancer `generate` unchanged). Coverage of another class may move for a claim
  that starts with a condition word and is read in a condition contrast; none was searched.

## Consequences

- 106.0 can count once a counted pair judges the `mage` entry.
- Tests: `test_a_condition_contrast_proves_a_condition_claim_only` (test_coverage.py), with an effect claim and a
  readback metric as the mutants that stay data.
