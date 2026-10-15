-- Electrified Waters (573436) never fired.
--
-- Its only effect is SPELL_AURA_PROC_TRIGGER_SPELL of 573437, but its Spell.dbc record has
-- ProcFlags 0. SpellMgr::LoadSpellProcs only generates a default proc entry for a record that has
-- proc flags, and no `spell_proc` row existed, so Aura::GetProcEffectMask returned 0 for every
-- event and the aura could not proc at all.
--
-- ProcFlags 69972 is the Air Elemental's done-hit set (332116) without PROC_FLAG_DONE_PERIODIC,
-- which is the tooltip's "direct" gate, and HitMask 2 is PROC_HIT_CRITICAL. AttributesMask stays 0,
-- so the engine's default rule holds and only the player's own casts proc, not triggered ones.
-- The remaining clause, "against an enemy affected by Drown", is the aura script below.
DELETE FROM `spell_proc` WHERE `SpellId` = 573436;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (573436, 0, 0, 0, 0, 0, 69972, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_electrified_waters';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(573436, 'aura_ascension_electrified_waters');

-- The chain 573436 -> 573437 -> 573438 ends in SPELL_EFFECT_SUMMON with MiscValue 310603 and
-- MiscValueB 61 (SummonProperties category 1, type 2), so Spell::SummonGuardian summons creature
-- 310603 for the 20000 ms of SpellDuration 18. That creature had no template, so even a firing
-- proc would have summoned nothing.
--
-- Static Electricity (524954 -> 573451, #1692) carries EffectTriggerSpell 573438 as well, so both
-- talents summon this one entry and this file is its single definition.
--
-- Faction, unit class, creature type and family follow the Stormbringer's own Air Elemental
-- (500941). The level band is the summoner's level: Guardian::InitStats overrides it with the
-- owner's level on the proc path, and the creature script sets the owner's level on the Static
-- Electricity path, so 80 is only what an untouched row would show.
--
-- The script name carries the second tooltip clause, which both talents state: when the elemental
-- dissipates it casts 573442, whose SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN refunds 2000 ms of Drown.
INSERT INTO `creature_template`
  (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `family`, `AIName`,
   `MovementType`, `ScriptName`)
VALUES
  (310603, 'Electrified Water Elemental', 80, 80, 35, 2, 4, 0, '', 0,
   'npc_ascension_electrified_water_elemental')
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
  `family` = VALUES(`family`), `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`),
  `ScriptName` = VALUES(`ScriptName`);

-- 525 is the model creature 510 "Water Elemental" already uses, so it is known to render.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 310603;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(310603, 0, 525, 1, 1);
