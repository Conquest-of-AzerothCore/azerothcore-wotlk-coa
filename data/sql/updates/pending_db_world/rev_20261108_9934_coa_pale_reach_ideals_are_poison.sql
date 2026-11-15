-- Ideals Are Poison (175035): the five clue lines from rev_20261027_27 were written for the port; they now read as on
-- the live realm (DuWTvw19xtg_003556, 003632, 003708, 003740, 003756 and i5vATMYui0I_010612, 010916).
-- The footprints clue breaks after its second sentence there, which keeps it on screen.
UPDATE `creature_text` SET `Text` = 'Warm furs caught in a bush. The broken branches seem to indicate a sudden, violent movement.' WHERE `CreatureID` = 164511 AND `GroupID` = 0 AND `ID` = 0;
UPDATE `creature_text` SET `Text` = 'A makeshift path through the undergrowth. The grass has been uprooted in several patches.' WHERE `CreatureID` = 164511 AND `GroupID` = 1 AND `ID` = 0;
UPDATE `creature_text` SET `Text` = 'An abandoned, damaged shield. The lack of moss suggests it hasn''t been lying here for long.' WHERE `CreatureID` = 164511 AND `GroupID` = 2 AND `ID` = 0;
UPDATE `creature_text` SET `Text` = 'A chaotic and confusing trail of footprints. They converge, diverge, and trace circles around one another.\nThe dried mud has immortalized the scene; you''re lucky the rain hasn''t washed it away.' WHERE `CreatureID` = 164511 AND `GroupID` = 3 AND `ID` = 0;
UPDATE `creature_text` SET `Text` = 'It could belong to any animal. A mere coincidence. But something tells you this is the blood of one of the two brothers.' WHERE `CreatureID` = 164511 AND `GroupID` = 4 AND `ID` = 0;
