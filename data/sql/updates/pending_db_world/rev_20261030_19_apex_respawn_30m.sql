-- Thirty-minute respawn for the three apex bosses. The timer lives on the spawn row,
-- not on creature_template, in this schema.
UPDATE `creature` SET `spawntimesecs` = 1800 WHERE `id` IN (9916222, 9916223, 9916224);
