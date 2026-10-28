-- Issue #8281 follow-up: the mount journal renders the streamed Description's first sentence but
-- emits the $?s riding-speed conditional block as raw sNNN| markers instead of evaluating it. Give the
-- Description static, markup-free speed text (renders identically everywhere); the dynamic conditional
-- stays in ToolTip for the spellbook/buff path. Reversible diagnostic step, one row only.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (91617);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(91617, 'Summons and dismisses Aima, Steed of the Second Eidolon. This mount is capable of flight.\n\nGround speed 100%, flying speed 280%.', 'Increases ground speed by ${$w2}%.$?s34090|s34091|s91774[ Increases flying speed by ${$w3}%.][]');
