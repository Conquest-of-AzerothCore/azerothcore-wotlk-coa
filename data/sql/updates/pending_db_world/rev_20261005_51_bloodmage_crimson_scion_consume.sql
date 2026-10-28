-- Bloodmage: Crimson Scion's proc promises the "next Sanguine Mend within $806425d" (10 s) is
-- instant, so that Sanguine Mend must consume the 806425 buff. Nothing did: the native aura 108
-- instant modifier stayed for its whole duration and one proc covered every mend cast in the window
-- (#6452). spell_ascension_bloodmage_sanguine_mend removes 806425 after a successful cast of any
-- rank whose SpellFamilyFlags include 0x80000, the nine ranks the modifier itself covers:
-- 802310 (Rank 1) and 504079-504086 (Ranks 2-9). 355716, 680033, 681032, 802462 and the
-- "Improved Sanguine Mend" records carry no 0x80000 flag and are not covered by the modifier, so
-- they must not consume it either.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_bloodmage_sanguine_mend';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(802310, 'spell_ascension_bloodmage_sanguine_mend'),
(504079, 'spell_ascension_bloodmage_sanguine_mend'),
(504080, 'spell_ascension_bloodmage_sanguine_mend'),
(504081, 'spell_ascension_bloodmage_sanguine_mend'),
(504082, 'spell_ascension_bloodmage_sanguine_mend'),
(504083, 'spell_ascension_bloodmage_sanguine_mend'),
(504084, 'spell_ascension_bloodmage_sanguine_mend'),
(504085, 'spell_ascension_bloodmage_sanguine_mend'),
(504086, 'spell_ascension_bloodmage_sanguine_mend');
