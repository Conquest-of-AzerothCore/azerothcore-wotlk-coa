# 0020. Liquify pacifies melee attacks and Bloodmoon Power cleanses negative effects on apply

- Status: accepted (Bloodmage conformance S-7 / S-8, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Liquify `806310`: `"Dissipate into a pool of blood, making you immune to damage from spells and attacks, but preventing
  you from attacking or casting spells and slowing your movement speed by $s3% for $d."` `Effect[0]` is aura `263`
  (`SPELL_AURA_PLAYER_ALLOW_ONLY_ABILITY`), which blocks spell casts (`Spell.cpp:5837`), while melee auto-attacks
  (`Unit::AttackerStateUpdate`, `Unit.cpp:3083`) are gated only on `UNIT_FLAG_PACIFIED`.
- Bloodmoon Power `801961`: `"Your Liquify now cleanses all negative effects when used."` Previously,
  `bloodmage_talent_events::OnAuraRemove` cleansed only when Liquify expired (`6000 ms`) and filtered by `Dispel !=
  DISPEL_NONE`. Live logs (`ev3.md`, `log 164`) confirm cleansing occurs at `0 ms` on Liquify application and includes
  `DISPEL_NONE` debuffs (such as Sated and Worn Out).

## Options

- Set `UNIT_FLAG_PACIFIED` and run `CleanseBloodmoonPower(player)` in `bloodmage_talent_events::OnAuraApply` for
  `806310`; clear `UNIT_FLAG_PACIFIED` in `OnAuraRemove` (before the death return and before Vampiric Pools `806311`)
  when no `SPELL_AURA_MOD_PACIFY` / `SPELL_AURA_MOD_PACIFY_SILENCE` aura remains; remove the old cleanse loop from
  `OnAuraRemove`. Chosen: class-scoped, preserves Bloodbolt's `cast_failure == 105` (`PreventionType == 1`), and cleanses
  all non-passive, timed negative auras except `806310` itself and `SPELL_ATTR0_NO_IMMUNITIES` encounter debuffs.
- Add `SPELL_AURA_MOD_PACIFY` directly onto `806310`. Rejected: all 3 effect slots on `806310` are occupied (`263`,
  `40`, `33`).

## Decision

In `src/server/coa/AscensionBloodmageTalents.cpp`:

1. Add `CleanseBloodmoonPower(Player* player)` removing applied auras where `!app->IsPositive() && !applied->IsPassive()
   && applied->GetDuration() > 0 && applied->GetId() != SPELL_LIQUIFY && !info->HasAttribute(SPELL_ATTR0_NO_IMMUNITIES)`.
2. In `bloodmage_talent_events::OnAuraApply` for `SPELL_LIQUIFY`: set `UNIT_FLAG_PACIFIED` and call
   `CleanseBloodmoonPower(player)` when self-cast.
3. In `bloodmage_talent_events::OnAuraRemove` for `SPELL_LIQUIFY`: clear `UNIT_FLAG_PACIFIED` before the death guard and
   before `SPELL_VAMPIRIC_POOLS_LEECH` if no pacify aura remains, and remove the old expiry cleanse loop.

## Consequences

- Liquify blocks both spellcasting and melee auto-attacks for its duration and restores attacking cleanly on end/death.
- Bloodmoon Power cleanses negative timed effects immediately when Liquify is used, including `DISPEL_NONE` debuffs.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
