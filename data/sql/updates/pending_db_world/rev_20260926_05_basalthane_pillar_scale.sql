-- Pillar creatures (10186/10187/10188) were too big at the default 1.0 scale.

UPDATE `creature_template_model` SET `DisplayScale` = 0.7
WHERE `CreatureID` IN (10186, 10187, 10188);
