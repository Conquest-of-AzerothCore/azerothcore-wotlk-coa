# 0005. Owner ruling Q-cu-10: Doomsayer triggers on Eldritch Shock overheals

- Status: accepted (owner ruling Cultist Q-cu-10 / O-12, 2026-11-24)
- Date: 2026-11-25

## Context

Doomsayer `704880` (server `Spell.dbc`, `Description[enUS]`): "Damage dealt by Eldritch Shock now increases the amount
healed by your next Eldritch Shock by 100%. Healing with Eldritch Shock now increases the damage dealt by your next
Eldritch Shock by 100%."

When Eldritch Shock (`808036..808038`) targets an enemy, `spell_ascension_cultist_ability` casts `808043..808045`
(damage); when it targets an ally, it casts `808050..808052` (heal). Under `704880`, `cultist_spells::OnSpellHitResult`
(`src/server/coa/AscensionCultistAbilities.cpp:228-233`) swaps the two `+100%` buffs `705106` (next heal) and `705107`
(next damage), read in `cultist_scaling::Factor` (`src/server/coa/AscensionCultistContracts.cpp:311-314`).

In `Spell::DoAllEffectOnTarget` (`src/server/game/Spells/Spell.cpp:2868-2874,3069-3071`), the engine records the raw
heal in `m_scriptHealingIncludingOverheal` (`src/server/game/Spells/Spell.h:634`), overwrites `m_healing` with the
effective health gain (`0` on a full-health target), and passes `m_healing` as `healing` to `OnSpellHitResult`. Because
`AscensionCultistAbilities.cpp:228` checked `(damage || healing)`, healing a full-health ally neither consumed `705106`
nor granted `705107`.

Conformance pair `prove-fix1` (`20261124-210808` / `20261124-210847`, server build `7a27a9f91e27`, commit
`1f991106edcf`) measured `704880 behaviour_hit_ratio heal_to_dmg_overheal` (Eldritch Shock healing a full-health caster
before damaging `dummy`) at `+0.01668%` and `+0.02500%` against expected `+100%` (while a 50%-health target measured
`3.00222` / `2.99926` cumulative ratio, `+100.22%` / `+99.93%`). Video `q742IyqxrV0` (2026-09-17) carries the exact
`Spell.dbc` tooltip text.

The owner ruled (Cultist `Q-cu-10`, `O-12`, 2026-11-24): "healing" includes a heal that is all overheal.

## Options

- Check `spell->GetScriptHealingIncludingOverheal()` instead of `healing` in `cultist_spells::OnSpellHitResult` for the
  `704880` Eldritch Shock check, matching the existing CoA `OnSpellHitResult` pattern (`AscensionChronomancerTime.cpp`,
  `AscensionPyromancerAbilities.cpp`, `AscensionStarcallerAbilities.cpp`, `AscensionTinkerAbilities.cpp`,
  `AscensionWitchDoctorAbilities.cpp`). Chosen.
- Keep `(damage || healing)` and reword client text to require effective healing. Rejected by owner ruling `Q-cu-10`.

## Decision

In `cultist_spells::OnSpellHitResult` (`src/server/coa/AscensionCultistAbilities.cpp:228-229`), gate the `704880` buff
swap for `{808043, 808044, 808045, 808050, 808051, 808052}` on
`(damage || spell->GetScriptHealingIncludingOverheal())`. No shared file, SQL, DBC, or client text changes.

## Consequences

- Any landed Eldritch Shock heal (`808050..808052`) with raw healing `> 0`, including a 100% overheal on a full-health
  target, consumes `705106` (after `ModifyHealReceived` applies its `+100%` factor to that heal) and grants `705107`
  (`+100%` damage on the next Eldritch Shock).
- Damage casts (`808043..808045`) have `GetScriptHealingIncludingOverheal() == 0` and keep their existing `damage > 0`
  behaviour. Without `704880` learned, no spell changes.
- Regressions (counted pair `20261125-010234` / `20261125-010301`, build `89f65b983cfd`):
  - `704880 behaviour_hit_ratio heal_to_dmg_overheal`: `+99.98%` (`21573.8` vs `10787.8`, ratio `1.9998`) and `+100.11%`
    (`21585` vs `10786.4`, ratio `2.0011`) against expected `+100%`, unlearned control unchanged.
  - `704880 behaviour_metric_delta heal_to_dmg` (50% HP caster): `10800 -> 32392` (`2.99926`) and `10800 -> 32354`
    (`2.99574`) against expected ratio `3.0`.
  - `704880 behaviour_hit_ratio dmg_to_heal` (clause 1): `+100.06%` (`17423.1` vs `8708.85`, ratio `2.0006`) and
    `+99.90%` (`17415` vs `8712`, ratio `1.9990`) against expected `+100%`.
