-- Quest pick-ups (Dry Stumps, Kharadol Supplies, Belorita, Gilded Vale pinecones) come back after 2 minutes instead of 30 seconds.
UPDATE `gameobject` SET `spawntimesecs` = 120 WHERE `id` BETWEEN 2300802 AND 2300809;
