# 0020. Felwrath Inner Demon stacks on each struck enemy

- Status: accepted (Felsworn mentor decision D-83, 2026-11-24)
- Date: 2026-11-24

## Context

Felwrath 520693 (server Spell.dbc, Description[enUS]): "Inner Demon: Striking at least 5 enemies with this spell
causes it to deal an additional ${$520832m1+$520832ppl1+$SP*.1} Shadowflame Damage over $520832d, stacking $520832u
times." 520832 carries StackAmount 3 and DurationIndex 32 (6000 ms).

Server DBC set, 520832: Effect[0] applies the periodic damage aura, Effect[1] is a dummy effect (no aura) and Effect[2]
applies aura 271 with an amount of 0. All three target TARGET_DEST_TARGET_ENEMY / TARGET_UNIT_DEST_AREA_ENEMY with an
8 yd radius. The Felsworn caster code casts 520832 once on every enemy Felwrath strikes, and the class contract
already retargeted Effect[0] to the struck enemy (initial Felsworn package, 46bf8121e5; no recorded reason). That keeps
one damage-over-time application per struck enemy per cast, where the area targets would give each enemy one from
every cast within 8 yd.

Effect[2] kept its area targets. The aura a cast leaves on its own target then carries Effect[0] and Effect[2]; every
other enemy within 8 yd gets an aura with Effect[2] alone. `Unit::_TryStackingOrRefreshingExistingAura` creates a new
aura instead of stacking when the effect masks differ. The counted pair of the conformance review (B8, prove5) read 10
applications on one dummy over four casts, 2.5 per cast, and never more than 1 stack.

## Options

- Retarget Effect[2] of 520832 to the struck enemy as well, in the Felsworn class contract. Every application then
  carries the same mask and stacks.
- Restore the DBC area targets on Effect[0] too. Rejected: each enemy in a cluster would take up to five applications
  per Felwrath cast and reach the cap from one cast.
- Change the engine's mask rule. Rejected: shared engine path.

## Decision

`AscensionFelsworn::ApplyContracts` sets TargetA of Effects[0] and [2] of 520832 to `TARGET_UNIT_TARGET_ENEMY` and
clears their TargetB. Effect[1] (dummy, no handler) is unchanged. No shared file, SQL, DBC or client text changes.

## Consequences

- Each Felwrath cast that strikes five enemies adds one stack of 520832 to every struck enemy, up to 3; a fourth cast
  keeps 3 stacks. The engine refreshes the duration on that stack path (`Aura::ModStackAmount`); the conformance
  tools cannot read it yet, since Felfury caps at 6 (three casts) outside `stack_feed`, and `stack_feed` voids any
  window in which the aura could expire. The periodic damage is multiplied by the stacks.
- Neighbours of a struck enemy no longer receive the Effect[2]-only aura (amount 0, no gameplay effect).
- The damage figure itself stays with owner question N-7 (per tick or total over the duration).
- Readers: 520832 is used only by the Felsworn caster code (`AscensionFelswornAbilities.cpp`), the coefficient row
  (`AscensionFelswornData.h`), the class contract and the Felsworn `spell_bonus_data` row. No other class lists it.
