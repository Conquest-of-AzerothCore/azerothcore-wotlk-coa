-- Conquest of Azeroth class trainers in Brill (#6552): Brill is the first town of Tirisfal Glades, and a
-- Forsaken or other Horde CoA character who leaves Deathknell finds only the stock trainers there. One trainer
-- for each CoA class 12-32 now stands in the town square, so every CoA class can train in Brill.
--
-- WHERE EACH VALUE COMES FROM
--   trainers  existing templates, reused unchanged (no new creature_template rows): the eighteen Undercity
--     trainers of migration rev_20260923_15 (faction 68) and, for the three classes Undercity lacks, the
--     Orgrimmar trainers of the same migration (faction 29, friendly to the Horde): Zerin'dai (Witch
--     Doctor), Wun'zujek (Venomancer) and Thako Maz (Primalist). Each serves its class through
--     creature_default_trainer (trainer 900000 + class) and its class gossip menu; none starts or ends a
--     quest. Apothecary Kelan, Deathknell's Venomancer trainer, is not reused: he ends quest 53015.
--   positions  INFERRED: no source gives a CoA trainer post in Brill. AscensionDB, CoA Tavern, the client
--     addons, the SUB world dump (0 spawns of the 261 CoA trainer templates on map 0) and the descension
--     trainer-spawn research (0 of 354 trainers with coordinates) were searched. The posts follow the
--     Arena Tournament layout of the square (event 31, which never starts): three arcs around its centre
--     (2266, 284), radius 19 inside the tournament's class trainer pedestals, radius 11.5 west of its vendor
--     pedestal row and radius 16.5 in front of the town hall. Every post keeps 3 yd or more from every stock
--     creature, 4 yd or more from every stock object and every event 31 pedestal, 2.5 yd or more from every
--     other event object and 3.6 yd or more from the next trainer.
--   z  a weighted plane through the ground spawns within 15 yd (the tournament pedestals, Noblegarden eggs,
--     the Wanted! poster and the Deathguards of the square), unchecked against the CoA maps; the gameplay
--     scenario brill-coa-class-trainers-6552 compares each post with the terrain height.
--   facing  toward the centre of the square.
--   event  every CoA class trainer spawn belongs to event 195 (rev_20261007_98), which the worldserver starts
--     on a CoA realm; that migration links only the spawns that existed then, so these are linked here.
--   spawn row  as the capital trainers: equipment 1, respawn 300 s, no movement.
DELETE FROM `creature` WHERE `guid` BETWEEN 9005000 AND 9005020;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9005000, 602951, 0, 0, 0, 1, 1, 1, 2247.0, 285.3, 34.83, 6.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Barbarian trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 1 of 8 from the south; faces the square centre'),
(9005001, 650296, 0, 0, 0, 1, 1, 1, 2247.6, 288.9, 34.88, 6.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Witch Doctor trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 2 of 8 from the south; faces the square centre'),
(9005002, 650276, 0, 0, 0, 1, 1, 1, 2248.9, 292.2, 34.88, 5.83, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Felsworn trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 3 of 8 from the south; faces the square centre'),
(9005003, 650275, 0, 0, 0, 1, 1, 1, 2250.7, 295.3, 34.85, 5.64, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Witch Hunter trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 4 of 8 from the south; faces the square centre'),
(9005004, 602773, 0, 0, 0, 1, 1, 1, 2253.1, 298.0, 34.81, 5.46, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Stormbringer trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 5 of 8 from the south; faces the square centre'),
(9005005, 602781, 0, 0, 0, 1, 1, 1, 2256.0, 300.2, 34.71, 5.27, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Knight of Xoroth trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 6 of 8 from the south; faces the square centre'),
(9005006, 650279, 0, 0, 0, 1, 1, 1, 2259.2, 301.8, 34.57, 5.08, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Guardian trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 7 of 8 from the south; faces the square centre'),
(9005007, 602803, 0, 0, 0, 1, 1, 1, 2262.7, 302.7, 34.45, 4.89, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Templar trainer (INFERRED hand spot): Brill square, west arc inside the tournament trainer pedestals, 8 of 8 from the south; faces the square centre'),
(9005008, 602922, 0, 0, 0, 1, 1, 1, 2254.9, 287.0, 34.53, 6.02, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Bloodmage trainer (INFERRED hand spot): Brill square, inner arc west of the tournament vendor pedestals, 1 of 3 from the south; faces the square centre'),
(9005009, 650281, 0, 0, 0, 1, 1, 1, 2256.6, 290.6, 34.23, 5.67, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Ranger trainer (INFERRED hand spot): Brill square, inner arc west of the tournament vendor pedestals, 2 of 3 from the south; faces the square centre'),
(9005010, 602822, 0, 0, 0, 1, 1, 1, 2259.4, 293.4, 34.24, 5.32, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Chronomancer trainer (INFERRED hand spot): Brill square, inner arc west of the tournament vendor pedestals, 3 of 3 from the south; faces the square centre'),
(9005011, 503930, 0, 0, 0, 1, 1, 1, 2277.5, 272.1, 34.95, 2.34, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Necromancer trainer (INFERRED hand spot): Brill square, east arc before the town hall, 1 of 10 from the Winter Veil tree; faces the square centre'),
(9005012, 650293, 0, 0, 0, 1, 1, 1, 2279.8, 274.9, 35.11, 2.56, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Pyromancer trainer (INFERRED hand spot): Brill square, east arc before the town hall, 2 of 10 from the Winter Veil tree; faces the square centre'),
(9005013, 602833, 0, 0, 0, 1, 1, 1, 2281.4, 278.1, 35.2, 2.77, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Cultist trainer (INFERRED hand spot): Brill square, east arc before the town hall, 3 of 10 from the Winter Veil tree; faces the square centre'),
(9005014, 602850, 0, 0, 0, 1, 1, 1, 2282.3, 281.5, 35.14, 2.99, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Starcaller trainer (INFERRED hand spot): Brill square, east arc before the town hall, 4 of 10 from the Winter Veil tree; faces the square centre'),
(9005015, 650327, 0, 0, 0, 1, 1, 1, 2282.5, 285.1, 35.12, 3.21, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Sun Cleric trainer (INFERRED hand spot): Brill square, east arc before the town hall, 5 of 10 from the Winter Veil tree; faces the square centre'),
(9005016, 602873, 0, 0, 0, 1, 1, 1, 2281.8, 288.6, 35.0, 3.42, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Tinker trainer (INFERRED hand spot): Brill square, east arc before the town hall, 6 of 10 from the Winter Veil tree; faces the square centre'),
(9005017, 650288, 0, 0, 0, 1, 1, 1, 2280.5, 291.9, 34.86, 3.64, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Venomancer trainer (INFERRED hand spot): Brill square, east arc before the town hall, 7 of 10 from the Winter Veil tree; faces the square centre'),
(9005018, 602891, 0, 0, 0, 1, 1, 1, 2278.4, 294.8, 34.69, 3.86, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Reaper trainer (INFERRED hand spot): Brill square, east arc before the town hall, 8 of 10 from the Winter Veil tree; faces the square centre'),
(9005019, 650290, 0, 0, 0, 1, 1, 1, 2275.8, 297.3, 34.54, 4.08, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Primalist trainer (INFERRED hand spot): Brill square, east arc before the town hall, 9 of 10 from the Winter Veil tree; faces the square centre'),
(9005020, 602913, 0, 0, 0, 1, 1, 1, 2272.7, 299.1, 34.4, 4.29, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Runemaster trainer (INFERRED hand spot): Brill square, east arc before the town hall, 10 of 10 from the Winter Veil tree; faces the square centre');

DELETE FROM `game_event_creature` WHERE `eventEntry` = 195 AND `guid` BETWEEN 9005000 AND 9005020;
INSERT INTO `game_event_creature` (`eventEntry`, `guid`) VALUES
(195, 9005000),
(195, 9005001),
(195, 9005002),
(195, 9005003),
(195, 9005004),
(195, 9005005),
(195, 9005006),
(195, 9005007),
(195, 9005008),
(195, 9005009),
(195, 9005010),
(195, 9005011),
(195, 9005012),
(195, 9005013),
(195, 9005014),
(195, 9005015),
(195, 9005016),
(195, 9005017),
(195, 9005018),
(195, 9005019),
(195, 9005020);
