-- #10286: Worldforged Pauldrons of Shadow (item 354460, ilvl 63, reqLevel 58, object 254516 Fallen Traveler's
-- Pauldrons) belongs solely in Deadwind Pass (guid 6940872, matching realm dump 6900243 and CoA sidekick map).
-- Remove the stray Swamp of Sorrows duplicate (guid 6940873) imported from a single-record non-CoA pin.
DELETE FROM `gameobject` WHERE `guid` = 6940873 AND `id` = 254516 AND `map` = 0;
