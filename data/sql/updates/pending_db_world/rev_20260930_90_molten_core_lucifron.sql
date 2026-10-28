-- Lucifron (12118): CoA's spawn coordinates match db.exil.es exactly (guid 56605, 1037.02/-986.342/-181.516),
-- but our `creature` row overrides MovementType to 2 (WAYPOINT) on a path that runs toward Magmadar's room
-- (waypoint_data 566050, point 3 = 1070.41/-1006.77, approaching Magmadar's spawn at 1144.63/-1020.48). His
-- two Flamewaker Protectors (12119, guids 56606/56607) follow him in `creature_formations` (groupAI 514,
-- FOLLOW), so the whole trio wanders off his platform together - matching the reported "Lucifron wanders
-- into Magmadar's room with 2 adds". Lucifron never leaves his corner in the reference fight (script_or_ai
-- 'boss_lucifron' in the export, a stationary boss); the export carries no MovementType column, so this is
-- the vanilla-design/export-position combination, not a measured CoA value. The Protectors' own coordinates
-- (within 4 yards of Lucifron in both our data and the export) confirm they belong at his side, stationary,
-- not that they should be removed.
UPDATE `creature_template` SET `MovementType` = 0 WHERE `entry` IN (12118, 12119);
UPDATE `creature` SET `MovementType` = 0 WHERE `guid` = 56605 AND `id` = 12118;
UPDATE `creature_addon` SET `path_id` = 0 WHERE `guid` = 56605;
DELETE FROM `waypoint_data` WHERE `id` = 566050;
