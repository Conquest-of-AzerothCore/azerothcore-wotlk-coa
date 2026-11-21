-- Dire Maul West: Lord Hel'nurath stands alone on Ascension, without Dread Guards, on the platform before Immol'thar (#11380).
DELETE FROM `creature` WHERE `guid` IN (9429002, 9429003) AND `id` = 14483;
UPDATE `creature` SET `position_x` = 59.1654, `position_y` = 653.502, `position_z` = -24.5791, `orientation` = 2.31301 WHERE `guid` = 9429001 AND `id` = 14506;
