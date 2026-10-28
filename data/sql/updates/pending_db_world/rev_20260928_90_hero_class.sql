-- Hero (class 10) on top of the Hero base of rev_1790611408872048168: auto attack on the first action button,
-- the defenses and every armor and weapon proficiency. The Wildcard starting spells and weapons are granted on a
-- Wildcard Hero's first login (AscensionWildcard GiveStartingKit), so Freepick Heroes keep their kit.
START TRANSACTION;
DELETE FROM `playercreateinfo_action` WHERE `class` = 10;
INSERT INTO `playercreateinfo_action` (`race`, `class`, `button`, `action`, `type`)
SELECT `race`, 10, 0, 6603, 0 FROM `playercreateinfo` WHERE `class` = 10;

-- Heroes wear every armor type and wield every weapon type.
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 0 AND `classmask` = 512;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(0, 512, 6603, 'Hero: Auto Attack'),
(0, 512, 81, 'Hero: Dodge'),
(0, 512, 3127, 'Hero: Parry'),
(0, 512, 107, 'Hero: Block'),
(0, 512, 674, 'Hero: Dual Wield'),
(0, 512, 3018, 'Hero: Shoot'),
(0, 512, 2764, 'Hero: Throw'),
(0, 512, 5019, 'Hero: Wand'),
(0, 512, 196, 'Hero: One-Handed Axes'),
(0, 512, 197, 'Hero: Two-Handed Axes'),
(0, 512, 198, 'Hero: One-Handed Maces'),
(0, 512, 199, 'Hero: Two-Handed Maces'),
(0, 512, 200, 'Hero: Polearms'),
(0, 512, 201, 'Hero: One-Handed Swords'),
(0, 512, 202, 'Hero: Two-Handed Swords'),
(0, 512, 227, 'Hero: Staves'),
(0, 512, 264, 'Hero: Bows'),
(0, 512, 266, 'Hero: Guns'),
(0, 512, 1180, 'Hero: Daggers'),
(0, 512, 2567, 'Hero: Thrown'),
(0, 512, 5009, 'Hero: Wands'),
(0, 512, 5011, 'Hero: Crossbows'),
(0, 512, 15590, 'Hero: Fist Weapons'),
(0, 512, 9078, 'Hero: Cloth'),
(0, 512, 9077, 'Hero: Leather'),
(0, 512, 8737, 'Hero: Mail'),
(0, 512, 750, 'Hero: Plate Mail'),
(0, 512, 9116, 'Hero: Shield');

DELETE FROM `playercreateinfo_item` WHERE `race` = 0 AND `class` = 10;
COMMIT;
