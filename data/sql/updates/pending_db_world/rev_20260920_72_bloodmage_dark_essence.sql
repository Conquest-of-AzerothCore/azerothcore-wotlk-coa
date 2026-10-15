-- Dark Essence (680732): "Casting Cursed Form abilities or Bloodbolt will now heal allies affected by
-- Blood Rituals for ${$681036m1+$681036ppl1+$BH*0.1} every $681036t1 sec for $681036d." The talent's
-- own record is a single aura 4 (SPELL_AURA_DUMMY) marker; every number lives in 681036, which is
-- SPELL_AURA_PERIODIC_HEAL, BasePoints 29 / DieSides 5 / RealPointsPerLevel 2.0, Amplitude 1500,
-- TargetA 22 (TARGET_SRC_CASTER) + TargetB 30 (TARGET_UNIT_SRC_AREA_ALLY), RadiusIndex 23,
-- DurationIndex 27. The only Spell.dbc row that triggers 681036 is 806945, a different and
-- unobtainable "Dark Essence" variant, so the obtainable talent never healed anyone.
-- The module casts 681036 on the qualifying casts; this script narrows its area selection to the allies
-- who actually carry Blood Rituals (706623), which the native area aura would otherwise ignore.
-- The $BH*0.1 healing coefficient has no native default that matches a 1.5 s tick over this duration,
-- so it is declared here the same way rev_20260914_13 declares 681025's $SP*0.25: as a dot_bonus,
-- because 681036's healing is periodic.
DELETE FROM `spell_bonus_data` WHERE `entry` = 681036;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(681036, 0, 0.1, 0, 0, 'Dark Essence - tooltip $BH*0.1 per periodic heal tick');

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_dark_essence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681036, 'spell_ascension_dark_essence');
