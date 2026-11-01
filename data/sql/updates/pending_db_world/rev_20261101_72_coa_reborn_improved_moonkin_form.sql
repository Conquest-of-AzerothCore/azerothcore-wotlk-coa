-- Reborn Improved Moonkin Form 1148384/1148395/1148396 is built differently from stock 48384-48396, so it is given no
-- copy of the stock links that put the haste auras on: its tooltip's 1/2/3% haste (1150170-1150172) never applied.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (1148384, 1148395, 1148396) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(1148384, 1150170, 2, 'Reborn Improved Moonkin Form (Rank 1)'),
(1148395, 1150171, 2, 'Reborn Improved Moonkin Form (Rank 2)'),
(1148396, 1150172, 2, 'Reborn Improved Moonkin Form (Rank 3)');
