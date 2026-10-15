-- Sanity Tap (802575) restores 20% of the caster's missing mana. Its client effect is an ENERGIZE_PCT of maximum mana,
-- so a spell script replaces the amount.
DELETE FROM `spell_script_names` WHERE `spell_id` = 802575 AND `ScriptName` = 'spell_ascension_cultist_sanity_tap';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802575, 'spell_ascension_cultist_sanity_tap');
