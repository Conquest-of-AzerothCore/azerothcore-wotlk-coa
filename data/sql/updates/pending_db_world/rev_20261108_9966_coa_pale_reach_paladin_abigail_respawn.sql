-- Paladin Abigail (164995) gives and ends No Holy Dead (175344) but can be killed for Sins Beyond Mercy (175200); she
-- was gone for five minutes afterwards. She now returns after 10 s.
UPDATE `creature` SET `spawntimesecs` = 10 WHERE `guid` = 9960644 AND `id` = 164995;
