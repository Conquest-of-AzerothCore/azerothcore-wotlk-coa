-- Might Experience Heirloom Cache (#8970): cache 1339056 held the two pieces its own description
-- does not list, Polished Breastplate of Might (1548685) and Polished Spaulders of Might (1542949),
-- neither of which carries the set's +10% experience equip spell. Its full cache (1339070) holds the
-- matching Burnished Breastplate of Might (3148685) and Burnished Spaulders of Might (3142949), as
-- every other Experience/full cache pair in the set already matches (#7977's own decision for this set).
UPDATE `ethereal_bazaar_set_cache` SET `member_item` = 3148685 WHERE `cache_item` = 1339056 AND `member_item` = 1548685;
UPDATE `ethereal_bazaar_set_cache` SET `member_item` = 3142949 WHERE `cache_item` = 1339056 AND `member_item` = 1542949;
