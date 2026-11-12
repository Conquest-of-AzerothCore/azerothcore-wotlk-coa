-- Setis and Azuregos are fought only in their own boss maps (880, 881): drop their open-world spawns.
DELETE FROM `creature_addon` WHERE `guid` IN (51838, 52349);
DELETE FROM `creature` WHERE `guid` IN (51838, 52349);
