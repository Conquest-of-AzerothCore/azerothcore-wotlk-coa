-- #12194: Add missing Wrists piece (774041, invType 9, member of ItemSet 61889
-- Set of Infinite Madness) to the Set of Infinite Madness armor cache (774042).
-- VanityCollection.dbc row 68366 listed only 774033-774040 (idx 0-7), omitting 774041.
DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 774042 AND `member_item` = 774041;
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
VALUES (774042, 774041, 8, 1);
