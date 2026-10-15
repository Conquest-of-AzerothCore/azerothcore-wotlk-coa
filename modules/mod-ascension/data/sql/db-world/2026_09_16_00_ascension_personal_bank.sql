-- Personal Bank / Celestial Personal Bank / Realm Bank
--
-- These three items (110000/134985, 509892, 1180097) carry a summon spell whose
-- effect is SPELL_EFFECT_DUMMY. A dummy effect does nothing on its own, and a
-- registered spell script runs only when the spell is bound to it here, so
-- without these rows the item is castable (and takes its 10 minute cooldown)
-- but summons nothing.
--
-- The script places the guild-vault object the client opens its bank frame for
-- and answers the activate that follows with the personal/realm bank data.

-- The summon spells used to be bound to 'spell_ascension_summon_bank', which answered them by
-- opening the ordinary bank window. A spell cannot both place the vault and open that window,
-- so the old binding is removed here - it is the binding that carried the superseded behaviour,
-- and clearing it is what makes the spell do one thing. Realms that applied the update which
-- added it keep the row, which is why this runs here and not only in that (now removed) update.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_ascension_personal_bank', 'spell_ascension_summon_bank');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(100702, 'spell_ascension_personal_bank'), -- Personal Bank
(93416,  'spell_ascension_personal_bank'), -- Celestial Personal Bank
(92078,  'spell_ascension_personal_bank'); -- Realm Bank
