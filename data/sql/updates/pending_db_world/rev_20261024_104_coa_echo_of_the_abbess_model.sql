-- Echo of the Abbess (161858): display 139062 is creature\Sitis\Sitis.m2 (CreatureModelData 112705) in both the
-- server and client DBC. The Northshire import's placeholder row and its 50% ghost copy 652007 used the bare
-- HumanMale model 49 instead, which renders untextured white.
UPDATE `creaturedisplayinfo_dbc` SET `ModelID` = 112705 WHERE `ID` IN (139062, 652007) AND `ModelID` = 49;
