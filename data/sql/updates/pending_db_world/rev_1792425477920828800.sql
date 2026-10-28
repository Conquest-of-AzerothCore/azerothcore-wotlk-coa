DELETE FROM `command` WHERE `name` = 'raf';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('raf', 0, 'Recruit-A-Friend commands:\n.raf <CharacterName> - Invite an online player to permanent recruitment (Accept/Decline).\n.raf status - Show your direct recruits and their two-hour qualification progress.\n.raf rewards - List rewards and their status for this realm.\n.raf claim <reward_id> - Claim an eligible reward through in-game mail.\n.help raf - Show this command list.');
