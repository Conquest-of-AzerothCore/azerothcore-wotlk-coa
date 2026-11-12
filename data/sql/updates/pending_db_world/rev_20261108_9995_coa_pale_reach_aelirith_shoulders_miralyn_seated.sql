-- Aelirith (164279) in the Hall of Stories wore shoulders 11701, which draw large pale-blue curling horns in this
-- client. Her dialogue model in wJ2j4NOgjRI 3:14:40 shows low flared blades in slate blue-violet with pale tips: the
-- Mistscape Mantle (display 8668), the user's pick in game. Her robe, belt, gloves and hair stay as they were.
UPDATE `creature_display_preset` SET `item_shoulders` = 8668 WHERE `entry` = 164279 AND `display_id` = 15475;

-- Miralyn (164291) stood on top of the bench beside her. The realm captured her root 0.24 yd over the floor, the height
-- of a seated NPC, on the bench seat (0.68 yd high), already facing across it; she now sits on it.
DELETE FROM `creature_addon` WHERE `guid` = 9960150;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960150, 0, 0, 5, 1, 0, 0, '');
