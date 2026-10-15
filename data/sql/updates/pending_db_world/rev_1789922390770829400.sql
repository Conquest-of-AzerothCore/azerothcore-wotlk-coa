--
-- Restore the authored SP/AP terms on Primalist physical spells across their rank chains.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (680448, 680442, 803981, 681119, 681251);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES
(680448, 1, 0, 0.1, 0, 'Primalist - Stoneshard: Nature spell power and attack power'),
(680442, 0.6, 0, 0, 0, 'Primalist - Seismic Tremor: direct Nature spell power'),
(803981, 0, 0.2, 0, 0.06, 'Primalist - Seismic Crash: spell power and attack power per tick'),
(681119, 1.3, 0, 0, 0, 'Primalist - Terrasurge: Nature spell power'),
(681251, 1.8, 0, 0, 0, 'Primalist - Lithic Lance: Nature spell power');
