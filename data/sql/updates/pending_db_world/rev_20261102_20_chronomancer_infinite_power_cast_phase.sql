-- #10806: Infinite Power (92118) reads "Casting damaging spells now reduces your damaging spell cooldowns by 10% of
-- their remaining cooldown", but its proc (rev_20260928_80) waited for the hit phase of a direct damage spell. Unmake,
-- Timerend and Melt Reality apply a periodic damage aura and deal no direct damage, so casting them never counted, while
-- every tick of Melt Reality's triggered damage did (-36% in one cast). The proc now fires in the cast phase, once per
-- cast of a non-triggered hostile spell; the spell script spell_ascension_infinite_power keeps only the casts of spells
-- that deal damage, directly or periodically. Triggered spells no longer proc it, so AttributesMask 2 is dropped.
-- SpellTypeMask 7 = every type: no damage has been done yet at the cast phase.
DELETE FROM `spell_proc` WHERE `SpellId` = 92118;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(92118, 0, 0, 0, 0, 0, 69888, 7, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 92118 AND `ScriptName` = 'spell_ascension_infinite_power';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(92118, 'spell_ascension_infinite_power');
