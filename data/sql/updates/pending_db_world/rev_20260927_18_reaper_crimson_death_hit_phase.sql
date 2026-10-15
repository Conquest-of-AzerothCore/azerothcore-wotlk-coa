-- Crimson Death (705414) recasts Slaughter (500373), which needs an explicit enemy target. At the cast
-- phase the proc event has no action target yet, so the recast fails; the hit phase carries the target.
UPDATE `spell_proc` SET `SpellPhaseMask` = 2 WHERE `SpellId` = 705414;
