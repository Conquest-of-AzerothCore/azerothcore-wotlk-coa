# 0536. A cast-state read counts for a haste claim

- Status: accepted
- Date: 2026-11-13

## Context

Three converted duration claims of the merged pair 20261113-084238 / -085831 had every game-time label (ADR 0501) ok in
both runs, yet the audit did not count them as behaviour. Re-auditing the same verdicts showed two causes, neither a
missing evidence class for the game-time windows (a window only adds a stamped read to a metric_delta verdict, whose
metric keeps its class):

- 97.0 Skeletal Archer haste (531126): `cast_held` / `cast_done` read the `casting` state, a STATE metric that counts
  as behaviour only where the claim promises it (coverage.py STATE_PROMISES, `\bcast\w*`); the claim says "increases
  your haste by $805025s3%", so the read counted as data.
- 391.0 Crypt Plague (92121) and 125.1 Rotling explosion (560800): the ledger listed value readbacks that are not
  conformant in any run (`92121 effect_value 570131e0 #0` not_measured, `92121 effect_value #3` unreadable,
  `560800 aura_amplitude_ms #0` unmodelled), and one non-conformant label holds a claim unproven.

## Decision

- STATE_PROMISES: `haste` also promises the `casting` state (a cast that ends sooner is the stated haste), as it
  already promises `owned_creature_cast_speed` and `attack_time_ms`; so does `all actions` (Entomb 500341, "preventing
  all actions": the banished dummy's casting state, claim 302.1). The read still counts only in a learned-contrast
  metric_delta.
- Ledger rows 405 (391.0), 131 (125.1, its explosion-time claim), 62 (58.0) and 151 (145.1): the non-conformant
  readbacks are removed from the labels and the reasons say so. No readback is reclassified as behaviour; the claims rest on their behaviour labels.

## Consequences

- Re-audit of both runs of the merged pair with this change: 97.0, 391.0, 125.1, 58.0, 145.1 and 302.1 are behaviour
  in both runs where their labels are conformant.
- Test: `test_a_cast_state_is_a_state_read_where_the_clause_promises_haste` (test_coverage.py): a haste claim counts
  the learned-contrast casting read; an armor claim, an unlearned contrast and a casting metric classed as a readback
  (mutant) do not. Templar `generate` is unaffected (audit-only change); the Templar audit was not re-run.
