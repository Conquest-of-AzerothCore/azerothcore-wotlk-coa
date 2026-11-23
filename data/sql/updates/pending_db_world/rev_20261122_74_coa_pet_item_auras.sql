DELETE FROM `spell_pet_auras` WHERE `spell` IN (304131, 2185064, 2186064, 2187064, 2188064, 985807, 313465, 317465, 321465,
2127044, 2127144, 2127244, 2127344, 2127444, 2127544, 2127644, 2127744, 2127844, 2128044, 2128144, 2128244, 2128344);
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(304131, 0, 0, 304132),
(2185064, 0, 0, 2185065),
(2186064, 0, 0, 2186065),
(2187064, 0, 0, 2187065),
(2188064, 0, 0, 2188065),
(985807, 0, 0, 985807),
(313465, 0, 0, 313465),
(317465, 0, 0, 317465),
(321465, 0, 0, 321465),
(2127044, 0, 0, 2127044),
(2127144, 0, 0, 2127144),
(2127244, 0, 0, 2127244),
(2127344, 0, 0, 2127344),
(2127444, 0, 0, 2127444),
(2127544, 0, 0, 2127544),
(2127644, 0, 0, 2127644),
(2127744, 0, 0, 2127744),
(2127844, 0, 0, 2127844),
(2128044, 0, 0, 2128044),
(2128144, 0, 0, 2128144),
(2128244, 0, 0, 2128244),
(2128344, 0, 0, 2128344);

DELETE FROM `spell_proc` WHERE `SpellId` IN (304133, 313227, 317227, 321227, 304168, 313295, 317295, 321295, 985807, 313465, 317465,
321465);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
`ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`,
`Cooldown`, `Charges`) VALUES
(304133, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(313227, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0),
(317227, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0),
(321227, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0),
(304168, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(313295, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 35000, 0),
(317295, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 35000, 0),
(321295, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 35000, 0),
(985807, 0, 0, 0, 0, 0, 65556, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(313465, 0, 0, 0, 0, 0, 65556, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(317465, 0, 0, 0, 0, 0, 65556, 1, 2, 2, 0, 0, 0, 100, 0, 0),
(321465, 0, 0, 0, 0, 0, 65556, 1, 2, 2, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (985807, 313465, 317465, 321465) AND `ScriptName` = 'aura_ascension_item_talon_ripper';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(985807, 'aura_ascension_item_talon_ripper'),
(313465, 'aura_ascension_item_talon_ripper'),
(317465, 'aura_ascension_item_talon_ripper'),
(321465, 'aura_ascension_item_talon_ripper');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2127044, 2127144, 2127244, 2127344, 2127444, 2127544, 2127644, 2127744, 2127844,
2128044, 2128144, 2128244, 2128344) AND `ScriptName` = 'aura_ascension_item_leggings_of_beast_mastery';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2127044, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127144, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127244, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127344, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127444, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127544, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127644, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127744, 'aura_ascension_item_leggings_of_beast_mastery'),
(2127844, 'aura_ascension_item_leggings_of_beast_mastery'),
(2128044, 'aura_ascension_item_leggings_of_beast_mastery'),
(2128144, 'aura_ascension_item_leggings_of_beast_mastery'),
(2128244, 'aura_ascension_item_leggings_of_beast_mastery'),
(2128344, 'aura_ascension_item_leggings_of_beast_mastery');

UPDATE `item_template` SET `spellid_1` = 2128044 WHERE `entry` = 31328 AND `spellid_1` = 38297;
