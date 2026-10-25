-- COA-7138: Icehide (76555), a level 14 elite cat beast, had no skinning table. Give it the level 10-15 leather table.
UPDATE `creature_template` SET `skinloot` = 100015 WHERE `entry` = 76555;
