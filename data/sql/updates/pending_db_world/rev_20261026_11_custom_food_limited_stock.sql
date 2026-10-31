-- COA-5542: the custom Ascension foods (772061-772076) sold by innkeepers and food vendors had unlimited stock.
-- Each vendor now holds 10 of each, restocked every hour.
UPDATE `npc_vendor` SET `maxcount` = 10, `incrtime` = 3600 WHERE `item` BETWEEN 772061 AND 772076;
