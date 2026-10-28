-- Blackfathom Deeps Heroic/Mythic boss fixes after ingame check (30.09.2026)

-- Torrent (Ghamoo-ra): the boss spins around itself while the water cone fires (CoADungeonBossSpells.cpp)
DELETE FROM `spell_script_names` WHERE `spell_id` = 2102687;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2102687, 'spell_coa_torrent_spin');

-- Lorgus Jett: Ascension position placed ingame on Mythic (9780127), Heroic copy (9780128); vanilla spawn stays Normal
DELETE FROM `creature` WHERE `guid` IN (9780127, 9780128);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`,
  `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
  `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9780127, 12902, 48, 0, 0, 4, 1, 1, -741.403, -105.815, -30.0953, 3.13432, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Lorgus Jett - Mythic'),
(9780128, 12902, 48, 0, 0, 2, 1, 1, -741.403, -105.815, -30.0953, 3.13432, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', 0, 0, 'Lorgus Jett - Heroic');
UPDATE `creature` SET `spawnMask` = 1 WHERE `guid` = 26173 AND `id` = 12902;
