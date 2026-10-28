-- Dar'danis 50276, Deathknell Felsworn trainer: CoA footage shows him in the Felsworn starter kit, not the
-- stand-in Felscale armour of rev_20260923_09. The kit is the class 14 StarterKit of AscensionCustomClassData.h:
-- Vile Tattoos 2000009 (shirt, display 143944), Vile Kilt 2000007 (legs, 143945), Vile Walkers 2000008 (feet,
-- 142933) and the Faded Glaive 629940.
UPDATE `creature_display_preset` SET `item_head` = 0, `item_shoulders` = 0, `item_body` = 143944, `item_chest` = 0,
    `item_waist` = 0, `item_legs` = 143945, `item_feet` = 142933, `item_wrists` = 0, `item_hands` = 0, `item_back` = 0,
    `item_tabard` = 0 WHERE `entry` = 50276;
UPDATE `creature_equip_template` SET `ItemID1` = 629940, `ItemID2` = 0, `ItemID3` = 0 WHERE `CreatureID` = 50276 AND `ID` = 1;
