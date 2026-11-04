-- Live Worldforged upgrade ladder (user, 2026-11-04): below Zul'Gurub 60 (always open), Zul'Gurub 64, Molten Core
-- 67 and 70, Onyxia 73, Blackwing Lair 77, Ahn'Qiraj 81, Naxxramas 88. Each epic rank opens with its raid's last boss.
UPDATE `worldforged_upgrade` `u`
JOIN `item_template` `t` ON `t`.`entry` = `u`.`target_item`
SET `u`.`unlock_creature` = CASE `t`.`ItemLevel`
    WHEN 64 THEN 14834
    WHEN 67 THEN 11502
    WHEN 70 THEN 11502
    WHEN 73 THEN 10184
    WHEN 77 THEN 11583
    WHEN 81 THEN 15727
    WHEN 88 THEN 15990
END
WHERE `t`.`Quality` = 4 AND `t`.`ItemLevel` IN (64, 67, 70, 73, 77, 81, 88);
