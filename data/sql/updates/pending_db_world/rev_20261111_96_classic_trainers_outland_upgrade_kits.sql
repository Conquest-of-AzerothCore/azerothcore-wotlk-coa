-- Profession Upgrade Kits for Outland and Northrend materials belong to the Outland and Northrend trainers.
-- The classic Artisan trainers (Blacksmithing 60, Leatherworking 61, Tailoring 74, Engineering 92) also taught
-- the Fel Iron, Knothide Leather, Bolt of Netherweave, Khorium and Saronite kits, which made the trainer
-- expansion check read these recipes as classic, so classic realms and the Book of Artisans offered them.
DELETE FROM `trainer_spell` WHERE (`TrainerId` = 60 AND `SpellId` = 94352)
    OR (`TrainerId` = 61 AND `SpellId` = 94449)
    OR (`TrainerId` = 74 AND `SpellId` = 94725)
    OR (`TrainerId` = 92 AND `SpellId` IN (94381, 94387, 94389));
