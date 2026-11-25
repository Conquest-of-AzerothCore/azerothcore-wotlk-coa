# 0025. Dark Veil final tick does not revive a broken shield before expiry check

- Status: accepted (provisional number)
- Date: 2026-11-25

## Context

Dark Veil `520345` (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Channel a shield of void energies
upon an ally, causing both you and them to absorb `${$520346m1+$520346ppl1+$bh*1+$AP*.25}` damage, stacking
`$520346u` times, every `$t1` sec for `$d`. At the end of the duration, if the shield holds, you teleport to them."

Effective `Spell.dbc` and execution path:

- `520345`: `DurationIndex 28` (`5000 ms`), `Effect[0]` rewritten to `SPELL_AURA_PERIODIC_DUMMY` (`Amplitude = 1000 ms`,
  `totalTicks = 5`) in `AscensionCultistContracts.cpp:162-169`. `520346`: `DurationIndex 39` (`2000 ms`),
  `StackAmount = 5`, `Effect[0]` absorb on ally, `Effect[1]` absorb on caster.
- In `Unit::_UpdateSpells` (`src/server/game/Entities/Unit/Unit.cpp:4700-4708`), `aura->UpdateOwner(diff, this)` runs
  before the expiry removal loop. `Aura::UpdateOwner` (`SpellAuras.cpp:744-754`) clamps `m_duration` to `0`
  (`:767-769`), then updates `m_effects[0]`. `AuraEffect::Update` (`SpellAuraEffects.cpp:1035-1058`) sees
  `GetDuration() >= 0` and `(m_tickNumber + 1) <= totalTicks` (`5 <= 5`) and fires tick #5 ->
  `aura_ascension_cultist_lifecycle::Tick` (`src/server/coa/AscensionCultistAuras.cpp:218-219`, since initial commit
  `e36bc50aad`), which unconditionally called `Cast(player, GetTarget(), 520346)`.
- That re-applied 1 fresh stack of `520346` to both ally and caster right before `RemoveOwnedAura(...,
  AURA_REMOVE_BY_EXPIRE)` ran `aura_ascension_cultist_lifecycle::Remove` (`AscensionCultistAuras.cpp:164-172`), so
  `allyShield && selfShield && allyShield->GetAmount() > 0 && selfShield->GetAmount() > 0` always held and the caster
  teleported even when the shield had been broken.

Before measurement (`cu-tb2/prove-520345-v2`, runs `20261125-074205` and `20261125-074236`, build `e9e86b73f8b6`,
`tools-review/cu-rtb2/review.md:137-145`):

- `520345 behaviour_metric_delta teleport_holds`: `ok` / `ok` (`15.0 yd` displacement, `distance_2d 15 -> 0`, `520346`
  at `5` stacks).
- `520345 behaviour_metric_delta teleport_broken_control`: `alert` / `alert` (`6x` Void Zone `92559` broke all `4`
  stacks at `4200-4500 ms`, yet tick #5 revived `1` stack of `520346` and teleported the caster `15.0 yd` to the ally
  instead of `0.0 yd` and `0` stacks).

## Options

- On the final tick (`GetAura()->IsExpired() || (effect->GetTotalTicks() > 0 && int32(effect->GetTickNumber()) >=
  effect->GetTotalTicks())`) inside `aura_ascension_cultist_lifecycle::Tick`
  (`src/server/coa/AscensionCultistAuras.cpp`), cast `520346` only if both `allyShield` (`EFFECT_0`) and `selfShield`
  (`EFFECT_1`) are still active with `GetAmount() > 0`. Chosen: preserves all 5 ticks and 5-stack capping when the
  shield holds (`520345 stacks`, `period_early/late`, `teleport_holds`) and under `520682` Endless Devotion
  (`2500 ms / 500 ms = 5` ticks), while preventing tick #5 from reviving a broken shield before `Remove()` checks
  whether the shield held.
- Suppress tick #5 unconditionally. Rejected: caps Dark Veil at 4 stacks on a single unbroken channel, breaking
  `"stacking $520346u times"` (`520345 stacks` and `teleport_holds` 5-stack check).

## Decision

In `aura_ascension_cultist_lifecycle::Tick` (`src/server/coa/AscensionCultistAuras.cpp`), guard the final tick of
`520345` so `Cast(player, GetTarget(), 520346)` runs only if both the ally and caster `520346` shields currently hold
with `GetAmount() > 0`. No shared engine, DBC, SQL, or client text changes.

## Consequences

- When Dark Veil's shields hold through the channel, tick #5 raises `520346` to 5 stacks and expiry teleports the
  Cultist to the ally. When either shield is broken before expiry, tick #5 does not revive `520346` and the Cultist
  does not teleport.
- Other spells reached: `520682` Endless Devotion (`-50%` period/duration of `520345`); no other spell is reached.
- Regressions (`prove-D`, runs `20261125-091043` and `20261125-091121`, build `d6d2e5b8395a`, `18/18` ok, `0` flips):
  - `520345 behaviour_metric_delta teleport_holds`: `ok` / `ok` (`15.0` / `15.0` yd, `distance_2d 15 -> 0`, `520346`
    at `5` stacks).
  - `520345 behaviour_metric_delta teleport_broken_control`: `ok` / `ok` (`0.0` / `0.0` yd, `distance_2d 15 -> 15`,
    `520346` at `0` stacks).
  - All 12 sibling `520345` entries (`absorb_caster_base`, `absorb_caster_sp`, `absorb_caster_ap`, `absorb_ally_base`,
    `stacks`, `period_early`, `period_late`, `duration`, `immune_stun`, `immune_silence`, `no_self_cast`,
    `ally_cast_allowed`) and all 4 `520682` entries (`faster_period_early`, `faster_period_late`, `faster_duration`,
    `duration_contrast`): `ok` / `ok`, no reading moved.
