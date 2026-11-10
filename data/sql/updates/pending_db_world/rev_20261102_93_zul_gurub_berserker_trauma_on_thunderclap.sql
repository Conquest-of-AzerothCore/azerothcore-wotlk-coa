-- Gurubashi Berserker (11352): in the live combat logs (C:\CoA\SUB\old-logs, 2026-08-02 and 2026-08-09) all 155
-- Trauma (2118910) applications land with a Thunderclap (340080) hit on the same player, never with a cast of
-- their own. Trauma now rides every Thunderclap hit instead of a separate timed cast on the tank. Thunderclap
-- 340080 is used by no other creature.

DELETE FROM `smart_scripts` WHERE `entryorguid` = 11352 AND `source_type` = 0 AND `id` = 5;

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 340080 AND `spell_effect` = 2118910 AND `type` = 1;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(340080, 2118910, 1, 'Gurubashi Berserker Thunderclap - Trauma on every target hit');
