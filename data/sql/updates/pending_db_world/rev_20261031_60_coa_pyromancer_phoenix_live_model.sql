-- Phoenix Egg 800796 (#10203): the Pyromancer's Phoenix (50258) uses the live Ascension model, display 18987,
-- instead of Kael'thas's raid Phoenix (17765). At scale 0.5 it stands about half the player's height (checked in game).
UPDATE `creature_template_model` SET `CreatureDisplayID` = 18987, `DisplayScale` = 0.5
WHERE `CreatureID` = 50258 AND `Idx` = 0;
