-- Millhouse's Mystical Transportation Device (item 233223, spell 991527).
-- Reconstruct its missing summon target 179536 using the existing Millhouse
-- display 19942 supplied for creatures 20977, 21602 and 179538.
-- Friendly, stationary and passive; no dungeon combat AI or vendor/gossip flags.
-- The native spell owns the five-minute summon lifetime and cleanup.
-- Portal selection/interactions are not implemented by this reconstruction.
-- INSERT IGNORE preserves existing upstream templates and model choices.

INSERT IGNORE INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `type`,
 `unit_class`, `unit_flags`, `flags_extra`, `MovementType`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (179536, 'Millhouse Manastorm', 80, 80, 35, 0, 7,
1, 770, 2, 0, 'PassiveAI', '', 0);

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 179536, 0, 19942, 1, 1, 0
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 179536);
