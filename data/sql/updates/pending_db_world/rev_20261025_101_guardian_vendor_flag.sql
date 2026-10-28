UPDATE `creature_template`
SET `npcflag` = `npcflag` | 128
WHERE `entry` = 9780012 AND `ScriptName` = 'npc_worldforged_guardian';
