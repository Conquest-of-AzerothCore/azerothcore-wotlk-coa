# 0482. A forced-chance fixture reads a rolled minion aura

- Status: accepted
- Date: 2026-11-13

## Context

Ghoul Mastery 503740 and Plague Horde 802986 put an aura on a minion through the minion's own roll (15% and 10% per
hit; the live logs show 707014 and 807653 self-cast by the minions). A caster-side cast of the aura lands on the
caster (TARGET_UNIT_CASTER), and a read at a fixed time is a coin flip. The effect claims of those auras (transform,
haste, crit) had no route. The rates are already proven by the proc entries (ADR 0346). The mentor approved design 1
of note N-a1 on 2026-11-13: a SPELLMOD_CHANCE_OF_SUCCESS modifier on the talent, for effect claims only.

## Decision

- A `metric_delta` entry may set `forced_chance` {talent, aura, entry}. The scenario adds the existing harness action
  `spell_mod_mutant` (op 18 SPELLMOD_CHANCE_OF_SUCCESS, +1000%) on the talent after the base steps: both the class
  rolls (`Chance`/`MinionChance`, AscensionNecromancer.cpp:225-251) and the stock proc chance (`Aura::CalcProcChance`,
  SpellAuras.cpp:2380-2381) apply the caster's modifier to the talent, so a 10% or 15% roll exceeds 100%.
- The aura is read on the creature before the before reading (must be 0: no aura without the talent) and before the
  after reading, on every creature of the entry (otherwise `unmeasured`: one creature read could be one that
  has not hit yet). At the end the mutant owner aura 100523 is removed and `spell_mod_mutants` must
  read 0. The verdict explanation and its detail (`forced_chance`: the talent) name the fixture.
- No harness C++ change: the mutant action exists (class conformance server mutants).

## Consequences

- Ghoul Mastery reads the Frenzied Ghoul's haste (swing interval) and display; Plague Horde reads the minion's crit.
- Durations of these auras stay open: every forced hit refreshes the aura, so the expiry cannot be bracketed to the
  usual 500 ms.
- Tests: `MetricDeltaForcedChanceTests` (test_behaviours.py). Templar and Necromancer entries without the field
  generate byte-identical scenarios.
