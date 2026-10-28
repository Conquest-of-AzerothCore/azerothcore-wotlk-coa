-- Sunken Temple: the hallway where Dungeon Finder groups start (rev_20261020_71) has no enemies, as on Ascension
-- (#7689): five Nightmare Whelps, a Nightmare Scalebane, Whelp, Wanderer and Wyrmkin. None has an addon,
-- formation, pool, linked respawn or spawn script.
DELETE FROM `creature` WHERE `map` = 109 AND `guid` IN (33714, 33715, 33716, 33717, 33718, 33719, 33721, 33722, 33723);
