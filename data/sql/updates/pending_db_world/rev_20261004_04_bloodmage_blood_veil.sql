-- Blood Veil (#4679).
--
-- All four Blood Veil ranks (504263, 572277, 572278, 572279) carry two SPELL_AURA_SCHOOL_ABSORB
-- (aura 69) effects: effect 0's BasePoints 49 -> 50 is the "absorbing 50% of incoming damage"
-- marker, and effect 1 is the veil's total capacity
-- (510/684/883/1078 plus 7.686/10.531/3.279/3.87 per level and $SPI*1.5 + $AP*.75).
--
-- Native absorption (Unit::CalcAbsorbResist) treats every SCHOOL_ABSORB effect as a flat pool and
-- removes the whole aura as soon as any of its effects is drained to 0, so a single hit bigger than
-- 50 consumed effect 0 and popped the veil - it never absorbed 50% of anything and never got close
-- to its advertised capacity.
--
-- bloodmage_talent_contracts::OnLoadSpellCustomAttr (AscensionBloodmageTalents.cpp) now converts
-- effect 0 to SPELL_AURA_DUMMY, so the native absorb loop ignores it and the aura script can read
-- the 50 from it. aura_ascension_blood_veil adds the caster's $SPI*1.5 + $AP*.75 to effect 1's
-- capacity and limits each hit to 50% of the incoming damage; effect 1 stays a native absorb, so
-- the capacity still drains and the aura still falls off once it is used up.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (504263, 572277, 572278, 572279) AND `ScriptName` = 'aura_ascension_blood_veil';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504263, 'aura_ascension_blood_veil'),
(572277, 'aura_ascension_blood_veil'),
(572278, 'aura_ascension_blood_veil'),
(572279, 'aura_ascension_blood_veil');
