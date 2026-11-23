-- Five Worldforged weapons jumped from item level 64 straight to 77 (#11952). Their tier ids interleave
-- (64 = X, 70 = X+1, 73 = X+12000, 77 = X+2000, 81 = X+2001, 88 = X+4000), so the fixed-offset tier migration linked
-- 64 to 77 and never reached 70, 73, 81 or 88. The chain is now 64 -> 70 (Ragnaros) -> 73 (Onyxia) -> 77 (Nefarian)
-- -> 81 (C'Thun) -> 88 (Kel'Thuzad), priced like every other chain from the item level 64 rank's cost c:
-- 1.5c, 2c, 2.5c, 3c, 3.5c.

-- 77 now comes from 73 instead of 64.
UPDATE `worldforged_upgrade` SET `base_item` = 1390437, `cost` = 12500 WHERE `id` = 1380437 AND `target_item` = 1380437;
UPDATE `worldforged_upgrade` SET `base_item` = 1390463, `cost` = 9375 WHERE `id` = 1380463 AND `target_item` = 1380463;
UPDATE `worldforged_upgrade` SET `base_item` = 1390608, `cost` = 12500 WHERE `id` = 1380608 AND `target_item` = 1380608;
UPDATE `worldforged_upgrade` SET `base_item` = 1390827, `cost` = 7030 WHERE `id` = 1380827 AND `target_item` = 1380827;
UPDATE `worldforged_upgrade` SET `base_item` = 1391460, `cost` = 9375 WHERE `id` = 1381460 AND `target_item` = 1381460;

DELETE FROM `worldforged_upgrade` WHERE `id` IN (
1378438, 1390437, 1380438, 1382437,
1378464, 1390463, 1380464, 1382463,
1378609, 1390608, 1380609, 1382608,
1378828, 1390827, 1380828, 1382827,
1379461, 1391460, 1381461, 1383460);
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`) VALUES
-- Chillbane Cleaver
(1378438, 8, 1378437, 1378438, 7500, 11502),
(1390437, 8, 1378438, 1390437, 10000, 10184),
(1380438, 8, 1380437, 1380438, 15000, 15727),
(1382437, 8, 1380438, 1382437, 17500, 15990),
-- Chillhammer
(1378464, 8, 1378463, 1378464, 5625, 11502),
(1390463, 8, 1378464, 1390463, 7500, 10184),
(1380464, 8, 1380463, 1380464, 11250, 15727),
(1382463, 8, 1380464, 1382463, 13125, 15990),
-- Heavy Tempered Blade
(1378609, 8, 1378608, 1378609, 7500, 11502),
(1390608, 8, 1378609, 1390608, 10000, 10184),
(1380609, 8, 1380608, 1380609, 15000, 15727),
(1382608, 8, 1380609, 1382608, 17500, 15990),
-- Arcane Glinting Shard
(1378828, 9, 1378827, 1378828, 4218, 11502),
(1390827, 9, 1378828, 1390827, 5624, 10184),
(1380828, 9, 1380827, 1380828, 8436, 15727),
(1382827, 9, 1380828, 1382827, 9842, 15990),
-- Shahiar's Lost Horn
(1379461, 8, 1379460, 1379461, 5625, 11502),
(1391460, 8, 1379461, 1391460, 7500, 10184),
(1381461, 8, 1381460, 1381461, 11250, 15727),
(1383460, 8, 1381461, 1383460, 13125, 15990);
