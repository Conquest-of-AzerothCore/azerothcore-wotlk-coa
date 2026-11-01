-- Twilight Witch's Attire (420044) gave only 8 of the set's 15 pieces. It now also holds the seven alternative pieces
-- (shoulders, shirt, chest, waist and three legs), one of each, after the eight it already had (idx 8-14).
-- ON DUPLICATE KEY UPDATE keeps one row per piece, so a reapply leaves the result unchanged. Like rev_20261024_01 it
-- only acts on a realm that fills the Vanity Store price table.
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
SELECT 420044, `p`.`member_item`, `p`.`idx`, 1
FROM (VALUES
  ROW(420604, 8),   -- Twilight Witch's Mantle (shoulders)
  ROW(420606, 9),   -- Twilight Witch's Halter (shirt)
  ROW(420615, 10),  -- Twilight Witch's Camisole (chest)
  ROW(420605, 11),  -- Twilight Witch's Buckle (waist)
  ROW(420609, 12),  -- Twilight Witch's Shorts (legs)
  ROW(420612, 13),  -- Twilight Witch's Pants (legs)
  ROW(420618, 14)   -- Twilight Witch's Pleated skirt (legs)
) `p` (`member_item`, `idx`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `idx` = `p`.`idx`, `count` = 1;
