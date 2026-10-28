-- Hellfire Imp uses the Outland imp display of Blizzard's own Hellfire Imp (17477), slightly smaller;
-- the classic imp at 0.55 was barely visible.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 16888, `DisplayScale` = 0.75
WHERE `CreatureID` = 50301 AND `Idx` = 0;
