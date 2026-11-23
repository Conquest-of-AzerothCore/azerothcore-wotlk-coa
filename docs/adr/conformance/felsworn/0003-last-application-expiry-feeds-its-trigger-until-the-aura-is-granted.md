# 0003. last_application_expiry feeds its trigger until the aura is granted

- Status: proposed (class ADR, numbered at merge)
- Date: 2026-11-23

## Context

Felsworn Legionfall 801899 ("within $801902d", ledger row of clause 233) and Malice of Gul'dan 800214 (Felstrike
802678 lasts 6000 ms, Fragment of Malice 800239 5000 ms) grant an aura only through a rolled proc: `Chance()` rolls
the raw ProcChance (`src/server/coa/AscensionFelsworn.cpp:231-239`, 15% and 60%), so the ADR 0588 spell-modifier
mutant forces nothing. The first design (`last_application_expiry` with `repeat` and `forced_roll`) read `unmeasured`
twice: one grant in the first cast and none after, and an instant grant landing before the first poll. Mentor
conditions D-11: a cap sized to 0.05% per run, the apply stamp taken from the aura itself, no state carried from the
extra casts, opt-in keys on existing kinds only, no C++.

## Options

- The 4-line Necromancer pattern in `Chance()` (apply `SPELLMOD_CHANCE_OF_SUCCESS`) so the mutant forces it: C++,
  owner decision G-39, not built.
- Unforced `repeat` casts: 4 casts of two strikes leave 27% of runs without a grant at 15% (review I-1).
- `aura_fed_effect` `window`: judges an instant cast through a Sun Cleric channel; Legionfall's effect is a cost and
  Malice's auras sit on the dummy and the caster, so it would change what the variant judges.
- An opt-in `feed` key on `last_application_expiry` driving the existing `cast_until_aura` step.

## Decision

`feed` on `last_application_expiry`, with the cap computed from the ProcChance of the gate spell, the loop stopped
by the first grant, the grant dated by the stop (at most 100 ms before the first poll), a loop at its cap
unmeasured, a control arm fed alike without the gate, and `force_crit` and `quote_spell` as opt-in fixtures. The
judged bracket is unchanged. Not covered: the 3-stack cap of Felstrike (needs four grants inside 6000 ms, a new
judgement, written as a design note instead of built).

## Consequences

- Existing entries regenerate byte-identical (no key, no change).
- A feed run costs up to 2 x max_casts x every_ms of game time at the cap (80 s for Legionfall), about 10 s on
  average.
- Reaching the cap is a void run, so a flaky roll never reads as a fail.
- A `feed` `ok` is voided when the aura's age at the stop read (expected less remaining) is above 100 ms or the remaining duration cannot be read (mentor D-21); a failing bracket still alerts. Superseded by ADR 0004: the age is read from
  an apply stamp, not derived from the expected duration.
