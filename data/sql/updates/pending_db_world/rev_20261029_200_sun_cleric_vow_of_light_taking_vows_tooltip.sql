-- Vow of Light (807547): the buff tooltip reads $807750s1 without the caster's spell modifiers, so it kept
-- showing 10% after Taking Vows (300331) adds 5 to 807750 effect 1 (#9780). State the talent-adjusted value.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 807547;
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(807547, 'Direct damage taken or direct healing taken by you generates 1 |cFFFF9800Solar Power|r and heals the nearest nearby ally equal to $807750s1% of the amount.\r\n\r\n|cffffffffFulfillment|r: Doubles the amount of healing done.\r\n\r\n@ext:Only 1 |cffffffffVow|r can be active at a time.:ext@', 'Damage taken or direct healing taken by you now heals the nearest nearby ally for $?s300331[${$807750s1+$300331s1}][$807750s1]% of the value.');
