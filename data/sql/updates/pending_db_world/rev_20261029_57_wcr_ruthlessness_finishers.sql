-- Warcraft Reborn Ruthlessness (1114156, 1114160, 1114161, and the crossover Mystic Enchant 1314161): the stock talent
-- procs on finishing moves through its spell_proc mask, but the Reborn ranks are built differently, are not twinned,
-- and fell back to their Spell.dbc proc flags - every ability (Riposte) could add a combo point. The mask is every
-- Warcraft Reborn rogue finishing move (attributes FINISHING_MOVE_DAMAGE / _DURATION), less 0x800000: Envenom and
-- Deadly Throw share that bit with Backstab and Sinister Strike, and their second word already admits them.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1114156, 1114160, 1114161, 1314161);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1114156, 0, 8, 0x083E2000, 0x00000009, 0x30000100, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0),
(1114160, 0, 8, 0x083E2000, 0x00000009, 0x30000100, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0),
(1114161, 0, 8, 0x083E2000, 0x00000009, 0x30000100, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0),
(1314161, 0, 8, 0x083E2000, 0x00000009, 0x30000100, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0);
