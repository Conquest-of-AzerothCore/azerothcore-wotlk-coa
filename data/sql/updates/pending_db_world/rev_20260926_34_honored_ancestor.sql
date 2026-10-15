-- #168: Ancestor's Call 804834 (taught by the Ancestry talent 804729) is SPELL_EFFECT_SUMMON_PET with MiscValue 51265,
-- the Honored Ancestor the Barbarian scripts look for (AscensionBarbarian::Ancestor). No world SQL ever defined that
-- entry, so Player::SummonPet logged "No such creature entry 51265" and every cast summoned nothing.
-- The CoA database mirror (hertigservices/ascension-data, supplemental/exiles-db npc 51265) records it as
-- 'Honored Ancestor', type Beast (1), display 173031. Client CreatureDisplayInfo 173031 is Creature\Troll\TrollMelee
-- with skin TrollSkinJungleForestMelee at model scale 1.55; display 17303 is the same model and skin at scale 1.0
-- with bounding radius 0.522 and combat reach 1.5, and the stock rows for that model scale linearly (298, 592),
-- so 173031 gets 0.8091 and 2.325. Levels are pinned to 1/1: Pet::InitStatsForLevel takes the owner's level.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`) VALUES
(51265, 'Honored Ancestor', 1, 1, 0, 35, 1, 1, 2000, 2000)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 173031;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(173031, 0.8091, 2.325, 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 51265;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(51265, 0, 173031, 1, 1);
