-- Dungeon Finder wings of Uldaman and Gnomeregan had no start point, so every wing began at the front door (#7686,
-- #7814, #7817). No source records Ascension's own wing starts; each wing now begins at the dungeon's own second
-- entrance, the one closer to its bosses: Uldaman's rear entrance (areatrigger 902) for Map Chamber, The Stone Vault
-- and Hall of the Crafters, Gnomeregan's Train Depot entrance (areatrigger 523) for Launch Bay and Tinker's Court.
-- Engineering Labs keeps the front door. A finer start can still be recorded in game with `.mythic lfgpos`.
DELETE FROM `lfg_dungeon_template` WHERE `dungeonId` IN (1004, 1005, 1006, 1007, 1033);
INSERT INTO `lfg_dungeon_template` (`dungeonId`, `name`, `position_x`, `position_y`, `position_z`, `orientation`, `VerifiedBuild`) VALUES
(1005, 'Uldaman - Map Chamber', -214.02, 383.607, -38.7687, 0.5, 0),
(1006, 'Uldaman - The Stone Vault', -214.02, 383.607, -38.7687, 0.5, 0),
(1007, 'Uldaman - Hall of the Crafters', -214.02, 383.607, -38.7687, 0.5, 0),
(1004, 'Gnomeregan - Launch Bay', -736.51, 2.71, -249.99, 3.14, 0),
(1033, 'Gnomeregan - Tinker''s Court', -736.51, 2.71, -249.99, 3.14, 0);
