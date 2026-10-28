-- Basalthane holds a weapon: item 218129 "Infernos, the Ignited" (2H weapon,
-- displayid 141303) in mainhand, all 4 difficulties.
--
-- creature_equip_template alone isn't enough: Creature::LoadEquipment()
-- reads the SPAWN row's `equipment_id` and treats 0 as "no equipment for
-- creature table" unconditionally, ignoring any creature_equip_template rows
-- that exist -- confirmed in Creature.cpp's LoadCreatureAddon path. The
-- spawn (guid 9650000) needs equipment_id = 1 to actually pick up ID=1 below.

DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (10189, 10190, 10191, 10192);
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`) VALUES
    (10189, 1, 218129, 0, 0),
    (10190, 1, 218129, 0, 0),
    (10191, 1, 218129, 0, 0),
    (10192, 1, 218129, 0, 0);

UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9650000;
