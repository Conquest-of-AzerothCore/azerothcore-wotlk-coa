-- Eonar's Blessing (993963) computes its heal/mana amounts itself per kill
-- (mod-coa-titan-scrolls' OnPlayerCreatureKill hook), as 1% of the killed
-- creature's max health per buff stack. Without an explicit zero row here,
-- the native periodic-heal path folds the caster's own spell power into
-- that amount (AuraEffect::HandlePeriodicHealAurasTick calls
-- SpellHealingBonusDone for DYNOBJ_AURA_TYPE), so a geared caster's heal
-- would exceed the intended 1%-per-stack contract while the paired
-- energize effect (mana) would not scale the same way.
DELETE FROM `spell_bonus_data` WHERE `entry` = 993963;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(993963, 0, 0, 0, 0, 'Titan Scroll: Eonar — heal amount is script-computed, no native SP/AP coefficient');
