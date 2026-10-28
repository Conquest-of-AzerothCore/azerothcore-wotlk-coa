-- Runemaster talents whose Spell.dbc records carry ProcFlags 0: SpellMgr::LoadSpellProcs builds no entry for them,
-- so their SPELL_AURA_PROC_TRIGGER_SPELL effects never fire.
-- Leystone Springs 300581 (#1660): "Your melee auto attacks now have a $h% chance to restore
-- ${$520866m1*$<scalingbp>} mana." Done melee auto attacks cast 520866; Chance 0 keeps the Spell.dbc 15%.
-- Effect 1 is the Runic Tattoos: Water modifier, which does not proc.
-- Magic Etchings 300582 (#1661): "Dealing damage with Primordial Blast now reduces the affected target's armor by
-- $520555s1% for $520555d, stacking $520555u times." Primordial Blast and its elemental versions (family 38 mask1
-- 0x100000, magic class) cast Leybreaker 520555 on the damaged target; Chance 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300581, 300582);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300581, 0, 0, 0, 0, 0, 0x00000004, 0, 0, 0, 0, 0x2, 0, 0, 0, 0),
(300582, 0, 38, 0, 0x00100000, 0, 0x00010000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);
