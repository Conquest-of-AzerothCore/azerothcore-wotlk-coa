-- Celedorn's Bread (quest 175105), #10294: Aldaria, Sylana, Findan and Remmos each have their own creature
-- entry (164318/164319/164320/164321), but every one of their gossip-option scripts credited the same
-- RequiredNpcOrGo1=164318 target, so talking to one NPC four times completed the quest. Credit each NPC's own
-- entry and require all four distinct entries once each.
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 164318, `RequiredNpcOrGo2` = 164319, `RequiredNpcOrGo3` = 164320,
  `RequiredNpcOrGo4` = 164321, `RequiredNpcOrGoCount1` = 1, `RequiredNpcOrGoCount2` = 1,
  `RequiredNpcOrGoCount3` = 1, `RequiredNpcOrGoCount4` = 1 WHERE `ID` = 175105;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164318, 164319, 164320, 164321) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164318, 0, 0, 0, 62, 0, 100, 0, 1200398, 0, 0, 0, 0, 0, 33, 164318, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Aldaria - On Gossip Option 0 Selected - Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164319, 0, 0, 0, 62, 0, 100, 0, 1200399, 0, 0, 0, 0, 0, 33, 164319, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Sylana - On Gossip Option 0 Selected - Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164320, 0, 0, 0, 62, 0, 100, 0, 1200400, 0, 0, 0, 0, 0, 33, 164320, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Findan - On Gossip Option 0 Selected - Quest Credit Distribute Celedorn''s Enchanted Bread'),
(164321, 0, 0, 0, 62, 0, 100, 0, 1200401, 0, 0, 0, 0, 0, 33, 164321, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Remmos - On Gossip Option 0 Selected - Quest Credit Distribute Celedorn''s Enchanted Bread');
