-- Kerebor Guards (164271) defend the Blackrock's Kerebor Fort in the Pale Reach; they used dwarf display 1598 instead of an orc (#10449).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 6029 WHERE `CreatureID` = 164271 AND `Idx` = 0 AND `CreatureDisplayID` = 1598;
