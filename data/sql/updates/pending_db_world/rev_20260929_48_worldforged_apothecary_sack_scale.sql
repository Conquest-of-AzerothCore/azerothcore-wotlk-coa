-- Apothecary Sack (worldforged pickup 96246, Dun Morogh wendigo cave) carries gameobject_template.size 2.00
-- while every one of its ~30 sibling worldforged_pickup templates (96215-97102, including 97101 Yeti Loot
-- Hoard right next to the same wendigo-cave cluster) carries 1.00 - a clean, isolated outlier that renders
-- as a giant model (#5170). Position is left untouched: no ground-truth height/placement data was found to
-- support moving it.
UPDATE `gameobject_template` SET `size` = 1.00 WHERE `entry` = 96246;
