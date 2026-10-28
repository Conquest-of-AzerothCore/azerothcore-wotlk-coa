-- Classic dungeons: entry from the lowest target level of their wings in LFGDungeons.dbc (TargetLevelMin),
-- matching the Dungeon Finder (LFGMgr), which now opens them from that level too. Ascension let anyone
-- from 15 to 59 queue for any Classic dungeon; before, the Dungeon Finder sent a level 18 player into
-- Scarlet Monastery and the instance then refused them ("You must be level 20").
UPDATE `dungeon_access_template` SET `min_level` = LEAST(`min_level`, 15) WHERE `difficulty` = 0 AND `map_id` IN (34, 43, 47, 70, 90, 129, 189, 209);
UPDATE `dungeon_access_template` SET `min_level` = LEAST(`min_level`, 20) WHERE `difficulty` = 0 AND `map_id` = 349;
UPDATE `dungeon_access_template` SET `min_level` = LEAST(`min_level`, 30) WHERE `difficulty` = 0 AND `map_id` = 230;
