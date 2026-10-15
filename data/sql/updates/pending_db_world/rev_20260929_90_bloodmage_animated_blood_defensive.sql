-- #3998: Animated Blood summons fight for their owner instead of pulling every hostile in sight
UPDATE `creature_template` SET `ScriptName` = 'npc_ascension_animated_blood'
WHERE `entry` IN (315301, 325301, 335301) AND `ScriptName` = '';
