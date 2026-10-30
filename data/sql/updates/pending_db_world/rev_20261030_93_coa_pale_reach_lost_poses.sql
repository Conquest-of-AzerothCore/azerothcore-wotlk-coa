-- rev_20261017_77_pale_reach_npc_looks_poses deleted these addon rows without reinserting them, so the kneeling,
-- sitting, sleeping and dead Pale Reach NPCs below stood up, Torric Graven inside his rocking chair. Restore their
-- original rows.
DELETE FROM `creature_addon` WHERE `guid` IN (9960015, 9960129, 9960134, 9960185, 9960194, 9960202, 9960216, 9960217,
9960218, 9960326, 9960327, 9960330, 9960488, 9999004);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
`auras`) VALUES
(9960015, 0, 0, 8, 1, 0, 0, NULL),
(9960129, 0, 0, 1, 1, 0, 0, NULL),
(9960134, 0, 0, 8, 1, 0, 0, NULL),
(9960185, 0, 0, 0, 1, 0, 0, '29266'),
(9960194, 0, 0, 5, 1, 0, 0, ''),
(9960202, 0, 0, 8, 1, 0, 0, ''),
(9960216, 0, 0, 0, 1, 0, 0, '29266'),
(9960217, 0, 0, 0, 1, 0, 0, '29266'),
(9960218, 0, 0, 0, 1, 0, 0, '29266'),
(9960326, 0, 0, 3, 1, 0, 0, ''),
(9960327, 0, 0, 8, 1, 0, 0, ''),
(9960330, 0, 0, 3, 1, 0, 0, ''),
(9960488, 0, 0, 8, 0, 0, 0, ''),
(9999004, 0, 0, 1, 1, 0, 0, NULL);
