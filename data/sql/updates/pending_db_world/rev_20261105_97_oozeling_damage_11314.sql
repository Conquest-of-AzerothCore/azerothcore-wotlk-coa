-- Oozeling (8257), summoned when a Devouring Ooze dies during "Slimed and Primed for Battle": the stock 2.4 damage
-- modifier makes the swarm hit far harder than Ascension's 0.5, so players had to run back after every kill.
UPDATE `creature_template` SET `DamageModifier` = 0.5 WHERE `entry` = 8257 AND `DamageModifier` BETWEEN 2.399 AND 2.401;
