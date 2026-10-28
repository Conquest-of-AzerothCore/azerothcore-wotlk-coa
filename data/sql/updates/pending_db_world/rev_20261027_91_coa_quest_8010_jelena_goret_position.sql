-- Jelena Goret (164982, guid 9920211), one of 5 "Voices at the North Gate" NPCs for quest 175198, was captured
-- in-game 27 yards from the other 4 (Baldur, Gareth Lindgren, Sereniel, Brother Caesar, clustered around
-- -8350,642), isolated near the gate opening instead of "in the croud at the gate". Move her next to Baldur
-- (-8345.11,641.389) to join the crowd the other 4 already form.
UPDATE `creature` SET `position_x` = -8348.0, `position_y` = 639.0, `position_z` = 95.35, `orientation` = 2.23
    WHERE `guid` = 9920211 AND `id` = 164982;
