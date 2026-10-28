-- CoA/Ascension: restore hostile faction on starter-area mobs that should aggro on sight.
-- On the original CoA server these creatures attacked players; the AzerothCore baseline
-- ships them on passive factions -- most on faction 7 (Prey), and three on other factions
-- that are equally non-aggressive (no enemy group, no enemy factions):
--   Frostmane Troll Whelp (706) = faction 190, Grik'nir the Cold (808) = faction 2136,
--   Bristleback Quilboar (2952) = faction 189.
-- All 23 were verified passive against factiontemplate data. Changing to faction 14
-- (Monster) restores attack-on-sight behaviour.
-- Source: hertigservices/ascension-data (CoA preservation archive), issue #129
-- Shadowglen: Webwood Spider (1986), Githyiss the Vile (1994), Mangy Nightsaber (2032)
-- Northshire: Defias Thug (38), Garrick Padfoot (103)
-- Coldridge: Frostmane Troll Whelp (706), Grik'nir the Cold (808)
-- Deathknell: Night Web Spider (1505), Scarlet Convert (1506), Scarlet Initiate (1507), Meven Korgal (1667)
-- Valley of Trials: Scorpid Worker (3124), Vile Familiar (3101), Felstalker (3102), Yarrog Baneshadow (3183)
-- Camp Narache: Bristleback Quilboar (2952), Bristleback Shaman (2953), Chief Sharptusk Thornmantle (8554)
-- Azuremyst Isle: Blood Elf Scout (16521), Surveyor Candress (16522)
-- Sunstrider Isle: Arcane Wraith (15273), Tainted Arcane Wraith (15298), Felendren the Banished (15367)

UPDATE `creature_template` SET `faction` = 14 WHERE `entry` IN (1986, 1994, 2032, 38, 103, 706, 808, 1505, 1506, 1507, 1667, 3101, 3102, 3124, 3183, 2952, 2953, 8554, 16521, 16522, 15273, 15298, 15367);
