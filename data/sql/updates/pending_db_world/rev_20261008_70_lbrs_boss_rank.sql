-- The Lower Blackrock Spire bosses are bosses (rank 3) in CoA's own creature query cache
-- (hertigservices/ascension-data, conquest-of-azeroth, captured 2026-08-28 to 2026-09-07): Highlord Omokk,
-- Wizz'Magg the Magus, Razmorg the Decapitator, Chop'gog the Butcher, Shadow Hunter Vosh'gajin, War Master Voone,
-- Overlord Wyrmthalak, Bannok Grimaxe, Ghok Bashguud, Quartermaster Zigris, Halycon, Xot'hot the Burning,
-- Crystal Fang and Mother Smolderweb. Their Heroic and Mythic templates follow.
UPDATE `creature_template` SET `rank` = 3 WHERE `entry` IN (
    9196, 9217, 9218, 9219, 9236, 9237, 9568, 9596, 9718, 9736, 10220, 10263, 10376, 10596,
    109196, 109217, 109218, 109219, 109236, 109237, 109568, 109596, 109718, 109736, 110220, 110263, 110376, 110596,
    209196, 209217, 209218, 209219, 209236, 209237, 209568, 209596, 209718, 209736, 210220, 210263, 210376, 210596);
