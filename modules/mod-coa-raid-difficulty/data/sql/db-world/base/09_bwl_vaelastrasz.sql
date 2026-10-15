-- Vaelastrasz the Corrupt as Ascension redesigned him; see boss_vaelastrasz_coa.cpp.
--
-- The Orb of Corruption exists nowhere in Ascension's data: its spells do
-- (2110640 on a player, 2110641 on Vaelastrasz), the orb does not. It is a new
-- creature, 9780020, copied from the World Invisible Trigger and given the
-- client's own void corruption orb model (display 130547,
-- spells\8fx_discboss_voidcorruption_orb). Not selectable, not attackable,
-- slow; the script moves it.
--
-- Undo: SET `ScriptName` = 'boss_vaelastrasz' on 13020, and delete 9780020.

DELETE FROM `creature_template` WHERE `entry` = 9780020;
DROP TEMPORARY TABLE IF EXISTS `vael_orb`;
CREATE TEMPORARY TABLE `vael_orb` AS SELECT * FROM `creature_template` WHERE `entry` = 12999;
UPDATE `vael_orb` SET
    `entry` = 9780020, `name` = 'Orb of Corruption', `subname` = '',
    `minlevel` = 63, `maxlevel` = 63, `faction` = 14,
    `unit_flags` = 33554434,        -- non attackable | not selectable
    `flags_extra` = 0,              -- not a trigger: players must see it
    `speed_walk` = 0.5, `speed_run` = 0.5,
    `AIName` = '', `ScriptName` = 'npc_vael_corruption_orb';
INSERT INTO `creature_template` SELECT * FROM `vael_orb`;
DROP TEMPORARY TABLE `vael_orb`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9780020;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES (9780020, 0, 130547, 1, 1, 0);

-- Without a row here the core refuses to create the creature at all.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 130547;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`)
VALUES (130547, 0.5, 1, 2, 0, 0);

UPDATE `creature_template` SET `ScriptName` = 'boss_vaelastrasz_coa' WHERE `entry` = 13020;
