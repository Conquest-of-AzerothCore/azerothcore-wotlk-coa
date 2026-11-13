# 0545. A cost gate may force the roll that opens it

- Status: accepted
- Date: 2026-11-13

## Context

Several Necromancer clauses state what a proc does to a later cast: Refreshing Chill 300940 "reset the cooldown of
Ice Barrage", Deadly Bond 704724 "cause their next use within $572777d to be free of cost". Their chances are proven by
pooled proc entries; the effects were route pending, because a cost gate's opening (a setup or after cast) rolls the
proc at 20% or 30% and the gate then reads a refusal half the time for a reason that is not the claim. The mentor
approved one forcing fixture for effect claims (N-a1, ADR 0482): a SPELLMOD_CHANCE_OF_SUCCESS +1000% spell modifier on
the talent, removed at the end and read gone. ADR 0482 put it in `metric_delta` only, tied to a minion aura read.

## Decision

- `cost_gate` takes `forced_roll` (a talent id): the scenario adds the `spell_mod_mutant` step on that talent after
  its learns and, at the end, removes the mutant and reads `spell_mod_mutants`; a `released` expectation
  (`<spell> cost_gate <gated>[ <suffix>] released`) must read 0.
- Refreshing Chill: `resets` on Ice Barrage 801760, Command: Undead 504868 3500 ms after the priming cast, the attempt
  500 ms later. Deadly Bond: a power gate on Command: Undead, the setup Command rolls, the next Command at 0 power goes
  through only with the talent, and the one after is refused (`next_arm`).
- Bone King 707175 is not entered: Lichfrost and Blight cost a percentage of base mana, which `cost_gate` does not
  model.
- No harness C++ change. Entries without `forced_roll` generate the same scenarios (Templar `generate --class 19`
  and `--stack` byte-identical).

## Consequences

- Ledger claims 15.1 and 185.1 gain cost-gate labels. The forced roll proves no rate.
- Tests: `CostGateForcedRollTests` (test_behaviours.py).
