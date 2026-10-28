-- Bloodmage issue batch: Atherann's Anguish accumulator (#504), Night Stalker (#1275), Cardiac Arrest (#3658),
-- Lunge facing (#3959) and the Bloodmoon Blast / Bloodbolt spell power coefficients (#3680). The bonus rows sit on
-- the chain heads 500125 and 804685, which cover the other ranks through the first-rank lookup.
DELETE FROM `spell_script_names` WHERE (`spell_id` = 680680 AND `ScriptName` = 'aura_ascension_bloodmage_atheranns_anguish')
    OR (`spell_id` = 680681 AND `ScriptName` = 'spell_ascension_bloodmage_atheranns_anguish_explosion')
    OR (`spell_id` = 807774 AND `ScriptName` = 'aura_ascension_bloodmage_night_stalker')
    OR (`spell_id` = 806944 AND `ScriptName` = 'aura_ascension_bloodmage_cardiac_arrest')
    OR (`spell_id` = 500126 AND `ScriptName` = 'spell_ascension_bloodmage_lunge');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680680, 'aura_ascension_bloodmage_atheranns_anguish'),
(680681, 'spell_ascension_bloodmage_atheranns_anguish_explosion'),
(807774, 'aura_ascension_bloodmage_night_stalker'),
(806944, 'aura_ascension_bloodmage_cardiac_arrest'),
(500126, 'spell_ascension_bloodmage_lunge');

DELETE FROM `spell_proc` WHERE `SpellId` IN (680680, 806944);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680680, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 2, 6, 0, 100, 0, 0),
(806944, 0, 26, 262144, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` IN (500125, 804685);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(500125, 0.466229, 0, 0, 0, 'Bloodmage - Bloodmoon Blast'),
(804685, 0.45, 0, 0.2, 0, 'Bloodmage - Bloodbolt');
