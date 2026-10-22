-- The End Is Near (#2223): Wraithblade's spectral copy of the Reaper is creature 850000, which had no template, so
-- nothing appeared. The live creature cache names it Spectral Reaper (humanoid, health modifier 0.5) on the invisible
-- stalker display; the script clones the Reaper's look onto it, as for Uncanny Likeness 840000, and casts Dirge and
-- Murder on the Reaper's target. SummonProperties 61 replaces faction 35 with the caster's; flags_extra 64 is NO_XP.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`HealthModifier`, `BaseAttackTime`, `RangeAttackTime`, `flags_extra`, `ScriptName`) VALUES
(850000, 'Spectral Reaper', 1, 1, 35, 1, 7, 0.5, 2000, 2000, 64, 'npc_ascension_reaper_spectral_reaper')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `type` = VALUES(`type`), `HealthModifier` = VALUES(`HealthModifier`),
`flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 850000;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(850000, 0, 11686, 1, 1);
