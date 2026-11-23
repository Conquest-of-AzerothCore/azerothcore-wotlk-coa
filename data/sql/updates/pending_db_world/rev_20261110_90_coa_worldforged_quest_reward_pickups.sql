-- Worldforged pickups added in #8904 for items that are not Worldforged (no @Worldforged@ in the CoA client
-- item cache, LootCollector isWF false). Hidden, not deleted.

-- #11744: Defias Turncoat's Jerkin 500815 and Goldshire Traveler's Boots 500814 are choice rewards of
-- "Supply Run" (100073), Scholar's Ring of Enlightenment 500817 of "Minervia's Fate" (254069),
-- Icehide Cloak 500663 of "Icehide the Unbroken" (500006); all four quests already reward them
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6975032, 6975014, 6975000, 6975010) AND `id` IN (1345037, 1345061, 1345121, 1345074);

-- #11810: the Gadgetzan pickup dropped the ilvl 64 rung 1379103 of Apothecary's Lantern; the real
-- Worldforged Lantern 515015 stays in Tirisfal Glades (object 1345003)
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` = 6975030 AND `id` = 1345004;
