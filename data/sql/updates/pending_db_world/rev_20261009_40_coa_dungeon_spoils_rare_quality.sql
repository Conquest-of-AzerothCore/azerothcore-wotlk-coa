-- Dungeon Spoils (2021814) shows as rare (blue); Dungeon Spoils (Heroic) and (Mythic) stay epic.
UPDATE `item_template` SET `Quality` = 3 WHERE `entry` = 2021814;
