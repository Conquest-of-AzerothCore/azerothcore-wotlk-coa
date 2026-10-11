-- Patch-WB1 raised the ground at The Sepulcher by about 2 yards; Apothecary Renferrel stood 2.17 yards under it.
UPDATE `creature` SET `position_z` = 128.01 WHERE `guid` = 17612 AND `id` = 1937;
