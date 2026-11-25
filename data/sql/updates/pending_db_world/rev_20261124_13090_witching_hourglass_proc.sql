-- Witching Hourglass never procced (#13090): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip: "Your
-- direct damage and healing spells ... (45 sec cd)". Flags 81920 (harmful and helpful magic spells) as the stock
-- records with that wording, damage and heals. Chance from each record (100 on the heroic dungeon copies, 15 on the
-- level 70 copies), by the PR author's ruling. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (5011142, 5011143, 5011144, 5011145, 5011146, 5011147, 5011148, 5011149,
    5011150, 5011151, 5011152, 5012142, 5012143, 5012144, 5012145, 5012146, 5012147, 5012148, 5012149, 5012150, 5012151,
    5012152);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(5011142, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011143, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011144, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011145, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011146, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011147, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011148, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011149, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011150, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011151, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5011152, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012142, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012143, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012144, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012145, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012146, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012147, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012148, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012149, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012150, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012151, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0),
(5012152, 0, 0, 0, 0, 0, 81920, 3, 2, 0, 0, 0, 0, 0, 45000, 0);
