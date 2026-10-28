-- Challenger Vilria 10157358 <Leveling Challenges and Trials>, mounted on her Dreadsteed in the Shadow Grave.
--   name, title  SOURCED-CACHE (creaturecache) and the Exiles export; her mount Vilria's Dreadsteed 200203 is
--     display 10718 (creaturecache).
--   role  CoA's client sends gossip with 10157358, like Stony Tark 10157257, to its Challenges window
--     (Interface\FrameXML\UIParent.lua, C_Gossip:RedirectNPCs); she copies Stony Tark's template
--     (mod-path-to-ascension 2026_09_28_00).
--   place  the client's map marker challenger-tirisfal-glades (1660.26, 1691.89) (Ascension_POI
--     GameObjectPOIs.lua) falls on the Plague Cistern Prop; CoA footage shows the rider beside the props. She
--     stands at the nearest standable crypt floor 5 yd from the marker, clear of the cistern and cauldron
--     (surface.standable on Md_Cryptonerm.wmo), facing Undertaker Mordo.
--   look  her CoA display 213970 is in neither DBC: stand-in Forsaken female death knight 25779 (horned helm,
--     as in the footage) (INFERRED).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `faction`, `npcflag`, `rank`, `unit_class`, `unit_flags`,
`type`, `type_flags`)
VALUES
(10157358, 'Challenger Vilria', 'Leveling Challenges and Trials', 35, 3, 0, 1, 0, 7, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `faction` = VALUES(`faction`),
`npcflag` = VALUES(`npcflag`), `rank` = VALUES(`rank`), `unit_class` = VALUES(`unit_class`),
`unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 10157358;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(10157358, 0, 25779, 1, 1);
DELETE FROM `creature_template_addon` WHERE `entry` = 10157358;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(10157358, 0, 10718, 0, 0, 0, 0, '');
DELETE FROM `creature` WHERE `guid` = 9010900;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9010900, 10157358, 0, 0, 0, 1, 1, 0, 1665.26, 1691.89, 120.719, 5.17, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Shadow Grave: Challenger Vilria, 5 yd from her map marker, beside the cistern, facing Mordo');
