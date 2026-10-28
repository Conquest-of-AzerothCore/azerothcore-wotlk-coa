-- Swap Basalthane's 3 pillars from the placeholder gameobject (entry 9500100,
-- Mantid Spike model) to the real pillar creatures Ascension uses for this
-- encounter (10186/10187/10188, added in rev_20260925_34).
--
-- The gameobject spawns are REMOVED from the raid (guids 6901536-6901538
-- deleted from `gameobject`), but the template (9500100) is left alone in
-- case it's wanted again later.
--
-- The 3 creature pillars spawn at the exact same coords the gameobjects
-- used. They're set up to read as a static object, not an NPC:
--   unit_flags  = UNIT_FLAG_NON_ATTACKABLE (0x2) | UNIT_FLAG_NOT_SELECTABLE (0x02000000)
--               = 0x02000002 -- can't be damaged, can't be targeted/clicked
--   flags_extra = CREATURE_FLAG_EXTRA_TRIGGER (0x80) -- standard "this is a
--               prop, not a real NPC" marker used elsewhere in this fork
--   faction     = 35 (Friendly) -- never hostile, never auto-aggros
--   npcflag     = 0 -- no gossip/vendor/interaction of any kind
--   MovementType = 0 -- stays put
--
-- FOLLOW-UP NOT DONE HERE: spell_basalthane.cpp's ShatterPillar/RestorePillar
-- still phase-hides/shows gameobject guids 6901536-6901538 for the "pillar
-- shatters" visual. Those guids no longer exist in the world after this
-- migration, so that part of the mechanic is now a no-op until the C++ is
-- reworked to act on the new creature pillars instead (e.g. despawn/respawn
-- or a visual state change on 10186/10187/10188's live spawns).

UPDATE `creature_template` SET
    `unit_flags` = 0x02000002,
    `flags_extra` = `flags_extra` | 0x00000080,
    `faction` = 35,
    `npcflag` = 0,
    `MovementType` = 0
WHERE `entry` IN (10186, 10187, 10188);

DELETE FROM `gameobject` WHERE `guid` IN (6901536, 6901537, 6901538);

DELETE FROM `creature` WHERE `guid` IN (9650001, 9650002, 9650003);
INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`,
     `dynamicflags`, `ScriptName`, `CreateObject`, `Comment`)
VALUES
    (9650001, 10186, 249, 2159, 2159, 15, 1, -209.264, -47.7954, -76.9938, 0,
     120, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 'Basalthane Pillar 1 (Volatile Pillar)'),
    (9650002, 10187, 249, 2159, 2159, 15, 1, -247.185,  14.6485, -78.3442, 0,
     120, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 'Basalthane Pillar 2 (Crumbling Pillar)'),
    (9650003, 10188, 249, 2159, 2159, 15, 1, -190.622,   5.15241, -78.6413, 0,
     120, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 'Basalthane Pillar 3 (Searing Pillar)');
