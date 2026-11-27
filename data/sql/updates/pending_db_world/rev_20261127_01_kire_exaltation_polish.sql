DELETE FROM `spell_proc` WHERE `SpellId` IN (201148, 312433, 316433, 320433);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
    (201148, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 12000, 0),
    (312433, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 12000, 0),
    (316433, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 12000, 0),
    (320433, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 12000, 0);

DELETE FROM `creature_loot_template` WHERE `Entry` = 501008;
UPDATE `creature_template` SET `lootid` = 0, `DamageModifier` = 3.1 WHERE `entry` = 501008;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (501003, 501006) AND `source_type` = 1 AND `id` IN (1, 2, 3);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
    `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
    `target_y`, `target_z`, `target_o`, `comment`) VALUES
    (501003, 1, 1, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 105, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave - On Gossip Hello - Add Not Selectable Flag'),
    (501003, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 67, 1, 400000, 400000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave - On Gossip Hello - Create Timed Event 1 (400s)'),
    (501003, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 106, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave - On Timed Event 1 Triggered - Remove Not Selectable Flag'),
    (501006, 1, 1, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 105, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave (Return) - On Gossip Hello - Add Not Selectable Flag'),
    (501006, 1, 2, 0, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 67, 1, 400000, 400000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave (Return) - On Gossip Hello - Create Timed Event 1 (400s)'),
    (501006, 1, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 106, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Forgotten Grave (Return) - On Timed Event 1 Triggered - Remove Not Selectable Flag');
