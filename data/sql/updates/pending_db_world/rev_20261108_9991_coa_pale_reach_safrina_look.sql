-- Safrina (164276), the dwarf scribe, drew bare bandaged legs (22261), black heart-plate bracers and fur-flared tan
-- boots. Her quest window in RIEMlZSgbQw 3:00:12-3:01:06 shows plain dark navy trousers, white sleeves with gold
-- flame cuffs and dark brown boots under the Stormwind tabard, the outfit Darvin (164273) wears. The trousers, boots
-- and belt are the nearest pieces found; her face is too small there to be sure of skin and face.
DELETE FROM `creature_display_preset` WHERE `entry` = 164276;
INSERT INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(164276, 54, 3, 1, 1, 2, 4, 0, 2, 0, 0, 0, 0, 10038, 18670, 4407, 71277, 166045, 0, 0, 0, 16657);
