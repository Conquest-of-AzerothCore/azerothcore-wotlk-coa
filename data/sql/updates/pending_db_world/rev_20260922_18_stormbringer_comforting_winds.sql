-- #1044 Comforting Winds. 704209 and 584238 both ship ProcFlags = 0, so SpellMgr::LoadSpellProcs
-- generates no proc entry and neither direction of the reciprocal haste loop can fire.
-- Both rows consume "any damage the aura holder deals", the same event mask the sibling Air Elemental
-- row for 806020 already uses (rev_20260914_09_air_elemental.sql).
-- 704209 sits on the Stormbringer and triggers 584235 (TARGET_UNIT_PET, 1% spell haste, 5 stacks, 10 s);
-- 584238 sits on the Air Elemental, kept there by stormbringer_pet_lifecycle, and triggers 584237
-- (APPLY_AREA_AURA_OWNER, the same 1% for 10 s on the owner).
DELETE FROM `spell_proc` WHERE `SpellId` IN (584238, 704209);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(584238, 332116, 1, 2, 3, 2, 100),
(704209, 332116, 1, 2, 3, 2, 100);
