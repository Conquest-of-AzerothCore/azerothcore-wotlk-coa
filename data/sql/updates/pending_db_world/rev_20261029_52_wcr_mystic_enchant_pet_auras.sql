-- Warcraft Reborn pet auras the stock talents get from spell_pet_auras but their Reborn and crossover copies did not:
-- Focused Fire (your damage +1%/2% while the pet is out, 1135060/1135061) and Demonology Mastery (your demon deals 10%
-- more damage and attacks 10% faster, 1134966).
DELETE FROM `spell_pet_auras` WHERE `spell` IN (1135029, 1135030, 1335030, 1134965);
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(1135029, 0, 0, 1135060),
(1135030, 0, 0, 1135061),
(1335030, 0, 0, 1135061),
(1134965, 0, 0, 1134966);
