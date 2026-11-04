-- Zul'Gurub, tester feedback round 3 (Hakkar).
-- A Son of Hakkar leaves its Pool of Poisoned Blood only where it dies (boss_hakkar_coa), not during combat.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11357 AND `source_type` = 0 AND `id` = 3;

-- Standing in several Pools of Corrupted Blood hurts only as much as standing in one.
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 2118606;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(2118606, 536870912);

-- The Heart of Hakkar's display 28887 names a model path the client cannot load; 428001 is the same heart
-- with a valid path. Live shows it at scale 2 inside Hakkar's chest: a combat reach of 13 lets melee at his
-- feet hit it 8 yards up while a hunter's minimum range still ends about 21 yards away.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 92005;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(92005, 0, 428001, 2, 1, 0);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 428001;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(428001, 0.5, 6.5, 2, 0);

-- Normal Hakkar drops no Cache of the Blood God (tester 2026-11-04, user decision); the higher tiers keep theirs.
DELETE FROM `creature_loot_template` WHERE `Entry` = 14834 AND `Item` = 1400023;
