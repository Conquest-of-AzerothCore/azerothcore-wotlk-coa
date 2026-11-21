-- Zul'Gurub: the Blood Orb over Jin'do's Blood Pit is three times larger and Mar'li's Spider Eggs half as large
-- again (tester feedback round 10 and the user, 2026-11-16); live sizes are not in the client cache.
UPDATE `creature_template_model` SET `DisplayScale` = 3 WHERE `CreatureID` = 92008 AND `Idx` = 0;
UPDATE `creature_template_model` SET `DisplayScale` = 1.5
    WHERE `CreatureID` IN (14915, 114915, 214915, 314915) AND `Idx` = 0;
