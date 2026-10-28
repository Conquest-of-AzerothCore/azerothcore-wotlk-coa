--
-- Sanguine Rupture's area damage is native. Bind a spell script to its rank chain so only the effect 1 bleed
-- trigger requires Cursed Ground (561195) and at least five successful targets.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = -800774
    AND `ScriptName` = 'spell_ascension_bloodmage_sanguine_rupture';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-800774, 'spell_ascension_bloodmage_sanguine_rupture');
COMMIT;
