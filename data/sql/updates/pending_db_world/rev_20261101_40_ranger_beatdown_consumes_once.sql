-- Beatdown (801437, granted by #2493 Brigand/Ranger talent 705047) tooltip: "Your next instance of
-- ability damage will ignore Armor." Spell.dbc gives it ProcFlags 0 and ProcCharges 0, and no
-- spell_proc row exists for 801437 itself, so the ignore-armor buff never procs off the next hit and
-- is never consumed: it silently buffs every Physical ability hit for its whole duration instead of
-- exactly one. Scopes the proc to the caster's own Physical ability damage (melee or ranged dmg
-- class, School Physical) and gives it a single charge so it is removed after the first qualifying
-- hit, matching the tooltip's "next instance" wording.

DELETE FROM `spell_proc` WHERE `SpellId` IN (801437);
INSERT INTO `spell_proc`
    (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
     `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
     `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
    (801437, 1, 0, 0, 0, 0, 272, 1, 2, 0, 0, 0, 0, 100, 0, 1);
