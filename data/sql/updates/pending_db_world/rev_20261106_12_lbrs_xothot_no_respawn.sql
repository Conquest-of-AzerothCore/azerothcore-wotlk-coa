-- Lower Blackrock Spire: Xot'hot the Burning on Mythic came back 5 minutes after each kill (#11387).
UPDATE `creature` SET `spawntimesecs` = 1000000 WHERE `guid` = 9970189 AND `id` = 10263;
