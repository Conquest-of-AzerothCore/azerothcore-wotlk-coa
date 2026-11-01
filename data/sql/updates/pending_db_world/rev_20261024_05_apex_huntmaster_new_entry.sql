-- Apex Huntmaster: move the Alliance NPC to a fresh creature entry.
-- The client caches creature names by entry in creaturecache.wdb; entry 9916111 was first
-- seen as "Halda Bronzebraid" and keeps resolving to that cached name on some clients.
-- Entry 9916113 has never been seen, so the client must ask the server and gets Torvald.

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `tmp_apex_huntmaster`;
CREATE TEMPORARY TABLE `tmp_apex_huntmaster` AS
    SELECT * FROM `creature_template` WHERE `entry` = 9916111;
UPDATE `tmp_apex_huntmaster`
   SET `entry` = 9916113, `name` = 'Torvald Greyfeather', `subname` = 'Huntmaster';

DELETE FROM `creature_template` WHERE `entry` = 9916113;
INSERT INTO `creature_template` SELECT * FROM `tmp_apex_huntmaster`;
DROP TEMPORARY TABLE `tmp_apex_huntmaster`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9916113;
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
SELECT 9916113, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`
  FROM `creature_template_model` WHERE `CreatureID` = 9916111;

DELETE FROM `creature_display_preset` WHERE `entry` = 9916113;
INSERT INTO `creature_display_preset`
(`entry`,`display_id`,`race`,`gender`,`class`,`skin`,`face`,`hair`,`haircolor`,`facialhair`,`guild_id`,
 `item_head`,`item_shoulders`,`item_body`,`item_chest`,`item_waist`,`item_legs`,`item_feet`,`item_wrists`,`item_hands`,`item_back`,`item_tabard`)
SELECT 9916113, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`,
       `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`,
       `item_wrists`, `item_hands`, `item_back`, `item_tabard`
  FROM `creature_display_preset` WHERE `entry` = 9916111;

UPDATE `creature` SET `id` = 9916113 WHERE `id` = 9916111;

DELETE FROM `creature_template` WHERE `entry` = 9916111;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9916111;
DELETE FROM `creature_display_preset` WHERE `entry` = 9916111;

COMMIT;
