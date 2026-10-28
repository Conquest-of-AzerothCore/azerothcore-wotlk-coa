-- Basalthane's pillars: restore what live actually showed.
--
-- Every live source (client WDB captures, Exiles, SUB) gives the pillar creatures
-- 10186/10187/10188 display 200003, Ascension's shared invisible trigger display
-- (ClockworkGiantHeart_NoAnim). The creature was only a marker; the visible pillar
-- was a pair of "Fire Pillar" gameobjects standing on it (SUB gameobject dump,
-- 2026-10-04), all type 5, displays already in the shipped GameObjectDisplayInfo.dbc:
--   348503 763459  8fx_wrathion_yellspike_pillar.m2  (yellow)
--   348504 763458  8fx_wrathion_oranspike_pillar.m2  (orange)
--   348505 1063458 8fx_wrathion_firespike_pillar.m2  (fire)
--   348506-348508 763460 bzb_onyxia_spike_pillar_collision.m2 (collision)
-- The spike visuals animate by GO state: ACTIVE (0) = Open/Opened, spike up;
-- READY (1) = Close then Closed, the shattered plate. spell_basalthane.cpp flips
-- them when a pillar shatters and back on wipe/evade. All six are scaled to 2.12
-- (size matched by eye in game; the collision keeps the spike's scale).
--
-- SUB has no gameobject spawns, so each pair is placed on its pillar creature, and
-- the creatures are moved to the in-room spots confirmed in game first, so marker
-- and gameobjects always share a position.
-- Colour per pillar is not recorded anywhere; Volatile = orange, Crumbling =
-- yellow, Searing = fire, placed by eye in game - not a capture.
--
-- rev_20260926_01 dropped CREATURE_FLAG_EXTRA_TRIGGER when the creature itself was
-- the visible pillar. Now that the gameobjects are, the markers go back to being
-- triggers: invisible to players, shown only in GM mode, as on live.

UPDATE `creature` SET `position_x` = -251.87961, `position_y` = -36.663902, `position_z` = -77.93691 WHERE `guid` = 9650001; -- Volatile Pillar
UPDATE `creature` SET `position_x` = -238.38716, `position_y` =  22.310553, `position_z` = -78.10099 WHERE `guid` = 9650002; -- Crumbling Pillar
UPDATE `creature` SET `position_x` = -204.22008, `position_y` = -50.77867,  `position_z` = -76.75303 WHERE `guid` = 9650003; -- Searing Pillar

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(348503, 5, 763459, 'Fire Pillar', '', '', '', 2.12, '', '', 0),
(348504, 5, 763458, 'Fire Pillar', '', '', '', 2.12, '', '', 0),
(348505, 5, 1063458, 'Fire Pillar', '', '', '', 2.12, '', '', 0),
(348506, 5, 763460, 'Fire Pillar', '', '', '', 2.12, '', '', 0),
(348507, 5, 763460, 'Fire Pillar', '', '', '', 2.12, '', '', 0),
(348508, 5, 763460, 'Fire Pillar', '', '', '', 2.12, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);

DELETE FROM `gameobject` WHERE `guid` IN (9650101, 9650102, 9650103, 9650104, 9650105, 9650106);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9650101, 348504, 249, 2159, 2159, 15, 1, -251.87961, -36.663902, -77.93691, 0, 0, 0, 0, 1, 0, 100, 0, '', 0, 'Basalthane - Volatile Pillar spike'),
(9650102, 348503, 249, 2159, 2159, 15, 1, -238.38716,  22.310553, -78.10099, 0, 0, 0, 0, 1, 0, 100, 0, '', 0, 'Basalthane - Crumbling Pillar spike'),
(9650103, 348505, 249, 2159, 2159, 15, 1, -204.22008, -50.77867,  -76.75303, 0, 0, 0, 0, 1, 0, 100, 0, '', 0, 'Basalthane - Searing Pillar spike'),
(9650104, 348506, 249, 2159, 2159, 15, 1, -251.87961, -36.663902, -77.93691, 0, 0, 0, 0, 1, 0, 100, 1, '', 0, 'Basalthane - Volatile Pillar collision'),
(9650105, 348507, 249, 2159, 2159, 15, 1, -238.38716,  22.310553, -78.10099, 0, 0, 0, 0, 1, 0, 100, 1, '', 0, 'Basalthane - Crumbling Pillar collision'),
(9650106, 348508, 249, 2159, 2159, 15, 1, -204.22008, -50.77867,  -76.75303, 0, 0, 0, 0, 1, 0, 100, 1, '', 0, 'Basalthane - Searing Pillar collision');

UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 0x00000080 WHERE `entry` IN (10186, 10187, 10188);
