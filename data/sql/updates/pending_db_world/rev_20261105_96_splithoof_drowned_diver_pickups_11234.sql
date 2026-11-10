-- Drowned Diver's set at Splithoof Crag (Thousand Needles): Ascension client caches put the signet, helm and blade
-- together in the cave under the crag. Their cached z (about -80) is a sealed hollow below our client's cave floor, and
-- the floor straight above it is broken rock, so they stand on the flat cave floor 3 yd south-west (z -64.55).
-- Our LootCollector-derived spawns used the crag top height and sat on the cliff slope (the ring halfway down the drop).
-- Move one pickup of each item there and drop the second helm and blade copies.
UPDATE `gameobject` SET `position_x` = -4953.40, `position_y` = -2295.70, `position_z` = -64.55 WHERE `guid` = 6970038 AND `id` = 9900035;
UPDATE `gameobject` SET `position_x` = -4954.30, `position_y` = -2296.40, `position_z` = -64.55 WHERE `guid` = 6970042 AND `id` = 9900038;
UPDATE `gameobject` SET `position_x` = -4953.30, `position_y` = -2297.00, `position_z` = -64.55 WHERE `guid` = 6970037 AND `id` = 9900034;
DELETE FROM `gameobject` WHERE `guid` IN (6970036, 6970041) AND `id` IN (9900034, 9900038);
