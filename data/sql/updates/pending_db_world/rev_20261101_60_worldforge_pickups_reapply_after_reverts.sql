-- DB update: re-apply the Death Trophy (#10507), Badlands (#10520) and Tanaris (#10527) worldforge positions
-- where the removed *_revert.sql files already restored the old ones
UPDATE `gameobject`
SET `position_x` = -11682.3, `position_y` = 559.3, `position_z` = 50.16064045771634, `orientation` = 2.6133,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.965316, `rotation3` = 0.261085
WHERE `guid` = 6941373 AND `id` = 95732 AND `position_z` BETWEEN 49.80 AND 49.92;
UPDATE `gameobject`
SET `position_x` = -6602.942737946511, `position_y` = -2639.223582017307, `position_z` = 266.9942051370507,
    `orientation` = 3.22012, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.999229, `rotation3` = -0.039254
WHERE `guid` = 6940271 AND `id` = 518345 AND `position_x` BETWEEN -6601.91 AND -6601.89
    AND `position_y` BETWEEN -2651.01 AND -2650.99;
UPDATE `gameobject`
SET `position_x` = -7531, `position_y` = -3599, `position_z` = 12.45913792126871, `orientation` = 2.17713,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.885962, `rotation3` = 0.463757
WHERE `guid` = 6941616 AND `id` = 515745 AND `position_z` BETWEEN 9.91 AND 9.93;
