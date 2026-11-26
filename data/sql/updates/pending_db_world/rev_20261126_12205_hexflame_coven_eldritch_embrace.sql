-- #12205: Include Eldritch Embrace of the Hexflame Coven (298156, cosmetic backpack)
-- in the Eldritch Rites of the Hexflame Coven set box (298084). VanityCollection.dbc
-- row 64805 states 298156 is part of the Eldritch Rites of the Hexflame Coven set,
-- and rev_20261024_01 removed it from individual Vanity Store sale, but row 64788
-- listed only the nine armor pieces (idx 0-8).
DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 298084 AND `member_item` = 298156;
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
VALUES (298084, 298156, 9, 1);
