-- Hamhock's kit Chain Lightning (2102502) on Normal and Heroic went from 599 to 1198 base damage when its interval
-- became 10 s (rev_20261009_50). Ascension's RDF combat logs (2026-05-16, 2026-05-25) show it every ~8 s for
-- 431-607 on the first target, so the doubled value one-shot level 27-28 groups.
UPDATE `smart_scripts` SET `action_param3` = 599 WHERE `entryorguid` = 1717 AND `source_type` = 0 AND `id` = 9010;
