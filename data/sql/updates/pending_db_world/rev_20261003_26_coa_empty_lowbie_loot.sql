-- CoA: low-level creatures whose loot table rolled nothing.
--
-- Seven creature loot tables in the 7-11 level band carried only 'World Loot Level' reference
-- rows at Chance 0. A reference row is skipped entirely when its own chance roll fails, and a
-- chance of 0 never rolls (LootStoreItem::Roll: `if (_reference) return roll_chance_f(_chance
-- * rate)`), so those creatures dropped nothing at all. The base data has the same shape for
-- each one, so this is an authoring gap in the shipped tables, not a CoA clobber.
--
-- The correct kit is already written on the creatures' own siblings, and this file applies that
-- shared kit rather than inventing one:
--
--   Scarlet family (faction 67) - 1535 Scarlet Warrior (6-7) and 1537 Scarlet Zealot (8-9)
--   both carry: 159 Refreshing Spring Water 4%, 2589 Linen Cloth 33% (1-2), 4604 Forest
--   Mushroom Cap 10%, and 2875 Scarlet Insignia Ring 40% with QuestRequired 1 (the quest 374
--   'Proof of Demise' turn-in item). 1538 Scarlet Friar (9-10), 1539 Scarlet Neophyte (10-11)
--   and 1540 Scarlet Vanguard (10-11) carried only the dead reference rows and are brought onto
--   the same kit, so the ring keeps dropping as the player moves up the Scarlet ladder.
--
--   Undead family (faction 21) - 1527 Hungering Dead (7-8) and 1533 Tormented Spirit (8-9) both
--   carry: 159 Refreshing Spring Water 4%, 2589 Linen Cloth 33% (1-2), 4604 Forest Mushroom Cap
--   10%. 1528 Shambling Horror (8-9) and 1534 Wailing Ancestor (9-10) sit inside that same band
--   and are brought onto the same kit.
--
-- The chance-0 'World Loot Level' reference rows are deliberately left in place: they are
-- present on every sibling too and are inert by design.
--
-- Idempotent: delete/reinsert of the four/five rows added per creature.

DELETE FROM `creature_loot_template` WHERE `Entry` IN (1528, 1534, 1538, 1539, 1540) AND `Reference` = 0;

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(1528, 159,  0, 4,  0, 1, 0, 1, 1, 'Shambling Horror - Refreshing Spring Water (undead family kit)'),
(1528, 2589, 0, 33, 0, 1, 0, 1, 2, 'Shambling Horror - Linen Cloth (undead family kit)'),
(1528, 4604, 0, 10, 0, 1, 0, 1, 1, 'Shambling Horror - Forest Mushroom Cap (undead family kit)'),
(1534, 159,  0, 4,  0, 1, 0, 1, 1, 'Wailing Ancestor - Refreshing Spring Water (undead family kit)'),
(1534, 2589, 0, 33, 0, 1, 0, 1, 2, 'Wailing Ancestor - Linen Cloth (undead family kit)'),
(1534, 4604, 0, 10, 0, 1, 0, 1, 1, 'Wailing Ancestor - Forest Mushroom Cap (undead family kit)'),
(1538, 159,  0, 4,  0, 1, 0, 1, 1, 'Scarlet Friar - Refreshing Spring Water (Scarlet family kit)'),
(1538, 2589, 0, 33, 0, 1, 0, 1, 2, 'Scarlet Friar - Linen Cloth (Scarlet family kit)'),
(1538, 2875, 0, 40, 1, 1, 0, 1, 1, 'Scarlet Friar - Scarlet Insignia Ring (quest 374)'),
(1538, 4604, 0, 10, 0, 1, 0, 1, 1, 'Scarlet Friar - Forest Mushroom Cap (Scarlet family kit)'),
(1539, 159,  0, 4,  0, 1, 0, 1, 1, 'Scarlet Neophyte - Refreshing Spring Water (Scarlet family kit)'),
(1539, 2589, 0, 33, 0, 1, 0, 1, 2, 'Scarlet Neophyte - Linen Cloth (Scarlet family kit)'),
(1539, 2875, 0, 40, 1, 1, 0, 1, 1, 'Scarlet Neophyte - Scarlet Insignia Ring (quest 374)'),
(1539, 4604, 0, 10, 0, 1, 0, 1, 1, 'Scarlet Neophyte - Forest Mushroom Cap (Scarlet family kit)'),
(1540, 159,  0, 4,  0, 1, 0, 1, 1, 'Scarlet Vanguard - Refreshing Spring Water (Scarlet family kit)'),
(1540, 2589, 0, 33, 0, 1, 0, 1, 2, 'Scarlet Vanguard - Linen Cloth (Scarlet family kit)'),
(1540, 2875, 0, 40, 1, 1, 0, 1, 1, 'Scarlet Vanguard - Scarlet Insignia Ring (quest 374)'),
(1540, 4604, 0, 10, 0, 1, 0, 1, 1, 'Scarlet Vanguard - Forest Mushroom Cap (Scarlet family kit)');

-- 1536 Scarlet Missionary (7-8) already received 2875 in rev_20261003_20; complete it with the
-- same family kit so it is not the only Scarlet left without cloth and water.
DELETE FROM `creature_loot_template` WHERE `Entry` = 1536 AND `Reference` = 0 AND `Item` <> 2875;

INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
VALUES
(1536, 159,  0, 4,  0, 1, 0, 1, 1, 'Scarlet Missionary - Refreshing Spring Water (Scarlet family kit)'),
(1536, 2589, 0, 33, 0, 1, 0, 1, 2, 'Scarlet Missionary - Linen Cloth (Scarlet family kit)'),
(1536, 4604, 0, 10, 0, 1, 0, 1, 1, 'Scarlet Missionary - Forest Mushroom Cap (Scarlet family kit)');
