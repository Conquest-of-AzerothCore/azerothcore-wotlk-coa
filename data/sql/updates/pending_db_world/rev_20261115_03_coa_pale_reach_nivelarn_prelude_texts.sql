-- Nivelarn prelude (175131-175137) progress and completion texts: the realm's English originals recorded by the
-- AscensionES addon (pEN/cEN); <hic> tags it strips are restored where the gap shows. 175136 and 175137 have no
-- objectives and no progress text.
DELETE FROM `quest_request_items` WHERE `ID` IN (175131, 175132, 175133, 175134, 175135);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(175131, 0, 0, '<A torn piece of paper, damp and half-buried in the snow.>', 0),
(175132, 1, 0, 'Yes? <Hic>. Can I... help you with somethin''?', 0),
(175133, 1, 0, 'How''d it go with the yaks?', 0),
(175134, 1, 0, 'Is it done? <Hic>. Good. Good, aye.', 0),
(175135, 1, 0, 'So you say Captain Mountaineer Kildar sent ye?', 0);

DELETE FROM `quest_offer_reward` WHERE `ID` IN (175131, 175132, 175133, 175134, 175135, 175136, 175137);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `Emote3`, `Emote4`, `EmoteDelay1`, `EmoteDelay2`, `EmoteDelay3`, `EmoteDelay4`, `RewardText`, `VerifiedBuild`) VALUES
(175131, 0, 0, 0, 0, 0, 0, 0, 0, '<An encrypted document; the text appears to be a random combination of letters and spaces, and does not correspond to any language or dialect you know.>$B$B<Judging by the surroundings, it is clear that this was the ambushers'' camp; a camp they had to dismantle in great haste.>', 0),
(175132, 1, 0, 0, 0, 0, 0, 0, 0, 'You... you weren''t sent by the innkeeper, were ye?$B$B<Gorlin listens to your story intently; or as intently as a drunkard can manage.>$B$BSo he did send ye, then, but not for his coin. Good. Good. Let me see that document; it can''t be that... that... hard to crack.', 0),
(175133, 1, 0, 0, 0, 0, 0, 0, 0, 'Ye were fast! Too fast! <Hic>. If I''d known, I''d have asked you for a few more favors.$B$BAnyway, I''m almost through. Give me just a moment; I want to double-check this translation...', 0),
(175134, 1, 0, 0, 0, 0, 0, 0, 0, '<Gorlin''s cheeks flush bright red for a moment before he bursts into laughter.>$B$BI... <hic>, I''m almost through. Yes...', 0),
(175135, 1, 0, 0, 0, 0, 0, 0, 0, 'Ye have rendered an invaluable service to Ironforge, friend.$B$BThat the ambushers took their orders from Dun Kazad is naught but confirmation of how vital our diplomatic work will be in the comin'' days.$B$BTogether, my cousin and I can lead the reunion between Ironforge and this city; a reunion the dwarven people so desperately need.$B$BAnd we shall succeed, on my honor, despite the schemin'' hand that conspires against us.', 0),
(175136, 1, 0, 0, 0, 0, 0, 0, 0, 'You come with the delegation, I assume.$B$B<The look the Thane of Dun Kazad gives you from beneath his thick, sprawling eyebrows reeks of cold authority, detached from worldly troubles.>$B$BSpare me your veiled accusations. The ambush Senator Thargas suffered was a tragic coincidence; no dwarf of honor in this city, of all places, would have conspired to kill a fellow dwarf.', 0),
(175137, 1, 0, 0, 0, 0, 0, 0, 0, '<Baugwolf listens to what you have to say and nods with impatience, a military and pragmatic haste.>$B$BI see, aye. Say no more. Dun Kazad has always been a quiet place; a refuge. But in recent times, the city has faced one crisis after another:$B$BThe Frostmane trolls and their invasion of the Kingsway; the Dark Iron incursions and their sabotages... and this convoy ye''re part of, with the resultin'' political earthquake.$B$BWork is as plenty as the troubles. The question is: will you measure up?', 0);

-- Bitter Legacy of the War (175131): the corpse's raid-boss whisper ran off the screen as one line; the centre-screen
-- frame does not wrap, so the text breaks between sentences.
DELETE FROM `creature_text` WHERE `CreatureID` = 164377 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164377, 0, 0, '<The body of a dwarf dressed in the colors and honors befitting an Ironforge diplomat.\nIt is curious; all the corpses belong to members of the diplomatic corps.\nDid not a single ambusher die? How, then, did the other survivors of the convoy escape?>', 42, 0, 100, 0, 0, 0, 0, 0, 'Ironforge Diplomatic - corpse inspected');
