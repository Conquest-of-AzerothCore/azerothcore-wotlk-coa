-- The sawmill focus is answered by the woodworking script hook
-- (ScriptMgr::OnSpellFocusAnswered), not by a spell script, so the five rows
-- that bound the Refine spells to spell_woodworking_sawmill_focus are retired.
-- The spells keep SpellFocusObject 1653, which is what the refusal names.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_woodworking_sawmill_focus';
