-- Package shared tool bindings within the module and align the Treasure Keeper
-- fallback with the supplied working-world export dated 2026-10-08.
-- Apply after SQL 14 and 28. Safe to repeat; unrelated bindings are preserved.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 254440 AND `ScriptName` = 'spell_ascension_manastorm_potion';

DELETE FROM `spell_script_names`
WHERE `spell_id` IN (254440, 93309, 93311)
  AND `ScriptName` = 'spell_manastorm_baseline_tool';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(254440, 'spell_manastorm_baseline_tool'),
(93309, 'spell_manastorm_baseline_tool'),
(93311, 'spell_manastorm_baseline_tool');

-- SQL 14 creates the fallback when absent. This follow-up also aligns databases
-- that previously received its older fallback, without replacing the template.
UPDATE `creature_template`
SET `subname` = NULL, `faction` = 35, `rank` = 0, `type` = 12,
    `movementId` = 0, `flags_extra` = 0, `VerifiedBuild` = NULL
WHERE `entry` = 10111377;
