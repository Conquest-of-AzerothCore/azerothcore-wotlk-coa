DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` BETWEEN 303595 AND 303602;
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`) VALUES
(303595, 255960, 0, 1), (303595, 282753, 1, 1),
(303596, 255961, 0, 1), (303596, 282754, 1, 1),
(303597, 255962, 0, 1), (303597, 282755, 1, 1),
(303598, 255963, 0, 1), (303598, 282756, 1, 1),
(303599, 255964, 0, 1), (303599, 282757, 1, 1),
(303600, 255965, 0, 1), (303600, 282758, 1, 1),
(303601, 255966, 0, 1), (303601, 282759, 1, 1),
(303602, 255967, 0, 1), (303602, 282760, 1, 1);

UPDATE `item_template` SET `ScriptName` = 'item_ethereal_set_cache' WHERE `entry` BETWEEN 303595 AND 303602;

UPDATE `item_template` SET `ScriptName` = 'item_ascension_vanity_mount_cache' WHERE `entry` IN (199735, 199736);
