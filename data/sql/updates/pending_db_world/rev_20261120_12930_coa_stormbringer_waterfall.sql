-- #12930 Waterfall 806412: "Dealing critical damage now reduces all of your cooldowns by 0.5 sec."
-- Its trigger 807661 named only three spells, so spell_ascension_stormbringer_waterfall applies the 0.5 sec to
-- every Stormbringer spell on cooldown. The proc row only took direct magic-class damage; add melee-class,
-- ranged-class, no-class and periodic damage so any critical damage counts.
DELETE FROM `spell_script_names` WHERE `spell_id` = 807661 AND `ScriptName` = 'spell_ascension_stormbringer_waterfall';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (807661, 'spell_ascension_stormbringer_waterfall');
UPDATE `spell_proc` SET `ProcFlags` = 332048 WHERE `SpellId` = 806412;
