-- Lord of Lightning (#1137): the passive 707618 has a single effect, an aura 42 proc that casts the buff 801841
-- on the caster. Its Spell.dbc ProcFlags are 0 and no spell_proc row existed, so no proc entry was generated and
-- the aura could never proc. With the proc being the talent's only effect, nothing of it reached the player.
-- The buff itself is native: ADD_PCT_MODIFIER SPELLMOD_DAMAGE +30 and ADD_FLAT_MODIFIER SPELLMOD_JUMP_TARGETS +3.
-- Family 22 with SpellFamilyFlags word 2 bit 0 is carried by exactly two Spell.dbc rows, Storm Ascendance 681110
-- and its companion 681187, so the mask admits the proc on Storm Ascendance and on nothing else.
DELETE FROM `spell_proc` WHERE `SpellId` = 707618;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707618, 0, 22, 0, 0, 1, 1024, 4, 2, 0, 0, 0, 0, 100, 0, 0);
