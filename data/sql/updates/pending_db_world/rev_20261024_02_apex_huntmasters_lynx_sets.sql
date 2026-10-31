-- Apex Huntmasters: correct name/subtitle and the Great Lynx sets.
--
-- The first look test used display ids from the stale base item_template dump, which is why
-- only some slots rendered. These ids come from the live world DB (item_template.displayid).
--
-- Alliance: Halda Bronzebraid, dwarf male, Moonlit Mane of the Great Lynx (9-slot appearance).
-- Horde:    Zul'khar, troll male, Emberlit Mane of the Great Lynx.
-- "Huntmaster" is the subtitle, not part of the name.

START TRANSACTION;

UPDATE `creature_template` SET `name` = 'Halda Bronzebraid', `subname` = 'Huntmaster' WHERE `entry` = 9916111;
UPDATE `creature_template` SET `name` = 'Zul''khar',        `subname` = 'Huntmaster' WHERE `entry` = 9916112;

DELETE FROM `creature_display_preset` WHERE `entry` IN (9916111, 9916112);
INSERT INTO `creature_display_preset`
(`entry`,`display_id`,`race`,`gender`,`class`,`skin`,`face`,`hair`,`haircolor`,`facialhair`,`guild_id`,
 `item_head`,`item_shoulders`,`item_body`,`item_chest`,`item_waist`,`item_legs`,`item_feet`,`item_wrists`,`item_hands`,`item_back`,`item_tabard`)
VALUES
-- Moonlit: mask, maw, vest, faulds, leggings, treads, wristwraps, eviscerators, cloak
(9916111,53,   3,0,3,1,2,3,5,4,0, 140207,140213,0,140261,140231,140243,140201,140255,140249,140195,0),
-- Emberlit: mask, maw, vest, faulds, leggings, treads, wristwraps, eviscerators, cloak
(9916112,1478, 8,0,3,1,2,3,0,0,0, 140205,140211,0,140259,140229,140241,140199,140253,140247,140193,0);

COMMIT;
