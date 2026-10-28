-- Apex Huntmaster: move the Horde NPC to a fresh creature entry.
-- Entry 9916112 was first seen with subname "Apex Huntmaster"; the client caches the
-- name/subtitle by entry. Entry 9916114 has never been seen and carries "Huntmaster".

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS `tmp_apex_zulkhar`;
CREATE TEMPORARY TABLE `tmp_apex_zulkhar` AS
    SELECT * FROM `creature_template` WHERE `entry` = 9916112;
UPDATE `tmp_apex_zulkhar`
   SET `entry` = 9916114, `name` = 'Zul''khar', `subname` = 'Huntmaster';

DELETE FROM `creature_template` WHERE `entry` = 9916114;
INSERT INTO `creature_template` SELECT * FROM `tmp_apex_zulkhar`;
DROP TEMPORARY TABLE `tmp_apex_zulkhar`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9916114;
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
SELECT 9916114, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`
  FROM `creature_template_model` WHERE `CreatureID` = 9916112;

DELETE FROM `creature_display_preset` WHERE `entry` = 9916114;
INSERT INTO `creature_display_preset`
(`entry`,`display_id`,`race`,`gender`,`class`,`skin`,`face`,`hair`,`haircolor`,`facialhair`,`guild_id`,
 `item_head`,`item_shoulders`,`item_body`,`item_chest`,`item_waist`,`item_legs`,`item_feet`,`item_wrists`,`item_hands`,`item_back`,`item_tabard`)
SELECT 9916114, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`,
       `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`,
       `item_wrists`, `item_hands`, `item_back`, `item_tabard`
  FROM `creature_display_preset` WHERE `entry` = 9916112;

UPDATE `creature` SET `id` = 9916114 WHERE `id` = 9916112;

DELETE FROM `creature_template` WHERE `entry` = 9916112;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9916112;
DELETE FROM `creature_display_preset` WHERE `entry` = 9916112;

COMMIT;
