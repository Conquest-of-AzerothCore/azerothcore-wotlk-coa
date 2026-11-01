-- The three witch transmog sets (Twilight, Sky and Love Witch) get complete caches. Like rev_20261024_01 every
-- statement only acts on a realm that fills the Vanity Store price table; a reapply leaves the result unchanged
-- (ON DUPLICATE KEY UPDATE keeps one row per piece; the description is only rewritten where the old text is).

-- 1) Sky Witch's Attire (420043) and Love Witch's Attire (420042) gave 8 of 15 pieces, like Twilight Witch's
--    Attire before rev_20261029_20: add the seven alternative pieces after the eight they have (idx 8-14).
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
SELECT `p`.`cache_item`, `p`.`member_item`, `p`.`idx`, 1
FROM (VALUES
  ROW(420043, 420593, 8),   -- Sky Witch's Mantle (shoulders)
  ROW(420043, 420595, 9),   -- Sky Witch's Halter (shirt)
  ROW(420043, 420614, 10),  -- Sky Witch's Camisole (chest)
  ROW(420043, 420594, 11),  -- Sky Witch's Buckle (waist)
  ROW(420043, 420608, 12),  -- Sky Witch's Shorts (legs)
  ROW(420043, 420611, 13),  -- Sky Witch's Pants (legs)
  ROW(420043, 420617, 14),  -- Sky Witch's Pleated skirt (legs)
  ROW(420042, 420582, 8),   -- Love Witch's Mantle (shoulders)
  ROW(420042, 420584, 9),   -- Love Witch's Halter (shirt)
  ROW(420042, 420613, 10),  -- Love Witch's Camisole (chest)
  ROW(420042, 420583, 11),  -- Love Witch's Buckle (waist)
  ROW(420042, 420607, 12),  -- Love Witch's Shorts (legs)
  ROW(420042, 420610, 13),  -- Love Witch's Pants (legs)
  ROW(420042, 420616, 14)   -- Love Witch's Pleated Skirt (legs)
) `p` (`cache_item`, `member_item`, `idx`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `idx` = `p`.`idx`, `count` = 1;

-- 2) The three Arsenals held only their bow. They now hold the bow, the Arrow Incarnation, the sword, the staff and the
--    wand of their set.
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
SELECT `p`.`cache_item`, `p`.`member_item`, `p`.`idx`, 1
FROM (VALUES
  ROW(198333, 191427, 1),  -- Twilight Witch's Gothic Arsenal: Incarnation: Twilight Witch's Gothic Arrow
  ROW(198333, 110160, 2),  -- Twilight Witch's Gothic Sword
  ROW(198333, 113680, 3),  -- Twilight Witch's Gothic Staff
  ROW(198333, 114130, 4),  -- Twilight Witch's Gothic Wand
  ROW(198332, 191426, 1),  -- Sky Witch's Airy Arsenal: Incarnation: Sky Witch's Airy Arrow
  ROW(198332, 111717, 2),  -- Sky Witch's Airy Sword
  ROW(198332, 113678, 3),  -- Sky Witch's Airy Staff
  ROW(198332, 114118, 4),  -- Sky Witch's Airy Wand
  ROW(198331, 191425, 1),  -- Love Witch's Lovely Arsenal: Incarnation: Love Witch's Lovely Arrow
  ROW(198331, 110159, 2),  -- Love Witch's Rosy Sword
  ROW(198331, 113676, 3),  -- Love Witch's Rosy Staff
  ROW(198331, 114114, 4)   -- Love Witch's Rosy Wand
) `p` (`cache_item`, `member_item`, `idx`)
WHERE EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0)
ON DUPLICATE KEY UPDATE `idx` = `p`.`idx`, `count` = 1;

UPDATE `item_template`
SET `description` = REPLACE(`description`, 'contains 1 Bow and 1 Arrow Incarnation.',
                            'contains 1 Bow, 1 Arrow Incarnation, 1 Sword, 1 Staff and 1 Wand.')
WHERE `entry` IN (198331, 198332, 198333)
  AND EXISTS (SELECT 1 FROM `coa_client_vanity_collection` WHERE `BazaarTokenCost` > 0);

-- 3) With five pieces each, the Arsenals cost what rev_20261023_03 gives a cache of 4-7 pieces: 2700 (was 2200).
UPDATE `coa_client_vanity_collection`
SET `BazaarTokenCost` = 2700
WHERE `ItemID` IN (198331, 198332, 198333)  -- Love, Sky and Twilight Witch's Arsenal
  AND `BazaarTokenCost` > 0;
