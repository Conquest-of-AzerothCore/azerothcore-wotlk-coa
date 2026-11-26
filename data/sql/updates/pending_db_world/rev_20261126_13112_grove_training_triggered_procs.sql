-- Grove Training (92150): allow triggered melee hits and triggered heals to proc Aftershock (301086).
-- Aura::GetProcEffectMask drops every triggered non-auto-attack spell unless PROC_ATTR_TRIGGERED_CAN_PROC (2) is set,
-- which excluded Wildclaw (Offhand) (504240), Hammer of Life (806073), Mountain's Reverence (712433),
-- Earthmother's Pendant (524972), Elemental Cascade (570051), and Sacred Grove recovery (800179) (#13112).
DELETE FROM `spell_proc` WHERE `SpellId` = 92150;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(92150, 0, 0, 0, 0, 0, 17428, 3, 2, 0, 2, 0, 0, 0, 0, 0);
