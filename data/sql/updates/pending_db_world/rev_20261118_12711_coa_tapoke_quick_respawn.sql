-- Tapoke "Slim" Jahn's respawn gives Mikhail his quest marker back after The Missing Diplomat (1249).
-- The vanilla respawn sweep raised this spawn from the stock 10 seconds to 300, so Mikhail stayed locked for
-- five minutes after the subdue. Restore the stock 10 seconds for this scripted spawn only.
UPDATE `creature` SET `spawntimesecs` = 10 WHERE `guid` = 10873 AND `id` = 4962 AND `spawntimesecs` = 300;
