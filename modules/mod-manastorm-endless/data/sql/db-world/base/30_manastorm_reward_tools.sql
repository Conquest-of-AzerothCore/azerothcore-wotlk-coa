-- Scoped random-effect handlers: do not implement effect 184 globally or cast
-- the stock shaman talents 51524/51525 used as Ascension pool identifiers.
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (991542, 991584)
AND `ScriptName` = 'spell_manastorm_reward_random';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(991542, 'spell_manastorm_reward_random'),
(991584, 'spell_manastorm_reward_random');

-- Duplicator 900938 is a self-transform, not a summoned clone. Reconstruct its
-- missing cosmetic selector with the supplied Millhouse display 19942.
-- INSERT IGNORE preserves existing/upstream templates and model choices.
INSERT IGNORE INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `type`, `unit_class`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (254140, 'Millhouse Manastorm', 1, 1, 35, 7, 1, '', '', 0);

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 254140, 0, 19942, 1, 1, 0
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 254140);

-- Reconstruct the missing interactive pylon. The original display is not in the
-- supplied world data; 231 is an existing client GnomeMachine model, used here
-- as a reconstruction. The native summon owns its five-minute lifetime.
-- Native goober data10 casts 991584 on the player who interacts with it.
-- Preserve any existing upstream object instead of replacing its appearance.
INSERT IGNORE INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `size`, `data10`, `VerifiedBuild`)
VALUES (210798, 10, 231, 'Recalibrator Pylon', 1, 991584, 0);
