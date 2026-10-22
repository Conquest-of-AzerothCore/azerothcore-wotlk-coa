-- The CoA-placed Stratholme bosses kept a 300 s respawn (rev_20260923_62 excluded CoA spawns from the vanilla timers),
-- so Hearthsinger Forresten and the others came back during the same run. Give them the 86400 s of the stock
-- Stratholme bosses.
UPDATE `creature` SET `spawntimesecs` = 86400 WHERE `spawntimesecs` = 300 AND `map` = 329
  AND `guid` IN (9950080, 9970179, 9950081, 9950286, 9950289);
