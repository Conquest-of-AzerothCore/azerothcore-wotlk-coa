-- Built from Ascension's combat logs and client data. Regenerate rather than edit by hand.
--
-- Onyxia in four difficulties, rebuilt from combat logs.
--
-- Attested: MapDifficulty.dbc has four rows for map 249, and the logs hold a
-- kill on every difficulty.
--
-- Assumed: the template ids. Onyxia pointed at 36538 "Onyxia (1)", which is
-- AzerothCore's own 25-player Onyxia and naming, not something found on
-- Ascension. For Mythic and Ascended there was nothing, and the core falls back
-- to Normal and Heroic, which would give Mythic less melee than Heroic. So the
-- convention attested for Molten Core applies here too: base + 100000 / 200000
-- / 300000, exact copies of the base. Health comes from flex and spell damage
-- from SpellDifficulty.dbc either way.

DELETE FROM `creature_template` WHERE `entry` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 110184, `name` = 'Onyxia',
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 110184;
INSERT INTO `creature_template_model` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 10184;
UPDATE `ony_tier` SET `CreatureId` = 110184;
INSERT INTO `creature_template_movement` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 110184;
INSERT INTO `creature_template_resistance` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 110184;
INSERT INTO `creature_template_spell` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_addon` WHERE `entry` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 110184;
INSERT INTO `creature_template_addon` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` = 110184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_onkill_reputation` WHERE `creature_id` = 10184;
UPDATE `ony_tier` SET `creature_id` = 110184;
INSERT INTO `creature_onkill_reputation` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;

DELETE FROM `creature_template` WHERE `entry` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 210184, `name` = 'Onyxia',
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 210184;
INSERT INTO `creature_template_model` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 10184;
UPDATE `ony_tier` SET `CreatureId` = 210184;
INSERT INTO `creature_template_movement` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 210184;
INSERT INTO `creature_template_resistance` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 210184;
INSERT INTO `creature_template_spell` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_addon` WHERE `entry` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 210184;
INSERT INTO `creature_template_addon` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` = 210184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_onkill_reputation` WHERE `creature_id` = 10184;
UPDATE `ony_tier` SET `creature_id` = 210184;
INSERT INTO `creature_onkill_reputation` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;

DELETE FROM `creature_template` WHERE `entry` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 310184, `name` = 'Onyxia',
    `difficulty_entry_1` = 0, `difficulty_entry_2` = 0, `difficulty_entry_3` = 0;
INSERT INTO `creature_template` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_model` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 310184;
INSERT INTO `creature_template_model` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_movement` WHERE `CreatureId` = 10184;
UPDATE `ony_tier` SET `CreatureId` = 310184;
INSERT INTO `creature_template_movement` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_resistance` WHERE `CreatureID` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_resistance` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 310184;
INSERT INTO `creature_template_resistance` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_spell` WHERE `CreatureID` = 10184;
UPDATE `ony_tier` SET `CreatureID` = 310184;
INSERT INTO `creature_template_spell` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_template_addon` WHERE `entry` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_template_addon` WHERE `entry` = 10184;
UPDATE `ony_tier` SET `entry` = 310184;
INSERT INTO `creature_template_addon` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` = 310184;
DROP TEMPORARY TABLE IF EXISTS `ony_tier`;
CREATE TEMPORARY TABLE `ony_tier` AS SELECT * FROM `creature_onkill_reputation` WHERE `creature_id` = 10184;
UPDATE `ony_tier` SET `creature_id` = 310184;
INSERT INTO `creature_onkill_reputation` SELECT * FROM `ony_tier`;
DROP TEMPORARY TABLE `ony_tier`;

-- Links, and the script: the stock choreography with Ascension's numbers.
UPDATE `creature_template` SET
    `difficulty_entry_1` = 110184,
    `difficulty_entry_2` = 210184,
    `difficulty_entry_3` = 310184,
    `ScriptName` = 'boss_onyxia_coa'
 WHERE `entry` = 10184;
UPDATE `creature_template` SET `ScriptName` = 'boss_onyxia_coa' WHERE `entry` IN (110184,210184,310184);

-- Every difficulty: 1 | 2 | 4 | 8.
UPDATE `creature` SET `spawnMask` = 15 WHERE `map` = 249;
UPDATE `gameobject` SET `spawnMask` = 15 WHERE `map` = 249;

