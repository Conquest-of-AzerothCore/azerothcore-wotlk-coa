DELETE FROM `coa_client_spell_description` WHERE `ID` = 680639;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES (680639,
CONCAT(
    'Become a paragon of the light for $d, increasing all primary attributes by $s1% ',
    'and increasing your Armor by an amount equal to 5 times your Intellect.\r\n\r\nFor ',
    'the duration, |CffffffffSun Stride|r triggers a $s3% reduced cooldown. ',
    '\r\n\r\nRequires |cffffffffDawn|r to be active.'
  ), CONCAT(
    'A paragon of the light. All primary attributes are increased by ${$w1}% and ',
    'Armor increased by an amount equal to 5 times your ',
    'Intellect.\r\n\r\n|CffffffffSeraphim Stride|r has a ${$w3}% reduced cooldown.'
  ));
