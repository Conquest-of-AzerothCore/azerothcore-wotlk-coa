-- Vanity items: enforce the restrictions stated on their tooltips
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_ascension_vanity_use_restriction', 'spell_ascension_stick_on_a_carrot');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(100706, 'spell_ascension_vanity_use_restriction'),
(364909, 'spell_ascension_vanity_use_restriction'),
(364910, 'spell_ascension_vanity_use_restriction'),
(364911, 'spell_ascension_vanity_use_restriction'),
(364912, 'spell_ascension_vanity_use_restriction'),
(364913, 'spell_ascension_vanity_use_restriction'),
(364914, 'spell_ascension_vanity_use_restriction'),
(979611, 'spell_ascension_vanity_use_restriction'),
(979612, 'spell_ascension_vanity_use_restriction'),
(991885, 'spell_ascension_stick_on_a_carrot');

-- Gnomish Portable Transpolyporter: only usable by its owner and the owner's group
UPDATE `gameobject_template` SET `Data2` = 1 WHERE `entry` = 1903510;

-- Stones of Retreat: Sanctum of the Stars (The Scryers) and Altar of Sha'tar (The Aldor) refuse Hated and Hostile standing
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 17 AND `SourceEntry` IN (777018, 777019) AND `ConditionTypeOrReference` = 5;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(17, 0, 777018, 0, 0, 5, 0, 932, 252, 0, 0, 149, 0, '', 'Stone of Retreat: Altar of Sha''tar - not usable while Hostile with The Aldor'),
(17, 0, 777019, 0, 0, 5, 0, 934, 252, 0, 0, 149, 0, '', 'Stone of Retreat: Sanctum of the Stars - not usable while Hostile with The Scryers');
