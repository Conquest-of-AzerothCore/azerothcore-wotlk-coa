-- House of Nobles: the footage and realm chat give the answering lines to Lord Aldous Bruck (three) and Countess Cecilia
-- Clessington (one), in the order Servin, Bruck, Bruck, Clessington, Servin, Servin, Bruck (0MqPfOJqF8w 7:36, chat
-- "Lord Aldous Bruck says"). #8051 moved them to Feandor and Mortel; this keeps its voiced timing on the right speakers.
DELETE FROM `creature_text` WHERE `CreatureID` IN (164217, 164218);
DELETE FROM `creature_text` WHERE (`CreatureID` = 164211 AND `GroupID` IN (0, 1, 2)) OR (`CreatureID` = 164212 AND `GroupID` = 0);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164211, 0, 0, 'And we, I believe, have made ours clear, Lord Darengar.', 12, 0, 100, 0, 0, 215201, 0, 0, 'Lord Aldous Bruck'),
(164211, 1, 0, 'Even if there were unanimity, this council cannot simply march the army into Scadeald without the consent of House Coldmere.', 12, 0, 100, 0, 0, 215202, 0, 0, 'Lord Aldous Bruck'),
(164211, 2, 0, 'You are wasting your time barking up the wrong tree, Lord Darengar. Our laws exist for a reason. This session is adjourned.', 12, 0, 100, 0, 0, 215206, 0, 0, 'Lord Aldous Bruck'),
(164212, 0, 0, 'And do remember that it is the Coldmeres, and not yourself, who rule Scadeald.', 12, 0, 100, 0, 0, 215203, 0, 0, 'Countess Cecilia Clessington');

-- Voiced lines shipped in the client (sound\scadeald\*.wav, SoundEntries 215207-215226), matched to their chat lines by
-- transcript: Deirdre (bruja1, 4, 5), Lady Serenya Coldmere (senerya1, 2, 5-8) and the Sicklight loa story (loa1-7).
UPDATE `creature_text` SET `Sound` = 215212 WHERE `CreatureID` = 164005 AND `GroupID` = 3 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215213 WHERE `CreatureID` = 164005 AND `GroupID` = 4 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215216 WHERE `CreatureID` = 164005 AND `GroupID` = 5 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215217 WHERE `CreatureID` = 164005 AND `GroupID` = 6 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215218 WHERE `CreatureID` = 164005 AND `GroupID` = 7 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215219 WHERE `CreatureID` = 164005 AND `GroupID` = 8 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215207 WHERE `CreatureID` = 164355 AND `GroupID` = 1 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215210 WHERE `CreatureID` = 164355 AND `GroupID` = 2 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215211 WHERE `CreatureID` = 164355 AND `GroupID` = 3 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215220 WHERE `CreatureID` = 164806 AND `GroupID` = 0 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215221 WHERE `CreatureID` = 164806 AND `GroupID` = 1 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215222 WHERE `CreatureID` = 164806 AND `GroupID` = 2 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215223 WHERE `CreatureID` = 164806 AND `GroupID` = 3 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215224 WHERE `CreatureID` = 164806 AND `GroupID` = 4 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215225 WHERE `CreatureID` = 164806 AND `GroupID` = 5 AND `ID` = 0;
UPDATE `creature_text` SET `Sound` = 215226 WHERE `CreatureID` = 164806 AND `GroupID` = 6 AND `ID` = 0;
