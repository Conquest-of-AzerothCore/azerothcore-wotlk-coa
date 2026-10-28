-- Firemaw, Ebonroc and Flamegor with Ascension's spells; see boss_bwl_drakes_coa.cpp.
-- Undo: SET `ScriptName` back to boss_firemaw, boss_ebonroc, boss_flamegor.

UPDATE `creature_template` SET `ScriptName` = 'boss_firemaw_coa'  WHERE `entry` = 11983;
UPDATE `creature_template` SET `ScriptName` = 'boss_ebonroc_coa'  WHERE `entry` = 14601;
UPDATE `creature_template` SET `ScriptName` = 'boss_flamegor_coa' WHERE `entry` = 11981;
