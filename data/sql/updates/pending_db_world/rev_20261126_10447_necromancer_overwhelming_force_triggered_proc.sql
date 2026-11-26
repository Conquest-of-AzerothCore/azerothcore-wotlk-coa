-- #10447 (#11462): Overwhelming Force (531128) omitted PROC_ATTR_TRIGGERED_CAN_PROC (2) in
-- spell_proc, blocking all triggered Necromancer minion spells (Command: Skeletal Warriors
-- 570042, Putrid Claws 570050, Zombie Plague 504022, Skeletal Arrow 800609, Frozen Barbs
-- 803406) from proccing Overwhelming Forces (531131 -> 531129). Use HitMask 9283 (normal,
-- critical, block, absorb, full block; positive damage is filtered by the aura script).
DELETE FROM `spell_proc` WHERE `SpellId` = 531128;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(531128, 332116, 1, 2, 9283, 2, 5);
