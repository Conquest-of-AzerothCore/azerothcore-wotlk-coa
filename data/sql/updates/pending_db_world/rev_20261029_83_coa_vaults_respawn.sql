-- Vaults of the Inquisition (map 936): every spawn was placed in game with `.npc add` / `.gobject add` and kept their
-- 300 s respawn, so trash and bosses came back while the group was still inside (#10038, #10047). One day, as the
-- vanilla dungeons.
UPDATE `creature` SET `spawntimesecs` = 86400 WHERE `map` = 936 AND `spawntimesecs` = 300;
UPDATE `gameobject` SET `spawntimesecs` = 86400 WHERE `map` = 936 AND `spawntimesecs` = 300;
