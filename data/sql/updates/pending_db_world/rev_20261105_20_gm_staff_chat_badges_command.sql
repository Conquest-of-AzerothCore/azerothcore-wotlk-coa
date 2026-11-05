DELETE FROM `command` WHERE `name` IN ('gm mod chat', 'gm cm chat');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('gm mod chat', 1, 'Syntax: .gm mod chat [on/off]\nShows the MOD badge in front of your name in chat (say, yell, whisper, party, raid, battleground, guild, officer and channels), or the current state if on/off is not given. Replaces .gm cm chat. Clients without the badge UI see <MOD> in front of the text. Resets on logout.'),
('gm cm chat', 1, 'Syntax: .gm cm chat [on/off]\nShows the CM (Community Manager) badge in front of your name in chat (say, yell, whisper, party, raid, battleground, guild, officer and channels), or the current state if on/off is not given. Replaces .gm mod chat. Clients without the badge UI see <CM> in front of the text. Resets on logout.');
