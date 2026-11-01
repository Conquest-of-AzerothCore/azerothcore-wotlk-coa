-- Zul'Gurub creature corrections from the CoA client creature cache: elite rank, ManaModifier and
-- the Sacrificed Troll display. The Zul'Gurub Trigger (14758) stays normal.
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` IN (11360, 11368, 11387, 11388, 11389, 11390, 11391, 14826);

UPDATE `creature_template` SET `ManaModifier` = 1.35 WHERE `entry` IN (11339, 11340, 11830, 11831, 14825);
UPDATE `creature_template` SET `ManaModifier` = 0.3375 WHERE `entry` = 11388;
UPDATE `creature_template` SET `ManaModifier` = 0.65 WHERE `entry` IN (14883, 15111);

UPDATE `creature_template_model` SET `CreatureDisplayID` = 27651 WHERE `CreatureID` = 14826 AND `Idx` = 0;

-- Spawn 51391 in the formation led by 51388 is a Hakkari Shadowcaster live, not a Soulflayer.
UPDATE `creature` SET `id` = 11338, `equipment_id` = 1 WHERE `guid` = 51391;
