-- Runic Omen 705580 (#2746): "Every 3rd cast of Runeblade now deals $705596s1% increased damage." Effect 0 is a
-- PROC_TRIGGER_SPELL of 520285, ProcChance 100, but Spell.dbc gives 705580 itself ProcFlags 0, so
-- SpellMgr::LoadSpellProcs generates no entry and the aura never registers. Runeblade (707141-707148,
-- 573444-573447) is the only family 38 spell with mask2 0x40000, DmgClass melee. 520285 carries its own
-- StackAmount 3 (DurationIndex 8): once the cast-phase proc lets it apply, the native aura system stacks it by 1
-- on every Runeblade cast, capped at 3 by that StackAmount -- the "every 3rd cast" counter already lives in the
-- DBC record. Chance 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 705580;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705580, 0, 38, 0, 0, 262144, 16, 0, 1, 0, 0, 0, 0, 0, 0, 0);

-- 520285's own effect 1 is SPELL_EFFECT_DUMMY (no native handler) with EffectTriggerSpell 705596: a scripted hook
-- reads that on every cast of 520285. 705596 is a self-contained ADD_PCT_MODIFIER (+30%, family 38 mask2 0x40000
-- = Runeblade) with its own 10 sec window, delivering "deals X% increased damage" without further scripting.
-- aura_ascension_runemaster_runic_omen_empower checks whether this cast just brought 520285 to its 3rd stack; if
-- so it removes the counter and casts 705596, which empowers the next Runeblade within its own duration.
DELETE FROM `spell_script_names` WHERE `spell_id` = 520285
    AND `ScriptName` = 'spell_ascension_runemaster_runic_omen_empower';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(520285, 'spell_ascension_runemaster_runic_omen_empower');
