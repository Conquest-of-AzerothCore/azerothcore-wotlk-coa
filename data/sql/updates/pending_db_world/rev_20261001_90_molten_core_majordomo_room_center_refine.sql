-- Refine the Majordomo room-center point (rev_20261001_18's centroid estimate) with the exact
-- spot the user stood on and read off `.gps` in game (floor Z -120.0913, orientation 5.7636776,
-- map 409). Moves the Ragnaros portal GO (guid 9000601, go_ragnaros_portal_coa) to this same
-- point, matching the chain spawn (MajordomoSummonPos, boss_majordomo_executus.cpp). Also fixes
-- the portal's oversized scale: the reused "Molten Core Instance Portal" template (181623) was
-- never spawned anywhere in the base data and carried `size = 5`, five times every comparable
-- portal GO in gameobject_template (Instance Portal/Mage Portal/Caverns of Time Portal all use
-- `size = 1`) - the mismatch is the most likely cause of both the oversized visual and the
-- reported click misses (the model's scaled collision no longer lines up with the GO's logical
-- position). Late-sorting on purpose: must sort after rev_20261001_08's own INSERT and
-- rev_20261001_18's UPDATE.
UPDATE `gameobject_template` SET `size` = 1 WHERE `entry` = 181623;

UPDATE `gameobject` SET `position_x` = 742.1174, `position_y` = -1181.1216, `position_z` = -120.0913
WHERE `guid` = 9000601;
