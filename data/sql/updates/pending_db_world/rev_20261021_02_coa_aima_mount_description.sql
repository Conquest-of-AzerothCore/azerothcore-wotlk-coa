-- Issue #8281: Aima's mount-journal entry rendered the raw riding-conditional template instead of the
-- resolved speed line. Its description shared the generic "Summons and dismisses this mount." first
-- sentence used by several custom mounts; give it a mount-specific first sentence like the stock mounts
-- carry. The riding-speed tiers below are unchanged.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (91617);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(91617, 'Summons and dismisses Aima, Steed of the Second Eidolon. This mount is capable of flight.\n\n$?s91774[Ground speed 100%, flying speed 310%.][$?s34091[Ground speed 100%, flying speed 280%.][$?s34090[Ground speed 100%, flying speed 150%.][$?s33391[Ground speed 100%.][$?s33388[Ground speed 60%.][Ground speed 40%.]]]]]', 'Increases ground speed by ${$w2}%.$?s34090|s34091|s91774[ Increases flying speed by ${$w3}%.][]');
