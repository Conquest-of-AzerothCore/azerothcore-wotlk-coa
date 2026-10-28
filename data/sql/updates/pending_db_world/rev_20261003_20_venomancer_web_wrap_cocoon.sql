-- Web Wrap (504335) effect 1 is SPELL_AURA_TRANSFORM to creature 411372, which the world lacks,
-- so the engine falls back to pig display 16358 and the target turns into a pig.
-- No captured creature record exists for 411372 (ascension-data, client WDB caches, CoA Tavern).
-- The client ships CreatureDisplayInfo 411372 with model 411372 creature\cocoon\cocoon.m2 at scale 1.0,
-- the same id as the transform, matching the tooltip "Wrap your target in a cocoon".
-- The name follows the spell; no spawn is added.
START TRANSACTION;
INSERT INTO `creature_template` (`entry`, `name`, `faction`, `unit_class`, `type`) VALUES
(411372, 'Web Wrap', 35, 1, 10) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 411372;
INSERT INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(411372, 0, 411372, 1, 1);
COMMIT;
