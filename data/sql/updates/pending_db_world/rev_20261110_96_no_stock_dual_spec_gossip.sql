-- Ascension does not use the stock Dual Talent Specialization: specializations come from spec books and the
-- specialization swap spells. Class trainers still offered "I wish to know about Dual Talent Specialization."
-- (OptionType 20) and its 1000 gold "Purchase a Dual Talent Specialization" (OptionType 18), on every realm type.
DELETE FROM `gossip_menu_option` WHERE `OptionType` IN (18, 20);
