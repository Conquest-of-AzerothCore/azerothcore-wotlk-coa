-- Apex Huntmasters: complete Great Lynx sets.
-- The canonical nine pieces from ItemSet.dbc are:
--   Cloak, Eviscerators, Faulds, Hide (chest), Leggings, Mask, Maw, Treads, Wristwraps.
-- The previous row used Vest as the chest, which is an alternate look, not the set piece.

START TRANSACTION;

DELETE FROM `creature_display_preset` WHERE `entry` IN (9916111, 9916112);
INSERT INTO `creature_display_preset`
(`entry`,`display_id`,`race`,`gender`,`class`,`skin`,`face`,`hair`,`haircolor`,`facialhair`,`guild_id`,
 `item_head`,`item_shoulders`,`item_body`,`item_chest`,`item_waist`,`item_legs`,`item_feet`,`item_wrists`,`item_hands`,`item_back`,`item_tabard`)
VALUES
-- Moonlit: Mask, Maw, Hide, Faulds, Leggings, Treads, Wristwraps, Eviscerators, Cloak
(9916111,53,   3,0,3,1,2,3,5,4,0, 140207,140213,0,140225,140231,140243,140201,140255,140249,140195,0),
-- Emberlit: Mask, Maw, Hide, Faulds, Leggings, Treads, Wristwraps, Eviscerators, Cloak
(9916112,1478, 8,0,3,1,2,3,0,0,0, 140205,140211,0,140223,140229,140241,140199,140253,140247,140193,0);

COMMIT;
