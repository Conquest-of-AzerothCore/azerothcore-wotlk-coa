-- The Lumber Axe (6954) on the Book of Artisans' two shelves, slot 29. Neither
-- trade has a trainer or a camp shop, so the book is the counter at which a
-- character whose axe is gone replaces it.
--
-- Declared here rather than in the module's own file: that file re-declares both
-- shelves and deletes what another script writes to them, so these rows have to
-- arrive after it. Updates are applied in filename order, and
-- `book_of_artisans.sql` sorts before `rev_*`.
--
-- The delete first, so a re-apply replaces the rows instead of colliding with
-- `npc_vendor`'s primary key.
DELETE FROM `npc_vendor` WHERE `entry` IN (57500, 57524) AND `slot` = 29;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(57500, 29, 6954, 0, 0, 0, 0),
(57524, 29, 6954, 0, 0, 0, 0);
