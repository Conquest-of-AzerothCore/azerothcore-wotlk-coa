-- Dire Maul East: Zevrim's Ascension Sacrifice puts the player on the altar as seen in game on Ascension (#11764):
-- -25.95 -448.34 -36.09, facing 4.70.
UPDATE `spell_target_position` SET `PositionX` = -25.9524, `PositionY` = -448.3445, `PositionZ` = -36.0912,
    `Orientation` = 4.70477
WHERE `ID` = 2100215 AND `EffectIndex` = 0;
