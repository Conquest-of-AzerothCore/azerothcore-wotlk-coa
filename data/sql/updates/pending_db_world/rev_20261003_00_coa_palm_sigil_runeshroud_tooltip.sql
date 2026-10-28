CREATE TABLE IF NOT EXISTS `coa_client_spell_description` (
  `ID` INT UNSIGNED NOT NULL,
  `Description` TEXT NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (500639,534803,534804,534805,534806,534807,805380,805381,805382,807013,807322,807323);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(500639,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a water rune into your palm, causing your next instance of direct Magic damage within $d to drain the target\'s mana equal to $s1% of the damage dealt.\r\n\r\nUsable while moving.'),
(534803,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a fire rune into your palm, your next direct damaging spell deals $s1% bonus damage as Fire. Lasts for $d.\r\n\r\nUsable while moving.'),
(534804,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a fire rune into your palm, your next direct damaging spell deals $s1% bonus damage as Fire. Lasts for $d.\r\n\r\nUsable while moving.'),
(534805,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a fire rune into your palm, your next direct damaging spell deals $s1% bonus damage as Fire. Lasts for $d.\r\n\r\nUsable while moving.'),
(534806,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a fire rune into your palm, your next direct damaging spell deals $s1% bonus damage as Fire. Lasts for $d.\r\n\r\nUsable while moving.'),
(534807,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a fire rune into your palm, your next direct damaging spell deals $s1% bonus damage as Fire. Lasts for $d.\r\n\r\nUsable while moving.'),
(805380,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave an arcane rune into your palm, causing your next instance of direct Magic damage within $d to deal an additional $s1% of the damage dealt as Arcane damage every $807819t1 sec for $807819d and silences the target for $808020d.\r\n\r\nUsable while moving.'),
(805381,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a frost rune into your palm, causing your next instance of direct Magic damage within $d to deal $s1% of the damage dealt as Frost damage and slow the enemy\'s movement speed by $808022s1% for $808022d. \r\n\r\nUsable while moving.'),
(805382,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave an earth rune into your palm, causing your next instance of direct Magic damage within $d to stun a target enemy for $807824d.\r\n\r\nUsable while moving.'),
(807013,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave a wind rune into your palm, causing your next instance of direct Magic damage within $d to make you immune to movement impairing effects and increase your movement speed by $807826s3% for $807826d.\r\n\r\nUsable while moving.'),
(807322,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave an arcane rune into your palm, causing your next instance of direct Magic damage within $d to deal an additional $s1% of the damage dealt as Arcane damage every $807819t1 sec for $807819d and silences the target for $808020d.\r\n\r\nUsable while moving.'),
(807323,'$?a500288[|cffffffff][|cffff3232]Requires Runeshroud|r\r\nEngrave an arcane rune into your palm, causing your next instance of direct Magic damage within $d to deal an additional $s1% of the damage dealt as Arcane damage every $807819t1 sec for $807819d and silences the target for $808020d.\r\n\r\nUsable while moving.');
