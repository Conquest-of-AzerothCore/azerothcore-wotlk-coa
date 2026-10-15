-- Kobold Desecrators 161751 use the Kobold Worker's display 2299, drawn at 1.15x like Elwynn's largest kobolds. They
-- stand at 1.0x, the size of Elwynn's Kobold Vermin and Tunnelers (playtest: too large).
UPDATE `creature_template_model` SET `DisplayScale` = 0.8696 WHERE `CreatureID` = 161751 AND `Idx` = 0;
