-- Rylak's Bite (#5313): "You and your pet rush towards an enemy and strike them". The castable ranks only
-- carry the weapon-damage effects; the rush is client helper 707293 (SPELL_EFFECT_CHARGE), which nothing cast.
-- The script casts it for the owner and a living pet on the bite target for every rank. The authored pet
-- helper 806380 is not used: its 1-10 yd range fails (out of range / no path / too close) at bite distances.
DELETE FROM `spell_script_names` WHERE `spell_id` = -706342 AND `ScriptName` = 'spell_ascension_rylaks_bite';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-706342, 'spell_ascension_rylaks_bite');
