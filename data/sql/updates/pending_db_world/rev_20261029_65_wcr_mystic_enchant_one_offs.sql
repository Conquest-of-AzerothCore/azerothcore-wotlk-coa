-- Warcraft Reborn Mystic Enchants whose effect is a one-off mechanic (AscensionMysticEnchantMechanics.cpp):
-- Shadow of Death 1571172 (Ambush on your Rupture target: a 30% Shadow burst around it), Thundering Blow 1581997
-- (Shockwave on your Thunder Clap target: a 15% Nature strike and 1 sec off Shockwave per strike, up to 5 sec),
-- Vanguard 1181451 (charge to your Vigilance target, giving it Vigilant Vanguard 1181452) and Vigilant Vanguard
-- (the ally's auto attacks are followed by the warrior's Vanguard Attack, once every 3 sec).
DELETE FROM `spell_proc` WHERE `SpellId` IN (1571172, 1581997, 1181452);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1571172, 0, 8, 0x00000200, 0x00000000, 0x00000000, 0x10, 1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
(1581997, 0, 4, 0x00000000, 0x00008000, 0x00000000, 0x110, 1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
(1181452, 0, 0, 0x00000000, 0x00000000, 0x00000000, 0x4, 0, 0x2, 0x3, 0x0, 0, 0, 100, 3000, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1571172, 1581997, 1181451, 1181452);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1571172, 'spell_ascension_mystic_shadow_of_death'),
(1581997, 'spell_ascension_mystic_thundering_blow'),
(1181451, 'spell_ascension_mystic_vanguard'),
(1181452, 'spell_ascension_mystic_vigilant_vanguard');
