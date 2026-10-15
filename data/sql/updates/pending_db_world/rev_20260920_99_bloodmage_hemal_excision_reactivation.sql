-- Hemal Excision (803681): "Cut into an ally's vital essence, siphoning all curse effects from them. You
-- may reactivate this ability again within $803734d to place these curse effects on an enemy."
--
-- The first half is native. 803681's single effect is 38 SPELL_EFFECT_DISPEL, MiscValue 2 (DISPEL_CURSE),
-- BasePoints 19 -> 20 dispels, TargetA 21 (TARGET_UNIT_TARGET_ALLY); Spell::EffectDispel strips the ally's
-- curses with no script. It records nothing about what it took, which is why the capture has to happen in
-- a script.
--
-- The second half had records but no caller. 803734 "Hemal Excision" is the window: DurationIndex 1 =
-- 10000 ms, one SPELL_AURA_DUMMY on the caster, AuraDescription "You may reactivate Hemal Excision to
-- place all siphoned curses on an enemy"; nothing ever cast it. 803733 "Excision" is the re-activation:
-- "Apply all siphoned curses onto an enemy", CastingTimeIndex 1 (instant), RecoveryTime 0, RangeIndex 4
-- (30 yds), ManaCostPercentage 5, effect 0 = 3 SPELL_EFFECT_DUMMY on TargetA 6 (TARGET_UNIT_TARGET_ENEMY)
-- and effect 1 = 164 SPELL_EFFECT_REMOVE_AURA with TriggerSpell 803734 on the caster; nothing referenced
-- it either (`grep -w 803733` over src/, modules/ and data/sql/ returned nothing).
--
-- Those two records settle the design question: the re-activation is a separate, cooldown-free spell, not
-- a second cast of 803681, so Hemal Excision's own RecoveryTime 90000 is never bypassed, reset or
-- shortened - it starts on the first cast and keeps running while the 10 s window is open. The window
-- swaps the button with Player::SetTemporarySpellReplacement, the fork's own machinery for exactly this
-- (see AscensionRangerFalconstrike), so reactivating Hemal Excision reaches 803733.
--
-- Scripts, all in modules/mod-ascension-compat/src/AscensionBloodmageSecondary.cpp:
--   spell_ascension_bloodmage_hemal_excision (803681) snapshots the ally's dispellable curses before the
--     native effect and keeps the ones that are gone afterwards, then casts 803734 on the caster;
--   aura_ascension_bloodmage_hemal_excision (803734) learns 803733 temporarily and points 803681 at it
--     while the window is open, and undoes both plus the stored curses when it ends;
--   spell_ascension_bloodmage_excision (803733) refuses the cast without an open window and applies the
--     stored curses to the enemy, each with the remaining duration and stack count it had on the ally.
-- Every value used is in Spell.dbc: the 10 s window, DISPEL_CURSE, the 20-dispel count and 803733's own
-- range and cost. Nothing is invented.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (803681, 803733, 803734) AND `ScriptName` IN
('spell_ascension_bloodmage_hemal_excision', 'aura_ascension_bloodmage_hemal_excision',
 'spell_ascension_bloodmage_excision');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(803681, 'spell_ascension_bloodmage_hemal_excision'),
(803734, 'aura_ascension_bloodmage_hemal_excision'),
(803733, 'spell_ascension_bloodmage_excision');
