-- Warcraft Reborn Rogue spells whose stock twins are built differently.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((-1151625, 'spell_rog_deadly_brew'), (-1151685, 'spell_rog_prey_on_the_weak'), (-1151664, 'spell_ascension_reborn_cut_to_the_chase'), (1151662, 'spell_ascension_reborn_hunger_for_blood'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1151625, 'spell_rog_deadly_brew'),
(-1151685, 'spell_rog_prey_on_the_weak'),
(-1151664, 'spell_ascension_reborn_cut_to_the_chase'),
(1151662, 'spell_ascension_reborn_hunger_for_blood');

DELETE FROM `spell_proc` WHERE `SpellId` IN (-1151625, -1151664);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1151625, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -51625;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1151664, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -51664;
