-- Dire Maul West (#6851), checked against Ascension combat logs.

-- Arcane Aberration: on death it leaves Arcane Residues (2100265), a 10 s zone that restores health and mana
-- (69 deaths in the logs, never a Mana Burn).
UPDATE `smart_scripts` SET `event_flags` = `event_flags` | 16 WHERE `entryorguid` = 11480 AND `source_type` = 0 AND `id` = 1;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11480 AND `source_type` = 0 AND `id` = 9000;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11480, 0, 9000, 0, 6, 0, 100, 512, 0, 0, 0, 0, 0, 0, 11, 2100265, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arcane Aberration - On Death - Cast ''Arcane Residues''');

-- Tendris Warpwood: Entangle (pulls the target in front of him, facing away), Grasping Vines and Trample
-- never come in the logs (7 pulls); Mass Entanglement, Entangling Roots and Uppercut stay.
UPDATE `smart_scripts` SET `event_flags` = `event_flags` | 16 WHERE `entryorguid` = 11489 AND `source_type` = 0 AND `id` IN (9004, 9005, 9006);

-- Immol'thar: Ascension has no ring of Highborne Summoners, nobody fights him when the shield drops.
DELETE FROM `creature` WHERE `guid` BETWEEN 247831 AND 247848 AND `id` = 11466;
-- Eyes only from Summon Eye of Immol'thar (2 eyes), every 22 s; Eye of Immol'thar (one eye that lives 4 min),
-- Trample, Infected Bite and Portal never come in the logs.
UPDATE `smart_scripts` SET `event_param1` = 22000, `event_param2` = 22000, `event_param3` = 22000, `event_param4` = 22000
WHERE `entryorguid` = 11496 AND `source_type` = 0 AND `id` = 9002;
UPDATE `smart_scripts` SET `event_flags` = `event_flags` | 16 WHERE `entryorguid` = 11496 AND `source_type` = 0 AND `id` IN (9003, 9005, 9006, 9007);

-- Prince Tortheldrin: his Heroic melee was above his Mythic one (25.37 vs 17.83): Heroic = Mythic / 1.3.
UPDATE `smart_scripts` SET `event_flags` = 0 WHERE `entryorguid` = 11486 AND `source_type` = 0 AND `id` IN (9004, 9005, 9006);
UPDATE `creature_template` SET `DamageModifier` = 13.72 WHERE `entry` = 111486;

-- Eye of Immol'thar: on Ascension it takes 75 % more damage (888150, on it for its whole life) and casts its own
-- Eye of Immol'thar (2100245: damage over time and -20 % haste) right after it appears, not 22909. It goes for a
-- random player in range, not the nearest one.
UPDATE `smart_scripts` SET `target_type` = 17, `target_param1` = 0, `target_param2` = 60, `target_param3` = 0,
`comment` = 'Eye of Immol''thar - Out of Combat - Attack Random Player'
WHERE `entryorguid` = 14396 AND `source_type` = 0 AND `id` = 0;
DELETE FROM `creature_template_addon` WHERE `entry` = 14396;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(14396, 0, 0, 0, 0, 0, 0, '888150');
UPDATE `smart_scripts` SET `event_param1` = 0, `event_param2` = 500, `event_param3` = 10000, `event_param4` = 12000,
`action_param1` = 2100245, `target_type` = 5, `target_param1` = 0, `target_param2` = 1, `comment` = 'Eye of Immol''thar - In Combat - Cast Eye of Immol''thar (2100245)'
WHERE `entryorguid` = 14396 AND `source_type` = 0 AND `id` = 1;

-- Dire Maul Crystal Totem (first crystal) could be attacked; on Ascension it could not, like the other crystals.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 0x2 | 0x100 | 0x200 WHERE `entry` = 13916;
