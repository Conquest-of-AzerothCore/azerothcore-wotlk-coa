-- Reborn Frost Mastery (1134961) effect 0: the Water Elemental's damage aura (1134963), a pet aura like the stock
-- talents' spell_pet_auras rows.
DELETE FROM `spell_pet_auras` WHERE `spell` = 1134961 AND `effectId` = 0;
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(1134961, 0, 1137994, 1134963);
