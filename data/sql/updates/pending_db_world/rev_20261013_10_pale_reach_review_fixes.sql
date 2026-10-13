-- Pale Reach fixes from the playtest review of PR #7047, one block per todo item (see the PR discussion).

-- #3: the Fel Cauldron Worldforged pickup (level 51) belongs to Felwood; the realm had no Worldforged pickups in Pale Reach.
DELETE FROM `gameobject` WHERE `guid` = 9920684 AND `id` = 517233;
