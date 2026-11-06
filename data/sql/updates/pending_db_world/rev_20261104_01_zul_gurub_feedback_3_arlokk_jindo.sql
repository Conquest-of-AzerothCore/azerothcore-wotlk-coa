-- Zul'Gurub, tester feedback round 3 (Arlokk, Jin'do).
-- Arlokk's Razor Claws bleed comes from her melee and Ravage, not from Claw Storm (boss_arlokk_coa).
DELETE FROM `spell_script_names` WHERE `spell_id` = 2118325 AND `ScriptName` = 'spell_arlokk_coa_razor_claws';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2118325, 'spell_arlokk_coa_razor_claws');

-- Jin'do's totems lose one health per hit (boss_jindo_coa).
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_jindo_coa_totem' WHERE `entry` IN (14987, 15112);

-- The Blood Pit is empty before the fight: Animate Bones summons the Sacrificed Trolls at these spots.
DELETE FROM `creature_formations` WHERE `memberGUID` BETWEEN 49078 AND 49087 OR `leaderGUID` BETWEEN 49078 AND 49087;
DELETE FROM `creature_addon` WHERE `guid` BETWEEN 49078 AND 49087;
DELETE FROM `creature` WHERE `guid` BETWEEN 49078 AND 49087 AND `id` = 14826;

-- The risen trolls strike with Fierce Blow, as on live.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 14826 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
`event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
`event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
`action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
`target_y`, `target_z`, `target_o`, `comment`) VALUES
(14826, 0, 0, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
'Sacrificed Troll - On Just Died - Despawn In 5000 ms'),
(14826, 0, 1, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 70, 0, 0, 0, 0, 0, 0, 9, 14826, 0, 100, 2, 0, 0, 0, 0,
'Sacrificed Troll - On Respawn - Respawn Closest Creature \'Sacrificed Troll\''),
(14826, 0, 2, 0, 0, 0, 100, 0, 6700, 17300, 6000, 10000, 0, 0, 11, 975011, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
'Sacrificed Troll - In Combat - Cast Fierce Blow');
