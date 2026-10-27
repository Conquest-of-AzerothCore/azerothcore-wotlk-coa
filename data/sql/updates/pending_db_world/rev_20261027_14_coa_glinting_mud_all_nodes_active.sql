-- Hilary's Necklace (3741): Glinting Mud (gameobject 154357) has 11 spawn points along the Lakeshire lake, but its pool
-- kept only 2 active at a time, so players had to search the shore for the current ones. On Ascension every point had
-- mud at once to spread players out; all 11 are now active, each back 2 s after it is looted.
UPDATE `pool_template` SET `max_limit` = 11, `description` = 'Glinting Mud - 11/11' WHERE `entry` = 138;
