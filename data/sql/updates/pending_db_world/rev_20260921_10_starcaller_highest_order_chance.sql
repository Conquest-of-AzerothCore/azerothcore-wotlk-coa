-- Highest Order 680771 E1 is SPELL_AURA_ADD_FLAT_MODIFIER (107) on SPELLMOD_CHANCE_OF_SUCCESS (18),
-- EffectBasePoints 59, EffectSpellClassMask word2 0x20 = the SpellFamilyFlags of Shadowsong's Mandate 805439.
-- Mandate's proc (aura_ascension_starcaller_event, case 805439) rolls Chance(player, 805439) in its script,
-- and Chance() now applies SPELLMOD_CHANCE_OF_SUCCESS. rev_20260919_20 cleared spell_proc.Chance for 805439,
-- so Aura::CalcProcChance rolled the DBC ProcChance (40) a second time, natively, before the script's own
-- roll: 16% without the talent. Chance 100 leaves the script roll as the only roll, at the record's own
-- ProcChance plus the modifier (40, or 100 with Highest Order).
-- The row keeps the ProcFlags, masks and hit mask rev_20260909_06 wrote; only Chance changes, and the UPDATE
-- is idempotent. This file sorts after rev_20260919_20, so its value is the one that stays.
UPDATE `spell_proc` SET `Chance` = 100 WHERE `SpellId` = 805439;
