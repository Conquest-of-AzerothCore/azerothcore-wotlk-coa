UPDATE `gameobject` SET `state` = 1 WHERE `guid` = 15576 AND `id` = 157923;
UPDATE `gameobject` SET `state` = 0 WHERE `guid` = 15640 AND `id` = 161462;
UPDATE `gameobject` SET `state` = 0 WHERE `guid` = 15352 AND `id` = 161516;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161460 AND `source_type` = 1 AND `id` IN (1, 2, 3);
UPDATE `smart_scripts` SET `link` = 0 WHERE `entryorguid` = 161460 AND `source_type` = 1 AND `id` = 0;
