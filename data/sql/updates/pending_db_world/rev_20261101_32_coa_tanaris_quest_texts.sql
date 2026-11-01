-- CoA Tanaris: the 15 quests rev_20261101_30_coa_tanaris_restore.sql restores had no progress or completion text,
-- so their turn-in windows opened empty. The client quest cache does not store them, and SUB, AscensionDB/Exiles,
-- CoA Tavern, the addons and Descension have none. The live lines below come from a live stream (YouTube
-- rEaTnfr2Ke4): the progress and completion texts of Sea Giant Fantasy 255036, Battery Salvage 255055 and Power
-- From Storms 255056, the completion texts of Nothing to Declare 255037 and Contractual Concern 982257, and the
-- progress text of Smoke on the Water 255048. Words the stream overlay hides are reconstructed: "hell" in the
-- progress text of 255036, "Snazzy" in the completion text of 255037, whose opening sentence the stream never
-- shows and is left out, and "Oh" and "sent ya," in the completion text of 982257. Every other text is a
-- placeholder, newly written to match its quest's description and giver until the original line is found: both
-- texts of 255028, 255029, 255041, 909041, 909042 and 982258, the completion texts of 255040, 255042, 909040 and
-- 255048, and the progress text of 255037. The Informant 255040, The Informant - Bloodsail's Ally 255042, Emergency
-- Measures 909040 and Contractual Concern 982257 have nothing to collect and get no progress text.

DELETE FROM `quest_request_items` WHERE `ID` IN (255028, 255029, 255036, 255037, 255041, 255048, 255055, 255056, 909041, 909042, 982258);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(255028, 0, 0, 'Well? Is that naga still slitherin'' around behind the ridge, $r?', 0),
(255029, 0, 0, 'Do you bring the ssssands, $r? Time ssslips away from usss with every moment you delay.', 0),
(255036, 0, 0, 'Of course it''ll still work if it got dragged ta hell. Don''t ya know goblin tech''s nothin'' if not reliable?!', 0),
(255037, 0, 0, 'You''re standin'' in my port, so I hope you''re here with good news. Did Snazzy''s goods reach the right hands?', 0),
(255041, 0, 0, 'You have news about that tannery, $N? Out with it.', 0),
(255048, 0, 0, 'You got my cigar shipment yet?', 0),
(255055, 0, 0, '<You''ll need to destroy that cloud serpent before you can get a good look at this battery.>', 0),
(255056, 0, 0, 'Found anything yet?', 0),
(909041, 0, 0, 'Did you find one? A real diary? Not a forgery. I will know, $N.', 0),
(909042, 0, 0, 'The ground still trembles beneath the dunes. They still feed.', 0),
(982258, 0, 0, 'The sand still calls. Have you faced the vortex?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (255028, 255029, 255036, 255037, 255040, 255041, 255042, 255048, 255055, 255056, 909040, 909041, 909042, 982257, 982258);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(255028, 0, 0, 0, 0, 0, 0, 0, 0, 'A talkin'' naga that just wants to be left alone? Long as it stays out of my water and away from my alchemists, it can sing sea shanties for all I care.$B$BGood work, $r. Here, ya earned this.', 0),
(255029, 0, 0, 0, 0, 0, 0, 0, 0, 'Yesss... I can feel the flow of time within it. Thisss is only the beginning, but it is more hope than my people have had in an age.$B$BAccept my gratitude, $r, and this token of it.', 0),
(255036, 0, 0, 0, 0, 0, 0, 0, 0, 'Right. It was a pleasure doing business with ya!$B$BGlad yer one of the understandin'' types, and with our stories straight I think we''ll be just fine.', 0),
(255037, 0, 0, 0, 0, 0, 0, 0, 0, 'Snazzy already filled me in. Who knew he was so good at slaying sea giants? Good thing he was there to save your hide huh?$B$BAnyways, great work. Maybe one day you''ll make a fine sailor. Or dock worker, not sure, just follow your dreams kid.', 0),
(255040, 0, 0, 0, 0, 0, 0, 0, 0, '<Arvon glances at the logbook in your hand and the color drains from his face.>$B$BWhere did you get that? Keep your voice down. Let''s talk about this like reasonable people.', 0),
(255041, 0, 0, 0, 0, 0, 0, 0, 0, 'A Bloodsail spy in my own port, running a tannery right under my nose! You have done Booty Bay a great service, $N. The Steamwheedle Cartel will not forget it.', 0),
(255042, 0, 0, 0, 0, 0, 0, 0, 0, 'Smart choice. Here''s your gold, as promised. You never saw that logbook, and I never saw you.', 0),
(255048, 0, 0, 0, 0, 0, 0, 0, 0, 'Now that''s what I''m talkin'' about! Dry, fresh, and not a single one missin''. You''re makin'' a habit of bein'' useful, kid. Here, for your trouble.', 0),
(255055, 0, 0, 0, 0, 0, 0, 0, 0, '<Upon closer inspection, the energy crackling from the battery seems to be close to fizzling out. Most likely its charge was absorbed by the creature you just fought. Renthar isn''t going to find much use in this in its current state.>', 0),
(255056, 0, 0, 0, 0, 0, 0, 0, 0, 'This was in the Zeppelin?! I don''t know what this thing was charged with, but I''ve never seen a battery like this before. It''s plenty powerful, a bit unstable actually, but I can keep it in check.$B$BHere''s your pay, I need to get this to my engineers.', 0),
(909040, 0, 0, 0, 0, 0, 0, 0, 0, 'An order from Bilgewhizzle, huh? Water for Gadgetzan, on the double. Fine, fine, I''ll get the barrels movin''. Thanks for haulin'' this all the way out here.', 0),
(909041, 0, 0, 0, 0, 0, 0, 0, 0, 'It''s real! Look at the handwriting, the salt stains, the little doodles of... oh my.$B$BThis is wonderful, $N. Truly. For research, of course. Take this, you have more than earned it.', 0),
(909042, 0, 0, 0, 0, 0, 0, 0, 0, 'The hollows grow quiet. The dunes breathe easier now.$B$BYou did what was needed. Take this, and remember that the desert remembers those who protect it.', 0),
(982257, 0, 0, 0, 0, 0, 0, 0, 0, 'Oh man, you was lookin'' for me? And Zebel sent ya, that''s not good, no no no, that''s really bad.$B$BI swear I wasn''t slackin''. It''s those damn sea giants, they turned aggressive and stole my damn radio! Please, you gotta understand!', 0),
(982258, 0, 0, 0, 0, 0, 0, 0, 0, 'It is still warm, as I said it would be. Hold it a moment longer... feel it shift. The desert speaks through it.$B$BThank you, $N.', 0);
