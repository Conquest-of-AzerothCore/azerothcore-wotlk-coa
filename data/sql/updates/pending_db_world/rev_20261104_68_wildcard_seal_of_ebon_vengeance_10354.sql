-- Wildcard Seal of Ebon Vengeance 288847 (#10354) copies Seal of Vengeance 31801 (attributes, dummy + expertise +
-- dummy effects): 'Paladin and Death Knight melee abilities apply Ebon Corruption 288848 (5 stacks, Shadow every
-- 3 s for 15 s). Once stacked to 5 times, each ... deals damage as additional Shadow damage' (Seal of Ebon
-- Vengeance 288849: 75 Shadow + 20% weapon damage). It had neither a spell_proc row nor a script, so no ability
-- applied the DoT. Paladin and Death Knight melee abilities now apply Ebon Corruption and deal 288849 scaled by
-- stacks, as the inherited Seal of Vengeance script does; auto attacks do not, per the tooltip.
DELETE FROM `spell_proc` WHERE `SpellId` = 288847;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(288847, 0, 0, 0, 0, 0, 0x10, 0x1, 0x2, 0, 0x2, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_seal_of_ebon_vengeance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(288847, 'aura_wildcard_seal_of_ebon_vengeance');
