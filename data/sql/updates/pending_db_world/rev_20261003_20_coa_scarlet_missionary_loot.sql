-- Issue #6206: Scarlet Missionary does not drop the Scarlet Insignia Ring quest item.
--
-- Quest 374 'Proof of Demise' requires 10x item 2875 'Scarlet Insignia Ring'. Of the six low-level
-- Scarlet mobs only two can drop it - 1535 'Scarlet Warrior' (level 6) and 1537 'Scarlet Zealot'
-- (level 8) - both at chance 40 with QuestRequired = 1.
--
-- 1536 'Scarlet Missionary' (level 7) sits between those two levels but its loot table holds only
-- the two chance-0 world-loot reference rows, so it can never roll the ring. This matches the
-- report exactly ("only Scarlet Zealot seem to" drop it).
--
-- Fix: add the ring row to 1536 with the same chance/flag values its siblings use.
--
-- Idempotent: delete/reinsert of the single added row.

DELETE FROM `creature_loot_template` WHERE `Entry` = 1536 AND `Item` = 2875;

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(1536, 2875, 0, 40, 1, 1, 0, 1, 1, 'Scarlet Missionary - Scarlet Insignia Ring');
