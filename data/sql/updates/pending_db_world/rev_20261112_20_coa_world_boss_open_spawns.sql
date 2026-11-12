-- Setis and Azuregos are fought only in their own boss maps (880, 881), and the Emerald Dragons (Ysondre,
-- Lethon, Emeriss, Taerar) will get theirs later: drop all their open-world spawns.
DELETE FROM `creature_addon` WHERE `guid` IN (51838, 52349, 32343, 52350, 50012, 4256);
DELETE FROM `creature` WHERE `guid` IN (51838, 52349, 32343, 52350, 50012, 4256);
