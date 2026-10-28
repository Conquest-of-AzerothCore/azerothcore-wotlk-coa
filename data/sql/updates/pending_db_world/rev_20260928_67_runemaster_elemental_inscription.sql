-- Elemental Inscription 806737 (#3655): "Casting Smolder now reduces the cooldown of Primordial Fury by 10 sec
-- and Zenith by 5 sec." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 100, trigger 706522
-- (SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN x2: -5000ms on Zenith 712325, RecoveryTime 45000ms; -10000ms on
-- Primordial Fury 806543, RecoveryTime 90000ms; matching the tooltip exactly), but Spell.dbc ProcFlags is 0 and
-- no spell_proc row exists, so it never fires. Smolder (801087, and its lower ranks) is family 38,
-- SpellFamilyFlags0 512, SPELL_EFFECT_NORMALIZED_WEAPON_DMG on the enemy (harmful), DmgClass melee: the cast
-- phase reuses m_procAttacker, which prepareDataForTriggerSystem sets to PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS
-- (0x10) for melee-class spells; SpellPhaseMask 1 (cast) fires on casting Smolder
-- specifically; Chance 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 806737;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806737, 0, 38, 512, 0, 0, 0x00000010, 0, 0x1, 0, 0, 0, 0, 0, 0, 0);
