# 0010. Valkyr's Calling lands when its flight aura ends

- Status: accepted
- Date: 2026-11-22

## Context

Last Call 681448, Spell.dbc text: "Increases the duration of Valkyr's Calling by $/1000;s1 sec." Its effect 0 is
`SPELL_AURA_ADD_FLAT_MODIFIER`, `SPELLMOD_DURATION`, BasePoints 999 (+1000 ms), on class mask word 2 `0x00200000`.
In family 33 of the server Spell.dbc that bit is the `SpellFamilyFlags[2]` of Valkyr's Calling 520024 and of its
flight aura 520025, both DurationIndex 39 (2000 ms), and 681448 is the only family 33 spell modifier that reaches it.

A 520024 cast runs `AscensionSunCleric::Valkyr` (`AscensionSunClericSummons.cpp`): it applies 520025 to the caster
and schedules the landing, which removes 520025 and charges the caster to the target for 570034. The schedule read
`sSpellMgr->GetSpellInfo(520024)->GetDuration()`, the unmodified 2000 ms. Measured on batch 5a (pair
20261122-025000 / 20261122-025043, build c1653c52): with the passive 520025 reads 2694 ms remaining at 300 ms (the
modifier reaches the aura, 3000 ms in all), but the aura is gone at 2730-2790 ms, as in the control without it.

## Options

- Schedule the landing at the maximum duration of the 520025 aura just applied, which carries the spell modifier;
  the unmodified 520024 duration stays as the fallback when the aura is missing.
- Apply `SPELLMOD_DURATION` to the 520024 duration in the script: a second path for a value the aura already holds.

## Decision

The first option (mentor decision D-69, 2026-11-22).

## Consequences

- Without Last Call the flight and the landing stay at 2 s; with it, at 3 s.
- 520025 is read only by `AscensionSunClericSummons.cpp`; 520024 is read by id in `AscensionSunCleric.cpp`,
  `AscensionSunClericAbilities.cpp` and `AscensionSunClericContracts.cpp`, none of them for its duration. No other
  class reads 520024, 520025 or 681448.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-last-call-extends-valkyrs-calling-flight.json`, a control
  without Last Call (flight up before 1950 ms, gone after 2050 ms) and a Last Call arm (up after 2800 ms, gone after
  3050 ms), each read bounded by game time.
