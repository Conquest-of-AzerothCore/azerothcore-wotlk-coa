-- Taragaman the Hungerer raises the Rumbling Earth pillars (663030) before every Massive Fire Nova (2102516) on all
-- difficulties, as Ascension's Normal runs show (Earth Break 2102515 ahead of the nova). Normal used to cast the nova
-- without pillars, leaving no cover (#7236).
UPDATE `smart_scripts` SET `event_flags` = 0,
    `comment` = 'Taragaman the Hungerer - Ascension kit - In Combat - Summon Creature 663030 (all difficulties)'
WHERE `entryorguid` = 11520 AND `source_type` = 0 AND `id` = 9010;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11520 AND `source_type` = 0 AND `id` = 9013;
