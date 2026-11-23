-- Carden (164591) lies face-down beside his diary in the Cresthairn crypt. The realm's display 652974 is streamed and
-- absent locally; this rebuilds it from c3a0y5pCKpE 0:14:56, YzysjpunNbs 0:06:06 and i5vATMYui0I 0:53:48: yellow
-- hood, the Hallow Wind Initiates' gold tabard with its blue collar, gold-cuffed gauntlets. Legs and feet follow the
-- Initiates; the face and hair are hidden.
UPDATE `creature_display_preset` SET `race` = 1, `gender` = 0, `class` = 1, `skin` = 3, `face` = 8, `hair` = 6,
    `haircolor` = 4, `facialhair` = 4, `guild_id` = 0, `item_head` = 80034, `item_shoulders` = 0, `item_body` = 0,
    `item_chest` = 24528, `item_waist` = 0, `item_legs` = 2038, `item_feet` = 7504, `item_wrists` = 0,
    `item_hands` = 24531, `item_back` = 0, `item_tabard` = 0
    WHERE `entry` = 164591 AND `display_id` = 49;
