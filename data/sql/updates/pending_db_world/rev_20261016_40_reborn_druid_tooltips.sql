-- Warcraft Reborn Druid: Earth and Moon also procs from Starsurge, Primal Fury and Revitalize proc like their tooltips say,
-- and Bear Form no longer picks up the stock tank passive (+25% damage taken) that its tooltip does not list.
DELETE FROM `spell_proc` WHERE `SpellId` IN (-1148506, -1137116, -1148539);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1148506, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2` | 0x80000, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -48506;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-1137116, 0, 0, 0, 0, 0, 0x14, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(-1148539, 0, 7, 0x10, 0x4000000, 0, 0x40000, 2, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((-1137116, 'spell_ascension_reborn_primal_fury'), (-1148539, 'spell_dru_revitalize'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1137116, 'spell_ascension_reborn_primal_fury'),
(-1148539, 'spell_dru_revitalize');

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 1121178 AND `spell_effect` = -57339 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(1121178, -57339, 2, 'Reborn Bear Form (Passive2) - no stock Tank Class Passive Threat');
