# 0021. Lead Me Not Astray doubles the Bless heal as well as the mana

- Status: accepted
- Date: 2026-11-22

## Context

300357 Lead Me Not Astray reads "Doubles the healing done and mana restored by Bless." The Bless tick handler
(`AscensionSunClericAuras.cpp`, `aura_ascension_sun_cleric_lifecycle`) stops the default tick with
`PreventDefaultAction()` and heals through `Copy(player, target, 707522, CalculatePct(target->GetMaxHealth(), percent))`
with no 300357 term. Only the mana branch doubles (`if (player->HasAura(300357)) mana *= 2`). Commit e36bc50aad
(2026-09-10) added both lines in that shape and gives no reason for doubling only the mana; 9c33e7219c changed only
the source argument of `Mana()`.

The b8b review proved the cause (mentor decision D-113):
- The measured heal after one tick is 5500 before and after learning 300357 (pair 20261122-070213 / 20261122-070253),
  against 6000 expected; the mana half of the same pair reads 1234 then 1377.
- 300357's DBC spell mod (Effect[0] aura 108, misc 8, +99%) has an `EffectSpellClassMask` that does not overlap Bless
  804247's `SpellFamilyFlags`, so it never changes the amount.
- 707522 is in `SunClericCopies`, which sets `SPELL_ATTR3_IGNORE_CASTER_MODIFIERS`, so no healing-done modifier
  doubles it either.

## Options

- Leave the heal as it is. The tooltip names the healing, so the passive stays half implemented.
- Double the heal percent in the same handler when the caster has 300357, as the mana branch already does.
- Widen 300357's spell mod mask in data so the engine doubles the amount. The mana branch would then double twice, and
  the heal copy ignores caster modifiers anyway.

## Decision

The second option. `percent` is multiplied by 2 before `Copy()` when the caster has 300357. It applies to every Bless
tick, on the caster and on an ally, because the tooltip says "the healing done by Bless" without a target.

## Consequences

- A Bless tick heals twice its percent of the target's maximum health for a caster who knows 300357; without it
  nothing changes.
- The mana branch is unchanged: `mana_tick` (no 300357) and `mana_tick_lead` (with it) still read 1234 and 1377.
- The regression is `health_tick_lead` in `classes/sun_cleric.json`: Bless cast on the caster held at 5000 of 10000
  health, read after one tick, 5500 without 300357 (control) and 6000 with it learned between the phases.
- The ally heal with 300357 is not measured by an entry; the code path is the same line.
