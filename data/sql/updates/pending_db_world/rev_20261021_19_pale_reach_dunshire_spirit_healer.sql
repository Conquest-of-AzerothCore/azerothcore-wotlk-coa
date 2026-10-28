-- Dunshire's Spirit Healer (guid 9995001) stood on the bridge north of the graveyard. It now stands by the gravestones,
-- as placed in game, and graveyard 6092 releases ghosts in front of it so a released ghost still meets it (#8136).
UPDATE `creature` SET `position_x` = -7736.533, `position_y` = 600.034, `position_z` = 136.688, `orientation` = 3.828
    WHERE `guid` = 9995001 AND `id` = 6491;
UPDATE `game_graveyard` SET `x` = -7739.63, `y` = 597.5, `z` = 136.76 WHERE `ID` = 6092;
