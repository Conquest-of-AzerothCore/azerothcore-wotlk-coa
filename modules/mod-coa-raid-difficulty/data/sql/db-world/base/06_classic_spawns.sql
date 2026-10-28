-- Zul'Gurub, Blackwing Lair, Ruins and Temple of Ahn'Qiraj in four difficulties.
--
-- MapDifficulty.dbc has four rows for each of maps 309, 469, 509 and 531, just
-- like Molten Core. None of their creatures points at a difficulty template, so
-- the core uses the base template on every difficulty - which is what we want:
-- the Molten Core tier templates are exact copies of their base anyway. Health
-- comes from flex (04_boss_flex.sql), spell damage from SpellDifficulty.dbc.
--
-- All that is missing is the spawn mask. 15 is every difficulty: 1 | 2 | 4 | 8.
-- Undo: set it back to 1.

UPDATE `creature`   SET `spawnMask` = 15 WHERE `map` IN (309, 469, 509, 531);
UPDATE `gameobject` SET `spawnMask` = 15 WHERE `map` IN (309, 469, 509, 531);
