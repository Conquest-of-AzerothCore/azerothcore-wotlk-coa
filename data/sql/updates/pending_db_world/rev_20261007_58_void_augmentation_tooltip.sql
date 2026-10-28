DELETE FROM `coa_client_spell_description` WHERE `ID` = 680575;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES (680575,
CONCAT(
    'While |cFFFFFFFFDreadnought|r is active, your |cFFFFFFFFTwilight Shieldtoss|r ',
    'has a $/1000;s1 sec reduced cooldown.\r\n\r\nIn addition, your |cffffffffEldritch ',
    'Shock|r now strikes 2 additional enemies near the primary target.'
  ), '');
