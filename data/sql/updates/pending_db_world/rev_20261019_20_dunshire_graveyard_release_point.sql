-- Dunshire's Spirit Healer (guid 9995001) was moved to the spot placed in game (rev_20261017_76), 83 yd north of the
-- graveyard's release point, so a ghost released in Dunshire found no Spirit Healer (#8136). The release point of
-- graveyard 6092 now stands in front of the Spirit Healer, as it did before the move.
UPDATE `game_graveyard` SET `x` = -7726.5, `y` = 687.3, `z` = 136.48 WHERE `ID` = 6092;
