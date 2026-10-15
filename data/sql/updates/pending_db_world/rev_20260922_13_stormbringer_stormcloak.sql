-- Stormbringer: bind Stormcloak (804833) to the barrier script.
-- Its SPELL_AURA_SCHOOL_ABSORB effect carries a Spell.dbc pool of 2 (EffectBasePoints 1 + EffectDieSides 1)
-- and gets no bonus term, so Unit::CalcAbsorbResist drained it on the first incoming damage and removed the
-- whole aura together with the linked companion 805161. The script installs a non-depleting pool and absorbs
-- the effect-2 percentage of an incoming attack on the record's own ProcChance.
DELETE FROM `spell_script_names` WHERE `spell_id` = 804833 AND `ScriptName` = 'aura_ascension_stormcloak';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (804833, 'aura_ascension_stormcloak');
