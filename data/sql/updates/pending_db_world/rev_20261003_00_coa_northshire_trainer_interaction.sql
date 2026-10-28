-- The Northshire baseline restore (rev_20260930_98) rewrote the valley's CoA class trainers back to the
-- pre-revamp rows. The rows it restored are of two kinds: the 12 start-zone trainers carried no interaction
-- flags at all, and 4 more (Halbert the Scoundrel, Niki Thesla, Doctor Yara, Owen of Moonbrook) kept only the
-- stock 179 vendor/trainer mask but still lost their gossip menu. Either way their gossip, quest markers and
-- trainer windows never opened, so Amanda the Reaver could not finish the Ancient Tablet (#6296, #6107) and
-- the Necromancer, Stormbringer, Witch Doctor and Ranger trainers of the valley were silent too. Restore the
-- interaction contract of the class trainer migration (rev_20260923_06, trainer rows 900012-900032); the
-- revamp keeps every other column it restored.
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930200 WHERE `entry` = 50295;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930019 WHERE `entry` = 50280;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930022 WHERE `entry` = 50282;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930025 WHERE `entry` = 50283;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930027 WHERE `entry` = 50286;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930201 WHERE `entry` = 50287;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930030 WHERE `entry` = 50289;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930032 WHERE `entry` = 50291;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930020 WHERE `entry` = 50292;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930018 WHERE `entry` = 50324;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930015 WHERE `entry` = 50325;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930024 WHERE `entry` = 50340;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930023 WHERE `entry` = 502923;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930016 WHERE `entry` = 502770;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930202 WHERE `entry` = 502960;
UPDATE `creature_template` SET `npcflag` = 51, `gossip_menu_id` = 930021 WHERE `entry` = 503410;
