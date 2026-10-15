-- Tithe (804781) only carries an empty aura, so paying at a holy site never taught its party aura. Bind the
-- script that checks the site, charges 1 silver and teaches the aura, or casts Reset Tithe when nothing is learned.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 804781 AND `ScriptName` = 'spell_ascension_templar_tithe';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (804781, 'spell_ascension_templar_tithe');
COMMIT;
