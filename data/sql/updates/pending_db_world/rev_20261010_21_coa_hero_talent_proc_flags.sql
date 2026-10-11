-- Hero talents whose trigger auras have no ProcFlags in Ascension's Spell.dbc, so they never proc.
-- Omen of Clarity: auto attacks, damage and healing (the flags Ascension's own Warcraft Reborn copy 1116864 carries),
-- the tooltip's 6% chance (from the DBC) and 2 second cooldown, instead of the stock 3.5 procs per minute.
UPDATE `spell_proc` SET `ProcFlags` = 0x14004, `SpellTypeMask` = 0x3, `SpellPhaseMask` = 0x2, `ProcsPerMinute` = 0,
    `Chance` = 0, `Cooldown` = 2000
WHERE `SpellId` = 16864;

-- Double Down: Sinister Strike and its classless transforms (family flag 0x2) also strike with the off hand.
-- Hydromancer: Frostbolt (0x20), Frost Nova (0x40) and Frostfire Bolt (0x1000 in the second word) apply Doused.
DELETE FROM `spell_proc` WHERE `SpellId` IN (275235, 272057);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(275235, 0, 8, 0x2, 0, 0, 0x10, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0),
(272057, 0, 3, 0x60, 0x1000, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0);
