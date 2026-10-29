-- Frozen Slam 903130-903139 (Wildcard Slam rank chain) are dummy-effect spells with no handler bound, so casting
-- them spent rage/triggered no damage. Bind spell_warr_slam like the Storm Slam ranks (#6634); DamageSpell()
-- now maps these ids to helper 903245 (#8774).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (903130, 903131, 903132, 903133, 903134, 903135, 903136, 903137, 903138, 903139) AND `ScriptName` = 'spell_warr_slam';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(903130, 'spell_warr_slam'),
(903131, 'spell_warr_slam'),
(903132, 'spell_warr_slam'),
(903133, 'spell_warr_slam'),
(903134, 'spell_warr_slam'),
(903135, 'spell_warr_slam'),
(903136, 'spell_warr_slam'),
(903137, 'spell_warr_slam'),
(903138, 'spell_warr_slam'),
(903139, 'spell_warr_slam');
