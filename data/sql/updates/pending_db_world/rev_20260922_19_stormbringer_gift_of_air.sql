-- #755 Gift of Air. 705715 ships ProcFlags = 0, so its SPELL_AURA_PROC_TRIGGER_SPELL effect never fires,
-- and no shipped spell reaches 583254, the carrier of the critical-strike clause.
-- One proc entry serves both tooltip clauses and aura_ascension_gift_of_air separates them:
-- ProcFlags 333140 = 332116 (every damage the Stormbringer deals) | 1024 (a done positive spell of
-- damage class none, which is how Kiss of the Clouds is reported on the cast phase);
-- SpellPhaseMask 3 covers that cast phase and the hit phase the critical strikes are reported on.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_gift_of_air';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(705715, 'aura_ascension_gift_of_air');
DELETE FROM `spell_proc` WHERE `SpellId` = 705715;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellPhaseMask`, `HitMask`, `Chance`) VALUES
(705715, 333140, 3, 3, 100);
