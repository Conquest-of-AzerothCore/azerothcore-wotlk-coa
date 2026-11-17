-- Dark Ranger General's Kit (210740) held the nine pieces of its client VanityCollection row, one of them an item that
-- does not exist (210743). Its item set 40120 has three more pieces the kit never gave: the Shoulderguard (210750),
-- the Garment (210751) and the Cheststrap (210752). Add them after the nine it has, like rev_20261029_21 did for the
-- witch sets. A reapply leaves the result unchanged.
DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 210740 AND `member_item` IN (210750, 210751, 210752);
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`)
SELECT `p`.`cache_item`, `p`.`member_item`, `p`.`idx`, 1
FROM (VALUES
  ROW(210740, 210750, 9),   -- Dark Ranger General's Shoulderguard
  ROW(210740, 210751, 10),  -- Dark Ranger General's Garment
  ROW(210740, 210752, 11)   -- Dark Ranger General's Cheststrap
) `p` (`cache_item`, `member_item`, `idx`);
