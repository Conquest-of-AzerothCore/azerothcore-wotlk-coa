-- Keep Karazhan at the Classic level cap. Bosses use level 63, and ordinary enemies keep a level range.
UPDATE `creature_template` AS `template`
SET `template`.`minlevel` = CASE WHEN `template`.`minlevel` <= 70 THEN 60
        WHEN `template`.`minlevel` = 71 THEN 61 WHEN `template`.`minlevel` = 72 THEN 62 ELSE 63 END,
    `template`.`maxlevel` = CASE WHEN `template`.`maxlevel` <= 70 THEN 60
        WHEN `template`.`maxlevel` = 71 THEN 61 WHEN `template`.`maxlevel` = 72 THEN 62 ELSE 63 END
WHERE `template`.`maxlevel` > 63 AND `template`.`rank` IN (1, 2, 4)
    AND EXISTS (SELECT 1 FROM `creature` AS `spawn` WHERE `spawn`.`id` = `template`.`entry` AND `spawn`.`map` = 532)
    AND NOT EXISTS (
        SELECT 1 FROM `creature` AS `other` WHERE `other`.`id` = `template`.`entry` AND `other`.`map` <> 532);

UPDATE `creature_template` AS `template`
SET `template`.`minlevel` = 63, `template`.`maxlevel` = 63
WHERE `template`.`entry` IN (15550, 15687, 15688, 15689, 15690, 15691, 16151, 16152, 16179, 16180,
    16181, 16457, 16524, 17225, 17521, 17533, 17534, 17535, 18168, 28194);

UPDATE `creature_template` AS `template`
SET `template`.`minlevel` = 60, `template`.`maxlevel` = 60
WHERE `template`.`entry` IN (17229, 17248, 17261, 17267, 17543, 17546, 17547, 17548, 17646, 17650)
    AND NOT EXISTS (
        SELECT 1 FROM `creature` AS `other` WHERE `other`.`id` = `template`.`entry` AND `other`.`map` <> 532);
