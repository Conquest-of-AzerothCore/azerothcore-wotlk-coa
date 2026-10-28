-- CoA: 1660064 'Durotar's Dire Drought' - the completed quest left the empty
-- Dirgran's pitcher (558973) in bags: filling the pitcher creates the full one (558974)
-- without consuming the empty one, and only the full one is required on turn-in.
-- Require the empty pitcher as well so both are consumed when the quest completes.
UPDATE `quest_template` SET `RequiredItemId2` = 558973, `RequiredItemCount2` = 1 WHERE `ID` = 1660064;
