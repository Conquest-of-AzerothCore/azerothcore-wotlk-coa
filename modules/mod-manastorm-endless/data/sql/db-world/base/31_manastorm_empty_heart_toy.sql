-- Empty Heart Container (991514), item 53834: user-selected cosmetic behavior.
-- The DBC summons one creature 900027 for 30 seconds; retain that native lifetime.
-- Reuse the healing heart's invisible anchor display plus visual spell 991511,
-- but give the toy a separate script which only despawns on player proximity.
-- extra_flags 128 marks a cosmetic trigger, excluding it from normal stage
-- creature scaling, affixes, XP and loot. Healing entry 900025 is unchanged.
-- INSERT IGNORE preserves existing upstream records; bind only an empty script.

INSERT IGNORE INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `type`, `unit_class`,
 `unit_flags`, `flags_extra`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (900027, 'Empty Heart Container', 1, 1, 35, 10, 1,
33555206, 128, '', 'npc_manastorm_empty_heart', 0);

UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_manastorm_empty_heart',
`flags_extra` = `flags_extra` | 128
WHERE `entry` = 900027 AND `ScriptName` = '';

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 900027, 0, 11686, 1, 1, 0
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 900027);
