-- Surging Slash 705579 (#2745): "Every 3rd cast of Runeblade now transforms your next Runeblade within $572358d
-- into Surging Slash." Its only effect is a PROC_TRIGGER_SPELL of 572358, ProcChance 100, but Spell.dbc gives
-- 705579 itself ProcFlags 0, so SpellMgr::LoadSpellProcs generates no entry and the aura never registers.
-- Runeblade (707141-707148, 573444-573447) is the only family 38 spell with mask2 0x40000, DmgClass melee.
-- 572358 carries its own StackAmount 3 (DurationIndex 8): once the cast-phase proc lets it apply, the native
-- aura system stacks it by 1 on every Runeblade cast, capped at 3 by that StackAmount -- the "every 3rd cast"
-- counter already lives in the DBC record, so no extra script is needed. Chance 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 705579;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705579, 0, 38, 0, 0, 262144, 16, 0, 1, 0, 0, 0, 0, 0, 0, 0);
