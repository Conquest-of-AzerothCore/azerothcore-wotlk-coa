-- Basalthane's spawn (Onyxia's Lair) silently stopped spawning: rev_20260924_01
-- put him on guid 9000021, and rev_20260925_30 (upstream's restored Bazaar/
-- Weaver placements) reuses that same guid for the Destiny Weaver Veylae
-- (entry 449343, map 0, Undercity). Applied after Basalthane's file, it
-- overwrote his row outright -- confirmed live 2026-09-25, guid 9000021 now
-- points at Veylae.
--
-- 9000021 belongs to upstream's Tiraxis/Destiny Weaver guid block
-- (9000001-9000034 as of this fix) and will keep reclaiming it on every
-- reapply, so Basalthane moves to a new guid well outside that range
-- instead of contesting it back.

DELETE FROM `creature` WHERE `guid` = 9650000;
INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `currentwaypoint`,
     `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`,
     `dynamicflags`, `ScriptName`, `CreateObject`, `Comment`)
VALUES
    (9650000, 10185, 249, 2159, 2159, 15, 1,
     -222.149, -18.1718, -77.1028, 0.850519,
     604800, 35, 0,
     0, 0, 1, 0, 0,
     0, '', 0, 'Basalthane');
