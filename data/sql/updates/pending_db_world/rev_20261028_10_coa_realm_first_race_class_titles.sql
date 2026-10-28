-- Realm First! Level 60 Night Elf Reaper (86207) and Realm First! Level 60 Undead Witch Hunter (86056)
-- have criteria but no `achievement_reward` row, so completing them never grants a title. CharTitles.dbc
-- confirms the title text each race implies: ID 115 "%s, Champion of Elune" (Alliance, Night Elf) and
-- ID 119 "%s the Forsaken" (Horde, Undead). Only the earning faction's column is set because the
-- achievement's own criterion (S_PLAYER_CLASS_RACE) already restricts it to that race.
DELETE FROM `achievement_reward` WHERE `ID` IN (86056, 86207);
INSERT INTO `achievement_reward` (`ID`, `TitleA`, `TitleH`, `ItemID`, `Sender`, `Subject`, `Body`,
    `MailTemplateID`) VALUES
(86056, 0, 119, 0, 0, NULL, NULL, 0), -- Realm First! Level 60 Undead Witch Hunter -> "%s the Forsaken"
(86207, 115, 0, 0, 0, NULL, NULL, 0); -- Realm First! Level 60 Night Elf Reaper -> "%s, Champion of Elune"
