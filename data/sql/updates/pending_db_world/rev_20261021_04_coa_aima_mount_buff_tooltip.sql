-- Issue #8281 follow-up: the mounted buff tooltip reads the live aura for its flying number
-- (${$w3}), but the flight effect is stripped where flying is not allowed, rendering
-- "Increases flying speed by 0%." Use static riding-gated tiers instead, mirroring the spell
-- description: the buff path evaluates nested $?s fully, and static numbers do not depend on
-- the stripped aura. Ground speed keeps the live aura value, which is always present.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (91617);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(91617, 'Summons and dismisses Aima, Steed of the Second Eidolon. This mount is capable of flight.\n\nGround speed 100%, flying speed 280%.', 'Increases ground speed by ${$w2}%.$?s91774[ Increases flying speed by 310%.][$?s34091[ Increases flying speed by 280%.][$?s34090[ Increases flying speed by 150%.][]]');
