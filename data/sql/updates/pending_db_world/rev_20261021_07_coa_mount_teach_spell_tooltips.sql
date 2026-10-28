-- Issue #8281 follow-up: the three Great Raven teaching spells carry the same nested $?s speed
-- block as the fixed mounts. Same treatment: static speeds in the description, riding-gated static
-- flying value in the tooltip (pipe form, no nesting).

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (970040, 970041, 970042);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(970040, 'Teaches you how to transform into the Prophet''s Great Raven.\n\nGround speed 100%, flying speed 280%.', 'Increases ground speed by ${$w2}%.$?s34090|s34091|s91774[ Increases flying speed by 280%.][]'),
(970041, 'Teaches you how to transform into the Archmage''s Great Raven.\n\nGround speed 100%, flying speed 280%.', 'Increases ground speed by ${$w2}%.$?s34090|s34091|s91774[ Increases flying speed by 280%.][]'),
(970042, 'Teaches you how to transform into the Guardian''s Great Raven.\n\nGround speed 100%, flying speed 280%.', 'Increases ground speed by ${$w2}%.$?s34090|s34091|s91774[ Increases flying speed by 280%.][]');
