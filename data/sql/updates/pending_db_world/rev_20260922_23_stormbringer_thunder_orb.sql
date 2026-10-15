-- #3767: Summon: Thunder Orb (801802) summons creature 50074 (Spell.dbc EffectMiscValue[0], with
-- EffectMiscValueB[0] = 61 SummonProperties), and no creature_template row for 50074 is shipped, so
-- Creature::CreateFromProto rejects every summon and no orb ever appears.
--
-- The template follows Power Sphere (503201, rev_1789379311228000700.sql): the same class's other orb
-- guardian, summoned through the same SummonProperties 61 - faction 35, unit_class 2, type 4 (elemental),
-- level band 1 so nothing pulls it into level scaling. The script sets owner faction and level on summon.
--
-- The display is the shipped Thunder Orb creature 33378's own model 16925
-- (data/sql/base/db_world/creature_template_model.sql), reused deliberately because no Ascension creature
-- capture exists for entry 50074. creature_model_info already carries 16925.
INSERT INTO `creature_template`
  (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
   `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`,
   `flags_extra`, `ScriptName`)
VALUES
  (50074, 'Thunder Orb', NULL, 0, 1, 1, 35, 0, 1, 1.14286, 2, 0, 4, '', 0, 0, 'npc_ascension_thunder_orb')
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_class` = VALUES(`unit_class`),
  `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `flags_extra` = VALUES(`flags_extra`),
  `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 50074;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(50074, 0, 16925, 1, 1);

-- The summon effect targets TARGET_DEST_DEST and the orb has to carry Orb Shock (801863), the 2 s periodic
-- that triggers 801868; nothing in the data links the two, so the spell needs its own script.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_summon_thunder_orb';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801802, 'spell_ascension_summon_thunder_orb');

-- #3133: Binder of Storms (707542) is a SPELL_AURA_PROC_TRIGGER_SPELL aura with ProcFlags 0 and an empty
-- EffectSpellClassMask, so SpellMgr::LoadSpellProcs skips it ("Skip if no proc flags in DBC") and
-- Aura::GetProcEffectMask returns 0 for every event: the talent applies a permanent aura that does nothing.
--
-- SpellFamilyName 22 with SpellFamilyMask0 32768 selects exactly one spell in Spell.dbc, Conduction (567560),
-- which is the spell the tooltip names. Conduction is DmgClass 1 (magic) and negative, hence ProcFlags 65536
-- PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG with SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit).
-- Chance 60 is the spell's own ProcChance and the tooltip's $h%.
DELETE FROM `spell_proc` WHERE `SpellId` = 707542;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707542, 0, 22, 32768, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 60, 0, 0);
