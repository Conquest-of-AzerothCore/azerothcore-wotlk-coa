-- COA-7214: Verog the Dervish appeared so rarely (3% per Kolkar Pack Runner, Marauder or Bloodcharger kill at the
-- Stagnant Oasis) that players reported the quest as broken. Raise the chance to 5%. The chance is on the death row
-- whose link says the line and summons Verog.
UPDATE `smart_scripts` SET `event_chance` = 5
WHERE `source_type` = 0 AND `event_type` = 6 AND `event_chance` = 3
  AND ((`entryorguid` IN (3274, 3275) AND `id` = 1) OR (`entryorguid` = 3397 AND `id` = 2));
