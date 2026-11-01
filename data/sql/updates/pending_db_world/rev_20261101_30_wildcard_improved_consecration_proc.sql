-- Improved Consecration (410000-410002) is a SPELL_AURA_PROC_TRIGGER_SPELL_WITH_VALUE aura with
-- ProcFlags=0 and no spell_proc row in Spell.dbc, so it never fires: casting Consecration never
-- triggers its instant Holy damage + attack-speed slow (410003). The native engine already knows
-- how to handle this aura type (AuraEffect::HandleProcTriggerSpellWithValueAuraProc); it only
-- needed proc eligibility data, scoped to the caster's own Consecration (SpellFamilyName 10,
-- SpellFamilyMask0 32) dealing periodic damage.

DELETE FROM `spell_proc` WHERE `SpellId` IN (410000,410001,410002);
INSERT INTO `spell_proc`
    (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
     `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
     `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
    (410000, 0, 10, 32, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 100, 0, 0),
    (410001, 0, 10, 32, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 100, 0, 0),
    (410002, 0, 10, 32, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 100, 0, 0);
