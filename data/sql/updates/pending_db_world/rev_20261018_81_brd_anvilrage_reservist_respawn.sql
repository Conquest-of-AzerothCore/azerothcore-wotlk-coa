-- Blackrock Depths: the Anvilrage Reservists had no respawn time, so they came back seconds after their
-- corpses vanished. They now respawn after 2 hours like the rest of the dungeon's trash.
UPDATE `creature` SET `spawntimesecs` = 7200 WHERE `id` = 8901 AND `map` = 230 AND `spawntimesecs` = 0;
