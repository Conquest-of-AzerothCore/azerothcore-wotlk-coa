-- Poised Reinforcement: the shield enchant's equip aura 653410 (SpellItemEnchantment 1018) grants 653305 on every
-- block taken below 75% health. The 653278 tooltip states no chance ("causing blocking attacks while below 75% health
-- to grant you ..."); 653410's Spell.dbc ProcChance 30 is the shield-reinforcement family template value, and the
-- previous Poised Reinforcement aura 280416 with the same wording had ProcChance 100.
DELETE FROM `spell_proc` WHERE `SpellId` = 653410;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (653410, 0, 0, 0, 0, 0, 40, 1, 0, 8256, 0, 0, 0, 100, 0, 0);
