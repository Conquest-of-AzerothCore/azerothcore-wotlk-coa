-- Bind the Craftsman's Codex spell to the script this module registers.
--
-- Item 97871 "Craftsman's Codex" - and 2200001 "Soulbound Craftsman's Codex", the same row with
-- Bonding = 1 - carries the on-use spell 93292. That spell has exactly one effect,
-- SPELL_EFFECT_DUMMY, aimed at the caster, and its own text says what it is for:
--
--     "Unlocks a new primary profession slot. You can unlock all primary professions."
--
-- A dummy effect does nothing on its own, and a registered spell script runs only where the
-- database binds the spell to it, so without this row the item casts, spends its 5 second cast
-- time, is consumed (item_template.spellcharges_1 = -1) and grants nothing.
--
-- 'spell_craftsmans_codex' is registered by modules/mod-craftsmans-codex/src/craftsmans_codex.cpp.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_craftsmans_codex';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93292, 'spell_craftsmans_codex');
