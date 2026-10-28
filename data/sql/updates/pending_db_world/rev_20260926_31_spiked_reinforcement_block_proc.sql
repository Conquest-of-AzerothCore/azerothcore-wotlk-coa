-- Spiked Reinforcement (#156): the shield enchant's equip aura 653386 damages the attacker on every block.
-- The 653131 tooltip states no chance ("causing your blocks to deal ... damage"); 653386's Spell.dbc
-- ProcChance 30 is the family template value that the non-proc Weighted 653409 and Magic 653304 also carry.
DELETE FROM `spell_proc` WHERE `SpellId` = 653386;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (653386, 0, 0, 0, 0, 0, 40, 1, 0, 8256, 0, 0, 0, 100, 0, 0);
