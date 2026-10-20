-- Everything Will Be Alright (10164) had no prerequisite, so it could be offered to a player without the Auchindoun chain,
-- who then could not turn it in: its giver and ender Greatfather Aldrimus is only visible once Vision of the Dead (10252)
-- or Material Components (10045) is rewarded (spell_area, Commune With The Ancestors). The quest now asks the same.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 19 AND `SourceGroup` = 0 AND `SourceEntry` = 10164;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(19, 0, 10164, 0, 0, 8, 0, 10252, 0, 0, 0, 0, 0, '', 'Everything Will Be Alright: Vision of the Dead rewarded'),
(19, 0, 10164, 0, 1, 8, 0, 10045, 0, 0, 0, 0, 0, '', 'Everything Will Be Alright: or Material Components rewarded');
