-- Anguish (504742 talent, 500566 buff): Darkflock is no longer channeled, and the buff's -50% read as "by -50%".
DELETE FROM `spell_script_names` WHERE `spell_id` = 500566 AND `ScriptName` = 'aura_ascension_witch_hunter_anguish';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (500566, 'aura_ascension_witch_hunter_anguish');

-- Darkflock: changelog entry 71840 (2026-08-25) raised its attack power scaling to 35%; the client text still shows 25%.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (500566, 504742, 520270, 520708, 520709, 562024, 562025);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(500566, 'Reduces the duration of your next Darkflock by ${-$m1}%.', 'Reduces the duration of your next Darkflock.'),
(504742, 'Your Shadow damage dealt now has a $h% chance to reset the cooldown and reduce the duration of your next |cffffffffDarkflock|r within $500566d by ${-$500566m1}%.', ''),
(520270, 'For $d, command a flock of crows to deal ${$m1+0+$AP*.35+$SP*1.0625} Shadow damage to enemies in front of you every $t1 sec.', ''),
(520708, 'For $d, command a flock of crows to deal ${$m1+0+$AP*.35+$SP*1.0625} Shadow damage to enemies in front of you every $t1 sec.', ''),
(520709, 'For $d, command a flock of crows to deal ${$m1+0+$AP*.35+$SP*1.0625} Shadow damage to enemies in front of you every $t1 sec.', ''),
(562024, 'For $d, command a flock of crows to deal ${$m1+0+$AP*.35+$SP*1.0625} Shadow damage to enemies in front of you every $t1 sec.', ''),
(562025, 'For $d, command a flock of crows to deal ${$m1+0+$AP*.35+$SP*1.0625} Shadow damage to enemies in front of you every $t1 sec.', '');
