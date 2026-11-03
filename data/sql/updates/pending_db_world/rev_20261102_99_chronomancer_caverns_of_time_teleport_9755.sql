-- Chronomancer Teleport: Caverns of Time (#9755): the teleport spell 804753 had no destination row, so the cast went nowhere.
-- Land it at the Tanaris Caverns of Time entrance, the same point as stock 37778 and 46343 (Map 1, -8167.18, -4766.8, 33.9648, facing 5.165).
REPLACE INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`) VALUES (804753, 0, 1, -8167.18, -4766.8, 33.9648, 5.165, 0);
