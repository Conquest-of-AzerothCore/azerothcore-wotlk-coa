-- Crash Site minefield, Dun Morogh (area 10201), quest 1660006 "Smoke on the Wind".
-- Entry 2300506 "Proximity Bomb" (gameobject_template from rev_20260925_10): type 6 trap, spell 256480
-- Explosive Trap (20-23 damage plus knockback), activation diameter 2 (1 yard radius), despawns after
-- cast, 30 s cooldown, display 300360. The original field puts bombs on the crater floor between the
-- four objectives so a precise player can walk the direct line between them without triggering one.
-- 7914005 is the single preserved sighting (SOURCED-ATLAS, rev_20260925_10) between the plating and
-- the crate. The six rows below are INFERRED from the CoA footage at 23:37 (#8727), where further
-- bombs stand along the routes between the objectives. Each sits 1.4-1.8 yards off the straight line
-- between its two bracketing objectives, just outside the 1-yard activation radius.
-- Every z is the client ADT ground under that XY (Azeroth_30_43.adt, patch-WB1.MPQ; MCVT heights plus
-- the MCNK base), not the server .map surface, which reads 6-9 yards above the crater floor and is not
-- the collision surface here. The ADT reproduces the client-derived objective heights (crate 380.243 vs
-- 380.246, crewman 377.971 vs 377.819), so it is the ground the player walks on. The trap searches a
-- 1-yard sphere, so a bomb placed high or low does not reach the player at all: the six bombs below were
-- +2.01, +1.38, +0.44, -0.09, -1.01 and -0.13 off that ground before this snap, and 7914005 sat +0.50
-- high as well, which is why the floating ones never fired.
-- Each bomb also moved to the nearest ground under a 0.29 slope within 1.75 yards of its first spot:
-- two sat on 0.66 and 0.85 slopes (33-40 degrees) and visibly hovered on the downhill edge of the model.
-- The final positions below are the world-editor review (#8727): it refined six of them and added two more
-- (9999495, 9999496) on the eastern crater floor. Every editor value is kept verbatim; the ADT ground is
-- only the reference the review started from. Respawn is 180 s; the template cooldown (30 s) only matters
-- for a trap that survives its cast, and type 1 despawns.
DELETE FROM `gameobject` WHERE `guid` IN (7914100, 7914101, 7914102, 7914103, 7914104, 7914105, 9999495, 9999496);
-- The preserved sighting sat 0.50 above the same ground; the world-editor review seated it and set the spawn.
UPDATE `gameobject` SET `position_x` = -6207.2263, `position_y` = 739.6190, `position_z` = 381.0538, `orientation` = 0, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0, `rotation3` = 1, `spawntimesecs` = 180, `Comment` = 'CoA Radiance: SOURCED-ATLAS sighting on the goblin Crash Site (area 10201) crater floor between the plating and the crate, refined in the world editor (#8727)' WHERE `guid` = 7914005;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`)
VALUES
(7914100, 2300506, 0, 0, 0, 1, 1, -6210.2634, 727.6530, 383.1158, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb between the plating (7914001) and the crate (7914002), west of the direct line; position from the world-editor review (#8727)'),
(7914101, 2300506, 0, 0, 0, 1, 1, -6202.7126, 728.5807, 380.9706, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb between the plating (7914001) and the crate (7914002), east of the direct line; position from the world-editor review (#8727)'),
(7914102, 2300506, 0, 0, 0, 1, 1, -6191.40, 739.91, 379.02, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: INFERRED from the CoA footage at 23:37 (#8727) - Proximity Bomb between the crate (7914002) and the crystal shards (7914003), north of the direct line, on the client ADT ground'),
(7914103, 2300506, 0, 0, 0, 1, 1, -6181.2018, 739.5264, 378.7027, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb between the crate (7914002) and the crystal shards (7914003), south of the direct line; position from the world-editor review (#8727)'),
(7914104, 2300506, 0, 0, 0, 1, 1, -6171.1961, 749.4806, 377.8151, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb between the crystal shards (7914003) and the banner (7914004), north of the direct line; position from the world-editor review (#8727)'),
(7914105, 2300506, 0, 0, 0, 1, 1, -6166.5561, 749.0554, 377.9375, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb between the crystal shards (7914003) and the banner (7914004), south of the direct line; position from the world-editor review (#8727)'),
(9999495, 2300506, 0, 0, 0, 1, 1, -6180.3807, 730.6415, 380.1941, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb south of the crate-to-crystal route; added by the world-editor review (#8727)'),
(9999496, 2300506, 0, 0, 0, 1, 1, -6189.8690, 728.7113, 380.4303, 0, 0, 0, 0, 1, 180, 100, 1, '', 'CoA Radiance: Proximity Bomb south of the crate-to-crystal route; added by the world-editor review (#8727)');
