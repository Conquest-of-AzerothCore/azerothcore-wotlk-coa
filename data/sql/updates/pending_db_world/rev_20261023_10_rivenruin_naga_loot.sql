-- Rivenruin Myrmidon and Rivenruin Sorceress (Rivenruin Cave, Durotar) had no loot and no money.
-- They share the loot table and money of Razormane Quilboar (3111), the vanilla Durotar humanoid of the same level.
UPDATE `creature_template` SET `lootid` = 3111, `mingold` = 3, `maxgold` = 12 WHERE `entry` IN (162834, 162835) AND `lootid` = 0;
