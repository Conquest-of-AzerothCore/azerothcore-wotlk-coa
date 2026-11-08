-- Worldforged pickups reviewed in the world editor (batch 5): positions checked against the Ascension
-- catalogue, LootCollector and the reports; misplaced duplicate spawns hidden instead of deleted.

-- #6735 #7864
-- copies of other zones' pickups imported to Dun Morogh: 6940023 (Old Crossbow), 6941286 (Ulag's Other Cleaver), 6941330 (Floating Barrel), 6941331 (Floating Barrel), 6940804 (Forsaken Cart Crate) hidden, not deleted
UPDATE `gameobject` SET `spawnMask` = 0 WHERE `guid` IN (6940023, 6941286, 6941330, 6941331, 6940804) AND `id` IN (95803, 515405, 517351, 517352);
