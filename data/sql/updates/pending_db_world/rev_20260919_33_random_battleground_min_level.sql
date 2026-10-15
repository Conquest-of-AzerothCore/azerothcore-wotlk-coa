-- Random Battleground was limited to level 80, so lower-level players could never queue for it.
-- The random pool contains battlegrounds that open at level 10 or 20, so open the queue from level 10.
UPDATE `battleground_template` SET `MinLvl` = 10 WHERE `ID` = 32;
