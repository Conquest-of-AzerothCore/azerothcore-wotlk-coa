-- Damned (706786) casts 560420 on gaining Soul Infusion. Its speed is effect 1
-- (SPELL_AURA_MOD_INCREASE_SPEED, base points 29 = 30%, 3 sec); effect 2 is empty. Both client texts
-- read effect 2, so the talent said "by 1 to 0%" and the buff "increased 0%" (#8146). Point them at
-- effect 1; 560420 has no description of its own.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (706786, 560420);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(706786,'When you gain |cff5ee2ffSoul Infusion|r, your movement speed is increased by $560420s1% for $560420d.',NULL),
(560420,'','Movement speed increased ${$w1}%.');
