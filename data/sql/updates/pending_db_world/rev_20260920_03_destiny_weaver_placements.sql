-- Destiny Weaver: leave only the placements that are evidence-backed.
--
-- Three of the sixteen Weavers have a position observed in game:
--
--   * 449340 Tav'vin      Durotar  (-635.231, -4230.280, 38.135)   -- live npc dump
--   * 449357 Galrin Olemar Stormwind (-8818.580, 671.774, 95.425)  -- live npc dump
--   * 449350 Tav'ral      Orgrimmar -- the Horde capital Weaver; the unit that stood in
--                                       Orgrimmar was this one, not the orc-look 449346.
--
-- The other thirteen were placed by hand from each race's capital or starter town, which the
-- capture corpus cannot support: the mirror packet carries no position at all (an 8-byte GUID
-- request and a 68-byte appearance reply), and no dump, cache or archive record has a
-- coordinate for any of them. They are removed here rather than left as invented spawns.
--
--   Goldshire   9000019  Galric Olim          - the Alliance Weaver is the Stormwind one;
--                                               449347 is its twin and has no observed spawn
--   Orgrimmar   9000025  Waerun Cliffwalker   - orc-look Weaver, was standing in the Horde
--                                               capital slot that belongs to 449350
--
-- 9000012 keeps its row; only its position changes, to the Orgrimmar spot 449346 vacated. The
-- coordinates are the ones the Weaver stands at on the realm it was restored on, so a fresh
-- database places him where he was observed: (1621.81, -4385.91, 12.5408), facing 1.10337.

DELETE FROM `creature` WHERE `guid` = 9000019;
DELETE FROM `creature` WHERE `guid` = 9000025;

DELETE FROM `creature` WHERE `guid` IN (9000013, 9000014, 9000015, 9000016, 9000017, 9000018,
                                        9000021, 9000022, 9000023, 9000024, 9000026);

UPDATE `creature` SET `map` = 1, `position_x` = 1621.81, `position_y` = -4385.91, `position_z` = 12.5408, `orientation` = 1.10337, `Comment` = 'Destiny Weaver: Tav''ral (Orgrimmar)' WHERE `guid` = 9000012;
