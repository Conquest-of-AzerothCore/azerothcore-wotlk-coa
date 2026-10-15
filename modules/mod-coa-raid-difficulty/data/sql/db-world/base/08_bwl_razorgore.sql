-- Razorgore the Untamed with Ascension's spells. The stock choreography stays;
-- see boss_razorgore_coa.cpp for the kit and the timings.
-- Undo: SET `ScriptName` = 'boss_razorgore'.

UPDATE `creature_template` SET `ScriptName` = 'boss_razorgore_coa' WHERE `entry` = 12435;
