-- Terenthis (creature 3693, gossip_menu 6456 -> npc_text 3334) spells "Cenarion Circle" as
-- "Cenarian Circle" and "Night Elves" as "Night elves" (#13176).
UPDATE `npc_text`
SET `text0_0` = '$N, I\'ve come to find out how rampant the effects of Fel Moss are throughout Darkshore. The corruption of Teldrassil and our surrounding lands really concerns the druids of the Cenarion Circle, and all Night Elves.$B$BIt is my goal to find out why this has happened and to put an end to it.'
WHERE `ID` = 3334;
