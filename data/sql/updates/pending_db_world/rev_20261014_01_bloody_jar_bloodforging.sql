-- Bloody Jar: item targeting, irreversible-conversion confirmation and the matching cast icon.
START TRANSACTION;

DELETE FROM `spell_dbc` WHERE `ID` = 9977999;
INSERT INTO `spell_dbc` (`ID`, `Attributes`, `AttributesEx2`, `Targets`, `CastingTimeIndex`, `InterruptFlags`,
    `RangeIndex`, `EquippedItemClass`, `Effect_1`, `ImplicitTargetA_1`, `SpellVisualID_1`, `SpellIconID`,
    `Name_Lang_enUS`, `Description_Lang_enUS`, `SchoolMask`) VALUES
(9977999, 272, 8192, 16, 14, 31, 1, -1, 3, 26, 3220, 17922, 'Bloodforge',
    'Convert the selected item into Normal Bloodforged gear. This conversion is irreversible.', 1);

DELETE FROM `spell_script_names` WHERE `spell_id` = 9977999;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(9977999, 'spell_ascension_bloody_jar');

UPDATE `item_template` SET `ScriptName` = 'item_ascension_bloody_jar', `spellid_1` = 9977999, `spelltrigger_1` = 0,
    `spellcharges_1` = 0 WHERE `entry` = 777999;

COMMIT;
