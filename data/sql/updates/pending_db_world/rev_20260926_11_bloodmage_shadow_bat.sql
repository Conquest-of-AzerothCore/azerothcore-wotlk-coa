-- Every Call of the Darkwing summon fails because its creature does not exist in this world.
-- Call of the Darkwing 801958 and its sibling 802578 are SPELL_EFFECT_SUMMON (28) with MiscValue 50069 and
-- SummonProperties 61 (Category 1 ally, Type 2 guardian), so Petrified Legions, Screech of the Darkwing, Grim Omen
-- and Monstrous Howl all reach Spell::SummonGuardian, which logs "Creature::Create(): creature template (entry: 50069)
-- does not exist" and summons nothing. No world SQL has ever defined entry 50069.
-- The CoA database mirror (hertigservices/ascension-data, supplemental/exiles-db npc 50069) records it as
-- 'Shadow Bat', type Non-Combat Pet (12), display 80954, casting Bat Bite 802358. The same mirror gives the
-- War Falcons 50264/50393 the display and type their creature-cache fix used. Client CreatureDisplayInfo 80954 is
-- creature\bat_critter\bat_critter.mdx with texture batpetred; this world has no creature_model_info row for it, so
-- one is added with the collision defaults the other Ascension-only displays in this fork carry.
-- Levels are pinned to 1/1 like the War Falcons: Guardian::InitStatsForLevel re-derives the stats from the owner.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`) VALUES
(50069, 'Shadow Bat', 1, 1, 0, 35, 1, 12, 2000, 2000)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`);

DELETE FROM `creature_model_info` WHERE `DisplayID` = 80954;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(80954, 0.611111, 2.03128, 2);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 50069;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(50069, 0, 80954, 1, 1);
