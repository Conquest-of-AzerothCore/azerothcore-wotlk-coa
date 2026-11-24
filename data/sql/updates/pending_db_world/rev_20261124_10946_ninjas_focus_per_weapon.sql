-- Ninja's Focus (#10946): with the enchant on both weapons only one Agility buff 968746 could exist. The proc aura
-- 968716 cast the buff without its weapon, and the buff could not stack per weapon, so the second weapon's proc only
-- refreshed the first buff. The PR author's review on 2026-11-24 of original Ascension footage
-- (https://youtu.be/6kBk2joQmwQ) shows two buffs at once, each weapon proccing on its own.
DELETE FROM `spell_script_names` WHERE `spell_id` = 968716 AND `ScriptName` = 'aura_ascension_ninjas_focus';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(968716, 'aura_ascension_ninjas_focus');
