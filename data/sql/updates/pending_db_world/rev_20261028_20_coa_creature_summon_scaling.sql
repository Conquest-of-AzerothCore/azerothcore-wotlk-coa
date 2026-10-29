-- Creatures summoned by creatures now take CoA.CreatureScaling's regular-difficulty health multiplier. Road to De
-- Other Side carried it in the modifiers of its two summons (the Chimeric Embryo and its spiders); take it out again.
UPDATE `creature_template` SET `HealthModifier` = ROUND(`HealthModifier` / 2.5, 3) WHERE `entry` IN (162716, 162743);
