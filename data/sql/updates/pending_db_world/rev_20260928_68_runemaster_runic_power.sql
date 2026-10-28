-- Runic Power 300944 (#3907, PARTIAL FIX): "Increases all damage dealt by party and raid members by 3%. Does
-- not stack with similar effects. In addition, Primordial Blast now increase the chance for the target to be
-- critically struck by your spells by 3% for 20 sec." Effect0 (APPLY_AREA_AURA_RAID, MOD_DAMAGE_PERCENT_DONE)
-- is native and its "does not stack" clause is already fixed by the pending spell_group 2000184 row in
-- rev_20260922_27_raid_damage_percent_group.sql (#3910); that half is untouched here. Effect1 is
-- SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 100, trigger 561056 (SPELL_AURA_MOD_ATTACKER_SPELL_CRIT_CHANCE,
-- BasePoints 2/DieSides 1 = +3%, applied to the enemy target, DurationIndex 18 = 20000ms, matching the tooltip
-- exactly), but Spell.dbc ProcFlags is 0 and no spell_proc row exists, so landing Primordial Blast never applies
-- the crit-taken debuff. Primordial Blast (502823-502827, 800732) is family 38, SpellFamilyFlags0/1/2
-- 4194304/1048576/64, SPELL_EFFECT_SCHOOL_DAMAGE on the enemy (harmful), DmgClass magic: a hit-phase event
-- carries PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000); the tooltip does not require a critical hit, so
-- HitMask is left 0 (default normal+critical+absorb for a done hit); SpellTypeMask 0x1 (damage), SpellPhaseMask
-- 0x2 (hit); Chance 0 keeps the Spell.dbc 100%. DisableEffectsMask 0x1 keeps effect0 (the raid damage% aura, not
-- a trigger aura) out of the proc's effect mask.
DELETE FROM `spell_proc` WHERE `SpellId` = 300944;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300944, 0, 38, 4194304, 1048576, 64, 0x00010000, 0x1, 0x2, 0, 0, 0x1, 0, 0, 0, 0);
