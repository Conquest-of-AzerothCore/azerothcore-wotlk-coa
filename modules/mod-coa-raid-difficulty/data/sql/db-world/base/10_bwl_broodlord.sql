-- Broodlord Lashlayer with Ascension's spells; see boss_broodlord_coa.cpp.
-- Undo: SET `ScriptName` = 'boss_broodlord'.

UPDATE `creature_template` SET `ScriptName` = 'boss_broodlord_coa' WHERE `entry` = 12017;
