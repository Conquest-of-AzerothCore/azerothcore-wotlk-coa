-- rev_20261017_77_pale_reach_npc_looks_poses deleted creature_addon for every guid it lists, including the
-- Pale Reach Paladins-vs-Troggs battlefield corpses (entry 164206 guids 9960530-9960539, entry 164209 guids
-- 9962102-9962106), but only reinserted a handful of unrelated guids. Without their bytes1 = 7
-- (UNIT_STAND_STATE_DEAD) row, these live-health "dead" decoration spawns stand upright and idle instead of
-- lying as corpses (#9150). Restore their original rows; guid 9960610, dropped by the same DELETE at a
-- different location, is not part of this report and is left unfixed.
DELETE FROM `creature_addon` WHERE `guid` IN (9960530, 9960531, 9960532, 9960533, 9960534, 9960535, 9960536,
9960537, 9960538, 9960539, 9962102, 9962103, 9962104, 9962105, 9962106);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
`auras`) VALUES
(9960530, 0, 0, 7, 1, 0, 0, ''),
(9960531, 0, 0, 7, 1, 0, 0, ''),
(9960532, 0, 0, 7, 1, 0, 0, ''),
(9960533, 0, 0, 7, 1, 0, 0, ''),
(9960534, 0, 0, 7, 1, 0, 0, ''),
(9960535, 0, 0, 7, 1, 0, 0, ''),
(9960536, 0, 0, 7, 1, 0, 0, ''),
(9960537, 0, 0, 7, 1, 0, 0, ''),
(9960538, 0, 0, 7, 1, 0, 0, ''),
(9960539, 0, 0, 7, 1, 0, 0, ''),
(9962102, 0, 0, 7, 1, 0, 0, ''),
(9962103, 0, 0, 7, 1, 0, 0, ''),
(9962104, 0, 0, 7, 1, 0, 0, ''),
(9962105, 0, 0, 7, 1, 0, 0, ''),
(9962106, 0, 0, 7, 1, 0, 0, '');
