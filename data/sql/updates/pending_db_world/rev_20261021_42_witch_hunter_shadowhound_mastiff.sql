-- Shadowhound (#7445): the main hound 50124 wears the mastiff display 35355 again, as the live client cache records it
-- (Exiles DB capture; Ascension changelog "Shadowhound model has been updated"). The Lesser Shadowhound 50224 keeps
-- the DarkHound display 16049. Hound size stays open under #4962.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 35355 WHERE `CreatureID` = 50124 AND `Idx` = 0;
