-- Sally Vernal (Sentinel Hill town hall, guid 9950153) was spawned by rev_20261004_10_coa_westfall_restore
-- without a creature_addon row, so she defaulted to UNIT_STAND_STATE_STAND instead of sitting on her bench
-- pew like her neighbors Everard Handor (9950149) and Willow Brelor (9950152), both bytes1 = 5 (#9149).
DELETE FROM `creature_addon` WHERE `guid` = 9950153;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
`auras`) VALUES
(9950153, 0, 0, 5, 1, 0, 0, NULL);
