# 0129. Server mutants owned by a harness dummy aura, and K3 consumption rows

- Status: accepted
- Date: 2026-11-11

## Context

A readback proves that a value is right, not that the acting path uses it (data, not behaviour; ADR 0120). The
prototype's consumption probe K3 changes the read value on the server and checks that an acting observation moves.
Its trial X1 used a player-scoped `SpellModifier` without an owner aura: `Player::ApplyModToSpell`
(`Player.cpp`, `mod->ownerAura->IsUsingCharges()`) dereferences the owner whenever the modifier applies inside a
spell, so the worldserver crashed on 8 cores and 35 of 36 results were lost (prototype `x1-mutant-report.md`). Every
production construction passes an aura; the harness one was the only owner-less modifier (prototype
`mentor-review-g6.md`, "X1 crash"). Inherited code is not to be changed for a harness need, and the owner kept the
prove runner and the carried-over parts but no clause specs (`owner-rulings-2026-11-10.md`, "Prototype score (G6)
rulings"). The mentor asked for large factors (x2, or x0 where the mechanic allows), since a probe asks whether the
value is read: x0.80 on a +20% bonus stays inside the 5% band.

## Considered options

1. A null guard in `Player::ApplyModToSpell`. Rejected: inherited code changed for a harness need.
2. Own the modifier by an existing player aura of the scenario. Rejected (X1): that aura enters
   `Spell::m_appliedMods`, may carry charges or `PROC_ATTR_REQ_SPELLMOD` procs, and leaves the modifier dangling
   when the case removes it.
3. Own it by a dedicated harness aura applied to the lane's player, released with that aura. Chosen.

## Decision

- `spell_mod_mutant` applies Dummy Aura - Target: Any - Permanent 100523 to the player the way `set_aura` does
  (`Unit::AddAura`) and builds the `SPELLMOD_PCT` modifier with it as owner. 100523 in the server set: Effect[0] 6
  with EffectApplyAuraName[0] 4 (dummy), Effect[1..2] 0, DurationIndex 21 (permanent), ProcCharges 0, ProcFlags 0,
  SpellFamilyName 0, no class mask, hidden (`SPELL_ATTR0_DO_NOT_DISPLAY`); no `spell_script_names` row and no
  reference in `src/server`. No charges means `ApplyModToSpell` only records the aura in the spell, and no proc
  entry means nothing reads that record.
- `SpellModMutants` (harness) owns the modifiers per owner aura. The harness unit script releases them when that
  aura is removed (`OnAuraRemove`), so no modifier outlives its owner; `Dismiss` removes the aura before logout.
  The player metric `spell_mod_mutants` counts the active mutants, and a mutated conformance scenario ends by
  asserting it, so a mutant lost mid-case fails the scenario instead of reading as unconsumed.
- Mutant factors are 2 or 0 (`percent` from -100 to 1000 in the harness): x0 for a chance or an amount, x2 for a
  duration or a target count, whose zero can mean unlimited.
- `conformance.py mutate` and `conformance.py k3` (`mutants.py`, `k3.py`) replace the prototype's `prove --mutants`
  wiring, which was never committed. A K3 row needs an observation that is conformant in every baseline run and
  observes an acting outcome (`coverage.acting`); `consumed` needs a measured alert in every mutant run,
  `not_consumed` a predicted reading outside the tolerance (the prototype's ADR 0114 rules); no row is written for a
  spell whose modifier channel CoA code feeds with its own amount (`ApplySpellMod(<spell>` in `src/server/coa`), since
  the mutant then moves the reading although the DBC value is not read.
- Rows `{label, route: K3, spell, effect, build, evidence, result}` live in `classes/<class>_consumption.json`;
  coverage reads them beside the ledger and, on the judged build, promotes a `consumed` readback to behaviour.
  K3 is the only route: the K1 static join needs the value dump, which is not adopted, and no K1+K2 rows were ever
  written, so the K1+K2 validation on 10 clauses does not apply.

## Consequences

- Trial X1 runs without a crash: 7 mutants, 6 alert in both runs, 0 contaminated unmutated verdicts (lean
  `x1-mutant.md`).
- A spell modifier mutant tests the modifier channel of one spell. It cannot see a CoA literal that bypasses that
  channel unless the observation fails to move (Patience: no alert), and it refuses the channel CoA feeds itself
  (Scourgebane).
- A K3 row promotes a readback label only where an acting observation of the same value exists; on the Templar such a
  clause usually carries that observation already, so K3 moves few clause statuses.
