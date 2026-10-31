-- CoA Tanaris: the 15 quests rev_20261101_30_coa_tanaris_restore.sql restores had no progress or completion text,
-- so their turn-in windows opened empty. No capture of the original lines exists: the client quest cache does not
-- store them, and SUB, AscensionDB/Exiles, CoA Tavern, the addons and Descension have none. These are placeholder
-- texts, newly written to match each quest's description and giver, until the original lines are found.
-- The Informant 255040, The Informant - Bloodsail's Ally 255042, Emergency Measures 909040 and Contractual
-- Concern 982257 have nothing to collect and get no progress text.

DELETE FROM `quest_request_items` WHERE `ID` IN (255028, 255029, 255036, 255037, 255041, 255048, 255055, 255056, 909041, 909042, 982258);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(255028, 0, 0, 'Well? Is that naga still slitherin'' around behind the ridge, $r?', 0),
(255029, 0, 0, 'Do you bring the ssssands, $r? Time ssslips away from usss with every moment you delay.', 0),
(255036, 0, 0, 'Ya got my radio yet? Every minute it''s out there, Zebel gets a little closer ta findin'' out.', 0),
(255037, 0, 0, 'You''re standin'' in my port, so I hope you''re here with good news. Did Snazzy''s goods reach the right hands?', 0),
(255041, 0, 0, 'You have news about that tannery, $N? Out with it.', 0),
(255048, 0, 0, 'Tell me you got my cigars. Not soggy ones. Mine.', 0),
(255055, 0, 0, '<The battery sits wedged in the wreckage, but the storm serpent circling overhead will not let you work in peace.>', 0),
(255056, 0, 0, 'That battery isn''t going to charge itself. Did you find a way to wake it up?', 0),
(909041, 0, 0, 'Did you find one? A real diary? Not a forgery. I will know, $N.', 0),
(909042, 0, 0, 'The ground still trembles beneath the dunes. They still feed.', 0),
(982258, 0, 0, 'The sand still calls. Have you faced the vortex?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (255028, 255029, 255036, 255037, 255040, 255041, 255042, 255048, 255055, 255056, 909040, 909041, 909042, 982257, 982258);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(255028, 0, 0, 0, 0, 0, 0, 0, 0, 'A talkin'' naga that just wants to be left alone? Long as it stays out of my water and away from my alchemists, it can sing sea shanties for all I care.$B$BGood work, $r. Here, ya earned this.', 0),
(255029, 0, 0, 0, 0, 0, 0, 0, 0, 'Yesss... I can feel the flow of time within it. Thisss is only the beginning, but it is more hope than my people have had in an age.$B$BAccept my gratitude, $r, and this token of it.', 0),
(255036, 0, 0, 0, 0, 0, 0, 0, 0, 'My radio! Not a scratch on it... well, not a new scratch anyway. Ya saved my hide, pal.$B$BAnd remember: sea giants, a whole army of ''em, and I fought like a hero. Here''s yer cut.', 0),
(255037, 0, 0, 0, 0, 0, 0, 0, 0, 'So Snazzy''s been runnin'' a little side business on my coast, has he? And you were his delivery service.$B$BRelax, $r. The goods arrived, nobody got hurt, and I''m takin'' a cut from now on. Here''s your pay.', 0),
(255040, 0, 0, 0, 0, 0, 0, 0, 0, '<Arvon glances at the logbook in your hand and the color drains from his face.>$B$BWhere did you get that? Keep your voice down. Let''s talk about this like reasonable people.', 0),
(255041, 0, 0, 0, 0, 0, 0, 0, 0, 'A Bloodsail spy in my own port, running a tannery right under my nose! You have done Booty Bay a great service, $N. The Steamwheedle Cartel will not forget it.', 0),
(255042, 0, 0, 0, 0, 0, 0, 0, 0, 'Smart choice. Here''s your gold, as promised. You never saw that logbook, and I never saw you.', 0),
(255048, 0, 0, 0, 0, 0, 0, 0, 0, 'Now that''s what I''m talkin'' about! Dry, fresh, and not a single one missin''. You''re makin'' a habit of bein'' useful, kid. Here, for your trouble.', 0),
(255055, 0, 0, 0, 0, 0, 0, 0, 0, '<The battery is battered but intact. Its cells hold barely a flicker of charge. Renthar will not get far with it as it is.>', 0),
(255056, 0, 0, 0, 0, 0, 0, 0, 0, 'It''s humming! You actually charged it? With storm elementals? Actually, I don''t want to know.$B$BThis will get my rocket off the ground for sure. Here''s the gold I promised, and then some.', 0),
(909040, 0, 0, 0, 0, 0, 0, 0, 0, 'An order from Bilgewhizzle, huh? Water for Gadgetzan, on the double. Fine, fine, I''ll get the barrels movin''. Thanks for haulin'' this all the way out here.', 0),
(909041, 0, 0, 0, 0, 0, 0, 0, 0, 'It''s real! Look at the handwriting, the salt stains, the little doodles of... oh my.$B$BThis is wonderful, $N. Truly. For research, of course. Take this, you have more than earned it.', 0),
(909042, 0, 0, 0, 0, 0, 0, 0, 0, 'The hollows grow quiet. The dunes breathe easier now.$B$BYou did what was needed. Take this, and remember that the desert remembers those who protect it.', 0),
(982257, 0, 0, 0, 0, 0, 0, 0, 0, 'Zebel sent ya? Aw, sand and scales... Look, the coast is clear. I''ve been watchin'' real close. Mostly.$B$BJust... don''t tell him ya found me nappin'', aye?', 0),
(982258, 0, 0, 0, 0, 0, 0, 0, 0, 'It is still warm, as I said it would be. Hold it a moment longer... feel it shift. The desert speaks through it.$B$BThank you, $N.', 0);
