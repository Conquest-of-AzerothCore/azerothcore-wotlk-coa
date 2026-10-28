-- Glyph of Life Tap: "When you use Life Tap or Dark Pact, you gain 20% of your Spirit as spell power". The stock row
-- listens for no-damage-class helpful spells (0x400), which Life Tap's energize is; Dark Pact is a magic-class helpful
-- spell (0x4000) and never matched, stock or Reborn. The class mask still limits it to Life Tap and Dark Pact.
UPDATE `spell_proc` SET `ProcFlags` = `ProcFlags` | 0x4000 WHERE `SpellId` = 63320;
