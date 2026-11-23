-- #13092 Spellblade (812575-812577): "Your melee attacks have a $h% chance to restore $s1% of your base mana."
-- The talent aura carries DBC ProcFlags 0 and had no spell_proc row, so it never procced. Family 0 keeps it open
-- to every class's melee attacks on Wildcard; Chance 0 keeps each rank's own DBC ProcChance.
-- #13099 Hammerdin (282983): "Damaging Paladin abilities have a $h% chance to summon a Hammer from the Heavens and
-- reduce the cooldown of Hour of Judgement". Same ProcFlags-0 gap; ProcFlags 69904 are the spell and ability damage
-- flags without auto attacks, family 10 follows the tooltip's Paladin abilities, Chance is the DBC ProcChance 20.
-- #13094 Righteous Vengeance (53380-53382): the #10355 fix zeroed the ability masks but kept SpellFamilyName 10,
-- and SpellInfo::IsAffected rejects every other family, so on Wildcard only Paladin crits procced it.
DELETE FROM `spell_proc` WHERE `SpellId` IN (812575, 812576, 812577, 282983);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(812575, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(812576, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(812577, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(282983, 0, 10, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 20, 0, 0);

UPDATE `spell_proc` SET `SpellFamilyName` = 0 WHERE `SpellId` = -53380;

-- #12531 Seed of Corruption: ranks 1-5 carry DBC ProcFlags 0 and the stock row defers to them, so the damage taken
-- threshold never registered and the seed only detonated on death. Rank 6 (47836) supplies the taken-damage flags.
UPDATE `spell_proc` SET `ProcFlags` = 664232 WHERE `SpellId` IN (-27243, -1127243);

-- #12527 Sudden Doom: "Direct damage abilities and spells have a $h% chance to cast a free Grave Coil" kept the
-- stock Blood Strike/Heart Strike family mask and melee-only DBC flags. ProcFlags 69904 are direct ability and
-- spell damage for every family; Chance 0 keeps the DBC 3/6/9.
DELETE FROM `spell_proc` WHERE `SpellId` = -49018;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-49018, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 0, 0);
