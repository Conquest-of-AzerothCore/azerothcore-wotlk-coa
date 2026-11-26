-- Maiev's Ring Glaives (Backsheath) (198440) describes containing both a main-hand and an offhand
-- version, but its VanityCollection row only lists the main-hand Maiev's Ring Glaive (Backsheath)
-- (5532425). Add the matching offhand Maiev's Ring Glaive (Offhand Backsheath) (198441) so opening
-- the cache grants both weapons.
DELETE FROM `ethereal_bazaar_set_cache` WHERE `cache_item` = 198440 AND `member_item` = 198441;
INSERT INTO `ethereal_bazaar_set_cache` (`cache_item`, `member_item`, `idx`, `count`) VALUES
(198440, 198441, 1, 1);
