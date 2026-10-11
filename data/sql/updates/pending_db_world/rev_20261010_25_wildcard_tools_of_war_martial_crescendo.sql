-- Tools of War 271020 and Martial Crescendo 271051 have no ProcFlags in Spell.dbc, so they never granted their buffs.
-- Each unique direct damage Physical ability grants a stack that does not refresh the duration, and dealing magic
-- damage resets the stacks: melee and ranged abilities and harmful magic spells, direct or periodic, on a hit.
DELETE FROM `spell_proc` WHERE `SpellId` IN (271020, 271051);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(271020, 0, 0, 0, 0, 0, 0x50110, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(271051, 0, 0, 0, 0, 0, 0x50110, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_unique_physical_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(271020, 'aura_wildcard_unique_physical_ability'),
(271051, 'aura_wildcard_unique_physical_ability');
