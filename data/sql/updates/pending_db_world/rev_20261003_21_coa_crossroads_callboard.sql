-- Issue #6044: the Callboard is missing in front of the Crossroads inn.
--
-- GameObject 402001 'Warchief's Command Board' is the Horde dungeon-daily board and is wired to
-- the full Callboard quest set (rev_20260930_04 / rev_20260930_05). It has exactly one spawn in
-- the whole world - guid 7905401 at (1579.26, -4417.08) in the southern Barrens - so The
-- Crossroads, the Horde's main low-level hub, has no board at all.
--
-- Fix: add a second spawn of the same template in front of the inn, next to the innkeeper
-- (Innkeeper Boorand Plainswind 3934 stands at -407.1, -2645.2). The position and rotation below
-- are the board's tested in-game placement, captured from the live world database.
--
-- Idempotent: delete of the exact guid followed by the insert.

DELETE FROM `gameobject` WHERE `guid` = 7905402;

INSERT INTO `gameobject`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`)
VALUES
(7905402, 402001, 1, 0, 0, 1, 1, -424.212, -2636.64, 95.6861, 0.216519, 0, 0, -0.108048, -0.994146, 0, 0, 1, '', NULL, 'Warchief''s Command Board - The Crossroads, in front of the inn');
