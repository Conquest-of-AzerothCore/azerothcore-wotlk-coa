-- Shadewell Spring (game_graveyard 6074) has no Spirit Healer, so it serves only the Inquisitorial dungeon zones
-- (10197, 10218); Elwynn Forest deaths resolve to its graveyards with a Spirit Healer again.
DELETE FROM `graveyard_zone` WHERE `ID` = 6074 AND `GhostZone` = 12;
