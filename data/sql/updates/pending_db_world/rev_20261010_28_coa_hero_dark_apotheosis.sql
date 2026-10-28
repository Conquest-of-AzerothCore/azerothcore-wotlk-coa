-- Dark Apotheosis 275585 (free-pick and Wildcard Heroes): "Your threat generated is significantly increased. Dark
-- Apotheosis cannot cower behind a shield. Shields cannot be equipped while transformed." The form applied neither.
-- The script applies Dark Apotheosis - Shield Armor and Block Removal 275587 while transformed; the threat increase
-- (Warcraft Reborn's +260%) is added to the form at load time.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_dark_apotheosis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(275585, 'aura_hero_dark_apotheosis');
