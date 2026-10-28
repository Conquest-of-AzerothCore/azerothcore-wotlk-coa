-- Reborn Deep Freeze Immunity State (1171761) is the Warcraft Reborn copy of stock 71761: "Deep Freeze deals damage to
-- targets permanently immune to stuns". The Reborn Frost skill line teaches it to every mage, and without stock's row it
-- procs from any harmful spell (DBC: 0x10000, no class mask, 100%), so a level 1 Fireball cast 1171757 for ~1.5k damage.
-- Stock 71761 is not in the client data, so no twin carries its row or script over: copy both. The class mask is Deep
-- Freeze's (family 3, 0x100000 in word 1), and the stock script admits only creatures immune to stun.
DELETE FROM `spell_proc` WHERE `SpellId` = 1171761;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1171761, 0, 3, 0, 0x00100000, 0, 0, 0x5, 0x2, 256, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 1171761 AND `ScriptName` = 'spell_mage_deep_freeze_immunity_state';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1171761, 'spell_mage_deep_freeze_immunity_state');
