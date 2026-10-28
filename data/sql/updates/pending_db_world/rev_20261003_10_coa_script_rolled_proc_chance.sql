-- These auras roll their own proc chance in their AuraScript CheckProc (the class Chance(player, id) helpers or
-- roll_chance on the record's ProcChance) and need Chance 100 so the script's roll is the only one.
-- rev_20260919_20 set their spell_proc.Chance to 0, which SpellMgr::LoadSpellProcs replaces with the DBC ProcChance,
-- so Aura::GetProcEffectMask rolled it a second time after CheckProc (P x P: Umbral Glaive 10% became 1%, #4275).
-- rev_20260921_10/11, rev_20260926_31, rev_20260927_94 and rev_20260928_95/96 restored other ids the same way.
-- Only Chance changes; the rows keep their masks.
UPDATE `spell_proc` SET `Chance` = 100 WHERE `SpellId` IN (
    300278, 300300, 300313, 300369, 300480, 300490, 300855, 302548, 503851, 503856, 503960, 504375, 504406, 524642,
    538441, 560091, 560200, 560207, 560264, 560281, 560320, 560639, 560785, 561022, 561336, 562029, 572367, 573034,
    574354, 680663, 680975, 681242, 704264, 704610, 704741, 704800, 704920, 704971, 705993, 705998, 706018, 706030,
    706035, 706230, 706239, 706245, 706271, 706370, 706502, 706590, 706911, 707233, 707483, 707629, 707640, 800214,
    800394, 800443, 800463, 801065, 801143, 802068, 802603, 802604, 802605, 802935, 803035, 803037, 803082, 803210,
    803339, 804141, 804345, 804629, 804822, 804981, 804987, 805098, 805110, 805245, 805505, 805606, 805647, 806058,
    806603, 806629, 806699, 806736, 806758);
