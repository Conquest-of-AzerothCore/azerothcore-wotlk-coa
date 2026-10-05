-- Goggles of Impending Millhouse (991519), item 427920.
-- Aura 233 is client-side and requests creature entry 320977 for its appearance.
-- Reconstruct the missing cosmetic selector with Millhouse display 19942, used by
-- supplied templates 20977, 21602 and 179538 and present in CreatureDisplayInfo.dbc.
-- No spawn, AI, spell binding or client-file modification is required.
-- INSERT IGNORE is intentional: preserve any upstream/existing template and model.

INSERT IGNORE INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `type`, `unit_class`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (320977, 'Millhouse Manastorm', 1, 1, 35, 7, 1, '', '', 0);

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 320977, 0, 19942, 1, 1, 0
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 320977);