-- The stock Deep Breath trail, all 85 links of the chain, deals Ascension's
-- damage (2108306 and its tier variants) instead of its own.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_onyxia_coa_breath';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(17087, 'spell_onyxia_coa_breath'),
(17088, 'spell_onyxia_coa_breath'),
(17089, 'spell_onyxia_coa_breath'),
(17090, 'spell_onyxia_coa_breath'),
(17091, 'spell_onyxia_coa_breath'),
(17092, 'spell_onyxia_coa_breath'),
(17093, 'spell_onyxia_coa_breath'),
(17094, 'spell_onyxia_coa_breath'),
(17095, 'spell_onyxia_coa_breath'),
(17097, 'spell_onyxia_coa_breath'),
(18352, 'spell_onyxia_coa_breath'),
(18353, 'spell_onyxia_coa_breath'),
(18354, 'spell_onyxia_coa_breath'),
(18355, 'spell_onyxia_coa_breath'),
(18356, 'spell_onyxia_coa_breath'),
(18357, 'spell_onyxia_coa_breath'),
(18358, 'spell_onyxia_coa_breath'),
(18359, 'spell_onyxia_coa_breath'),
(18360, 'spell_onyxia_coa_breath'),
(18361, 'spell_onyxia_coa_breath'),
(18565, 'spell_onyxia_coa_breath'),
(18566, 'spell_onyxia_coa_breath'),
(18567, 'spell_onyxia_coa_breath'),
(18568, 'spell_onyxia_coa_breath'),
(18569, 'spell_onyxia_coa_breath'),
(18570, 'spell_onyxia_coa_breath'),
(18571, 'spell_onyxia_coa_breath'),
(18572, 'spell_onyxia_coa_breath'),
(18573, 'spell_onyxia_coa_breath'),
(18574, 'spell_onyxia_coa_breath'),
(18575, 'spell_onyxia_coa_breath'),
(18578, 'spell_onyxia_coa_breath'),
(18579, 'spell_onyxia_coa_breath'),
(18580, 'spell_onyxia_coa_breath'),
(18581, 'spell_onyxia_coa_breath'),
(18582, 'spell_onyxia_coa_breath'),
(18583, 'spell_onyxia_coa_breath'),
(18585, 'spell_onyxia_coa_breath'),
(18586, 'spell_onyxia_coa_breath'),
(18587, 'spell_onyxia_coa_breath'),
(18588, 'spell_onyxia_coa_breath'),
(18589, 'spell_onyxia_coa_breath'),
(18590, 'spell_onyxia_coa_breath'),
(18591, 'spell_onyxia_coa_breath'),
(18592, 'spell_onyxia_coa_breath'),
(18593, 'spell_onyxia_coa_breath'),
(18594, 'spell_onyxia_coa_breath'),
(18595, 'spell_onyxia_coa_breath'),
(18597, 'spell_onyxia_coa_breath'),
(18598, 'spell_onyxia_coa_breath'),
(18599, 'spell_onyxia_coa_breath'),
(18600, 'spell_onyxia_coa_breath'),
(18601, 'spell_onyxia_coa_breath'),
(18602, 'spell_onyxia_coa_breath'),
(18603, 'spell_onyxia_coa_breath'),
(18604, 'spell_onyxia_coa_breath'),
(18605, 'spell_onyxia_coa_breath'),
(18606, 'spell_onyxia_coa_breath'),
(18607, 'spell_onyxia_coa_breath'),
(18611, 'spell_onyxia_coa_breath'),
(18612, 'spell_onyxia_coa_breath'),
(18613, 'spell_onyxia_coa_breath'),
(18614, 'spell_onyxia_coa_breath'),
(18615, 'spell_onyxia_coa_breath'),
(18616, 'spell_onyxia_coa_breath'),
(18618, 'spell_onyxia_coa_breath'),
(18619, 'spell_onyxia_coa_breath'),
(18620, 'spell_onyxia_coa_breath'),
(18621, 'spell_onyxia_coa_breath'),
(18622, 'spell_onyxia_coa_breath'),
(18623, 'spell_onyxia_coa_breath'),
(18624, 'spell_onyxia_coa_breath'),
(18625, 'spell_onyxia_coa_breath'),
(18626, 'spell_onyxia_coa_breath'),
(18627, 'spell_onyxia_coa_breath'),
(18628, 'spell_onyxia_coa_breath'),
(21132, 'spell_onyxia_coa_breath'),
(21133, 'spell_onyxia_coa_breath'),
(21135, 'spell_onyxia_coa_breath'),
(21136, 'spell_onyxia_coa_breath'),
(21137, 'spell_onyxia_coa_breath'),
(21138, 'spell_onyxia_coa_breath'),
(21139, 'spell_onyxia_coa_breath'),
(22267, 'spell_onyxia_coa_breath'),
(22268, 'spell_onyxia_coa_breath');
