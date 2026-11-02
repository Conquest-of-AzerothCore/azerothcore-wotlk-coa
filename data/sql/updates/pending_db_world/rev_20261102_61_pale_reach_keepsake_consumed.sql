-- No Parent Should Bury Their Child (175041) hands out Abellon's Keepsake (559876) as its start item but never listed
-- it as a quest source item, so Player::RewardQuest left the buried keepsake in the bags after the turn-in (#10729).
UPDATE `quest_template` SET `ItemDrop1` = 559876, `ItemDropQuantity1` = 1 WHERE `ID` = 175041;
