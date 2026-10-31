-- #9990: "Depleted Elemental Lodestone" (415080) and its Worldforged upgrades (1388400, 1378672) cast
-- "Summon Lesser Water Elemental" (304100, and the per-tier copies 313161/317161/321161), whose
-- SPELL_EFFECT_SUMMON names creature 304100. That entry has no creature_template row, so Creature::Create
-- refuses it, Map::SummonCreature returns null and the effect stops before a creature is made: the cast
-- succeeds, its visual plays and nothing appears (#4707 reported the same trinket).
-- The preserved CoA creature cache has the entry: "Lesser Water Elemental", display 5561
-- (CreatureDisplayInfo 5561 -> CreatureModelData 110, Creature\WATERELEMENTAL\WaterElemental.mdx, scale 1),
-- type 1, family 0, health and mana modifiers 1. Everything the cache does not carry comes from the vanilla
-- creature the spell names, 691 "Lesser Water Elemental": level 36-37, faction 91, unit_class 2, 2000 ms
-- attack times. SummonProperties 61 is category ally with type guardian, so the summon takes the caster's
-- faction and follows and fights for the caster.
INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `BaseAttackTime`, `RangeAttackTime`)
VALUES (304100, 'Lesser Water Elemental', 36, 37, 91, 2, 1, 2000, 2000)
ON DUPLICATE KEY UPDATE `entry` = `entry`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 304100;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (304100, 0, 5561, 1, 1);
