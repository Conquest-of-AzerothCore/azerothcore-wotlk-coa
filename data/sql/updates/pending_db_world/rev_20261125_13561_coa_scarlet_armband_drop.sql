-- Scarlet Armband (3266) always drops from Scarlet Convert (1506), Scarlet Initiate (1507) and Meven Korgal (1667)
-- while the quest needs it, as on Ascension (db.exil.es dump of 2026-10-04: 100%; AzerothCore data: 70%).
UPDATE `creature_loot_template` SET `Chance` = 100
WHERE `Entry` IN (1506, 1507, 1667) AND `Item` = 3266 AND `Reference` = 0 AND `QuestRequired` = 1 AND `Chance` = 70;
