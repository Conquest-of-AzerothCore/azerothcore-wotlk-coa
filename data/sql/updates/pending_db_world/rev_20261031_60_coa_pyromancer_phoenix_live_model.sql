-- Phoenix Egg 800796 (#10203): the Pyromancer's Phoenix (50258) uses the live Ascension model, display 18987 at
-- its own scale, instead of Kael'thas's raid Phoenix (17765), which was far larger than the player.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18987, `DisplayScale` = 1
WHERE `CreatureID` = 50258 AND `Idx` = 0;
