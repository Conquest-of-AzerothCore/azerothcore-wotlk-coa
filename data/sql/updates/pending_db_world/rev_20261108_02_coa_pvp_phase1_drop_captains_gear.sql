-- Quartermaster Hadwin 666682 and Warbringer Krogash 666683 stop selling the Captain's PvP Gear of
-- rev_20261106_17_coa_pvp_phase1_vendors. Sergeant's shares its set bonus with the Corporal's and Grunt's catch-up
-- pieces, so players can swap one piece at a time; Captain's has a separate set and is removed. Sergeant's PvP Gear
-- stays as their only list.
DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (9966682, 9966683) AND `OptionID` = 1;
DELETE FROM `npc_vendor` WHERE `entry` IN (9666822, 9666832);
