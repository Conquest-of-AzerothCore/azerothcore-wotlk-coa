-- Stratholme: Magistrate Barthilas respawns once a day like the stock spawn, not 5 minutes after his death.
UPDATE `creature` SET `spawntimesecs` = 86400 WHERE `guid` = 9950286 AND `id` = 10435;
