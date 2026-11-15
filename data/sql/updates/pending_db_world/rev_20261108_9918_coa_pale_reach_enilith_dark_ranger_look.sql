-- Enilith Naemyl (164309), the Dark Ranger in the Chambers of Erdaya, set by the user in game: red Dark Ranger eyes on
-- pale skin (blood elf skin 32, was the cyan-glow death knight skin 18), the bald hair style 19 under her hood, and a
-- Skeletal Longsword (2018) in each hand. Her outfit from rev_20261018_11 is unchanged. She crouches in the stealth
-- stance (emote state 433) in place of the kneel from rev_20261030_93: every kneel animation sheathes weapons, while
-- the stealth stance keeps both swords drawn (sheath state 1).
UPDATE `creature_display_preset` SET `skin` = 32, `hair` = 19 WHERE `entry` = 164309 AND `display_id` = 15475;

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164309;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164309, 1, 2018, 2018, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960134 AND `id` = 164309;

DELETE FROM `creature_addon` WHERE `guid` = 9960134;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960134, 0, 0, 0, 1, 433, 0, NULL);
