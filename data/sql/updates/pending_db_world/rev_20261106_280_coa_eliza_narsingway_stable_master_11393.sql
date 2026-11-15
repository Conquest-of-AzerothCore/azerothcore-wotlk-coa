-- Eliza Narsingway (10960), the Mobile Stable Master (9931336) companion, had no npc flags and no gossip menu, so a
-- click did nothing (#11393).
-- Same flags and menu as the stable masters World Stable Master (9896) and Liza Cutlerflix (24974): gossip | stable
-- master, menu 9821.
UPDATE `creature_template` SET `npcflag` = 4194305, `gossip_menu_id` = 9821
WHERE `entry` = 10960 AND `name` = 'Eliza Narsingway' AND `npcflag` = 0 AND `gossip_menu_id` = 0;
