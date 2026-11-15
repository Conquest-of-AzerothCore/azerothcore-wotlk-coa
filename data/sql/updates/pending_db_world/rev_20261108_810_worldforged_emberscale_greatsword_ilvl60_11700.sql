-- Emberscale Greatsword 515223 skipped its ilvl 60 variant 1388927 (#11700): ItemAddon.dbc lists it against the base like
-- the other tiers, but the variant is epic, so the dungeon-tier migration (#7934) that only listed blue variants missed it.
-- The chain is base -> ilvl 60 variant (always open, the first rank's cost) -> Zul'Gurub tier (the old recipe).
UPDATE `worldforged_upgrade` SET `base_item` = 1388927 WHERE `base_item` = 515223 AND `target_item` = 1379216;

DELETE FROM `worldforged_upgrade` WHERE `id` = 4388927;
INSERT INTO `worldforged_upgrade` (`id`, `store`, `base_item`, `target_item`, `cost`, `unlock_creature`) VALUES
(4388927, 8, 515223, 1388927, 5000, 0);
