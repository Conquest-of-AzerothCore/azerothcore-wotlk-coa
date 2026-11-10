-- Wardrobe cosmetic pet tokens (Beastmaster's Whistle, Summoner's Stone, Blood Soaked Vellum,
-- Draconic Warhorn, Elemental Lodestone) dropping where the db.exil.es export
-- (hertigservices/ascension-data release exiles-db-export-2026-09-13) shows them, at its chances.
-- The server keeps each token to the realm types that can use it (AscensionCompat OnItemRoll).
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (1849, 4950, 5348, 7143, 7144, 7146, 10161, 10321, 10388, 10389, 13743, 19759, 21928, 23427, 24138, 24217, 26536, 28220, 30960, 31142, 31813, 32467, 36070, 36473, 36474, 36475, 113743, 213743, 299222, 299224) AND `lootid` = 0;
DELETE FROM `creature_loot_template` WHERE (`Entry`=3 AND `Item`=85718) OR
  (`Entry`=30 AND `Item`=79317) OR
  (`Entry`=43 AND `Item`=79336) OR
  (`Entry`=48 AND `Item`=85719) OR
  (`Entry`=69 AND `Item`=79337) OR
  (`Entry`=113 AND `Item`=79345) OR
  (`Entry`=118 AND `Item`=79346) OR
  (`Entry`=193 AND `Item`=1180107) OR
  (`Entry`=202 AND `Item`=85720) OR
  (`Entry`=203 AND `Item`=85721) OR
  (`Entry`=210 AND `Item`=85722) OR
  (`Entry`=213 AND `Item`=79351) OR
  (`Entry`=217 AND `Item`=79352) OR
  (`Entry`=299 AND `Item`=79353) OR
  (`Entry`=314 AND `Item`=85723) OR
  (`Entry`=330 AND `Item`=79354) OR
  (`Entry`=335 AND `Item`=1180109) OR
  (`Entry`=345 AND `Item`=79355) OR
  (`Entry`=390 AND `Item`=79356) OR
  (`Entry`=412 AND `Item`=85745) OR
  (`Entry`=428 AND `Item`=79357) OR
  (`Entry`=441 AND `Item`=1180111) OR
  (`Entry`=442 AND `Item`=79358) OR
  (`Entry`=471 AND `Item`=79361) OR
  (`Entry`=503 AND `Item`=85746) OR
  (`Entry`=505 AND `Item`=79362) OR
  (`Entry`=511 AND `Item`=85747) OR
  (`Entry`=521 AND `Item`=79363) OR
  (`Entry`=522 AND `Item`=85753) OR
  (`Entry`=524 AND `Item`=79364) OR
  (`Entry`=525 AND `Item`=79365) OR
  (`Entry`=531 AND `Item`=85775) OR
  (`Entry`=539 AND `Item`=79366) OR
  (`Entry`=565 AND `Item`=79368) OR
  (`Entry`=569 AND `Item`=79369) OR
  (`Entry`=570 AND `Item`=85779) OR
  (`Entry`=572 AND `Item`=85855) OR
  (`Entry`=574 AND `Item`=79370) OR
  (`Entry`=604 AND `Item`=85856) OR
  (`Entry`=616 AND `Item`=79371) OR
  (`Entry`=623 AND `Item`=85858) OR
  (`Entry`=624 AND `Item`=85859) OR
  (`Entry`=625 AND `Item`=85860) OR
  (`Entry`=626 AND `Item`=85872) OR
  (`Entry`=628 AND `Item`=79372) OR
  (`Entry`=681 AND `Item`=79373) OR
  (`Entry`=682 AND `Item`=79374) OR
  (`Entry`=683 AND `Item`=79375) OR
  (`Entry`=684 AND `Item`=79376) OR
  (`Entry`=685 AND `Item`=79377) OR
  (`Entry`=686 AND `Item`=79378) OR
  (`Entry`=687 AND `Item`=79379) OR
  (`Entry`=691 AND `Item`=600369) OR
  (`Entry`=704 AND `Item`=79380) OR
  (`Entry`=705 AND `Item`=79381) OR
  (`Entry`=708 AND `Item`=79382) OR
  (`Entry`=728 AND `Item`=79383) OR
  (`Entry`=729 AND `Item`=79384) OR
  (`Entry`=730 AND `Item`=79385) OR
  (`Entry`=731 AND `Item`=79386) OR
  (`Entry`=736 AND `Item`=79387) OR
  (`Entry`=740 AND `Item`=1180113) OR
  (`Entry`=741 AND `Item`=1180115) OR
  (`Entry`=742 AND `Item`=1180117) OR
  (`Entry`=743 AND `Item`=1180119) OR
  (`Entry`=744 AND `Item`=1180121) OR
  (`Entry`=745 AND `Item`=1180122) OR
  (`Entry`=746 AND `Item`=1180124) OR
  (`Entry`=764 AND `Item`=601024) OR
  (`Entry`=765 AND `Item`=601025) OR
  (`Entry`=766 AND `Item`=601026) OR
  (`Entry`=767 AND `Item`=79388) OR
  (`Entry`=768 AND `Item`=79389) OR
  (`Entry`=769 AND `Item`=79390) OR
  (`Entry`=771 AND `Item`=85873) OR
  (`Entry`=772 AND `Item`=79391) OR
  (`Entry`=785 AND `Item`=85874) OR
  (`Entry`=787 AND `Item`=85876) OR
  (`Entry`=822 AND `Item`=79392) OR
  (`Entry`=846 AND `Item`=85877) OR
  (`Entry`=854 AND `Item`=79397) OR
  (`Entry`=855 AND `Item`=79398) OR
  (`Entry`=856 AND `Item`=79399) OR
  (`Entry`=858 AND `Item`=79400) OR
  (`Entry`=922 AND `Item`=79401) OR
  (`Entry`=923 AND `Item`=79402) OR
  (`Entry`=930 AND `Item`=79403) OR
  (`Entry`=948 AND `Item`=85878) OR
  (`Entry`=949 AND `Item`=79404) OR
  (`Entry`=976 AND `Item`=79407) OR
  (`Entry`=977 AND `Item`=79408) OR
  (`Entry`=1015 AND `Item`=79409) OR
  (`Entry`=1015 AND `Item`=79410) OR
  (`Entry`=1016 AND `Item`=79409) OR
  (`Entry`=1016 AND `Item`=79410) OR
  (`Entry`=1017 AND `Item`=79411) OR
  (`Entry`=1018 AND `Item`=79412) OR
  (`Entry`=1019 AND `Item`=79413) OR
  (`Entry`=1020 AND `Item`=79414) OR
  (`Entry`=1020 AND `Item`=79415) OR
  (`Entry`=1021 AND `Item`=79414) OR
  (`Entry`=1021 AND `Item`=79415) OR
  (`Entry`=1022 AND `Item`=79416) OR
  (`Entry`=1022 AND `Item`=79417) OR
  (`Entry`=1023 AND `Item`=79416) OR
  (`Entry`=1023 AND `Item`=79417) OR
  (`Entry`=1039 AND `Item`=601027) OR
  (`Entry`=1040 AND `Item`=601028) OR
  (`Entry`=1041 AND `Item`=601029) OR
  (`Entry`=1042 AND `Item`=1180126) OR
  (`Entry`=1043 AND `Item`=1180130) OR
  (`Entry`=1044 AND `Item`=1180132) OR
  (`Entry`=1045 AND `Item`=1180134) OR
  (`Entry`=1046 AND `Item`=1180137) OR
  (`Entry`=1047 AND `Item`=1180140) OR
  (`Entry`=1048 AND `Item`=1180142) OR
  (`Entry`=1063 AND `Item`=1180151) OR
  (`Entry`=1069 AND `Item`=1180153) OR
  (`Entry`=1081 AND `Item`=601030) OR
  (`Entry`=1082 AND `Item`=79418) OR
  (`Entry`=1084 AND `Item`=79419) OR
  (`Entry`=1085 AND `Item`=79420) OR
  (`Entry`=1087 AND `Item`=79421) OR
  (`Entry`=1088 AND `Item`=79422) OR
  (`Entry`=1108 AND `Item`=79423) OR
  (`Entry`=1110 AND `Item`=85879) OR
  (`Entry`=1111 AND `Item`=79425) OR
  (`Entry`=1112 AND `Item`=79426) OR
  (`Entry`=1114 AND `Item`=79427) OR
  (`Entry`=1125 AND `Item`=79428) OR
  (`Entry`=1126 AND `Item`=79429) OR
  (`Entry`=1127 AND `Item`=79430) OR
  (`Entry`=1128 AND `Item`=79431) OR
  (`Entry`=1129 AND `Item`=79432) OR
  (`Entry`=1130 AND `Item`=79433) OR
  (`Entry`=1131 AND `Item`=79434) OR
  (`Entry`=1132 AND `Item`=79435) OR
  (`Entry`=1133 AND `Item`=79436) OR
  (`Entry`=1138 AND `Item`=79437) OR
  (`Entry`=1140 AND `Item`=79438) OR
  (`Entry`=1152 AND `Item`=79441) OR
  (`Entry`=1184 AND `Item`=79442) OR
  (`Entry`=1185 AND `Item`=79443) OR
  (`Entry`=1186 AND `Item`=79444) OR
  (`Entry`=1188 AND `Item`=79445) OR
  (`Entry`=1189 AND `Item`=79446) OR
  (`Entry`=1190 AND `Item`=79447) OR
  (`Entry`=1191 AND `Item`=79448) OR
  (`Entry`=1192 AND `Item`=79449) OR
  (`Entry`=1194 AND `Item`=79450) OR
  (`Entry`=1195 AND `Item`=79451) OR
  (`Entry`=1196 AND `Item`=79452) OR
  (`Entry`=1199 AND `Item`=79453) OR
  (`Entry`=1201 AND `Item`=79454) OR
  (`Entry`=1225 AND `Item`=79456) OR
  (`Entry`=1258 AND `Item`=79457) OR
  (`Entry`=1270 AND `Item`=85880) OR
  (`Entry`=1353 AND `Item`=79458) OR
  (`Entry`=1400 AND `Item`=79459) OR
  (`Entry`=1417 AND `Item`=79460) OR
  (`Entry`=1488 AND `Item`=85881) OR
  (`Entry`=1489 AND `Item`=85934) OR
  (`Entry`=1502 AND `Item`=85965) OR
  (`Entry`=1504 AND `Item`=79461) OR
  (`Entry`=1505 AND `Item`=79462) OR
  (`Entry`=1508 AND `Item`=79463) OR
  (`Entry`=1509 AND `Item`=79464) OR
  (`Entry`=1512 AND `Item`=79465) OR
  (`Entry`=1513 AND `Item`=79466) OR
  (`Entry`=1520 AND `Item`=85966) OR
  (`Entry`=1522 AND `Item`=85967) OR
  (`Entry`=1523 AND `Item`=85968) OR
  (`Entry`=1525 AND `Item`=85969) OR
  (`Entry`=1526 AND `Item`=85970) OR
  (`Entry`=1527 AND `Item`=85971) OR
  (`Entry`=1528 AND `Item`=86008) OR
  (`Entry`=1529 AND `Item`=86072) OR
  (`Entry`=1530 AND `Item`=86077) OR
  (`Entry`=1531 AND `Item`=86078) OR
  (`Entry`=1533 AND `Item`=86085) OR
  (`Entry`=1534 AND `Item`=86101) OR
  (`Entry`=1547 AND `Item`=601716) OR
  (`Entry`=1553 AND `Item`=79467) OR
  (`Entry`=1554 AND `Item`=79468) OR
  (`Entry`=1555 AND `Item`=79469) OR
  (`Entry`=1557 AND `Item`=79470) OR
  (`Entry`=1558 AND `Item`=79471) OR
  (`Entry`=1559 AND `Item`=79472) OR
  (`Entry`=1654 AND `Item`=86102) OR
  (`Entry`=1655 AND `Item`=86103) OR
  (`Entry`=1656 AND `Item`=86104) OR
  (`Entry`=1657 AND `Item`=86105) OR
  (`Entry`=1658 AND `Item`=86106) OR
  (`Entry`=1688 AND `Item`=79473) OR
  (`Entry`=1689 AND `Item`=79474) OR
  (`Entry`=1693 AND `Item`=79475) OR
  (`Entry`=1713 AND `Item`=79476) OR
  (`Entry`=1765 AND `Item`=79477) OR
  (`Entry`=1766 AND `Item`=79478) OR
  (`Entry`=1778 AND `Item`=79479) OR
  (`Entry`=1780 AND `Item`=79480) OR
  (`Entry`=1781 AND `Item`=79481) OR
  (`Entry`=1783 AND `Item`=86107) OR
  (`Entry`=1784 AND `Item`=86108) OR
  (`Entry`=1785 AND `Item`=86109) OR
  (`Entry`=1787 AND `Item`=86423) OR
  (`Entry`=1788 AND `Item`=86424) OR
  (`Entry`=1789 AND `Item`=86426) OR
  (`Entry`=1791 AND `Item`=86466) OR
  (`Entry`=1793 AND `Item`=86474) OR
  (`Entry`=1794 AND `Item`=86475) OR
  (`Entry`=1795 AND `Item`=86488) OR
  (`Entry`=1796 AND `Item`=86506) OR
  (`Entry`=1797 AND `Item`=79482) OR
  (`Entry`=1802 AND `Item`=86528) OR
  (`Entry`=1804 AND `Item`=86530) OR
  (`Entry`=1805 AND `Item`=86531) OR
  (`Entry`=1809 AND `Item`=79483) OR
  (`Entry`=1812 AND `Item`=601032) OR
  (`Entry`=1813 AND `Item`=601033) OR
  (`Entry`=1815 AND `Item`=79484) OR
  (`Entry`=1816 AND `Item`=79485) OR
  (`Entry`=1817 AND `Item`=79486) OR
  (`Entry`=1821 AND `Item`=79487) OR
  (`Entry`=1822 AND `Item`=79488) OR
  (`Entry`=1824 AND `Item`=79489) OR
  (`Entry`=1847 AND `Item`=86535) OR
  (`Entry`=1849 AND `Item`=86543) OR
  (`Entry`=1850 AND `Item`=86555) OR
  (`Entry`=1851 AND `Item`=601034) OR
  (`Entry`=1865 AND `Item`=86556) OR
  (`Entry`=1866 AND `Item`=86557) OR
  (`Entry`=1868 AND `Item`=87207) OR
  (`Entry`=1869 AND `Item`=87211) OR
  (`Entry`=1870 AND `Item`=87255) OR
  (`Entry`=1890 AND `Item`=87479) OR
  (`Entry`=1916 AND `Item`=87480) OR
  (`Entry`=1917 AND `Item`=87481) OR
  (`Entry`=1918 AND `Item`=87482) OR
  (`Entry`=1919 AND `Item`=87483) OR
  (`Entry`=1922 AND `Item`=79490) OR
  (`Entry`=1923 AND `Item`=79491) OR
  (`Entry`=1953 AND `Item`=601035) OR
  (`Entry`=1954 AND `Item`=601036) OR
  (`Entry`=1955 AND `Item`=601037) OR
  (`Entry`=1956 AND `Item`=601038) OR
  (`Entry`=1961 AND `Item`=79492) OR
  (`Entry`=1971 AND `Item`=87563) OR
  (`Entry`=1973 AND `Item`=87564) OR
  (`Entry`=1974 AND `Item`=87567) OR
  (`Entry`=1983 AND `Item`=87568) OR
  (`Entry`=1984 AND `Item`=79493) OR
  (`Entry`=1985 AND `Item`=79494) OR
  (`Entry`=1986 AND `Item`=79495) OR
  (`Entry`=1994 AND `Item`=79496) OR
  (`Entry`=1995 AND `Item`=79497) OR
  (`Entry`=1996 AND `Item`=79498) OR
  (`Entry`=1997 AND `Item`=79499) OR
  (`Entry`=1998 AND `Item`=79500) OR
  (`Entry`=1999 AND `Item`=79501) OR
  (`Entry`=2000 AND `Item`=79502) OR
  (`Entry`=2001 AND `Item`=79503) OR
  (`Entry`=2022 AND `Item`=601039) OR
  (`Entry`=2025 AND `Item`=601040) OR
  (`Entry`=2027 AND `Item`=601041) OR
  (`Entry`=2029 AND `Item`=601042) OR
  (`Entry`=2030 AND `Item`=601043) OR
  (`Entry`=2031 AND `Item`=79504) OR
  (`Entry`=2032 AND `Item`=79505) OR
  (`Entry`=2033 AND `Item`=79506) OR
  (`Entry`=2034 AND `Item`=79507) OR
  (`Entry`=2038 AND `Item`=82350) OR
  (`Entry`=2042 AND `Item`=79508) OR
  (`Entry`=2043 AND `Item`=79509) OR
  (`Entry`=2069 AND `Item`=79510) OR
  (`Entry`=2070 AND `Item`=79511) OR
  (`Entry`=2071 AND `Item`=79512) OR
  (`Entry`=2089 AND `Item`=79516) OR
  (`Entry`=2156 AND `Item`=601667) OR
  (`Entry`=2157 AND `Item`=601668) OR
  (`Entry`=2163 AND `Item`=79517) OR
  (`Entry`=2165 AND `Item`=79518) OR
  (`Entry`=2166 AND `Item`=601044) OR
  (`Entry`=2172 AND `Item`=79519) OR
  (`Entry`=2175 AND `Item`=79520) OR
  (`Entry`=2176 AND `Item`=87644) OR
  (`Entry`=2177 AND `Item`=87645) OR
  (`Entry`=2178 AND `Item`=87653) OR
  (`Entry`=2231 AND `Item`=79521) OR
  (`Entry`=2232 AND `Item`=79522) OR
  (`Entry`=2233 AND `Item`=79523) OR
  (`Entry`=2234 AND `Item`=79524) OR
  (`Entry`=2235 AND `Item`=79525) OR
  (`Entry`=2236 AND `Item`=79526) OR
  (`Entry`=2237 AND `Item`=79527) OR
  (`Entry`=2283 AND `Item`=87654) OR
  (`Entry`=2321 AND `Item`=79528) OR
  (`Entry`=2322 AND `Item`=79529) OR
  (`Entry`=2323 AND `Item`=79530) OR
  (`Entry`=2348 AND `Item`=79531);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(3, 85718, 0, 0.1, 0, 1, 0, 1, 1, 'Flesh Eater - Blood Soaked Vellum: Flesh Eater'),
(30, 79317, 0, 1, 0, 1, 0, 1, 1, 'Forest Spider - Beastmaster''s Whistle: Forest Spider'),
(43, 79336, 0, 1, 0, 1, 0, 1, 1, 'Mine Spider - Beastmaster''s Whistle: Mine Spider'),
(48, 85719, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Warrior - Blood Soaked Vellum: Skeletal Warrior'),
(69, 79337, 0, 1, 0, 1, 0, 1, 1, 'Timber Wolf - Beastmaster''s Whistle: Timber Wolf'),
(113, 79345, 0, 1, 0, 1, 0, 1, 1, 'Stonetusk Boar - Beastmaster''s Whistle: Stonetusk Boar'),
(118, 79346, 0, 1, 0, 1, 0, 1, 1, 'Prowler - Beastmaster''s Whistle: Prowler'),
(193, 1180107, 0, 1, 0, 1, 0, 1, 1, 'Blue Dragonspawn - Draconic Warhorn: Blue Dragonspawn'),
(202, 85720, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Horror - Blood Soaked Vellum: Skeletal Horror'),
(203, 85721, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Mage - Blood Soaked Vellum: Skeletal Mage'),
(210, 85722, 0, 0.1, 0, 1, 0, 1, 1, 'Bone Chewer - Blood Soaked Vellum: Bone Chewer'),
(213, 79351, 0, 1, 0, 1, 0, 1, 1, 'Starving Dire Wolf - Beastmaster''s Whistle: Starving Dire Wolf'),
(217, 79352, 0, 1, 0, 1, 0, 1, 1, 'Venom Web Spider - Beastmaster''s Whistle: Venom Web Spider'),
(299, 79353, 0, 1, 0, 1, 0, 1, 1, 'Young Wolf - Beastmaster''s Whistle: Young Wolf'),
(314, 85723, 0, 0.1, 0, 1, 0, 1, 1, 'Eliza - Blood Soaked Vellum: Eliza'),
(330, 79354, 0, 1, 0, 1, 0, 1, 1, 'Princess - Beastmaster''s Whistle: Princess'),
(335, 1180109, 0, 1, 0, 1, 0, 1, 1, 'Singe - Draconic Warhorn: Singe'),
(345, 79355, 0, 1, 0, 1, 0, 1, 1, 'Bellygrub - Beastmaster''s Whistle: Bellygrub'),
(390, 79356, 0, 1, 0, 1, 0, 1, 1, 'Porcine Entourage - Beastmaster''s Whistle: Porcine Entourage'),
(412, 85745, 0, 0.1, 0, 1, 0, 1, 1, 'Stitches - Blood Soaked Vellum: Stitches'),
(428, 79357, 0, 1, 0, 1, 0, 1, 1, 'Dire Condor - Beastmaster''s Whistle: Dire Condor'),
(441, 1180111, 0, 1, 0, 1, 0, 1, 1, 'Black Dragon Whelp - Draconic Warhorn: Black Dragon Whelp'),
(442, 79358, 0, 1, 0, 1, 0, 1, 1, 'Tarantula - Beastmaster''s Whistle: Tarantula'),
(471, 79361, 0, 1, 0, 1, 0, 1, 1, 'Mother Fang - Beastmaster''s Whistle: Mother Fang'),
(503, 85746, 0, 0.1, 0, 1, 0, 1, 1, 'Lord Malathrom - Blood Soaked Vellum: Lord Malathrom'),
(505, 79362, 0, 1, 0, 1, 0, 1, 1, 'Greater Tarantula - Beastmaster''s Whistle: Greater Tarantula'),
(511, 85747, 0, 0.1, 0, 1, 0, 1, 1, 'Insane Ghoul - Blood Soaked Vellum: Insane Ghoul'),
(521, 79363, 0, 1, 0, 1, 0, 1, 1, 'Lupos - Beastmaster''s Whistle: Lupos'),
(522, 85753, 0, 0.1, 0, 1, 0, 1, 1, 'Mor''Ladim - Blood Soaked Vellum: Mor''Ladim'),
(524, 79364, 0, 1, 0, 1, 0, 1, 1, 'Rockhide Boar - Beastmaster''s Whistle: Rockhide Boar'),
(525, 79365, 0, 1, 0, 1, 0, 1, 1, 'Mangy Wolf - Beastmaster''s Whistle: Mangy Wolf'),
(531, 85775, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Fiend - Blood Soaked Vellum: Skeletal Fiend'),
(539, 79366, 0, 1, 0, 1, 0, 1, 1, 'Pygmy Venom Web Spider - Beastmaster''s Whistle: Pygmy Venom Web Spider'),
(565, 79368, 0, 1, 0, 1, 0, 1, 1, 'Rabid Dire Wolf - Beastmaster''s Whistle: Rabid Dire Wolf'),
(569, 79369, 0, 1, 0, 1, 0, 1, 1, 'Green Recluse - Beastmaster''s Whistle: Green Recluse'),
(570, 85779, 0, 0.1, 0, 1, 0, 1, 1, 'Brain Eater - Blood Soaked Vellum: Brain Eater'),
(572, 85855, 0, 0.1, 0, 1, 0, 1, 1, 'Leprithus - Blood Soaked Vellum: Leprithus'),
(574, 79370, 0, 1, 0, 1, 0, 1, 1, 'Naraxis - Beastmaster''s Whistle: Naraxis'),
(604, 85856, 0, 0.1, 0, 1, 0, 1, 1, 'Plague Spreader - Blood Soaked Vellum: Plague Spreader'),
(616, 79371, 0, 1, 0, 1, 0, 1, 1, 'Chatter - Beastmaster''s Whistle: Chatter'),
(623, 85858, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Miner - Blood Soaked Vellum: Skeletal Miner'),
(624, 85859, 0, 0.1, 0, 1, 0, 1, 1, 'Undead Excavator - Blood Soaked Vellum: Undead Excavator'),
(625, 85860, 0, 0.1, 0, 1, 0, 1, 1, 'Undead Dynamiter - Blood Soaked Vellum: Undead Dynamiter'),
(626, 85872, 0, 0.1, 0, 1, 0, 1, 1, 'Foreman Thistlenettle - Blood Soaked Vellum: Foreman Thistlenettle'),
(628, 79372, 0, 1, 0, 1, 0, 1, 1, 'Black Ravager - Beastmaster''s Whistle: Black Ravager'),
(681, 79373, 0, 1, 0, 1, 0, 1, 1, 'Young Stranglethorn Tiger - Beastmaster''s Whistle: Young Stranglethorn Tiger'),
(682, 79374, 0, 1, 0, 1, 0, 1, 1, 'Stranglethorn Tiger - Beastmaster''s Whistle: Stranglethorn Tiger'),
(683, 79375, 0, 1, 0, 1, 0, 1, 1, 'Young Panther - Beastmaster''s Whistle: Young Panther'),
(684, 79376, 0, 1, 0, 1, 0, 1, 1, 'Shadowmaw Panther - Beastmaster''s Whistle: Shadowmaw Panther'),
(685, 79377, 0, 1, 0, 1, 0, 1, 1, 'Stranglethorn Raptor - Beastmaster''s Whistle: Stranglethorn Raptor'),
(686, 79378, 0, 1, 0, 1, 0, 1, 1, 'Lashtail Raptor - Beastmaster''s Whistle: Lashtail Raptor'),
(687, 79379, 0, 1, 0, 1, 0, 1, 1, 'Jungle Stalker - Beastmaster''s Whistle: Jungle Stalker'),
(691, 600369, 0, 1, 0, 1, 0, 1, 1, 'Lesser Water Elemental - Elemental Lodestone: Lesser Water Elemental'),
(704, 79380, 0, 1, 0, 1, 0, 1, 1, 'Ragged Timber Wolf - Beastmaster''s Whistle: Ragged Timber Wolf'),
(705, 79381, 0, 1, 0, 1, 0, 1, 1, 'Ragged Young Wolf - Beastmaster''s Whistle: Ragged Young Wolf'),
(708, 79382, 0, 1, 0, 1, 0, 1, 1, 'Small Crag Boar - Beastmaster''s Whistle: Small Crag Boar'),
(728, 79383, 0, 1, 0, 1, 0, 1, 1, 'Bhag''thera - Beastmaster''s Whistle: Bhag''thera'),
(729, 79384, 0, 1, 0, 1, 0, 1, 1, 'Sin''Dall - Beastmaster''s Whistle: Sin''Dall'),
(730, 79385, 0, 1, 0, 1, 0, 1, 1, 'Tethis - Beastmaster''s Whistle: Tethis'),
(731, 79386, 0, 1, 0, 1, 0, 1, 1, 'King Bangalash - Beastmaster''s Whistle: King Bangalash'),
(736, 79387, 0, 1, 0, 1, 0, 1, 1, 'Panther - Beastmaster''s Whistle: Panther'),
(740, 1180113, 0, 1, 0, 1, 0, 1, 1, 'Adolescent Whelp - Draconic Warhorn: Adolescent Whelp'),
(741, 1180115, 0, 1, 0, 1, 0, 1, 1, 'Dreaming Whelp - Draconic Warhorn: Dreaming Whelp'),
(742, 1180117, 0, 1, 0, 1, 0, 1, 1, 'Green Wyrmkin - Draconic Warhorn: Green Wyrmkin'),
(743, 1180119, 0, 1, 0, 1, 0, 1, 1, 'Wyrmkin Dreamwalker - Draconic Warhorn: Wyrmkin Dreamwalker'),
(744, 1180121, 0, 1, 0, 1, 0, 1, 1, 'Green Scalebane - Draconic Warhorn: Green Scalebane'),
(745, 1180122, 0, 1, 0, 1, 0, 1, 1, 'Scalebane Captain - Draconic Warhorn: Scalebane Captain'),
(746, 1180124, 0, 1, 0, 1, 0, 1, 1, 'Elder Dragonkin - Draconic Warhorn: Elder Dragonkin'),
(764, 601024, 0, 1, 0, 1, 0, 1, 1, 'Swampwalker - Elemental Lodestone: Swampwalker'),
(765, 601025, 0, 1, 0, 1, 0, 1, 1, 'Swampwalker Elder - Elemental Lodestone: Swampwalker Elder'),
(766, 601026, 0, 1, 0, 1, 0, 1, 1, 'Tangled Horror - Elemental Lodestone: Tangled Horror'),
(767, 79388, 0, 1, 0, 1, 0, 1, 1, 'Swamp Jaguar - Beastmaster''s Whistle: Swamp Jaguar'),
(768, 79389, 0, 1, 0, 1, 0, 1, 1, 'Shadow Panther - Beastmaster''s Whistle: Shadow Panther'),
(769, 79390, 0, 1, 0, 1, 0, 1, 1, 'Deathstrike Tarantula - Beastmaster''s Whistle: Deathstrike Tarantula'),
(771, 85873, 0, 0.1, 0, 1, 0, 1, 1, 'Commander Felstrom - Blood Soaked Vellum: Commander Felstrom'),
(772, 79391, 0, 1, 0, 1, 0, 1, 1, 'Stranglethorn Tigress - Beastmaster''s Whistle: Stranglethorn Tigress'),
(785, 85874, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Warder - Blood Soaked Vellum: Skeletal Warder'),
(787, 85876, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Healer - Blood Soaked Vellum: Skeletal Healer'),
(822, 79392, 0, 1, 0, 1, 0, 1, 1, 'Young Forest Bear - Beastmaster''s Whistle: Young Forest Bear'),
(846, 85877, 0, 0.1, 0, 1, 0, 1, 1, 'Ghoul - Blood Soaked Vellum: Ghoul'),
(854, 79397, 0, 1, 0, 1, 0, 1, 1, 'Young Jungle Stalker - Beastmaster''s Whistle: Young Jungle Stalker'),
(855, 79398, 0, 1, 0, 1, 0, 1, 1, 'Young Stranglethorn Raptor - Beastmaster''s Whistle: Young Stranglethorn Raptor'),
(856, 79399, 0, 1, 0, 1, 0, 1, 1, 'Young Lashtail Raptor - Beastmaster''s Whistle: Young Lashtail Raptor'),
(858, 79400, 0, 1, 0, 1, 0, 1, 1, 'Sorrow Spinner - Beastmaster''s Whistle: Sorrow Spinner'),
(922, 79401, 0, 1, 0, 1, 0, 1, 1, 'Silt Crawler - Beastmaster''s Whistle: Silt Crawler'),
(923, 79402, 0, 1, 0, 1, 0, 1, 1, 'Young Black Ravager - Beastmaster''s Whistle: Young Black Ravager'),
(930, 79403, 0, 1, 0, 1, 0, 1, 1, 'Black Widow Hatchling - Beastmaster''s Whistle: Black Widow Hatchling'),
(948, 85878, 0, 0.1, 0, 1, 0, 1, 1, 'Rotted One - Blood Soaked Vellum: Rotted One'),
(949, 79404, 0, 1, 0, 1, 0, 1, 1, 'Carrion Recluse - Beastmaster''s Whistle: Carrion Recluse'),
(976, 79407, 0, 1, 0, 1, 0, 1, 1, 'Kurzen War Tiger - Beastmaster''s Whistle: Kurzen War Tiger'),
(977, 79408, 0, 1, 0, 1, 0, 1, 1, 'Kurzen War Panther - Beastmaster''s Whistle: Kurzen War Panther'),
(1015, 79409, 0, 1, 0, 1, 0, 1, 1, 'Highland Raptor - Beastmaster''s Whistle: Highland Raptor'),
(1015, 79410, 0, 1, 0, 1, 0, 1, 1, 'Highland Raptor - Beastmaster''s Whistle: Highland Lashtail'),
(1016, 79409, 0, 1, 0, 1, 0, 1, 1, 'Highland Lashtail - Beastmaster''s Whistle: Highland Raptor'),
(1016, 79410, 0, 1, 0, 1, 0, 1, 1, 'Highland Lashtail - Beastmaster''s Whistle: Highland Lashtail'),
(1017, 79411, 0, 1, 0, 1, 0, 1, 1, 'Highland Scytheclaw - Beastmaster''s Whistle: Highland Scytheclaw'),
(1018, 79412, 0, 1, 0, 1, 0, 1, 1, 'Highland Razormaw - Beastmaster''s Whistle: Highland Razormaw'),
(1019, 79413, 0, 1, 0, 1, 0, 1, 1, 'Elder Razormaw - Beastmaster''s Whistle: Elder Razormaw'),
(1020, 79414, 0, 1, 0, 1, 0, 1, 1, 'Mottled Raptor - Beastmaster''s Whistle: Mottled Raptor'),
(1020, 79415, 0, 1, 0, 1, 0, 1, 1, 'Mottled Raptor - Beastmaster''s Whistle: Mottled Screecher'),
(1021, 79414, 0, 1, 0, 1, 0, 1, 1, 'Mottled Screecher - Beastmaster''s Whistle: Mottled Raptor'),
(1021, 79415, 0, 1, 0, 1, 0, 1, 1, 'Mottled Screecher - Beastmaster''s Whistle: Mottled Screecher'),
(1022, 79416, 0, 1, 0, 1, 0, 1, 1, 'Mottled Scytheclaw - Beastmaster''s Whistle: Mottled Scytheclaw'),
(1022, 79417, 0, 1, 0, 1, 0, 1, 1, 'Mottled Scytheclaw - Beastmaster''s Whistle: Mottled Razormaw'),
(1023, 79416, 0, 1, 0, 1, 0, 1, 1, 'Mottled Razormaw - Beastmaster''s Whistle: Mottled Scytheclaw'),
(1023, 79417, 0, 1, 0, 1, 0, 1, 1, 'Mottled Razormaw - Beastmaster''s Whistle: Mottled Razormaw'),
(1039, 601027, 0, 1, 0, 1, 0, 1, 1, 'Fen Dweller - Elemental Lodestone: Fen Dweller'),
(1040, 601028, 0, 1, 0, 1, 0, 1, 1, 'Fen Creeper - Elemental Lodestone: Fen Creeper'),
(1041, 601029, 0, 1, 0, 1, 0, 1, 1, 'Fen Lord - Elemental Lodestone: Fen Lord'),
(1042, 1180126, 0, 1, 0, 1, 0, 1, 1, 'Red Whelp - Draconic Warhorn: Red Whelp'),
(1043, 1180130, 0, 1, 0, 1, 0, 1, 1, 'Lost Whelp - Draconic Warhorn: Lost Whelp'),
(1044, 1180132, 0, 1, 0, 1, 0, 1, 1, 'Flamesnorting Whelp - Draconic Warhorn: Flamesnorting Whelp'),
(1045, 1180134, 0, 1, 0, 1, 0, 1, 1, 'Red Dragonspawn - Draconic Warhorn: Red Dragonspawn'),
(1046, 1180137, 0, 1, 0, 1, 0, 1, 1, 'Red Wyrmkin - Draconic Warhorn: Red Wyrmkin'),
(1047, 1180140, 0, 1, 0, 1, 0, 1, 1, 'Red Scalebane - Draconic Warhorn: Red Scalebane'),
(1048, 1180142, 0, 1, 0, 1, 0, 1, 1, 'Scalebane Lieutenant - Draconic Warhorn: Scalebane Lieutenant'),
(1063, 1180151, 0, 1, 0, 1, 0, 1, 1, 'Jade - Draconic Warhorn: Jade'),
(1069, 1180153, 0, 1, 0, 1, 0, 1, 1, 'Crimson Whelp - Draconic Warhorn: Crimson Whelp'),
(1081, 601030, 0, 1, 0, 1, 0, 1, 1, 'Mire Lord - Elemental Lodestone: Mire Lord'),
(1082, 79418, 0, 1, 0, 1, 0, 1, 1, 'Sawtooth Crocolisk - Beastmaster''s Whistle: Sawtooth Crocolisk'),
(1084, 79419, 0, 1, 0, 1, 0, 1, 1, 'Young Sawtooth Crocolisk - Beastmaster''s Whistle: Young Sawtooth Crocolisk'),
(1085, 79420, 0, 1, 0, 1, 0, 1, 1, 'Elder Stranglethorn Tiger - Beastmaster''s Whistle: Elder Stranglethorn Tiger'),
(1087, 79421, 0, 1, 0, 1, 0, 1, 1, 'Sawtooth Snapper - Beastmaster''s Whistle: Sawtooth Snapper'),
(1088, 79422, 0, 1, 0, 1, 0, 1, 1, 'Monstrous Crawler - Beastmaster''s Whistle: Monstrous Crawler'),
(1108, 79423, 0, 1, 0, 1, 0, 1, 1, 'Mistvale Gorilla - Beastmaster''s Whistle: Mistvale Gorilla'),
(1110, 85879, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Raider - Blood Soaked Vellum: Skeletal Raider'),
(1111, 79425, 0, 1, 0, 1, 0, 1, 1, 'Leech Stalker - Beastmaster''s Whistle: Leech Stalker'),
(1112, 79426, 0, 1, 0, 1, 0, 1, 1, 'Leech Widow - Beastmaster''s Whistle: Leech Widow'),
(1114, 79427, 0, 1, 0, 1, 0, 1, 1, 'Jungle Thunderer - Beastmaster''s Whistle: Jungle Thunderer'),
(1125, 79428, 0, 1, 0, 1, 0, 1, 1, 'Crag Boar - Beastmaster''s Whistle: Crag Boar'),
(1126, 79429, 0, 1, 0, 1, 0, 1, 1, 'Large Crag Boar - Beastmaster''s Whistle: Large Crag Boar'),
(1127, 79430, 0, 1, 0, 1, 0, 1, 1, 'Elder Crag Boar - Beastmaster''s Whistle: Elder Crag Boar'),
(1128, 79431, 0, 1, 0, 1, 0, 1, 1, 'Young Black Bear - Beastmaster''s Whistle: Young Black Bear'),
(1129, 79432, 0, 1, 0, 1, 0, 1, 1, 'Black Bear - Beastmaster''s Whistle: Black Bear'),
(1130, 79433, 0, 1, 0, 1, 0, 1, 1, 'Bjarn - Beastmaster''s Whistle: Bjarn'),
(1131, 79434, 0, 1, 0, 1, 0, 1, 1, 'Winter Wolf - Beastmaster''s Whistle: Winter Wolf'),
(1132, 79435, 0, 1, 0, 1, 0, 1, 1, 'Timber - Beastmaster''s Whistle: Timber'),
(1133, 79436, 0, 1, 0, 1, 0, 1, 1, 'Starving Winter Wolf - Beastmaster''s Whistle: Starving Winter Wolf'),
(1138, 79437, 0, 1, 0, 1, 0, 1, 1, 'Snow Tracker Wolf - Beastmaster''s Whistle: Snow Tracker Wolf'),
(1140, 79438, 0, 1, 0, 1, 0, 1, 1, 'Razormaw Matriarch - Beastmaster''s Whistle: Razormaw Matriarch'),
(1152, 79441, 0, 1, 0, 1, 0, 1, 1, 'Snapjaw Crocolisk - Beastmaster''s Whistle: Snapjaw Crocolisk'),
(1184, 79442, 0, 1, 0, 1, 0, 1, 1, 'Cliff Lurker - Beastmaster''s Whistle: Cliff Lurker'),
(1185, 79443, 0, 1, 0, 1, 0, 1, 1, 'Wood Lurker - Beastmaster''s Whistle: Wood Lurker'),
(1186, 79444, 0, 1, 0, 1, 0, 1, 1, 'Elder Black Bear - Beastmaster''s Whistle: Elder Black Bear'),
(1188, 79445, 0, 1, 0, 1, 0, 1, 1, 'Grizzled Black Bear - Beastmaster''s Whistle: Grizzled Black Bear'),
(1189, 79446, 0, 1, 0, 1, 0, 1, 1, 'Black Bear Patriarch - Beastmaster''s Whistle: Black Bear Patriarch'),
(1190, 79447, 0, 1, 0, 1, 0, 1, 1, 'Mountain Boar - Beastmaster''s Whistle: Mountain Boar'),
(1191, 79448, 0, 1, 0, 1, 0, 1, 1, 'Mangy Mountain Boar - Beastmaster''s Whistle: Mangy Mountain Boar'),
(1192, 79449, 0, 1, 0, 1, 0, 1, 1, 'Elder Mountain Boar - Beastmaster''s Whistle: Elder Mountain Boar'),
(1194, 79450, 0, 1, 0, 1, 0, 1, 1, 'Mountain Buzzard - Beastmaster''s Whistle: Mountain Buzzard'),
(1195, 79451, 0, 1, 0, 1, 0, 1, 1, 'Forest Lurker - Beastmaster''s Whistle: Forest Lurker'),
(1196, 79452, 0, 1, 0, 1, 0, 1, 1, 'Ice Claw Bear - Beastmaster''s Whistle: Ice Claw Bear'),
(1199, 79453, 0, 1, 0, 1, 0, 1, 1, 'Juvenile Snow Leopard - Beastmaster''s Whistle: Juvenile Snow Leopard'),
(1201, 79454, 0, 1, 0, 1, 0, 1, 1, 'Snow Leopard - Beastmaster''s Whistle: Snow Leopard'),
(1225, 79456, 0, 1, 0, 1, 0, 1, 1, 'Ol'' Sooty - Beastmaster''s Whistle: Ol'' Sooty'),
(1258, 79457, 0, 1, 0, 1, 0, 1, 1, 'Black Ravager Mastiff - Beastmaster''s Whistle: Black Ravager Mastiff'),
(1270, 85880, 0, 0.1, 0, 1, 0, 1, 1, 'Fetid Corpse - Blood Soaked Vellum: Fetid Corpse'),
(1353, 79458, 0, 1, 0, 1, 0, 1, 1, 'Sarltooth - Beastmaster''s Whistle: Sarltooth'),
(1400, 79459, 0, 1, 0, 1, 0, 1, 1, 'Wetlands Crocolisk - Beastmaster''s Whistle: Wetlands Crocolisk'),
(1417, 79460, 0, 1, 0, 1, 0, 1, 1, 'Young Wetlands Crocolisk - Beastmaster''s Whistle: Young Wetlands Crocolisk'),
(1488, 85881, 0, 0.1, 0, 1, 0, 1, 1, 'Zanzil Zombie - Blood Soaked Vellum: Zanzil Zombie'),
(1489, 85934, 0, 0.1, 0, 1, 0, 1, 1, 'Zanzil Hunter - Blood Soaked Vellum: Zanzil Hunter'),
(1502, 85965, 0, 0.1, 0, 1, 0, 1, 1, 'Wretched Ghoul - Blood Soaked Vellum: Wretched Ghoul'),
(1504, 79461, 0, 1, 0, 1, 0, 1, 1, 'Young Night Web Spider - Beastmaster''s Whistle: Young Night Web Spider'),
(1505, 79462, 0, 1, 0, 1, 0, 1, 1, 'Night Web Spider - Beastmaster''s Whistle: Night Web Spider'),
(1508, 79463, 0, 1, 0, 1, 0, 1, 1, 'Young Scavenger - Beastmaster''s Whistle: Young Scavenger'),
(1509, 79464, 0, 1, 0, 1, 0, 1, 1, 'Ragged Scavenger - Beastmaster''s Whistle: Ragged Scavenger'),
(1512, 79465, 0, 1, 0, 1, 0, 1, 1, 'Duskbat - Beastmaster''s Whistle: Duskbat'),
(1513, 79466, 0, 1, 0, 1, 0, 1, 1, 'Mangy Duskbat - Beastmaster''s Whistle: Mangy Duskbat'),
(1520, 85966, 0, 0.1, 0, 1, 0, 1, 1, 'Rattlecage Soldier - Blood Soaked Vellum: Rattlecage Soldier'),
(1522, 85967, 0, 0.1, 0, 1, 0, 1, 1, 'Darkeye Bonecaster - Blood Soaked Vellum: Darkeye Bonecaster'),
(1523, 85968, 0, 0.1, 0, 1, 0, 1, 1, 'Cracked Skull Soldier - Blood Soaked Vellum: Cracked Skull Soldier'),
(1525, 85969, 0, 0.1, 0, 1, 0, 1, 1, 'Rotting Dead - Blood Soaked Vellum: Rotting Dead'),
(1526, 85970, 0, 0.1, 0, 1, 0, 1, 1, 'Ravaged Corpse - Blood Soaked Vellum: Ravaged Corpse'),
(1527, 85971, 0, 0.1, 0, 1, 0, 1, 1, 'Hungering Dead - Blood Soaked Vellum: Hungering Dead'),
(1528, 86008, 0, 0.1, 0, 1, 0, 1, 1, 'Shambling Horror - Blood Soaked Vellum: Shambling Horror'),
(1529, 86072, 0, 0.1, 0, 1, 0, 1, 1, 'Bleeding Horror - Blood Soaked Vellum: Bleeding Horror'),
(1530, 86077, 0, 0.1, 0, 1, 0, 1, 1, 'Rotting Ancestor - Blood Soaked Vellum: Rotting Ancestor'),
(1531, 86078, 0, 0.1, 0, 1, 0, 1, 1, 'Lost Soul - Blood Soaked Vellum: Lost Soul'),
(1533, 86085, 0, 0.1, 0, 1, 0, 1, 1, 'Tormented Spirit - Blood Soaked Vellum: Tormented Spirit'),
(1534, 86101, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Ancestor - Blood Soaked Vellum: Wailing Ancestor'),
(1547, 601716, 0, 1, 0, 1, 0, 1, 1, 'Decrepit Darkhound - Summoner''s Stone: Decrepit Darkhound'),
(1553, 79467, 0, 1, 0, 1, 0, 1, 1, 'Greater Duskbat - Beastmaster''s Whistle: Greater Duskbat'),
(1554, 79468, 0, 1, 0, 1, 0, 1, 1, 'Vampiric Duskbat - Beastmaster''s Whistle: Vampiric Duskbat'),
(1555, 79469, 0, 1, 0, 1, 0, 1, 1, 'Vicious Night Web Spider - Beastmaster''s Whistle: Vicious Night Web Spider'),
(1557, 79470, 0, 1, 0, 1, 0, 1, 1, 'Elder Mistvale Gorilla - Beastmaster''s Whistle: Elder Mistvale Gorilla'),
(1558, 79471, 0, 1, 0, 1, 0, 1, 1, 'Silverback Patriarch - Beastmaster''s Whistle: Silverback Patriarch'),
(1559, 79472, 0, 1, 0, 1, 0, 1, 1, 'King Mukla - Beastmaster''s Whistle: King Mukla'),
(1654, 86102, 0, 0.1, 0, 1, 0, 1, 1, 'Gregor Agamand - Blood Soaked Vellum: Gregor Agamand'),
(1655, 86103, 0, 0.1, 0, 1, 0, 1, 1, 'Nissa Agamand - Blood Soaked Vellum: Nissa Agamand'),
(1656, 86104, 0, 0.1, 0, 1, 0, 1, 1, 'Thurman Agamand - Blood Soaked Vellum: Thurman Agamand'),
(1657, 86105, 0, 0.1, 0, 1, 0, 1, 1, 'Devlin Agamand - Blood Soaked Vellum: Devlin Agamand'),
(1658, 86106, 0, 0.1, 0, 1, 0, 1, 1, 'Captain Dargol - Blood Soaked Vellum: Captain Dargol'),
(1688, 79473, 0, 1, 0, 1, 0, 1, 1, 'Night Web Matriarch - Beastmaster''s Whistle: Night Web Matriarch'),
(1689, 79474, 0, 1, 0, 1, 0, 1, 1, 'Scarred Crag Boar - Beastmaster''s Whistle: Scarred Crag Boar'),
(1693, 79475, 0, 1, 0, 1, 0, 1, 1, 'Loch Crocolisk - Beastmaster''s Whistle: Loch Crocolisk'),
(1713, 79476, 0, 1, 0, 1, 0, 1, 1, 'Elder Shadowmaw Panther - Beastmaster''s Whistle: Elder Shadowmaw Panther'),
(1765, 79477, 0, 1, 0, 1, 0, 1, 1, 'Worg - Beastmaster''s Whistle: Worg'),
(1766, 79478, 0, 1, 0, 1, 0, 1, 1, 'Mottled Worg - Beastmaster''s Whistle: Mottled Worg'),
(1778, 79479, 0, 1, 0, 1, 0, 1, 1, 'Ferocious Grizzled Bear - Beastmaster''s Whistle: Ferocious Grizzled Bear'),
(1780, 79480, 0, 1, 0, 1, 0, 1, 1, 'Moss Stalker - Beastmaster''s Whistle: Moss Stalker'),
(1781, 79481, 0, 1, 0, 1, 0, 1, 1, 'Mist Creeper - Beastmaster''s Whistle: Mist Creeper'),
(1783, 86107, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Flayer - Blood Soaked Vellum: Skeletal Flayer'),
(1784, 86108, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Sorcerer - Blood Soaked Vellum: Skeletal Sorcerer'),
(1785, 86109, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Terror - Blood Soaked Vellum: Skeletal Terror'),
(1787, 86423, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Executioner - Blood Soaked Vellum: Skeletal Executioner'),
(1788, 86424, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Warlord - Blood Soaked Vellum: Skeletal Warlord'),
(1789, 86426, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Acolyte - Blood Soaked Vellum: Skeletal Acolyte'),
(1791, 86466, 0, 0.1, 0, 1, 0, 1, 1, 'Slavering Ghoul - Blood Soaked Vellum: Slavering Ghoul'),
(1793, 86474, 0, 0.1, 0, 1, 0, 1, 1, 'Rotting Ghoul - Blood Soaked Vellum: Rotting Ghoul'),
(1794, 86475, 0, 0.1, 0, 1, 0, 1, 1, 'Soulless Ghoul - Blood Soaked Vellum: Soulless Ghoul'),
(1795, 86488, 0, 0.1, 0, 1, 0, 1, 1, 'Searing Ghoul - Blood Soaked Vellum: Searing Ghoul'),
(1796, 86506, 0, 0.1, 0, 1, 0, 1, 1, 'Freezing Ghoul - Blood Soaked Vellum: Freezing Ghoul'),
(1797, 79482, 0, 1, 0, 1, 0, 1, 1, 'Giant Grizzled Bear - Beastmaster''s Whistle: Giant Grizzled Bear'),
(1802, 86528, 0, 0.1, 0, 1, 0, 1, 1, 'Hungering Wraith - Blood Soaked Vellum: Hungering Wraith'),
(1804, 86530, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Death - Blood Soaked Vellum: Wailing Death'),
(1805, 86531, 0, 0.1, 0, 1, 0, 1, 1, 'Flesh Golem - Blood Soaked Vellum: Flesh Golem'),
(1809, 79483, 0, 1, 0, 1, 0, 1, 1, 'Carrion Vulture - Beastmaster''s Whistle: Carrion Vulture'),
(1812, 601032, 0, 1, 0, 1, 0, 1, 1, 'Rotting Behemoth - Elemental Lodestone: Rotting Behemoth'),
(1813, 601033, 0, 1, 0, 1, 0, 1, 1, 'Decaying Horror - Elemental Lodestone: Decaying Horror'),
(1815, 79484, 0, 1, 0, 1, 0, 1, 1, 'Diseased Black Bear - Beastmaster''s Whistle: Diseased Black Bear'),
(1816, 79485, 0, 1, 0, 1, 0, 1, 1, 'Diseased Grizzly - Beastmaster''s Whistle: Diseased Grizzly'),
(1817, 79486, 0, 1, 0, 1, 0, 1, 1, 'Diseased Wolf - Beastmaster''s Whistle: Diseased Wolf'),
(1821, 79487, 0, 1, 0, 1, 0, 1, 1, 'Carrion Lurker - Beastmaster''s Whistle: Carrion Lurker'),
(1822, 79488, 0, 1, 0, 1, 0, 1, 1, 'Venom Mist Lurker - Beastmaster''s Whistle: Venom Mist Lurker'),
(1824, 79489, 0, 1, 0, 1, 0, 1, 1, 'Plague Lurker - Beastmaster''s Whistle: Plague Lurker'),
(1847, 86535, 0, 0.1, 0, 1, 0, 1, 1, 'Foulmane - Blood Soaked Vellum: Foulmane'),
(1849, 86543, 0, 0.1, 0, 1, 0, 1, 1, 'Dreadwhisper - Blood Soaked Vellum: Dreadwhisper'),
(1850, 86555, 0, 0.1, 0, 1, 0, 1, 1, 'Putridius - Blood Soaked Vellum: Putridius'),
(1851, 601034, 0, 1, 0, 1, 0, 1, 1, 'The Husk - Elemental Lodestone: The Husk'),
(1865, 86556, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Raider - Blood Soaked Vellum: Ravenclaw Raider'),
(1866, 86557, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Slave - Blood Soaked Vellum: Ravenclaw Slave'),
(1868, 87207, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Servant - Blood Soaked Vellum: Ravenclaw Servant'),
(1869, 87211, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Champion - Blood Soaked Vellum: Ravenclaw Champion'),
(1870, 87255, 0, 0.1, 0, 1, 0, 1, 1, 'Hand of Ravenclaw - Blood Soaked Vellum: Hand of Ravenclaw'),
(1890, 87479, 0, 0.1, 0, 1, 0, 1, 1, 'Rattlecage Skeleton - Blood Soaked Vellum: Rattlecage Skeleton'),
(1916, 87480, 0, 0.1, 0, 1, 0, 1, 1, 'Stephen Bhartec - Blood Soaked Vellum: Stephen Bhartec'),
(1917, 87481, 0, 0.1, 0, 1, 0, 1, 1, 'Daniel Ulfman - Blood Soaked Vellum: Daniel Ulfman'),
(1918, 87482, 0, 0.1, 0, 1, 0, 1, 1, 'Karrel Grayves - Blood Soaked Vellum: Karrel Grayves'),
(1919, 87483, 0, 0.1, 0, 1, 0, 1, 1, 'Samuel Fipps - Blood Soaked Vellum: Samuel Fipps'),
(1922, 79490, 0, 1, 0, 1, 0, 1, 1, 'Gray Forest Wolf - Beastmaster''s Whistle: Gray Forest Wolf'),
(1923, 79491, 0, 1, 0, 1, 0, 1, 1, 'Bloodsnout Worg - Beastmaster''s Whistle: Bloodsnout Worg'),
(1953, 601035, 0, 1, 0, 1, 0, 1, 1, 'Lake Skulker - Elemental Lodestone: Lake Skulker'),
(1954, 601036, 0, 1, 0, 1, 0, 1, 1, 'Elder Lake Skulker - Elemental Lodestone: Elder Lake Skulker'),
(1955, 601037, 0, 1, 0, 1, 0, 1, 1, 'Lake Creeper - Elemental Lodestone: Lake Creeper'),
(1956, 601038, 0, 1, 0, 1, 0, 1, 1, 'Elder Lake Creeper - Elemental Lodestone: Elder Lake Creeper'),
(1961, 79492, 0, 1, 0, 1, 0, 1, 1, 'Mangeclaw - Beastmaster''s Whistle: Mangeclaw'),
(1971, 87563, 0, 0.1, 0, 1, 0, 1, 1, 'Ivar the Foul - Blood Soaked Vellum: Ivar the Foul'),
(1973, 87564, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Guardian - Blood Soaked Vellum: Ravenclaw Guardian'),
(1974, 87567, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Drudger - Blood Soaked Vellum: Ravenclaw Drudger'),
(1983, 87568, 0, 0.1, 0, 1, 0, 1, 1, 'Nightlash - Blood Soaked Vellum: Nightlash'),
(1984, 79493, 0, 1, 0, 1, 0, 1, 1, 'Young Thistle Boar - Beastmaster''s Whistle: Young Thistle Boar'),
(1985, 79494, 0, 1, 0, 1, 0, 1, 1, 'Thistle Boar - Beastmaster''s Whistle: Thistle Boar'),
(1986, 79495, 0, 1, 0, 1, 0, 1, 1, 'Webwood Spider - Beastmaster''s Whistle: Webwood Spider'),
(1994, 79496, 0, 1, 0, 1, 0, 1, 1, 'Githyiss the Vile - Beastmaster''s Whistle: Githyiss the Vile'),
(1995, 79497, 0, 1, 0, 1, 0, 1, 1, 'Strigid Owl - Beastmaster''s Whistle: Strigid Owl'),
(1996, 79498, 0, 1, 0, 1, 0, 1, 1, 'Strigid Screecher - Beastmaster''s Whistle: Strigid Screecher'),
(1997, 79499, 0, 1, 0, 1, 0, 1, 1, 'Strigid Hunter - Beastmaster''s Whistle: Strigid Hunter'),
(1998, 79500, 0, 1, 0, 1, 0, 1, 1, 'Webwood Lurker - Beastmaster''s Whistle: Webwood Lurker'),
(1999, 79501, 0, 1, 0, 1, 0, 1, 1, 'Webwood Venomfang - Beastmaster''s Whistle: Webwood Venomfang'),
(2000, 79502, 0, 1, 0, 1, 0, 1, 1, 'Webwood Silkspinner - Beastmaster''s Whistle: Webwood Silkspinner'),
(2001, 79503, 0, 1, 0, 1, 0, 1, 1, 'Giant Webwood Spider - Beastmaster''s Whistle: Giant Webwood Spider'),
(2022, 601039, 0, 1, 0, 1, 0, 1, 1, 'Timberling - Elemental Lodestone: Timberling'),
(2025, 601040, 0, 1, 0, 1, 0, 1, 1, 'Timberling Bark Ripper - Elemental Lodestone: Timberling Bark Ripper'),
(2027, 601041, 0, 1, 0, 1, 0, 1, 1, 'Timberling Trampler - Elemental Lodestone: Timberling Trampler'),
(2029, 601042, 0, 1, 0, 1, 0, 1, 1, 'Timberling Mire Beast - Elemental Lodestone: Timberling Mire Beast'),
(2030, 601043, 0, 1, 0, 1, 0, 1, 1, 'Elder Timberling - Elemental Lodestone: Elder Timberling'),
(2031, 79504, 0, 1, 0, 1, 0, 1, 1, 'Young Nightsaber - Beastmaster''s Whistle: Young Nightsaber'),
(2032, 79505, 0, 1, 0, 1, 0, 1, 1, 'Mangy Nightsaber - Beastmaster''s Whistle: Mangy Nightsaber'),
(2033, 79506, 0, 1, 0, 1, 0, 1, 1, 'Elder Nightsaber - Beastmaster''s Whistle: Elder Nightsaber'),
(2034, 79507, 0, 1, 0, 1, 0, 1, 1, 'Feral Nightsaber - Beastmaster''s Whistle: Feral Nightsaber'),
(2038, 82350, 0, 1, 0, 1, 0, 1, 1, 'Lord Melenas - Summoner''s Stone: Lord Melenas'),
(2042, 79508, 0, 1, 0, 1, 0, 1, 1, 'Nightsaber - Beastmaster''s Whistle: Nightsaber'),
(2043, 79509, 0, 1, 0, 1, 0, 1, 1, 'Nightsaber Stalker - Beastmaster''s Whistle: Nightsaber Stalker'),
(2069, 79510, 0, 1, 0, 1, 0, 1, 1, 'Moonstalker - Beastmaster''s Whistle: Moonstalker'),
(2070, 79511, 0, 1, 0, 1, 0, 1, 1, 'Moonstalker Runt - Beastmaster''s Whistle: Moonstalker Runt'),
(2071, 79512, 0, 1, 0, 1, 0, 1, 1, 'Moonstalker Matriarch - Beastmaster''s Whistle: Moonstalker Matriarch'),
(2089, 79516, 0, 1, 0, 1, 0, 1, 1, 'Giant Wetlands Crocolisk - Beastmaster''s Whistle: Giant Wetlands Crocolisk'),
(2156, 601667, 0, 1, 0, 1, 0, 1, 1, 'Cracked Golem - Elemental Lodestone: Cracked Golem'),
(2157, 601668, 0, 1, 0, 1, 0, 1, 1, 'Stone Behemoth - Elemental Lodestone: Stone Behemoth'),
(2163, 79517, 0, 1, 0, 1, 0, 1, 1, 'Thistle Bear - Beastmaster''s Whistle: Thistle Bear'),
(2165, 79518, 0, 1, 0, 1, 0, 1, 1, 'Grizzled Thistle Bear - Beastmaster''s Whistle: Grizzled Thistle Bear'),
(2166, 601044, 0, 1, 0, 1, 0, 1, 1, 'Oakenscowl - Elemental Lodestone: Oakenscowl'),
(2172, 79519, 0, 1, 0, 1, 0, 1, 1, 'Strider Clutchmother - Beastmaster''s Whistle: Strider Clutchmother'),
(2175, 79520, 0, 1, 0, 1, 0, 1, 1, 'Shadowclaw - Beastmaster''s Whistle: Shadowclaw'),
(2176, 87644, 0, 0.1, 0, 1, 0, 1, 1, 'Cursed Highborne - Blood Soaked Vellum: Cursed Highborne'),
(2177, 87645, 0, 0.1, 0, 1, 0, 1, 1, 'Writhing Highborne - Blood Soaked Vellum: Writhing Highborne'),
(2178, 87653, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Highborne - Blood Soaked Vellum: Wailing Highborne'),
(2231, 79521, 0, 1, 0, 1, 0, 1, 1, 'Pygmy Tide Crawler - Beastmaster''s Whistle: Pygmy Tide Crawler'),
(2232, 79522, 0, 1, 0, 1, 0, 1, 1, 'Tide Crawler - Beastmaster''s Whistle: Tide Crawler'),
(2233, 79523, 0, 1, 0, 1, 0, 1, 1, 'Encrusted Tide Crawler - Beastmaster''s Whistle: Encrusted Tide Crawler'),
(2234, 79524, 0, 1, 0, 1, 0, 1, 1, 'Young Reef Crawler - Beastmaster''s Whistle: Young Reef Crawler'),
(2235, 79525, 0, 1, 0, 1, 0, 1, 1, 'Reef Crawler - Beastmaster''s Whistle: Reef Crawler'),
(2236, 79526, 0, 1, 0, 1, 0, 1, 1, 'Raging Reef Crawler - Beastmaster''s Whistle: Raging Reef Crawler'),
(2237, 79527, 0, 1, 0, 1, 0, 1, 1, 'Moonstalker Sire - Beastmaster''s Whistle: Moonstalker Sire'),
(2283, 87654, 0, 0.1, 0, 1, 0, 1, 1, 'Ravenclaw Regent - Blood Soaked Vellum: Ravenclaw Regent'),
(2321, 79528, 0, 1, 0, 1, 0, 1, 1, 'Foreststrider Fledgling - Beastmaster''s Whistle: Foreststrider Fledgling'),
(2322, 79529, 0, 1, 0, 1, 0, 1, 1, 'Foreststrider - Beastmaster''s Whistle: Foreststrider'),
(2323, 79530, 0, 1, 0, 1, 0, 1, 1, 'Giant Foreststrider - Beastmaster''s Whistle: Giant Foreststrider'),
(2348, 79531, 0, 1, 0, 1, 0, 1, 1, 'Elder Moss Creeper - Beastmaster''s Whistle: Elder Moss Creeper');
DELETE FROM `creature_loot_template` WHERE (`Entry`=2349 AND `Item`=79532) OR
  (`Entry`=2350 AND `Item`=79533) OR
  (`Entry`=2351 AND `Item`=79534) OR
  (`Entry`=2354 AND `Item`=79535) OR
  (`Entry`=2356 AND `Item`=79536) OR
  (`Entry`=2384 AND `Item`=79537) OR
  (`Entry`=2385 AND `Item`=79539) OR
  (`Entry`=2406 AND `Item`=79540) OR
  (`Entry`=2407 AND `Item`=79541) OR
  (`Entry`=2408 AND `Item`=79542) OR
  (`Entry`=2447 AND `Item`=1180168) OR
  (`Entry`=2476 AND `Item`=79543) OR
  (`Entry`=2505 AND `Item`=79544) OR
  (`Entry`=2521 AND `Item`=79545) OR
  (`Entry`=2522 AND `Item`=79546) OR
  (`Entry`=2535 AND `Item`=87655) OR
  (`Entry`=2536 AND `Item`=87656) OR
  (`Entry`=2537 AND `Item`=87657) OR
  (`Entry`=2544 AND `Item`=79547) OR
  (`Entry`=2551 AND `Item`=601669) OR
  (`Entry`=2559 AND `Item`=79548) OR
  (`Entry`=2560 AND `Item`=79549) OR
  (`Entry`=2561 AND `Item`=79550) OR
  (`Entry`=2563 AND `Item`=79551) OR
  (`Entry`=2565 AND `Item`=79552) OR
  (`Entry`=2578 AND `Item`=79553) OR
  (`Entry`=2579 AND `Item`=79554) OR
  (`Entry`=2580 AND `Item`=79555) OR
  (`Entry`=2635 AND `Item`=79556) OR
  (`Entry`=2680 AND `Item`=79557) OR
  (`Entry`=2681 AND `Item`=79558) OR
  (`Entry`=2686 AND `Item`=79559) OR
  (`Entry`=2723 AND `Item`=601670) OR
  (`Entry`=2725 AND `Item`=1180172) OR
  (`Entry`=2726 AND `Item`=1180174) OR
  (`Entry`=2727 AND `Item`=79560) OR
  (`Entry`=2728 AND `Item`=79561) OR
  (`Entry`=2729 AND `Item`=79562) OR
  (`Entry`=2730 AND `Item`=79563) OR
  (`Entry`=2731 AND `Item`=79564) OR
  (`Entry`=2732 AND `Item`=79565) OR
  (`Entry`=2734 AND `Item`=79566) OR
  (`Entry`=2749 AND `Item`=601671) OR
  (`Entry`=2751 AND `Item`=601672) OR
  (`Entry`=2753 AND `Item`=79567) OR
  (`Entry`=2757 AND `Item`=1180176) OR
  (`Entry`=2761 AND `Item`=600370) OR
  (`Entry`=2829 AND `Item`=79568) OR
  (`Entry`=2830 AND `Item`=79569) OR
  (`Entry`=2831 AND `Item`=79570) OR
  (`Entry`=2850 AND `Item`=79571) OR
  (`Entry`=2923 AND `Item`=79572) OR
  (`Entry`=2924 AND `Item`=79573) OR
  (`Entry`=2925 AND `Item`=79574) OR
  (`Entry`=2926 AND `Item`=79575) OR
  (`Entry`=2931 AND `Item`=79576) OR
  (`Entry`=2954 AND `Item`=79577) OR
  (`Entry`=2955 AND `Item`=79578) OR
  (`Entry`=2956 AND `Item`=79579) OR
  (`Entry`=2957 AND `Item`=79580) OR
  (`Entry`=2958 AND `Item`=79581) OR
  (`Entry`=2959 AND `Item`=79582) OR
  (`Entry`=2960 AND `Item`=79583) OR
  (`Entry`=2961 AND `Item`=79584) OR
  (`Entry`=2966 AND `Item`=79585) OR
  (`Entry`=2969 AND `Item`=79586) OR
  (`Entry`=2970 AND `Item`=79587) OR
  (`Entry`=2971 AND `Item`=79588) OR
  (`Entry`=3035 AND `Item`=79589) OR
  (`Entry`=3068 AND `Item`=79590) OR
  (`Entry`=3094 AND `Item`=87668) OR
  (`Entry`=3098 AND `Item`=79591) OR
  (`Entry`=3099 AND `Item`=79592) OR
  (`Entry`=3100 AND `Item`=79593) OR
  (`Entry`=3106 AND `Item`=79594) OR
  (`Entry`=3107 AND `Item`=79595) OR
  (`Entry`=3108 AND `Item`=79596) OR
  (`Entry`=3110 AND `Item`=79597) OR
  (`Entry`=3121 AND `Item`=79598) OR
  (`Entry`=3122 AND `Item`=79599) OR
  (`Entry`=3123 AND `Item`=79600) OR
  (`Entry`=3124 AND `Item`=79601) OR
  (`Entry`=3125 AND `Item`=79602) OR
  (`Entry`=3126 AND `Item`=79603) OR
  (`Entry`=3127 AND `Item`=79604) OR
  (`Entry`=3225 AND `Item`=79605) OR
  (`Entry`=3226 AND `Item`=79606) OR
  (`Entry`=3227 AND `Item`=79607) OR
  (`Entry`=3228 AND `Item`=79608) OR
  (`Entry`=3231 AND `Item`=79609) OR
  (`Entry`=3241 AND `Item`=79610) OR
  (`Entry`=3243 AND `Item`=79611) OR
  (`Entry`=3244 AND `Item`=79612) OR
  (`Entry`=3245 AND `Item`=79613) OR
  (`Entry`=3246 AND `Item`=79614) OR
  (`Entry`=3247 AND `Item`=79615) OR
  (`Entry`=3249 AND `Item`=79616) OR
  (`Entry`=3250 AND `Item`=79617) OR
  (`Entry`=3252 AND `Item`=79618) OR
  (`Entry`=3254 AND `Item`=79619) OR
  (`Entry`=3255 AND `Item`=79620) OR
  (`Entry`=3256 AND `Item`=79621) OR
  (`Entry`=3281 AND `Item`=79622) OR
  (`Entry`=3415 AND `Item`=79623) OR
  (`Entry`=3416 AND `Item`=79624) OR
  (`Entry`=3424 AND `Item`=79625) OR
  (`Entry`=3425 AND `Item`=79626) OR
  (`Entry`=3461 AND `Item`=79627) OR
  (`Entry`=3472 AND `Item`=79628) OR
  (`Entry`=3535 AND `Item`=601045) OR
  (`Entry`=3566 AND `Item`=79629) OR
  (`Entry`=3569 AND `Item`=601046) OR
  (`Entry`=3630 AND `Item`=79631) OR
  (`Entry`=3631 AND `Item`=79632) OR
  (`Entry`=3632 AND `Item`=79633) OR
  (`Entry`=3633 AND `Item`=79634) OR
  (`Entry`=3634 AND `Item`=79635) OR
  (`Entry`=3636 AND `Item`=79636) OR
  (`Entry`=3637 AND `Item`=79637) OR
  (`Entry`=3653 AND `Item`=79638) OR
  (`Entry`=3662 AND `Item`=82354) OR
  (`Entry`=3752 AND `Item`=82355) OR
  (`Entry`=3754 AND `Item`=82356) OR
  (`Entry`=3755 AND `Item`=82357) OR
  (`Entry`=3757 AND `Item`=82358) OR
  (`Entry`=3758 AND `Item`=82359) OR
  (`Entry`=3759 AND `Item`=82360) OR
  (`Entry`=3762 AND `Item`=82361) OR
  (`Entry`=3763 AND `Item`=82362) OR
  (`Entry`=3765 AND `Item`=82363) OR
  (`Entry`=3767 AND `Item`=82364) OR
  (`Entry`=3770 AND `Item`=82365) OR
  (`Entry`=3771 AND `Item`=82366) OR
  (`Entry`=3773 AND `Item`=82367) OR
  (`Entry`=3780 AND `Item`=601048) OR
  (`Entry`=3781 AND `Item`=601049) OR
  (`Entry`=3782 AND `Item`=601050) OR
  (`Entry`=3783 AND `Item`=601051) OR
  (`Entry`=3784 AND `Item`=601052) OR
  (`Entry`=3809 AND `Item`=79639) OR
  (`Entry`=3810 AND `Item`=79640) OR
  (`Entry`=3811 AND `Item`=79641) OR
  (`Entry`=3812 AND `Item`=79642) OR
  (`Entry`=3814 AND `Item`=79643) OR
  (`Entry`=3815 AND `Item`=1180188) OR
  (`Entry`=3819 AND `Item`=79644) OR
  (`Entry`=3820 AND `Item`=79645) OR
  (`Entry`=3821 AND `Item`=79646) OR
  (`Entry`=3823 AND `Item`=79647) OR
  (`Entry`=3824 AND `Item`=79648) OR
  (`Entry`=3825 AND `Item`=79649) OR
  (`Entry`=3834 AND `Item`=601837) OR
  (`Entry`=3861 AND `Item`=79650) OR
  (`Entry`=3862 AND `Item`=79651) OR
  (`Entry`=3866 AND `Item`=79652) OR
  (`Entry`=3868 AND `Item`=79653) OR
  (`Entry`=3898 AND `Item`=82368) OR
  (`Entry`=3900 AND `Item`=82370) OR
  (`Entry`=3917 AND `Item`=600373) OR
  (`Entry`=3919 AND `Item`=601838) OR
  (`Entry`=3931 AND `Item`=601053) OR
  (`Entry`=4005 AND `Item`=79654) OR
  (`Entry`=4006 AND `Item`=79655) OR
  (`Entry`=4007 AND `Item`=79656) OR
  (`Entry`=4016 AND `Item`=1180189) OR
  (`Entry`=4017 AND `Item`=1180191) OR
  (`Entry`=4031 AND `Item`=79657) OR
  (`Entry`=4032 AND `Item`=79658) OR
  (`Entry`=4034 AND `Item`=600376) OR
  (`Entry`=4040 AND `Item`=79659) OR
  (`Entry`=4066 AND `Item`=1180193) OR
  (`Entry`=4067 AND `Item`=79660) OR
  (`Entry`=4117 AND `Item`=79661) OR
  (`Entry`=4118 AND `Item`=79662) OR
  (`Entry`=4119 AND `Item`=79663) OR
  (`Entry`=4124 AND `Item`=79664) OR
  (`Entry`=4126 AND `Item`=79665) OR
  (`Entry`=4127 AND `Item`=79666) OR
  (`Entry`=4128 AND `Item`=79667) OR
  (`Entry`=4129 AND `Item`=79668) OR
  (`Entry`=4132 AND `Item`=79669) OR
  (`Entry`=4139 AND `Item`=79670) OR
  (`Entry`=4140 AND `Item`=79671) OR
  (`Entry`=4142 AND `Item`=79672) OR
  (`Entry`=4143 AND `Item`=79673) OR
  (`Entry`=4144 AND `Item`=79674) OR
  (`Entry`=4154 AND `Item`=79675) OR
  (`Entry`=4158 AND `Item`=79676) OR
  (`Entry`=4248 AND `Item`=79677) OR
  (`Entry`=4249 AND `Item`=79678) OR
  (`Entry`=4250 AND `Item`=79679) OR
  (`Entry`=4304 AND `Item`=79680) OR
  (`Entry`=4308 AND `Item`=87674) OR
  (`Entry`=4316 AND `Item`=79681) OR
  (`Entry`=4323 AND `Item`=1180194) OR
  (`Entry`=4324 AND `Item`=1180195) OR
  (`Entry`=4328 AND `Item`=1180196) OR
  (`Entry`=4329 AND `Item`=1180198) OR
  (`Entry`=4331 AND `Item`=1180200) OR
  (`Entry`=4334 AND `Item`=1180204) OR
  (`Entry`=4339 AND `Item`=1180206) OR
  (`Entry`=4341 AND `Item`=79682) OR
  (`Entry`=4343 AND `Item`=79683) OR
  (`Entry`=4344 AND `Item`=79684) OR
  (`Entry`=4345 AND `Item`=79685) OR
  (`Entry`=4346 AND `Item`=79686) OR
  (`Entry`=4347 AND `Item`=79687) OR
  (`Entry`=4348 AND `Item`=79688) OR
  (`Entry`=4351 AND `Item`=79689) OR
  (`Entry`=4352 AND `Item`=79690) OR
  (`Entry`=4356 AND `Item`=79691) OR
  (`Entry`=4357 AND `Item`=79692) OR
  (`Entry`=4376 AND `Item`=79693) OR
  (`Entry`=4378 AND `Item`=79694) OR
  (`Entry`=4379 AND `Item`=79695) OR
  (`Entry`=4380 AND `Item`=79696) OR
  (`Entry`=4382 AND `Item`=601054) OR
  (`Entry`=4385 AND `Item`=601055) OR
  (`Entry`=4386 AND `Item`=601056) OR
  (`Entry`=4387 AND `Item`=601057) OR
  (`Entry`=4397 AND `Item`=79697) OR
  (`Entry`=4412 AND `Item`=79698) OR
  (`Entry`=4414 AND `Item`=79699) OR
  (`Entry`=4415 AND `Item`=79700) OR
  (`Entry`=4425 AND `Item`=79701) OR
  (`Entry`=4472 AND `Item`=87675) OR
  (`Entry`=4474 AND `Item`=87676) OR
  (`Entry`=4475 AND `Item`=87677) OR
  (`Entry`=4511 AND `Item`=79702) OR
  (`Entry`=4512 AND `Item`=79703) OR
  (`Entry`=4514 AND `Item`=79704) OR
  (`Entry`=4538 AND `Item`=79705) OR
  (`Entry`=4539 AND `Item`=79706) OR
  (`Entry`=4543 AND `Item`=87690) OR
  (`Entry`=4548 AND `Item`=79707) OR
  (`Entry`=4619 AND `Item`=82371) OR
  (`Entry`=4662 AND `Item`=79708) OR
  (`Entry`=4670 AND `Item`=82372) OR
  (`Entry`=4671 AND `Item`=82373) OR
  (`Entry`=4672 AND `Item`=82374) OR
  (`Entry`=4673 AND `Item`=82375) OR
  (`Entry`=4674 AND `Item`=82376) OR
  (`Entry`=4675 AND `Item`=82377) OR
  (`Entry`=4676 AND `Item`=82378) OR
  (`Entry`=4688 AND `Item`=79709) OR
  (`Entry`=4689 AND `Item`=79714) OR
  (`Entry`=4690 AND `Item`=79725) OR
  (`Entry`=4692 AND `Item`=79726) OR
  (`Entry`=4693 AND `Item`=79727) OR
  (`Entry`=4694 AND `Item`=79728) OR
  (`Entry`=4695 AND `Item`=79729) OR
  (`Entry`=4696 AND `Item`=79730) OR
  (`Entry`=4697 AND `Item`=79732) OR
  (`Entry`=4699 AND `Item`=79733) OR
  (`Entry`=4788 AND `Item`=82379) OR
  (`Entry`=4789 AND `Item`=82380) OR
  (`Entry`=4798 AND `Item`=82385) OR
  (`Entry`=4799 AND `Item`=82386) OR
  (`Entry`=4821 AND `Item`=79736) OR
  (`Entry`=4822 AND `Item`=79737) OR
  (`Entry`=4823 AND `Item`=79738) OR
  (`Entry`=4824 AND `Item`=79739) OR
  (`Entry`=4825 AND `Item`=79741) OR
  (`Entry`=4841 AND `Item`=79742) OR
  (`Entry`=4857 AND `Item`=601673) OR
  (`Entry`=4860 AND `Item`=601674) OR
  (`Entry`=4861 AND `Item`=79743) OR
  (`Entry`=4887 AND `Item`=79747) OR
  (`Entry`=4950 AND `Item`=79748) OR
  (`Entry`=4978 AND `Item`=600378) OR
  (`Entry`=5048 AND `Item`=79751) OR
  (`Entry`=5053 AND `Item`=79752) OR
  (`Entry`=5055 AND `Item`=601103) OR
  (`Entry`=5056 AND `Item`=79754) OR
  (`Entry`=5224 AND `Item`=79755) OR
  (`Entry`=5225 AND `Item`=79756) OR
  (`Entry`=5226 AND `Item`=79757) OR
  (`Entry`=5260 AND `Item`=79758) OR
  (`Entry`=5262 AND `Item`=79759) OR
  (`Entry`=5263 AND `Item`=87691) OR
  (`Entry`=5267 AND `Item`=87692) OR
  (`Entry`=5268 AND `Item`=79760) OR
  (`Entry`=5270 AND `Item`=87693) OR
  (`Entry`=5271 AND `Item`=87694) OR
  (`Entry`=5272 AND `Item`=79761) OR
  (`Entry`=5274 AND `Item`=79762) OR
  (`Entry`=5276 AND `Item`=1180208) OR
  (`Entry`=5277 AND `Item`=1180210) OR
  (`Entry`=5278 AND `Item`=1180212) OR
  (`Entry`=5280 AND `Item`=1180214) OR
  (`Entry`=5283 AND `Item`=1180216) OR
  (`Entry`=5286 AND `Item`=79763) OR
  (`Entry`=5287 AND `Item`=79764) OR
  (`Entry`=5288 AND `Item`=79765) OR
  (`Entry`=5291 AND `Item`=79766) OR
  (`Entry`=5307 AND `Item`=79767) OR
  (`Entry`=5308 AND `Item`=79768) OR
  (`Entry`=5312 AND `Item`=1180218) OR
  (`Entry`=5314 AND `Item`=1180219) OR
  (`Entry`=5317 AND `Item`=1180222);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2349, 79532, 0, 1, 0, 1, 0, 1, 1, 'Giant Moss Creeper - Beastmaster''s Whistle: Giant Moss Creeper'),
(2350, 79533, 0, 1, 0, 1, 0, 1, 1, 'Forest Moss Creeper - Beastmaster''s Whistle: Forest Moss Creeper'),
(2351, 79534, 0, 1, 0, 1, 0, 1, 1, 'Gray Bear - Beastmaster''s Whistle: Gray Bear'),
(2354, 79535, 0, 1, 0, 1, 0, 1, 1, 'Vicious Gray Bear - Beastmaster''s Whistle: Vicious Gray Bear'),
(2356, 79536, 0, 1, 0, 1, 0, 1, 1, 'Elder Gray Bear - Beastmaster''s Whistle: Elder Gray Bear'),
(2384, 79537, 0, 1, 0, 1, 0, 1, 1, 'Starving Mountain Lion - Beastmaster''s Whistle: Starving Mountain Lion'),
(2385, 79539, 0, 1, 0, 1, 0, 1, 1, 'Feral Mountain Lion - Beastmaster''s Whistle: Feral Mountain Lion'),
(2406, 79540, 0, 1, 0, 1, 0, 1, 1, 'Mountain Lion - Beastmaster''s Whistle: Mountain Lion'),
(2407, 79541, 0, 1, 0, 1, 0, 1, 1, 'Hulking Mountain Lion - Beastmaster''s Whistle: Hulking Mountain Lion'),
(2408, 79542, 0, 1, 0, 1, 0, 1, 1, 'Snapjaw - Beastmaster''s Whistle: Snapjaw'),
(2447, 1180168, 0, 1, 0, 1, 0, 1, 1, 'Narillasanz - Draconic Warhorn: Narillasanz'),
(2476, 79543, 0, 1, 0, 1, 0, 1, 1, 'Large Loch Crocolisk - Beastmaster''s Whistle: Large Loch Crocolisk'),
(2505, 79544, 0, 1, 0, 1, 0, 1, 1, 'Saltwater Snapjaw - Beastmaster''s Whistle: Saltwater Snapjaw'),
(2521, 79545, 0, 1, 0, 1, 0, 1, 1, 'Skymane Gorilla - Beastmaster''s Whistle: Skymane Gorilla'),
(2522, 79546, 0, 1, 0, 1, 0, 1, 1, 'Jaguero Stalker - Beastmaster''s Whistle: Jaguero Stalker'),
(2535, 87655, 0, 0.1, 0, 1, 0, 1, 1, 'Maury "Club Foot" Wilkins - Blood Soaked Vellum: Maury "Club Foot" Wilkins'),
(2536, 87656, 0, 0.1, 0, 1, 0, 1, 1, 'Jon-Jon the Crow - Blood Soaked Vellum: Jon-Jon the Crow'),
(2537, 87657, 0, 0.1, 0, 1, 0, 1, 1, 'Chucky "Ten Thumbs" - Blood Soaked Vellum: Chucky "Ten Thumbs"'),
(2544, 79547, 0, 1, 0, 1, 0, 1, 1, 'Southern Sand Crawler - Beastmaster''s Whistle: Southern Sand Crawler'),
(2551, 601669, 0, 1, 0, 1, 0, 1, 1, 'Brutus - Elemental Lodestone: Brutus'),
(2559, 79548, 0, 1, 0, 1, 0, 1, 1, 'Highland Strider - Beastmaster''s Whistle: Highland Strider'),
(2560, 79549, 0, 1, 0, 1, 0, 1, 1, 'Highland Thrasher - Beastmaster''s Whistle: Highland Thrasher'),
(2561, 79550, 0, 1, 0, 1, 0, 1, 1, 'Highland Fleshstalker - Beastmaster''s Whistle: Highland Fleshstalker'),
(2563, 79551, 0, 1, 0, 1, 0, 1, 1, 'Plains Creeper - Beastmaster''s Whistle: Plains Creeper'),
(2565, 79552, 0, 1, 0, 1, 0, 1, 1, 'Giant Plains Creeper - Beastmaster''s Whistle: Giant Plains Creeper'),
(2578, 79553, 0, 1, 0, 1, 0, 1, 1, 'Young Mesa Buzzard - Beastmaster''s Whistle: Young Mesa Buzzard'),
(2579, 79554, 0, 1, 0, 1, 0, 1, 1, 'Mesa Buzzard - Beastmaster''s Whistle: Mesa Buzzard'),
(2580, 79555, 0, 1, 0, 1, 0, 1, 1, 'Elder Mesa Buzzard - Beastmaster''s Whistle: Elder Mesa Buzzard'),
(2635, 79556, 0, 1, 0, 1, 0, 1, 1, 'Elder Saltwater Crocolisk - Beastmaster''s Whistle: Elder Saltwater Crocolisk'),
(2680, 79557, 0, 1, 0, 1, 0, 1, 1, 'Vilebranch Wolf Pup - Beastmaster''s Whistle: Vilebranch Wolf Pup'),
(2681, 79558, 0, 1, 0, 1, 0, 1, 1, 'Vilebranch Raiding Wolf - Beastmaster''s Whistle: Vilebranch Raiding Wolf'),
(2686, 79559, 0, 1, 0, 1, 0, 1, 1, 'Witherbark Broodguard - Beastmaster''s Whistle: Witherbark Broodguard'),
(2723, 601670, 0, 1, 0, 1, 0, 1, 1, 'Stone Golem - Elemental Lodestone: Stone Golem'),
(2725, 1180172, 0, 1, 0, 1, 0, 1, 1, 'Scalding Whelp - Draconic Warhorn: Scalding Whelp'),
(2726, 1180174, 0, 1, 0, 1, 0, 1, 1, 'Scorched Guardian - Draconic Warhorn: Scorched Guardian'),
(2727, 79560, 0, 1, 0, 1, 0, 1, 1, 'Crag Coyote - Beastmaster''s Whistle: Crag Coyote'),
(2728, 79561, 0, 1, 0, 1, 0, 1, 1, 'Feral Crag Coyote - Beastmaster''s Whistle: Feral Crag Coyote'),
(2729, 79562, 0, 1, 0, 1, 0, 1, 1, 'Elder Crag Coyote - Beastmaster''s Whistle: Elder Crag Coyote'),
(2730, 79563, 0, 1, 0, 1, 0, 1, 1, 'Rabid Crag Coyote - Beastmaster''s Whistle: Rabid Crag Coyote'),
(2731, 79564, 0, 1, 0, 1, 0, 1, 1, 'Ridge Stalker - Beastmaster''s Whistle: Ridge Stalker'),
(2732, 79565, 0, 1, 0, 1, 0, 1, 1, 'Ridge Huntress - Beastmaster''s Whistle: Ridge Huntress'),
(2734, 79566, 0, 1, 0, 1, 0, 1, 1, 'Ridge Stalker Patriarch - Beastmaster''s Whistle: Ridge Stalker Patriarch'),
(2749, 601671, 0, 1, 0, 1, 0, 1, 1, 'Siege Golem - Elemental Lodestone: Siege Golem'),
(2751, 601672, 0, 1, 0, 1, 0, 1, 1, 'War Golem - Elemental Lodestone: War Golem'),
(2753, 79567, 0, 1, 0, 1, 0, 1, 1, 'Barnabus - Beastmaster''s Whistle: Barnabus'),
(2757, 1180176, 0, 1, 0, 1, 0, 1, 1, 'Blacklash - Draconic Warhorn: Blacklash'),
(2761, 600370, 0, 1, 0, 1, 0, 1, 1, 'Cresting Exile - Elemental Lodestone: Cresting Exile'),
(2829, 79568, 0, 1, 0, 1, 0, 1, 1, 'Starving Buzzard - Beastmaster''s Whistle: Starving Buzzard'),
(2830, 79569, 0, 1, 0, 1, 0, 1, 1, 'Buzzard - Beastmaster''s Whistle: Buzzard'),
(2831, 79570, 0, 1, 0, 1, 0, 1, 1, 'Giant Buzzard - Beastmaster''s Whistle: Giant Buzzard'),
(2850, 79571, 0, 1, 0, 1, 0, 1, 1, 'Broken Tooth - Beastmaster''s Whistle: Broken Tooth'),
(2923, 79572, 0, 1, 0, 1, 0, 1, 1, 'Mangy Silvermane - Beastmaster''s Whistle: Mangy Silvermane'),
(2924, 79573, 0, 1, 0, 1, 0, 1, 1, 'Silvermane Wolf - Beastmaster''s Whistle: Silvermane Wolf'),
(2925, 79574, 0, 1, 0, 1, 0, 1, 1, 'Silvermane Howler - Beastmaster''s Whistle: Silvermane Howler'),
(2926, 79575, 0, 1, 0, 1, 0, 1, 1, 'Silvermane Stalker - Beastmaster''s Whistle: Silvermane Stalker'),
(2931, 79576, 0, 1, 0, 1, 0, 1, 1, 'Zaricotl - Beastmaster''s Whistle: Zaricotl'),
(2954, 79577, 0, 1, 0, 1, 0, 1, 1, 'Bristleback Battleboar - Beastmaster''s Whistle: Bristleback Battleboar'),
(2955, 79578, 0, 1, 0, 1, 0, 1, 1, 'Plainstrider - Beastmaster''s Whistle: Plainstrider'),
(2956, 79579, 0, 1, 0, 1, 0, 1, 1, 'Adult Plainstrider - Beastmaster''s Whistle: Adult Plainstrider'),
(2957, 79580, 0, 1, 0, 1, 0, 1, 1, 'Elder Plainstrider - Beastmaster''s Whistle: Elder Plainstrider'),
(2958, 79581, 0, 1, 0, 1, 0, 1, 1, 'Prairie Wolf - Beastmaster''s Whistle: Prairie Wolf'),
(2959, 79582, 0, 1, 0, 1, 0, 1, 1, 'Prairie Stalker - Beastmaster''s Whistle: Prairie Stalker'),
(2960, 79583, 0, 1, 0, 1, 0, 1, 1, 'Prairie Wolf Alpha - Beastmaster''s Whistle: Prairie Wolf Alpha'),
(2961, 79584, 0, 1, 0, 1, 0, 1, 1, 'Mountain Cougar - Beastmaster''s Whistle: Mountain Cougar'),
(2966, 79585, 0, 1, 0, 1, 0, 1, 1, 'Battleboar - Beastmaster''s Whistle: Battleboar'),
(2969, 79586, 0, 1, 0, 1, 0, 1, 1, 'Wiry Swoop - Beastmaster''s Whistle: Wiry Swoop'),
(2970, 79587, 0, 1, 0, 1, 0, 1, 1, 'Swoop - Beastmaster''s Whistle: Swoop'),
(2971, 79588, 0, 1, 0, 1, 0, 1, 1, 'Taloned Swoop - Beastmaster''s Whistle: Taloned Swoop'),
(3035, 79589, 0, 1, 0, 1, 0, 1, 1, 'Flatland Cougar - Beastmaster''s Whistle: Flatland Cougar'),
(3068, 79590, 0, 1, 0, 1, 0, 1, 1, 'Mazzranache - Beastmaster''s Whistle: Mazzranache'),
(3094, 87668, 0, 0.1, 0, 1, 0, 1, 1, 'Unseen - Blood Soaked Vellum: Unseen'),
(3098, 79591, 0, 1, 0, 1, 0, 1, 1, 'Mottled Boar - Beastmaster''s Whistle: Mottled Boar'),
(3099, 79592, 0, 1, 0, 1, 0, 1, 1, 'Dire Mottled Boar - Beastmaster''s Whistle: Dire Mottled Boar'),
(3100, 79593, 0, 1, 0, 1, 0, 1, 1, 'Elder Mottled Boar - Beastmaster''s Whistle: Elder Mottled Boar'),
(3106, 79594, 0, 1, 0, 1, 0, 1, 1, 'Pygmy Surf Crawler - Beastmaster''s Whistle: Pygmy Surf Crawler'),
(3107, 79595, 0, 1, 0, 1, 0, 1, 1, 'Surf Crawler - Beastmaster''s Whistle: Surf Crawler'),
(3108, 79596, 0, 1, 0, 1, 0, 1, 1, 'Encrusted Surf Crawler - Beastmaster''s Whistle: Encrusted Surf Crawler'),
(3110, 79597, 0, 1, 0, 1, 0, 1, 1, 'Dreadmaw Crocolisk - Beastmaster''s Whistle: Dreadmaw Crocolisk'),
(3121, 79598, 0, 1, 0, 1, 0, 1, 1, 'Durotar Tiger - Beastmaster''s Whistle: Durotar Tiger'),
(3122, 79599, 0, 1, 0, 1, 0, 1, 1, 'Bloodtalon Taillasher - Beastmaster''s Whistle: Bloodtalon Taillasher'),
(3123, 79600, 0, 1, 0, 1, 0, 1, 1, 'Bloodtalon Scythemaw - Beastmaster''s Whistle: Bloodtalon Scythemaw'),
(3124, 79601, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Worker - Beastmaster''s Whistle: Scorpid Worker'),
(3125, 79602, 0, 1, 0, 1, 0, 1, 1, 'Clattering Scorpid - Beastmaster''s Whistle: Clattering Scorpid'),
(3126, 79603, 0, 1, 0, 1, 0, 1, 1, 'Armored Scorpid - Beastmaster''s Whistle: Armored Scorpid'),
(3127, 79604, 0, 1, 0, 1, 0, 1, 1, 'Venomtail Scorpid - Beastmaster''s Whistle: Venomtail Scorpid'),
(3225, 79605, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Mottled Boar - Beastmaster''s Whistle: Corrupted Mottled Boar'),
(3226, 79606, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Scorpid - Beastmaster''s Whistle: Corrupted Scorpid'),
(3227, 79607, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Bloodtalon Scythemaw - Beastmaster''s Whistle: Corrupted Bloodtalon Scythemaw'),
(3228, 79608, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Surf Crawler - Beastmaster''s Whistle: Corrupted Surf Crawler'),
(3231, 79609, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Dreadmaw Crocolisk - Beastmaster''s Whistle: Corrupted Dreadmaw Crocolisk'),
(3241, 79610, 0, 1, 0, 1, 0, 1, 1, 'Savannah Patriarch - Beastmaster''s Whistle: Savannah Patriarch'),
(3243, 79611, 0, 1, 0, 1, 0, 1, 1, 'Savannah Highmane - Beastmaster''s Whistle: Savannah Highmane'),
(3244, 79612, 0, 1, 0, 1, 0, 1, 1, 'Greater Plainstrider - Beastmaster''s Whistle: Greater Plainstrider'),
(3245, 79613, 0, 1, 0, 1, 0, 1, 1, 'Ornery Plainstrider - Beastmaster''s Whistle: Ornery Plainstrider'),
(3246, 79614, 0, 1, 0, 1, 0, 1, 1, 'Fleeting Plainstrider - Beastmaster''s Whistle: Fleeting Plainstrider'),
(3247, 79615, 0, 1, 0, 1, 0, 1, 1, 'Thunderhawk Hatchling - Beastmaster''s Whistle: Thunderhawk Hatchling'),
(3249, 79616, 0, 1, 0, 1, 0, 1, 1, 'Greater Thunderhawk - Beastmaster''s Whistle: Greater Thunderhawk'),
(3250, 79617, 0, 1, 0, 1, 0, 1, 1, 'Silithid Creeper - Beastmaster''s Whistle: Silithid Creeper'),
(3252, 79618, 0, 1, 0, 1, 0, 1, 1, 'Silithid Swarmer - Beastmaster''s Whistle: Silithid Swarmer'),
(3254, 79619, 0, 1, 0, 1, 0, 1, 1, 'Sunscale Lashtail - Beastmaster''s Whistle: Sunscale Lashtail'),
(3255, 79620, 0, 1, 0, 1, 0, 1, 1, 'Sunscale Screecher - Beastmaster''s Whistle: Sunscale Screecher'),
(3256, 79621, 0, 1, 0, 1, 0, 1, 1, 'Sunscale Scytheclaw - Beastmaster''s Whistle: Sunscale Scytheclaw'),
(3281, 79622, 0, 1, 0, 1, 0, 1, 1, 'Sarkoth - Beastmaster''s Whistle: Sarkoth'),
(3415, 79623, 0, 1, 0, 1, 0, 1, 1, 'Savannah Huntress - Beastmaster''s Whistle: Savannah Huntress'),
(3416, 79624, 0, 1, 0, 1, 0, 1, 1, 'Savannah Matriarch - Beastmaster''s Whistle: Savannah Matriarch'),
(3424, 79625, 0, 1, 0, 1, 0, 1, 1, 'Thunderhawk Cloudscraper - Beastmaster''s Whistle: Thunderhawk Cloudscraper'),
(3425, 79626, 0, 1, 0, 1, 0, 1, 1, 'Savannah Prowler - Beastmaster''s Whistle: Savannah Prowler'),
(3461, 79627, 0, 1, 0, 1, 0, 1, 1, 'Oasis Snapjaw - Beastmaster''s Whistle: Oasis Snapjaw'),
(3472, 79628, 0, 1, 0, 1, 0, 1, 1, 'Washte Pawne - Beastmaster''s Whistle: Washte Pawne'),
(3535, 601045, 0, 1, 0, 1, 0, 1, 1, 'Blackmoss the Fetid - Elemental Lodestone: Blackmoss the Fetid'),
(3566, 79629, 0, 1, 0, 1, 0, 1, 1, 'Flatland Prowler - Beastmaster''s Whistle: Flatland Prowler'),
(3569, 601046, 0, 1, 0, 1, 0, 1, 1, 'Bogling - Elemental Lodestone: Bogling'),
(3630, 79631, 0, 1, 0, 1, 0, 1, 1, 'Deviate Coiler - Beastmaster''s Whistle: Deviate Coiler'),
(3631, 79632, 0, 1, 0, 1, 0, 1, 1, 'Deviate Stinglash - Beastmaster''s Whistle: Deviate Stinglash'),
(3632, 79633, 0, 1, 0, 1, 0, 1, 1, 'Deviate Creeper - Beastmaster''s Whistle: Deviate Creeper'),
(3633, 79634, 0, 1, 0, 1, 0, 1, 1, 'Deviate Slayer - Beastmaster''s Whistle: Deviate Slayer'),
(3634, 79635, 0, 1, 0, 1, 0, 1, 1, 'Deviate Stalker - Beastmaster''s Whistle: Deviate Stalker'),
(3636, 79636, 0, 1, 0, 1, 0, 1, 1, 'Deviate Ravager - Beastmaster''s Whistle: Deviate Ravager'),
(3637, 79637, 0, 1, 0, 1, 0, 1, 1, 'Deviate Guardian - Beastmaster''s Whistle: Deviate Guardian'),
(3653, 79638, 0, 1, 0, 1, 0, 1, 1, 'Kresh - Beastmaster''s Whistle: Kresh'),
(3662, 82354, 0, 1, 0, 1, 0, 1, 1, 'Delmanis the Hated - Summoner''s Stone: Delmanis the Hated'),
(3752, 82355, 0, 1, 0, 1, 0, 1, 1, 'Xavian Rogue - Summoner''s Stone: Xavian Rogue'),
(3754, 82356, 0, 1, 0, 1, 0, 1, 1, 'Xavian Betrayer - Summoner''s Stone: Xavian Betrayer'),
(3755, 82357, 0, 1, 0, 1, 0, 1, 1, 'Xavian Felsworn - Summoner''s Stone: Xavian Felsworn'),
(3757, 82358, 0, 1, 0, 1, 0, 1, 1, 'Xavian Hellcaller - Summoner''s Stone: Xavian Hellcaller'),
(3758, 82359, 0, 1, 0, 1, 0, 1, 1, 'Felmusk Satyr - Summoner''s Stone: Felmusk Satyr'),
(3759, 82360, 0, 1, 0, 1, 0, 1, 1, 'Felmusk Rogue - Summoner''s Stone: Felmusk Rogue'),
(3762, 82361, 0, 1, 0, 1, 0, 1, 1, 'Felmusk Felsworn - Summoner''s Stone: Felmusk Felsworn'),
(3763, 82362, 0, 1, 0, 1, 0, 1, 1, 'Felmusk Shadowstalker - Summoner''s Stone: Felmusk Shadowstalker'),
(3765, 82363, 0, 1, 0, 1, 0, 1, 1, 'Bleakheart Satyr - Summoner''s Stone: Bleakheart Satyr'),
(3767, 82364, 0, 1, 0, 1, 0, 1, 1, 'Bleakheart Trickster - Summoner''s Stone: Bleakheart Trickster'),
(3770, 82365, 0, 1, 0, 1, 0, 1, 1, 'Bleakheart Shadowstalker - Summoner''s Stone: Bleakheart Shadowstalker'),
(3771, 82366, 0, 1, 0, 1, 0, 1, 1, 'Bleakheart Hellcaller - Summoner''s Stone: Bleakheart Hellcaller'),
(3773, 82367, 0, 1, 0, 1, 0, 1, 1, 'Akkrilus - Summoner''s Stone: Akkrilus'),
(3780, 601048, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Moss Eater - Elemental Lodestone: Shadethicket Moss Eater'),
(3781, 601049, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Wood Shaper - Elemental Lodestone: Shadethicket Wood Shaper'),
(3782, 601050, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Stone Mover - Elemental Lodestone: Shadethicket Stone Mover'),
(3783, 601051, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Raincaller - Elemental Lodestone: Shadethicket Raincaller'),
(3784, 601052, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Bark Ripper - Elemental Lodestone: Shadethicket Bark Ripper'),
(3809, 79639, 0, 1, 0, 1, 0, 1, 1, 'Ashenvale Bear - Beastmaster''s Whistle: Ashenvale Bear'),
(3810, 79640, 0, 1, 0, 1, 0, 1, 1, 'Elder Ashenvale Bear - Beastmaster''s Whistle: Elder Ashenvale Bear'),
(3811, 79641, 0, 1, 0, 1, 0, 1, 1, 'Giant Ashenvale Bear - Beastmaster''s Whistle: Giant Ashenvale Bear'),
(3812, 79642, 0, 1, 0, 1, 0, 1, 1, 'Clattering Crawler - Beastmaster''s Whistle: Clattering Crawler'),
(3814, 79643, 0, 1, 0, 1, 0, 1, 1, 'Spined Crawler - Beastmaster''s Whistle: Spined Crawler'),
(3815, 1180188, 0, 1, 0, 1, 0, 1, 1, 'Blink Dragon - Draconic Warhorn: Blink Dragon'),
(3819, 79644, 0, 1, 0, 1, 0, 1, 1, 'Wildthorn Stalker - Beastmaster''s Whistle: Wildthorn Stalker'),
(3820, 79645, 0, 1, 0, 1, 0, 1, 1, 'Wildthorn Venomspitter - Beastmaster''s Whistle: Wildthorn Venomspitter'),
(3821, 79646, 0, 1, 0, 1, 0, 1, 1, 'Wildthorn Lurker - Beastmaster''s Whistle: Wildthorn Lurker'),
(3823, 79647, 0, 1, 0, 1, 0, 1, 1, 'Ghostpaw Runner - Beastmaster''s Whistle: Ghostpaw Runner'),
(3824, 79648, 0, 1, 0, 1, 0, 1, 1, 'Ghostpaw Howler - Beastmaster''s Whistle: Ghostpaw Howler'),
(3825, 79649, 0, 1, 0, 1, 0, 1, 1, 'Ghostpaw Alpha - Beastmaster''s Whistle: Ghostpaw Alpha'),
(3834, 601837, 0, 1, 0, 1, 0, 1, 1, 'Crazed Ancient - Elemental Lodestone: Crazed Ancient'),
(3861, 79650, 0, 1, 0, 1, 0, 1, 1, 'Bleak Worg - Beastmaster''s Whistle: Bleak Worg'),
(3862, 79651, 0, 1, 0, 1, 0, 1, 1, 'Slavering Worg - Beastmaster''s Whistle: Slavering Worg'),
(3866, 79652, 0, 1, 0, 1, 0, 1, 1, 'Vile Bat - Beastmaster''s Whistle: Vile Bat'),
(3868, 79653, 0, 1, 0, 1, 0, 1, 1, 'Blood Seeker - Beastmaster''s Whistle: Blood Seeker'),
(3898, 82368, 0, 1, 0, 1, 0, 1, 1, 'Aligar the Tormentor - Summoner''s Stone: Aligar the Tormentor'),
(3900, 82370, 0, 1, 0, 1, 0, 1, 1, 'Caedakar the Vicious - Summoner''s Stone: Caedakar the Vicious'),
(3917, 600373, 0, 1, 0, 1, 0, 1, 1, 'Befouled Water Elemental - Elemental Lodestone: Befouled Water Elemental'),
(3919, 601838, 0, 1, 0, 1, 0, 1, 1, 'Withered Ancient - Elemental Lodestone: Withered Ancient'),
(3931, 601053, 0, 1, 0, 1, 0, 1, 1, 'Shadethicket Oracle - Elemental Lodestone: Shadethicket Oracle'),
(4005, 79654, 0, 1, 0, 1, 0, 1, 1, 'Deepmoss Creeper - Beastmaster''s Whistle: Deepmoss Creeper'),
(4006, 79655, 0, 1, 0, 1, 0, 1, 1, 'Deepmoss Webspinner - Beastmaster''s Whistle: Deepmoss Webspinner'),
(4007, 79656, 0, 1, 0, 1, 0, 1, 1, 'Deepmoss Venomspitter - Beastmaster''s Whistle: Deepmoss Venomspitter'),
(4016, 1180189, 0, 1, 0, 1, 0, 1, 1, 'Fey Dragon - Draconic Warhorn: Fey Dragon'),
(4017, 1180191, 0, 1, 0, 1, 0, 1, 1, 'Wily Fey Dragon - Draconic Warhorn: Wily Fey Dragon'),
(4031, 79657, 0, 1, 0, 1, 0, 1, 1, 'Fledgling Chimaera - Beastmaster''s Whistle: Fledgling Chimaera'),
(4032, 79658, 0, 1, 0, 1, 0, 1, 1, 'Young Chimaera - Beastmaster''s Whistle: Young Chimaera'),
(4034, 600376, 0, 1, 0, 1, 0, 1, 1, 'Enraged Stone Spirit - Elemental Lodestone: Enraged Stone Spirit'),
(4040, 79659, 0, 1, 0, 1, 0, 1, 1, 'Cave Stalker - Beastmaster''s Whistle: Cave Stalker'),
(4066, 1180193, 0, 1, 0, 1, 0, 1, 1, 'Nal''taszar - Draconic Warhorn: Nal''taszar'),
(4067, 79660, 0, 1, 0, 1, 0, 1, 1, 'Twilight Runner - Beastmaster''s Whistle: Twilight Runner'),
(4117, 79661, 0, 1, 0, 1, 0, 1, 1, 'Cloud Serpent - Beastmaster''s Whistle: Cloud Serpent'),
(4118, 79662, 0, 1, 0, 1, 0, 1, 1, 'Venomous Cloud Serpent - Beastmaster''s Whistle: Venomous Cloud Serpent'),
(4119, 79663, 0, 1, 0, 1, 0, 1, 1, 'Elder Cloud Serpent - Beastmaster''s Whistle: Elder Cloud Serpent'),
(4124, 79664, 0, 1, 0, 1, 0, 1, 1, 'Needles Cougar - Beastmaster''s Whistle: Needles Cougar'),
(4126, 79665, 0, 1, 0, 1, 0, 1, 1, 'Crag Stalker - Beastmaster''s Whistle: Crag Stalker'),
(4127, 79666, 0, 1, 0, 1, 0, 1, 1, 'Hecklefang Hyena - Beastmaster''s Whistle: Hecklefang Hyena'),
(4128, 79667, 0, 1, 0, 1, 0, 1, 1, 'Hecklefang Stalker - Beastmaster''s Whistle: Hecklefang Stalker'),
(4129, 79668, 0, 1, 0, 1, 0, 1, 1, 'Hecklefang Snarler - Beastmaster''s Whistle: Hecklefang Snarler'),
(4132, 79669, 0, 1, 0, 1, 0, 1, 1, 'Silithid Ravager - Beastmaster''s Whistle: Silithid Ravager'),
(4139, 79670, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Terror - Beastmaster''s Whistle: Scorpid Terror'),
(4140, 79671, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Reaver - Beastmaster''s Whistle: Scorpid Reaver'),
(4142, 79672, 0, 1, 0, 1, 0, 1, 1, 'Sparkleshell Tortoise - Beastmaster''s Whistle: Sparkleshell Tortoise'),
(4143, 79673, 0, 1, 0, 1, 0, 1, 1, 'Sparkleshell Snapper - Beastmaster''s Whistle: Sparkleshell Snapper'),
(4144, 79674, 0, 1, 0, 1, 0, 1, 1, 'Sparkleshell Borer - Beastmaster''s Whistle: Sparkleshell Borer'),
(4154, 79675, 0, 1, 0, 1, 0, 1, 1, 'Salt Flats Scavenger - Beastmaster''s Whistle: Salt Flats Scavenger'),
(4158, 79676, 0, 1, 0, 1, 0, 1, 1, 'Salt Flats Vulture - Beastmaster''s Whistle: Salt Flats Vulture'),
(4248, 79677, 0, 1, 0, 1, 0, 1, 1, 'Pesterhide Hyena - Beastmaster''s Whistle: Pesterhide Hyena'),
(4249, 79678, 0, 1, 0, 1, 0, 1, 1, 'Pesterhide Snarler - Beastmaster''s Whistle: Pesterhide Snarler'),
(4250, 79679, 0, 1, 0, 1, 0, 1, 1, 'Galak Packhound - Beastmaster''s Whistle: Galak Packhound'),
(4304, 79680, 0, 1, 0, 1, 0, 1, 1, 'Scarlet Tracking Hound - Beastmaster''s Whistle: Scarlet Tracking Hound'),
(4308, 87674, 0, 0.1, 0, 1, 0, 1, 1, 'Unfettered Spirit - Blood Soaked Vellum: Unfettered Spirit'),
(4316, 79681, 0, 1, 0, 1, 0, 1, 1, 'Kolkar Packhound - Beastmaster''s Whistle: Kolkar Packhound'),
(4323, 1180194, 0, 1, 0, 1, 0, 1, 1, 'Searing Hatchling - Draconic Warhorn: Searing Hatchling'),
(4324, 1180195, 0, 1, 0, 1, 0, 1, 1, 'Searing Whelp - Draconic Warhorn: Searing Whelp'),
(4328, 1180196, 0, 1, 0, 1, 0, 1, 1, 'Firemane Scalebane - Draconic Warhorn: Firemane Scalebane'),
(4329, 1180198, 0, 1, 0, 1, 0, 1, 1, 'Firemane Scout - Draconic Warhorn: Firemane Scout'),
(4331, 1180200, 0, 1, 0, 1, 0, 1, 1, 'Firemane Ash Tail - Draconic Warhorn: Firemane Ash Tail'),
(4334, 1180204, 0, 1, 0, 1, 0, 1, 1, 'Firemane Flamecaller - Draconic Warhorn: Firemane Flamecaller'),
(4339, 1180206, 0, 1, 0, 1, 0, 1, 1, 'Brimgore - Draconic Warhorn: Brimgore'),
(4341, 79682, 0, 1, 0, 1, 0, 1, 1, 'Drywallow Crocolisk - Beastmaster''s Whistle: Drywallow Crocolisk'),
(4343, 79683, 0, 1, 0, 1, 0, 1, 1, 'Drywallow Snapper - Beastmaster''s Whistle: Drywallow Snapper'),
(4344, 79684, 0, 1, 0, 1, 0, 1, 1, 'Mottled Drywallow Crocolisk - Beastmaster''s Whistle: Mottled Drywallow Crocolisk'),
(4345, 79685, 0, 1, 0, 1, 0, 1, 1, 'Drywallow Daggermaw - Beastmaster''s Whistle: Drywallow Daggermaw'),
(4346, 79686, 0, 1, 0, 1, 0, 1, 1, 'Noxious Flayer - Beastmaster''s Whistle: Noxious Flayer'),
(4347, 79687, 0, 1, 0, 1, 0, 1, 1, 'Noxious Reaver - Beastmaster''s Whistle: Noxious Reaver'),
(4348, 79688, 0, 1, 0, 1, 0, 1, 1, 'Noxious Shredder - Beastmaster''s Whistle: Noxious Shredder'),
(4351, 79689, 0, 1, 0, 1, 0, 1, 1, 'Bloodfen Raptor - Beastmaster''s Whistle: Bloodfen Raptor'),
(4352, 79690, 0, 1, 0, 1, 0, 1, 1, 'Bloodfen Screecher - Beastmaster''s Whistle: Bloodfen Screecher'),
(4356, 79691, 0, 1, 0, 1, 0, 1, 1, 'Bloodfen Razormaw - Beastmaster''s Whistle: Bloodfen Razormaw'),
(4357, 79692, 0, 1, 0, 1, 0, 1, 1, 'Bloodfen Lashtail - Beastmaster''s Whistle: Bloodfen Lashtail'),
(4376, 79693, 0, 1, 0, 1, 0, 1, 1, 'Darkmist Spider - Beastmaster''s Whistle: Darkmist Spider'),
(4378, 79694, 0, 1, 0, 1, 0, 1, 1, 'Darkmist Recluse - Beastmaster''s Whistle: Darkmist Recluse'),
(4379, 79695, 0, 1, 0, 1, 0, 1, 1, 'Darkmist Silkspinner - Beastmaster''s Whistle: Darkmist Silkspinner'),
(4380, 79696, 0, 1, 0, 1, 0, 1, 1, 'Darkmist Widow - Beastmaster''s Whistle: Darkmist Widow'),
(4382, 601054, 0, 1, 0, 1, 0, 1, 1, 'Withervine Creeper - Elemental Lodestone: Withervine Creeper'),
(4385, 601055, 0, 1, 0, 1, 0, 1, 1, 'Withervine Rager - Elemental Lodestone: Withervine Rager'),
(4386, 601056, 0, 1, 0, 1, 0, 1, 1, 'Withervine Bark Ripper - Elemental Lodestone: Withervine Bark Ripper'),
(4387, 601057, 0, 1, 0, 1, 0, 1, 1, 'Withervine Mire Beast - Elemental Lodestone: Withervine Mire Beast'),
(4397, 79697, 0, 1, 0, 1, 0, 1, 1, 'Mudrock Spikeshell - Beastmaster''s Whistle: Mudrock Spikeshell'),
(4412, 79698, 0, 1, 0, 1, 0, 1, 1, 'Darkfang Creeper - Beastmaster''s Whistle: Darkfang Creeper'),
(4414, 79699, 0, 1, 0, 1, 0, 1, 1, 'Darkfang Venomspitter - Beastmaster''s Whistle: Darkfang Venomspitter'),
(4415, 79700, 0, 1, 0, 1, 0, 1, 1, 'Giant Darkfang Spider - Beastmaster''s Whistle: Giant Darkfang Spider'),
(4425, 79701, 0, 1, 0, 1, 0, 1, 1, 'Blind Hunter - Beastmaster''s Whistle: Blind Hunter'),
(4472, 87675, 0, 0.1, 0, 1, 0, 1, 1, 'Haunting Vision - Blood Soaked Vellum: Haunting Vision'),
(4474, 87676, 0, 0.1, 0, 1, 0, 1, 1, 'Rotting Cadaver - Blood Soaked Vellum: Rotting Cadaver'),
(4475, 87677, 0, 0.1, 0, 1, 0, 1, 1, 'Blighted Zombie - Blood Soaked Vellum: Blighted Zombie'),
(4511, 79702, 0, 1, 0, 1, 0, 1, 1, 'Agam''ar - Beastmaster''s Whistle: Agam''ar'),
(4512, 79703, 0, 1, 0, 1, 0, 1, 1, 'Rotting Agam''ar - Beastmaster''s Whistle: Rotting Agam''ar'),
(4514, 79704, 0, 1, 0, 1, 0, 1, 1, 'Raging Agam''ar - Beastmaster''s Whistle: Raging Agam''ar'),
(4538, 79705, 0, 1, 0, 1, 0, 1, 1, 'Kraul Bat - Beastmaster''s Whistle: Kraul Bat'),
(4539, 79706, 0, 1, 0, 1, 0, 1, 1, 'Greater Kraul Bat - Beastmaster''s Whistle: Greater Kraul Bat'),
(4543, 87690, 0, 0.1, 0, 1, 0, 1, 1, 'Bloodmage Thalnos - Blood Soaked Vellum: Bloodmage Thalnos'),
(4548, 79707, 0, 1, 0, 1, 0, 1, 1, 'Steelsnap - Beastmaster''s Whistle: Steelsnap'),
(4619, 82371, 0, 1, 0, 1, 0, 1, 1, 'Geltharis - Summoner''s Stone: Geltharis'),
(4662, 79708, 0, 1, 0, 1, 0, 1, 1, 'Magram Bonepaw - Beastmaster''s Whistle: Magram Bonepaw'),
(4670, 82372, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Rogue - Summoner''s Stone: Hatefury Rogue'),
(4671, 82373, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Trickster - Summoner''s Stone: Hatefury Trickster'),
(4672, 82374, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Felsworn - Summoner''s Stone: Hatefury Felsworn'),
(4673, 82375, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Betrayer - Summoner''s Stone: Hatefury Betrayer'),
(4674, 82376, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Shadowstalker - Summoner''s Stone: Hatefury Shadowstalker'),
(4675, 82377, 0, 1, 0, 1, 0, 1, 1, 'Hatefury Hellcaller - Summoner''s Stone: Hatefury Hellcaller'),
(4676, 82378, 0, 1, 0, 1, 0, 1, 1, 'Lesser Infernal - Summoner''s Stone: Lesser Infernal'),
(4688, 79709, 0, 1, 0, 1, 0, 1, 1, 'Bonepaw Hyena - Beastmaster''s Whistle: Bonepaw Hyena'),
(4689, 79714, 0, 1, 0, 1, 0, 1, 1, 'Starving Bonepaw - Beastmaster''s Whistle: Starving Bonepaw'),
(4690, 79725, 0, 1, 0, 1, 0, 1, 1, 'Rabid Bonepaw - Beastmaster''s Whistle: Rabid Bonepaw'),
(4692, 79726, 0, 1, 0, 1, 0, 1, 1, 'Dread Swoop - Beastmaster''s Whistle: Dread Swoop'),
(4693, 79727, 0, 1, 0, 1, 0, 1, 1, 'Dread Flyer - Beastmaster''s Whistle: Dread Flyer'),
(4694, 79728, 0, 1, 0, 1, 0, 1, 1, 'Dread Ripper - Beastmaster''s Whistle: Dread Ripper'),
(4695, 79729, 0, 1, 0, 1, 0, 1, 1, 'Carrion Horror - Beastmaster''s Whistle: Carrion Horror'),
(4696, 79730, 0, 1, 0, 1, 0, 1, 1, 'Scorpashi Snapper - Beastmaster''s Whistle: Scorpashi Snapper'),
(4697, 79732, 0, 1, 0, 1, 0, 1, 1, 'Scorpashi Lasher - Beastmaster''s Whistle: Scorpashi Lasher'),
(4699, 79733, 0, 1, 0, 1, 0, 1, 1, 'Scorpashi Venomlash - Beastmaster''s Whistle: Scorpashi Venomlash'),
(4788, 82379, 0, 1, 0, 1, 0, 1, 1, 'Fallenroot Satyr - Summoner''s Stone: Fallenroot Satyr'),
(4789, 82380, 0, 1, 0, 1, 0, 1, 1, 'Fallenroot Rogue - Summoner''s Stone: Fallenroot Rogue'),
(4798, 82385, 0, 1, 0, 1, 0, 1, 1, 'Fallenroot Shadowstalker - Summoner''s Stone: Fallenroot Shadowstalker'),
(4799, 82386, 0, 1, 0, 1, 0, 1, 1, 'Fallenroot Hellcaller - Summoner''s Stone: Fallenroot Hellcaller'),
(4821, 79736, 0, 1, 0, 1, 0, 1, 1, 'Skittering Crustacean - Beastmaster''s Whistle: Skittering Crustacean'),
(4822, 79737, 0, 1, 0, 1, 0, 1, 1, 'Snapping Crustacean - Beastmaster''s Whistle: Snapping Crustacean'),
(4823, 79738, 0, 1, 0, 1, 0, 1, 1, 'Barbed Crustacean - Beastmaster''s Whistle: Barbed Crustacean'),
(4824, 79739, 0, 1, 0, 1, 0, 1, 1, 'Aku''mai Fisher - Beastmaster''s Whistle: Aku''mai Fisher'),
(4825, 79741, 0, 1, 0, 1, 0, 1, 1, 'Aku''mai Snapjaw - Beastmaster''s Whistle: Aku''mai Snapjaw'),
(4841, 79742, 0, 1, 0, 1, 0, 1, 1, 'Deadmire - Beastmaster''s Whistle: Deadmire'),
(4857, 601673, 0, 1, 0, 1, 0, 1, 1, 'Stone Keeper - Elemental Lodestone: Stone Keeper'),
(4860, 601674, 0, 1, 0, 1, 0, 1, 1, 'Stone Steward - Elemental Lodestone: Stone Steward'),
(4861, 79743, 0, 1, 0, 1, 0, 1, 1, 'Shrike Bat - Beastmaster''s Whistle: Shrike Bat'),
(4887, 79747, 0, 1, 0, 1, 0, 1, 1, 'Ghamoo-ra - Beastmaster''s Whistle: Ghamoo-ra'),
(4950, 79748, 0, 1, 0, 1, 0, 1, 1, 'Spot - Beastmaster''s Whistle: Spot'),
(4978, 600378, 0, 1, 0, 1, 0, 1, 1, 'Aku''mai Servant - Elemental Lodestone: Aku''mai Servant'),
(5048, 79751, 0, 1, 0, 1, 0, 1, 1, 'Deviate Adder - Beastmaster''s Whistle: Deviate Adder'),
(5053, 79752, 0, 1, 0, 1, 0, 1, 1, 'Deviate Crocolisk - Beastmaster''s Whistle: Deviate Crocolisk'),
(5055, 601103, 0, 1, 0, 1, 0, 1, 1, 'Deviate Lasher - Elemental Lodestone: Deviate Lasher'),
(5056, 79754, 0, 1, 0, 1, 0, 1, 1, 'Deviate Dreadfang - Beastmaster''s Whistle: Deviate Dreadfang'),
(5224, 79755, 0, 1, 0, 1, 0, 1, 1, 'Murk Slitherer - Beastmaster''s Whistle: Murk Slitherer'),
(5225, 79756, 0, 1, 0, 1, 0, 1, 1, 'Murk Spitter - Beastmaster''s Whistle: Murk Spitter'),
(5226, 79757, 0, 1, 0, 1, 0, 1, 1, 'Murk Worm - Beastmaster''s Whistle: Murk Worm'),
(5260, 79758, 0, 1, 0, 1, 0, 1, 1, 'Groddoc Ape - Beastmaster''s Whistle: Groddoc Ape'),
(5262, 79759, 0, 1, 0, 1, 0, 1, 1, 'Groddoc Thunderer - Beastmaster''s Whistle: Groddoc Thunderer'),
(5263, 87691, 0, 0.1, 0, 1, 0, 1, 1, 'Mummified Atal''ai - Blood Soaked Vellum: Mummified Atal''ai'),
(5267, 87692, 0, 0.1, 0, 1, 0, 1, 1, 'Unliving Atal''ai - Blood Soaked Vellum: Unliving Atal''ai'),
(5268, 79760, 0, 1, 0, 1, 0, 1, 1, 'Ironfur Bear - Beastmaster''s Whistle: Ironfur Bear'),
(5270, 87693, 0, 0.1, 0, 1, 0, 1, 1, 'Atal''ai Corpse Eater - Blood Soaked Vellum: Atal''ai Corpse Eater'),
(5271, 87694, 0, 0.1, 0, 1, 0, 1, 1, 'Atal''ai Deathwalker - Blood Soaked Vellum: Atal''ai Deathwalker'),
(5272, 79761, 0, 1, 0, 1, 0, 1, 1, 'Grizzled Ironfur Bear - Beastmaster''s Whistle: Grizzled Ironfur Bear'),
(5274, 79762, 0, 1, 0, 1, 0, 1, 1, 'Ironfur Patriarch - Beastmaster''s Whistle: Ironfur Patriarch'),
(5276, 1180208, 0, 1, 0, 1, 0, 1, 1, 'Sprite Dragon - Draconic Warhorn: Sprite Dragon'),
(5277, 1180210, 0, 1, 0, 1, 0, 1, 1, 'Nightmare Scalebane - Draconic Warhorn: Nightmare Scalebane'),
(5278, 1180212, 0, 1, 0, 1, 0, 1, 1, 'Sprite Darter - Draconic Warhorn: Sprite Darter'),
(5280, 1180214, 0, 1, 0, 1, 0, 1, 1, 'Nightmare Wyrmkin - Draconic Warhorn: Nightmare Wyrmkin'),
(5283, 1180216, 0, 1, 0, 1, 0, 1, 1, 'Nightmare Wanderer - Draconic Warhorn: Nightmare Wanderer'),
(5286, 79763, 0, 1, 0, 1, 0, 1, 1, 'Longtooth Runner - Beastmaster''s Whistle: Longtooth Runner'),
(5287, 79764, 0, 1, 0, 1, 0, 1, 1, 'Longtooth Howler - Beastmaster''s Whistle: Longtooth Howler'),
(5288, 79765, 0, 1, 0, 1, 0, 1, 1, 'Rabid Longtooth - Beastmaster''s Whistle: Rabid Longtooth'),
(5291, 79766, 0, 1, 0, 1, 0, 1, 1, 'Hakkari Frostwing - Beastmaster''s Whistle: Hakkari Frostwing'),
(5307, 79767, 0, 1, 0, 1, 0, 1, 1, 'Vale Screecher - Beastmaster''s Whistle: Vale Screecher'),
(5308, 79768, 0, 1, 0, 1, 0, 1, 1, 'Rogue Vale Screecher - Beastmaster''s Whistle: Rogue Vale Screecher'),
(5312, 1180218, 0, 1, 0, 1, 0, 1, 1, 'Lethlas - Draconic Warhorn: Lethlas'),
(5314, 1180219, 0, 1, 0, 1, 0, 1, 1, 'Phantim - Draconic Warhorn: Phantim'),
(5317, 1180222, 0, 1, 0, 1, 0, 1, 1, 'Jademir Oracle - Draconic Warhorn: Jademir Oracle');
DELETE FROM `creature_loot_template` WHERE (`Entry`=5319 AND `Item`=1180223) OR
  (`Entry`=5320 AND `Item`=1180224) OR
  (`Entry`=5348 AND `Item`=1180225) OR
  (`Entry`=5349 AND `Item`=79770) OR
  (`Entry`=5352 AND `Item`=79772) OR
  (`Entry`=5356 AND `Item`=79773) OR
  (`Entry`=5422 AND `Item`=79774) OR
  (`Entry`=5423 AND `Item`=79776) OR
  (`Entry`=5424 AND `Item`=79777) OR
  (`Entry`=5425 AND `Item`=79778) OR
  (`Entry`=5426 AND `Item`=79779) OR
  (`Entry`=5427 AND `Item`=79781) OR
  (`Entry`=5428 AND `Item`=79782) OR
  (`Entry`=5429 AND `Item`=79783) OR
  (`Entry`=5430 AND `Item`=79794) OR
  (`Entry`=5431 AND `Item`=79814) OR
  (`Entry`=5432 AND `Item`=79815) OR
  (`Entry`=5454 AND `Item`=79816) OR
  (`Entry`=5460 AND `Item`=79817) OR
  (`Entry`=5461 AND `Item`=600379) OR
  (`Entry`=5462 AND `Item`=600380) OR
  (`Entry`=5481 AND `Item`=601058) OR
  (`Entry`=5485 AND `Item`=601059) OR
  (`Entry`=5490 AND `Item`=601060) OR
  (`Entry`=5708 AND `Item`=79818) OR
  (`Entry`=5709 AND `Item`=1180226) OR
  (`Entry`=5711 AND `Item`=87697) OR
  (`Entry`=5712 AND `Item`=87698) OR
  (`Entry`=5713 AND `Item`=87699) OR
  (`Entry`=5714 AND `Item`=87700) OR
  (`Entry`=5715 AND `Item`=87711) OR
  (`Entry`=5716 AND `Item`=87717) OR
  (`Entry`=5717 AND `Item`=87718) OR
  (`Entry`=5718 AND `Item`=1180228) OR
  (`Entry`=5719 AND `Item`=1180229) OR
  (`Entry`=5720 AND `Item`=1180230) OR
  (`Entry`=5721 AND `Item`=1180231) OR
  (`Entry`=5722 AND `Item`=1180232) OR
  (`Entry`=5755 AND `Item`=79821) OR
  (`Entry`=5756 AND `Item`=79822) OR
  (`Entry`=5760 AND `Item`=82390) OR
  (`Entry`=5761 AND `Item`=601061) OR
  (`Entry`=5775 AND `Item`=601062) OR
  (`Entry`=5807 AND `Item`=79861) OR
  (`Entry`=5823 AND `Item`=79862) OR
  (`Entry`=5828 AND `Item`=79863) OR
  (`Entry`=5829 AND `Item`=79865) OR
  (`Entry`=5834 AND `Item`=79872) OR
  (`Entry`=5842 AND `Item`=79873) OR
  (`Entry`=5853 AND `Item`=601675) OR
  (`Entry`=5855 AND `Item`=600381) OR
  (`Entry`=5856 AND `Item`=79874) OR
  (`Entry`=5857 AND `Item`=79876) OR
  (`Entry`=5858 AND `Item`=79877) OR
  (`Entry`=5865 AND `Item`=79878) OR
  (`Entry`=5881 AND `Item`=601834) OR
  (`Entry`=5894 AND `Item`=600383) OR
  (`Entry`=5912 AND `Item`=1180233) OR
  (`Entry`=5937 AND `Item`=79879) OR
  (`Entry`=5982 AND `Item`=79881) OR
  (`Entry`=5982 AND `Item`=79882) OR
  (`Entry`=5983 AND `Item`=79881) OR
  (`Entry`=5983 AND `Item`=79882) OR
  (`Entry`=5984 AND `Item`=79883) OR
  (`Entry`=5985 AND `Item`=79886) OR
  (`Entry`=5988 AND `Item`=79887) OR
  (`Entry`=5992 AND `Item`=79888) OR
  (`Entry`=6072 AND `Item`=82391) OR
  (`Entry`=6073 AND `Item`=82452) OR
  (`Entry`=6109 AND `Item`=1180234) OR
  (`Entry`=6116 AND `Item`=87719) OR
  (`Entry`=6117 AND `Item`=87720) OR
  (`Entry`=6118 AND `Item`=87731) OR
  (`Entry`=6125 AND `Item`=82454) OR
  (`Entry`=6126 AND `Item`=82455) OR
  (`Entry`=6127 AND `Item`=82456) OR
  (`Entry`=6128 AND `Item`=82457) OR
  (`Entry`=6129 AND `Item`=1180235) OR
  (`Entry`=6130 AND `Item`=1180237) OR
  (`Entry`=6131 AND `Item`=1180238) OR
  (`Entry`=6167 AND `Item`=79889) OR
  (`Entry`=6200 AND `Item`=82458) OR
  (`Entry`=6201 AND `Item`=82459) OR
  (`Entry`=6202 AND `Item`=82461) OR
  (`Entry`=6220 AND `Item`=600387) OR
  (`Entry`=6352 AND `Item`=79890) OR
  (`Entry`=6369 AND `Item`=79891) OR
  (`Entry`=6426 AND `Item`=87732) OR
  (`Entry`=6427 AND `Item`=87733) OR
  (`Entry`=6489 AND `Item`=87734) OR
  (`Entry`=6498 AND `Item`=79892) OR
  (`Entry`=6499 AND `Item`=79893) OR
  (`Entry`=6500 AND `Item`=79918) OR
  (`Entry`=6505 AND `Item`=79919) OR
  (`Entry`=6506 AND `Item`=79920) OR
  (`Entry`=6507 AND `Item`=79921) OR
  (`Entry`=6508 AND `Item`=79922) OR
  (`Entry`=6509 AND `Item`=601104) OR
  (`Entry`=6510 AND `Item`=601195) OR
  (`Entry`=6511 AND `Item`=601196) OR
  (`Entry`=6512 AND `Item`=601197) OR
  (`Entry`=6513 AND `Item`=79923) OR
  (`Entry`=6514 AND `Item`=79924) OR
  (`Entry`=6516 AND `Item`=79925) OR
  (`Entry`=6517 AND `Item`=601063) OR
  (`Entry`=6518 AND `Item`=601064) OR
  (`Entry`=6519 AND `Item`=601065) OR
  (`Entry`=6527 AND `Item`=601066) OR
  (`Entry`=6553 AND `Item`=79926) OR
  (`Entry`=6560 AND `Item`=601676) OR
  (`Entry`=6581 AND `Item`=79927) OR
  (`Entry`=6582 AND `Item`=79928) OR
  (`Entry`=6584 AND `Item`=79930) OR
  (`Entry`=6585 AND `Item`=79931) OR
  (`Entry`=6652 AND `Item`=82466) OR
  (`Entry`=6788 AND `Item`=79943) OR
  (`Entry`=6789 AND `Item`=79944) OR
  (`Entry`=7022 AND `Item`=79945) OR
  (`Entry`=7031 AND `Item`=600390) OR
  (`Entry`=7032 AND `Item`=600391) OR
  (`Entry`=7039 AND `Item`=601678) OR
  (`Entry`=7040 AND `Item`=1180240) OR
  (`Entry`=7041 AND `Item`=1180243) OR
  (`Entry`=7042 AND `Item`=1180246) OR
  (`Entry`=7043 AND `Item`=1180248) OR
  (`Entry`=7044 AND `Item`=1180250) OR
  (`Entry`=7045 AND `Item`=1180253) OR
  (`Entry`=7046 AND `Item`=1180255) OR
  (`Entry`=7047 AND `Item`=1180257) OR
  (`Entry`=7048 AND `Item`=1180259) OR
  (`Entry`=7049 AND `Item`=1180261) OR
  (`Entry`=7055 AND `Item`=79946) OR
  (`Entry`=7078 AND `Item`=79947) OR
  (`Entry`=7079 AND `Item`=600392) OR
  (`Entry`=7097 AND `Item`=79948) OR
  (`Entry`=7098 AND `Item`=79949) OR
  (`Entry`=7099 AND `Item`=79950) OR
  (`Entry`=7100 AND `Item`=601068) OR
  (`Entry`=7101 AND `Item`=601069) OR
  (`Entry`=7104 AND `Item`=601070) OR
  (`Entry`=7105 AND `Item`=82724) OR
  (`Entry`=7106 AND `Item`=82725) OR
  (`Entry`=7107 AND `Item`=82726) OR
  (`Entry`=7108 AND `Item`=82727) OR
  (`Entry`=7109 AND `Item`=82728) OR
  (`Entry`=7110 AND `Item`=82729) OR
  (`Entry`=7111 AND `Item`=82730) OR
  (`Entry`=7132 AND `Item`=600393) OR
  (`Entry`=7135 AND `Item`=82731) OR
  (`Entry`=7136 AND `Item`=82732) OR
  (`Entry`=7137 AND `Item`=82733) OR
  (`Entry`=7138 AND `Item`=601845) OR
  (`Entry`=7139 AND `Item`=601846) OR
  (`Entry`=7143 AND `Item`=601847) OR
  (`Entry`=7144 AND `Item`=601848) OR
  (`Entry`=7146 AND `Item`=601849) OR
  (`Entry`=7206 AND `Item`=601679) OR
  (`Entry`=7268 AND `Item`=79951) OR
  (`Entry`=7272 AND `Item`=87735) OR
  (`Entry`=7276 AND `Item`=87736) OR
  (`Entry`=7276 AND `Item`=89801) OR
  (`Entry`=7286 AND `Item`=87737) OR
  (`Entry`=7319 AND `Item`=79981) OR
  (`Entry`=7327 AND `Item`=87749) OR
  (`Entry`=7328 AND `Item`=87765) OR
  (`Entry`=7329 AND `Item`=87766) OR
  (`Entry`=7332 AND `Item`=87767) OR
  (`Entry`=7333 AND `Item`=87778) OR
  (`Entry`=7334 AND `Item`=87808) OR
  (`Entry`=7340 AND `Item`=87809) OR
  (`Entry`=7341 AND `Item`=87810) OR
  (`Entry`=7342 AND `Item`=87818) OR
  (`Entry`=7344 AND `Item`=87819) OR
  (`Entry`=7345 AND `Item`=87820) OR
  (`Entry`=7346 AND `Item`=87840) OR
  (`Entry`=7347 AND `Item`=87842) OR
  (`Entry`=7348 AND `Item`=87845) OR
  (`Entry`=7349 AND `Item`=87847) OR
  (`Entry`=7351 AND `Item`=87851) OR
  (`Entry`=7352 AND `Item`=87852) OR
  (`Entry`=7353 AND `Item`=87857) OR
  (`Entry`=7355 AND `Item`=87858) OR
  (`Entry`=7357 AND `Item`=87859) OR
  (`Entry`=7370 AND `Item`=87860) OR
  (`Entry`=7376 AND `Item`=79982) OR
  (`Entry`=7405 AND `Item`=79991) OR
  (`Entry`=7430 AND `Item`=79992) OR
  (`Entry`=7431 AND `Item`=79993) OR
  (`Entry`=7432 AND `Item`=79994) OR
  (`Entry`=7433 AND `Item`=79995) OR
  (`Entry`=7434 AND `Item`=79996) OR
  (`Entry`=7435 AND `Item`=1180264) OR
  (`Entry`=7436 AND `Item`=1180266) OR
  (`Entry`=7437 AND `Item`=1180268) OR
  (`Entry`=7443 AND `Item`=79997) OR
  (`Entry`=7444 AND `Item`=79998) OR
  (`Entry`=7445 AND `Item`=80030) OR
  (`Entry`=7446 AND `Item`=80031) OR
  (`Entry`=7447 AND `Item`=80032) OR
  (`Entry`=7448 AND `Item`=80033) OR
  (`Entry`=7449 AND `Item`=80034) OR
  (`Entry`=7455 AND `Item`=80035) OR
  (`Entry`=7456 AND `Item`=80036) OR
  (`Entry`=7523 AND `Item`=87861) OR
  (`Entry`=7524 AND `Item`=87863) OR
  (`Entry`=7584 AND `Item`=601835) OR
  (`Entry`=7664 AND `Item`=82734) OR
  (`Entry`=7796 AND `Item`=87865) OR
  (`Entry`=7846 AND `Item`=1180270) OR
  (`Entry`=7864 AND `Item`=87867) OR
  (`Entry`=7977 AND `Item`=80037) OR
  (`Entry`=7997 AND `Item`=1180272) OR
  (`Entry`=8196 AND `Item`=1180273) OR
  (`Entry`=8197 AND `Item`=1180274) OR
  (`Entry`=8198 AND `Item`=1180276) OR
  (`Entry`=8204 AND `Item`=80038) OR
  (`Entry`=8205 AND `Item`=80039) OR
  (`Entry`=8207 AND `Item`=80041) OR
  (`Entry`=8208 AND `Item`=80042) OR
  (`Entry`=8211 AND `Item`=80043) OR
  (`Entry`=8213 AND `Item`=80044) OR
  (`Entry`=8277 AND `Item`=80045) OR
  (`Entry`=8278 AND `Item`=600396) OR
  (`Entry`=8279 AND `Item`=601680) OR
  (`Entry`=8280 AND `Item`=82744) OR
  (`Entry`=8299 AND `Item`=80046) OR
  (`Entry`=8300 AND `Item`=80047) OR
  (`Entry`=8301 AND `Item`=80048) OR
  (`Entry`=8303 AND `Item`=80049) OR
  (`Entry`=8319 AND `Item`=1180278) OR
  (`Entry`=8336 AND `Item`=80050) OR
  (`Entry`=8384 AND `Item`=601071) OR
  (`Entry`=8497 AND `Item`=1180281) OR
  (`Entry`=8519 AND `Item`=600397) OR
  (`Entry`=8520 AND `Item`=600398) OR
  (`Entry`=8521 AND `Item`=600399) OR
  (`Entry`=8522 AND `Item`=600400) OR
  (`Entry`=8523 AND `Item`=87868) OR
  (`Entry`=8524 AND `Item`=87869) OR
  (`Entry`=8525 AND `Item`=87870) OR
  (`Entry`=8526 AND `Item`=87873) OR
  (`Entry`=8527 AND `Item`=87876) OR
  (`Entry`=8528 AND `Item`=87877) OR
  (`Entry`=8529 AND `Item`=87879) OR
  (`Entry`=8530 AND `Item`=87904) OR
  (`Entry`=8531 AND `Item`=87905) OR
  (`Entry`=8532 AND `Item`=87906) OR
  (`Entry`=8534 AND `Item`=87907) OR
  (`Entry`=8535 AND `Item`=87908) OR
  (`Entry`=8538 AND `Item`=87909) OR
  (`Entry`=8539 AND `Item`=87910) OR
  (`Entry`=8540 AND `Item`=87997) OR
  (`Entry`=8541 AND `Item`=88002) OR
  (`Entry`=8542 AND `Item`=88003) OR
  (`Entry`=8543 AND `Item`=88261) OR
  (`Entry`=8544 AND `Item`=88262) OR
  (`Entry`=8545 AND `Item`=88304) OR
  (`Entry`=8555 AND `Item`=88305) OR
  (`Entry`=8556 AND `Item`=88306) OR
  (`Entry`=8557 AND `Item`=88307) OR
  (`Entry`=8558 AND `Item`=88308) OR
  (`Entry`=8567 AND `Item`=88309) OR
  (`Entry`=8600 AND `Item`=80051) OR
  (`Entry`=8601 AND `Item`=80052) OR
  (`Entry`=8602 AND `Item`=80053) OR
  (`Entry`=8660 AND `Item`=80054) OR
  (`Entry`=8716 AND `Item`=82763) OR
  (`Entry`=8762 AND `Item`=80055) OR
  (`Entry`=8763 AND `Item`=80056) OR
  (`Entry`=8764 AND `Item`=80058) OR
  (`Entry`=8905 AND `Item`=601682) OR
  (`Entry`=8906 AND `Item`=601683) OR
  (`Entry`=8908 AND `Item`=601684) OR
  (`Entry`=8923 AND `Item`=601685) OR
  (`Entry`=8956 AND `Item`=80059) OR
  (`Entry`=8957 AND `Item`=80060) OR
  (`Entry`=8958 AND `Item`=80062) OR
  (`Entry`=8959 AND `Item`=80063) OR
  (`Entry`=8960 AND `Item`=80064) OR
  (`Entry`=8961 AND `Item`=80065) OR
  (`Entry`=8976 AND `Item`=1180285) OR
  (`Entry`=8981 AND `Item`=601686) OR
  (`Entry`=9025 AND `Item`=600408) OR
  (`Entry`=9031 AND `Item`=88310) OR
  (`Entry`=9096 AND `Item`=1180286) OR
  (`Entry`=9416 AND `Item`=80066) OR
  (`Entry`=9454 AND `Item`=82766) OR
  (`Entry`=9461 AND `Item`=1180290) OR
  (`Entry`=9502 AND `Item`=601688) OR
  (`Entry`=9516 AND `Item`=82768) OR
  (`Entry`=9568 AND `Item`=1180292) OR
  (`Entry`=9601 AND `Item`=601851) OR
  (`Entry`=9622 AND `Item`=80075) OR
  (`Entry`=9690 AND `Item`=80076) OR
  (`Entry`=9691 AND `Item`=80077) OR
  (`Entry`=9694 AND `Item`=80078) OR
  (`Entry`=9695 AND `Item`=80079) OR
  (`Entry`=9696 AND `Item`=80080) OR
  (`Entry`=9697 AND `Item`=80081) OR
  (`Entry`=9698 AND `Item`=80082);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(5319, 1180223, 0, 1, 0, 1, 0, 1, 1, 'Jademir Tree Warder - Draconic Warhorn: Jademir Tree Warder'),
(5320, 1180224, 0, 1, 0, 1, 0, 1, 1, 'Jademir Boughguard - Draconic Warhorn: Jademir Boughguard'),
(5348, 1180225, 0, 1, 0, 1, 0, 1, 1, 'Dreamwatcher Forktongue - Draconic Warhorn: Dreamwatcher Forktongue'),
(5349, 79770, 0, 1, 0, 1, 0, 1, 1, 'Arash-ethis - Beastmaster''s Whistle: Arash-ethis'),
(5352, 79772, 0, 1, 0, 1, 0, 1, 1, 'Old Grizzlegut - Beastmaster''s Whistle: Old Grizzlegut'),
(5356, 79773, 0, 1, 0, 1, 0, 1, 1, 'Snarler - Beastmaster''s Whistle: Snarler'),
(5422, 79774, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Hunter - Beastmaster''s Whistle: Scorpid Hunter'),
(5423, 79776, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Tail Lasher - Beastmaster''s Whistle: Scorpid Tail Lasher'),
(5424, 79777, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Dunestalker - Beastmaster''s Whistle: Scorpid Dunestalker'),
(5425, 79778, 0, 1, 0, 1, 0, 1, 1, 'Starving Blisterpaw - Beastmaster''s Whistle: Starving Blisterpaw'),
(5426, 79779, 0, 1, 0, 1, 0, 1, 1, 'Blisterpaw Hyena - Beastmaster''s Whistle: Blisterpaw Hyena'),
(5427, 79781, 0, 1, 0, 1, 0, 1, 1, 'Rabid Blisterpaw - Beastmaster''s Whistle: Rabid Blisterpaw'),
(5428, 79782, 0, 1, 0, 1, 0, 1, 1, 'Roc - Beastmaster''s Whistle: Roc'),
(5429, 79783, 0, 1, 0, 1, 0, 1, 1, 'Fire Roc - Beastmaster''s Whistle: Fire Roc'),
(5430, 79794, 0, 1, 0, 1, 0, 1, 1, 'Searing Roc - Beastmaster''s Whistle: Searing Roc'),
(5431, 79814, 0, 1, 0, 1, 0, 1, 1, 'Surf Glider - Beastmaster''s Whistle: Surf Glider'),
(5432, 79815, 0, 1, 0, 1, 0, 1, 1, 'Giant Surf Glider - Beastmaster''s Whistle: Giant Surf Glider'),
(5454, 79816, 0, 1, 0, 1, 0, 1, 1, 'Hazzali Sandreaver - Beastmaster''s Whistle: Hazzali Sandreaver'),
(5460, 79817, 0, 1, 0, 1, 0, 1, 1, 'Centipaar Sandreaver - Beastmaster''s Whistle: Centipaar Sandreaver'),
(5461, 600379, 0, 1, 0, 1, 0, 1, 1, 'Sea Elemental - Elemental Lodestone: Sea Elemental'),
(5462, 600380, 0, 1, 0, 1, 0, 1, 1, 'Sea Spray - Elemental Lodestone: Sea Spray'),
(5481, 601058, 0, 1, 0, 1, 0, 1, 1, 'Thistleshrub Dew Collector - Elemental Lodestone: Thistleshrub Dew Collector'),
(5485, 601059, 0, 1, 0, 1, 0, 1, 1, 'Thistleshrub Rootshaper - Elemental Lodestone: Thistleshrub Rootshaper'),
(5490, 601060, 0, 1, 0, 1, 0, 1, 1, 'Gnarled Thistleshrub - Elemental Lodestone: Gnarled Thistleshrub'),
(5708, 79818, 0, 1, 0, 1, 0, 1, 1, 'Spawn of Hakkar - Beastmaster''s Whistle: Spawn of Hakkar'),
(5709, 1180226, 0, 1, 0, 1, 0, 1, 1, 'Shade of Eranikus - Draconic Warhorn: Shade of Eranikus'),
(5711, 87697, 0, 0.1, 0, 1, 0, 1, 1, 'Ogom the Wretched - Blood Soaked Vellum: Ogom the Wretched'),
(5712, 87698, 0, 0.1, 0, 1, 0, 1, 1, 'Zolo - Blood Soaked Vellum: Zolo'),
(5713, 87699, 0, 0.1, 0, 1, 0, 1, 1, 'Gasher - Blood Soaked Vellum: Gasher'),
(5714, 87700, 0, 0.1, 0, 1, 0, 1, 1, 'Loro - Blood Soaked Vellum: Loro'),
(5715, 87711, 0, 0.1, 0, 1, 0, 1, 1, 'Hukku - Blood Soaked Vellum: Hukku'),
(5716, 87717, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Lor - Blood Soaked Vellum: Zul''Lor'),
(5717, 87718, 0, 0.1, 0, 1, 0, 1, 1, 'Mijan - Blood Soaked Vellum: Mijan'),
(5718, 1180228, 0, 1, 0, 1, 0, 1, 1, 'Rothos - Draconic Warhorn: Rothos'),
(5719, 1180229, 0, 1, 0, 1, 0, 1, 1, 'Morphaz - Draconic Warhorn: Morphaz'),
(5720, 1180230, 0, 1, 0, 1, 0, 1, 1, 'Weaver - Draconic Warhorn: Weaver'),
(5721, 1180231, 0, 1, 0, 1, 0, 1, 1, 'Dreamscythe - Draconic Warhorn: Dreamscythe'),
(5722, 1180232, 0, 1, 0, 1, 0, 1, 1, 'Hazzas - Draconic Warhorn: Hazzas'),
(5755, 79821, 0, 1, 0, 1, 0, 1, 1, 'Deviate Viper - Beastmaster''s Whistle: Deviate Viper'),
(5756, 79822, 0, 1, 0, 1, 0, 1, 1, 'Deviate Venomwing - Beastmaster''s Whistle: Deviate Venomwing'),
(5760, 82390, 0, 1, 0, 1, 0, 1, 1, 'Lord Azrethoc - Summoner''s Stone: Lord Azrethoc'),
(5761, 601061, 0, 1, 0, 1, 0, 1, 1, 'Deviate Shambler - Elemental Lodestone: Deviate Shambler'),
(5775, 601062, 0, 1, 0, 1, 0, 1, 1, 'Verdan the Everliving - Elemental Lodestone: Verdan the Everliving'),
(5807, 79861, 0, 1, 0, 1, 0, 1, 1, 'The Rake - Beastmaster''s Whistle: The Rake'),
(5823, 79862, 0, 1, 0, 1, 0, 1, 1, 'Death Flayer - Beastmaster''s Whistle: Death Flayer'),
(5828, 79863, 0, 1, 0, 1, 0, 1, 1, 'Humar the Pridelord - Beastmaster''s Whistle: Humar the Pridelord'),
(5829, 79865, 0, 1, 0, 1, 0, 1, 1, 'Snort the Heckler - Beastmaster''s Whistle: Snort the Heckler'),
(5834, 79872, 0, 1, 0, 1, 0, 1, 1, 'Azzere the Skyblade - Beastmaster''s Whistle: Azzere the Skyblade'),
(5842, 79873, 0, 1, 0, 1, 0, 1, 1, 'Takk the Leaper - Beastmaster''s Whistle: Takk the Leaper'),
(5853, 601675, 0, 1, 0, 1, 0, 1, 1, 'Tempered War Golem - Elemental Lodestone: Tempered War Golem'),
(5855, 600381, 0, 1, 0, 1, 0, 1, 1, 'Magma Elemental - Elemental Lodestone: Magma Elemental'),
(5856, 79874, 0, 1, 0, 1, 0, 1, 1, 'Glassweb Spider - Beastmaster''s Whistle: Glassweb Spider'),
(5857, 79876, 0, 1, 0, 1, 0, 1, 1, 'Searing Lava Spider - Beastmaster''s Whistle: Searing Lava Spider'),
(5858, 79877, 0, 1, 0, 1, 0, 1, 1, 'Greater Lava Spider - Beastmaster''s Whistle: Greater Lava Spider'),
(5865, 79878, 0, 1, 0, 1, 0, 1, 1, 'Dishu - Beastmaster''s Whistle: Dishu'),
(5881, 601834, 0, 1, 0, 1, 0, 1, 1, 'Cursed Sycamore - Elemental Lodestone: Cursed Sycamore'),
(5894, 600383, 0, 1, 0, 1, 0, 1, 1, 'Corrupt Minor Manifestation of Water - Elemental Lodestone: Corrupt Minor Manifestation of Water'),
(5912, 1180233, 0, 1, 0, 1, 0, 1, 1, 'Brightwing - Draconic Warhorn: Deviate Faerie Dragon'),
(5937, 79879, 0, 1, 0, 1, 0, 1, 1, 'Vile Sting - Beastmaster''s Whistle: Vile Sting'),
(5982, 79881, 0, 1, 0, 1, 0, 1, 1, 'Black Slayer - Beastmaster''s Whistle: Black Slayer'),
(5982, 79882, 0, 1, 0, 1, 0, 1, 1, 'Black Slayer - Beastmaster''s Whistle: Bonepicker'),
(5983, 79881, 0, 1, 0, 1, 0, 1, 1, 'Bonepicker - Beastmaster''s Whistle: Black Slayer'),
(5983, 79882, 0, 1, 0, 1, 0, 1, 1, 'Bonepicker - Beastmaster''s Whistle: Bonepicker'),
(5984, 79883, 0, 1, 0, 1, 0, 1, 1, 'Starving Snickerfang - Beastmaster''s Whistle: Starving Snickerfang'),
(5985, 79886, 0, 1, 0, 1, 0, 1, 1, 'Snickerfang Hyena - Beastmaster''s Whistle: Snickerfang Hyena'),
(5988, 79887, 0, 1, 0, 1, 0, 1, 1, 'Scorpok Stinger - Beastmaster''s Whistle: Scorpok Stinger'),
(5992, 79888, 0, 1, 0, 1, 0, 1, 1, 'Ashmane Boar - Beastmaster''s Whistle: Ashmane Boar'),
(6072, 82391, 0, 1, 0, 1, 0, 1, 1, 'Diathorus the Seeker - Summoner''s Stone: Diathorus the Seeker'),
(6073, 82452, 0, 1, 0, 1, 0, 1, 1, 'Searing Infernal - Summoner''s Stone: Searing Infernal'),
(6109, 1180234, 0, 1, 0, 1, 0, 1, 1, 'Azuregos - Draconic Warhorn: Azuregos'),
(6116, 87719, 0, 0.1, 0, 1, 0, 1, 1, 'Highborne Apparition - Blood Soaked Vellum: Highborne Apparition'),
(6117, 87720, 0, 0.1, 0, 1, 0, 1, 1, 'Highborne Lichling - Blood Soaked Vellum: Highborne Lichling'),
(6118, 87731, 0, 0.1, 0, 1, 0, 1, 1, 'Varo''then''s Ghost - Blood Soaked Vellum: Varo''then''s Ghost'),
(6125, 82454, 0, 1, 0, 1, 0, 1, 1, 'Haldarr Satyr - Summoner''s Stone: Haldarr Satyr'),
(6126, 82455, 0, 1, 0, 1, 0, 1, 1, 'Haldarr Trickster - Summoner''s Stone: Haldarr Trickster'),
(6127, 82456, 0, 1, 0, 1, 0, 1, 1, 'Haldarr Felsworn - Summoner''s Stone: Haldarr Felsworn'),
(6128, 82457, 0, 1, 0, 1, 0, 1, 1, 'Vorlus Vilehoof - Summoner''s Stone: Vorlus Vilehoof'),
(6129, 1180235, 0, 1, 0, 1, 0, 1, 1, 'Draconic Magelord - Draconic Warhorn: Draconic Magelord'),
(6130, 1180237, 0, 1, 0, 1, 0, 1, 1, 'Blue Scalebane - Draconic Warhorn: Blue Scalebane'),
(6131, 1180238, 0, 1, 0, 1, 0, 1, 1, 'Draconic Mageweaver - Draconic Warhorn: Draconic Mageweaver'),
(6167, 79889, 0, 1, 0, 1, 0, 1, 1, 'Chimaera Matriarch - Beastmaster''s Whistle: Chimaera Matriarch'),
(6200, 82458, 0, 1, 0, 1, 0, 1, 1, 'Legashi Satyr - Summoner''s Stone: Legashi Satyr'),
(6201, 82459, 0, 1, 0, 1, 0, 1, 1, 'Legashi Rogue - Summoner''s Stone: Legashi Rogue'),
(6202, 82461, 0, 1, 0, 1, 0, 1, 1, 'Legashi Hellcaller - Summoner''s Stone: Legashi Hellcaller'),
(6220, 600387, 0, 1, 0, 1, 0, 1, 1, 'Irradiated Horror - Elemental Lodestone: Irradiated Horror'),
(6352, 79890, 0, 1, 0, 1, 0, 1, 1, 'Coralshell Lurker - Beastmaster''s Whistle: Coralshell Lurker'),
(6369, 79891, 0, 1, 0, 1, 0, 1, 1, 'Coralshell Tortoise - Beastmaster''s Whistle: Coralshell Tortoise'),
(6426, 87732, 0, 0.1, 0, 1, 0, 1, 1, 'Anguished Dead - Blood Soaked Vellum: Anguished Dead'),
(6427, 87733, 0, 0.1, 0, 1, 0, 1, 1, 'Haunting Phantasm - Blood Soaked Vellum: Haunting Phantasm'),
(6489, 87734, 0, 0.1, 0, 1, 0, 1, 1, 'Ironspine - Blood Soaked Vellum: Ironspine'),
(6498, 79892, 0, 1, 0, 1, 0, 1, 1, 'Devilsaur - Beastmaster''s Whistle: Devilsaur'),
(6499, 79893, 0, 1, 0, 1, 0, 1, 1, 'Ironhide Devilsaur - Beastmaster''s Whistle: Ironhide Devilsaur'),
(6500, 79918, 0, 1, 0, 1, 0, 1, 1, 'Tyrant Devilsaur - Beastmaster''s Whistle: Tyrant Devilsaur'),
(6505, 79919, 0, 1, 0, 1, 0, 1, 1, 'Ravasaur - Beastmaster''s Whistle: Ravasaur'),
(6506, 79920, 0, 1, 0, 1, 0, 1, 1, 'Ravasaur Runner - Beastmaster''s Whistle: Ravasaur Runner'),
(6507, 79921, 0, 1, 0, 1, 0, 1, 1, 'Ravasaur Hunter - Beastmaster''s Whistle: Ravasaur Hunter'),
(6508, 79922, 0, 1, 0, 1, 0, 1, 1, 'Venomhide Ravasaur - Beastmaster''s Whistle: Venomhide Ravasaur'),
(6509, 601104, 0, 1, 0, 1, 0, 1, 1, 'Bloodpetal Lasher - Elemental Lodestone: Bloodpetal Lasher'),
(6510, 601195, 0, 1, 0, 1, 0, 1, 1, 'Bloodpetal Flayer - Elemental Lodestone: Bloodpetal Flayer'),
(6511, 601196, 0, 1, 0, 1, 0, 1, 1, 'Bloodpetal Thresher - Elemental Lodestone: Bloodpetal Thresher'),
(6512, 601197, 0, 1, 0, 1, 0, 1, 1, 'Bloodpetal Trapper - Elemental Lodestone: Bloodpetal Trapper'),
(6513, 79923, 0, 1, 0, 1, 0, 1, 1, 'Un''Goro Stomper - Beastmaster''s Whistle: Un''Goro Stomper'),
(6514, 79924, 0, 1, 0, 1, 0, 1, 1, 'Un''Goro Gorilla - Beastmaster''s Whistle: Un''Goro Gorilla'),
(6516, 79925, 0, 1, 0, 1, 0, 1, 1, 'Un''Goro Thunderer - Beastmaster''s Whistle: Un''Goro Thunderer'),
(6517, 601063, 0, 1, 0, 1, 0, 1, 1, 'Tar Beast - Elemental Lodestone: Tar Beast'),
(6518, 601064, 0, 1, 0, 1, 0, 1, 1, 'Tar Lurker - Elemental Lodestone: Tar Lurker'),
(6519, 601065, 0, 1, 0, 1, 0, 1, 1, 'Tar Lord - Elemental Lodestone: Tar Lord'),
(6527, 601066, 0, 1, 0, 1, 0, 1, 1, 'Tar Creeper - Elemental Lodestone: Tar Creeper'),
(6553, 79926, 0, 1, 0, 1, 0, 1, 1, 'Gorishi Reaver - Beastmaster''s Whistle: Gorishi Reaver'),
(6560, 601676, 0, 1, 0, 1, 0, 1, 1, 'Stone Guardian - Elemental Lodestone: Stone Guardian'),
(6581, 79927, 0, 1, 0, 1, 0, 1, 1, 'Ravasaur Matriarch - Beastmaster''s Whistle: Ravasaur Matriarch'),
(6582, 79928, 0, 1, 0, 1, 0, 1, 1, 'Clutchmother Zavas - Beastmaster''s Whistle: Clutchmother Zavas'),
(6584, 79930, 0, 1, 0, 1, 0, 1, 1, 'King Mosh - Beastmaster''s Whistle: King Mosh'),
(6585, 79931, 0, 1, 0, 1, 0, 1, 1, 'Uhk''loc - Beastmaster''s Whistle: Uhk''loc'),
(6652, 82466, 0, 1, 0, 1, 0, 1, 1, 'Master Feardred - Summoner''s Stone: Master Feardred'),
(6788, 79943, 0, 1, 0, 1, 0, 1, 1, 'Den Mother - Beastmaster''s Whistle: Den Mother'),
(6789, 79944, 0, 1, 0, 1, 0, 1, 1, 'Thistle Cub - Beastmaster''s Whistle: Thistle Cub'),
(7022, 79945, 0, 1, 0, 1, 0, 1, 1, 'Venomlash Scorpid - Beastmaster''s Whistle: Venomlash Scorpid'),
(7031, 600390, 0, 1, 0, 1, 0, 1, 1, 'Obsidian Elemental - Elemental Lodestone: Obsidian Elemental'),
(7032, 600391, 0, 1, 0, 1, 0, 1, 1, 'Greater Obsidian Elemental - Elemental Lodestone: Greater Obsidian Elemental'),
(7039, 601678, 0, 1, 0, 1, 0, 1, 1, 'War Reaver - Elemental Lodestone: War Reaver'),
(7040, 1180240, 0, 1, 0, 1, 0, 1, 1, 'Black Dragonspawn - Draconic Warhorn: Black Dragonspawn'),
(7041, 1180243, 0, 1, 0, 1, 0, 1, 1, 'Black Wyrmkin - Draconic Warhorn: Black Wyrmkin'),
(7042, 1180246, 0, 1, 0, 1, 0, 1, 1, 'Flamescale Dragonspawn - Draconic Warhorn: Flamescale Dragonspawn'),
(7043, 1180248, 0, 1, 0, 1, 0, 1, 1, 'Flamescale Wyrmkin - Draconic Warhorn: Flamescale Wyrmkin'),
(7044, 1180250, 0, 1, 0, 1, 0, 1, 1, 'Black Drake - Draconic Warhorn: Black Drake'),
(7045, 1180253, 0, 1, 0, 1, 0, 1, 1, 'Scalding Drake - Draconic Warhorn: Scalding Drake'),
(7046, 1180255, 0, 1, 0, 1, 0, 1, 1, 'Searscale Drake - Draconic Warhorn: Searscale Drake'),
(7047, 1180257, 0, 1, 0, 1, 0, 1, 1, 'Black Broodling - Draconic Warhorn: Black Broodling'),
(7048, 1180259, 0, 1, 0, 1, 0, 1, 1, 'Scalding Broodling - Draconic Warhorn: Scalding Broodling'),
(7049, 1180261, 0, 1, 0, 1, 0, 1, 1, 'Flamescale Broodling - Draconic Warhorn: Flamescale Broodling'),
(7055, 79946, 0, 1, 0, 1, 0, 1, 1, 'Blackrock Worg - Beastmaster''s Whistle: Blackrock Worg'),
(7078, 79947, 0, 1, 0, 1, 0, 1, 1, 'Cleft Scorpid - Beastmaster''s Whistle: Cleft Scorpid'),
(7079, 600392, 0, 1, 0, 1, 0, 1, 1, 'Viscous Fallout - Elemental Lodestone: Viscous Fallout'),
(7097, 79948, 0, 1, 0, 1, 0, 1, 1, 'Ironbeak Owl - Beastmaster''s Whistle: Ironbeak Owl'),
(7098, 79949, 0, 1, 0, 1, 0, 1, 1, 'Ironbeak Screecher - Beastmaster''s Whistle: Ironbeak Screecher'),
(7099, 79950, 0, 1, 0, 1, 0, 1, 1, 'Ironbeak Hunter - Beastmaster''s Whistle: Ironbeak Hunter'),
(7100, 601068, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Moss Flayer - Elemental Lodestone: Warpwood Moss Flayer'),
(7101, 601069, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Shredder - Elemental Lodestone: Warpwood Shredder'),
(7104, 601070, 0, 1, 0, 1, 0, 1, 1, 'Dessecus - Elemental Lodestone: Dessecus'),
(7105, 82724, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Satyr - Summoner''s Stone: Jadefire Satyr'),
(7106, 82725, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Rogue - Summoner''s Stone: Jadefire Rogue'),
(7107, 82726, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Trickster - Summoner''s Stone: Jadefire Trickster'),
(7108, 82727, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Betrayer - Summoner''s Stone: Jadefire Betrayer'),
(7109, 82728, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Felsworn - Summoner''s Stone: Jadefire Felsworn'),
(7110, 82729, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Shadowstalker - Summoner''s Stone: Jadefire Shadowstalker'),
(7111, 82730, 0, 1, 0, 1, 0, 1, 1, 'Jadefire Hellcaller - Summoner''s Stone: Jadefire Hellcaller'),
(7132, 600393, 0, 1, 0, 1, 0, 1, 1, 'Toxic Horror - Elemental Lodestone: Toxic Horror'),
(7135, 82731, 0, 1, 0, 1, 0, 1, 1, 'Infernal Bodyguard - Summoner''s Stone: Infernal Bodyguard'),
(7136, 82732, 0, 1, 0, 1, 0, 1, 1, 'Infernal Sentry - Summoner''s Stone: Infernal Sentry'),
(7137, 82733, 0, 1, 0, 1, 0, 1, 1, 'Immolatus - Summoner''s Stone: Immolatus'),
(7138, 601845, 0, 1, 0, 1, 0, 1, 1, 'Irontree Wanderer - Elemental Lodestone: Irontree Wanderer'),
(7139, 601846, 0, 1, 0, 1, 0, 1, 1, 'Irontree Stomper - Elemental Lodestone: Irontree Stomper'),
(7143, 601847, 0, 1, 0, 1, 0, 1, 1, 'Decaying Treant - Elemental Lodestone: Decaying Treant'),
(7144, 601848, 0, 1, 0, 1, 0, 1, 1, 'Withered Treant - Elemental Lodestone: Withered Treant'),
(7146, 601849, 0, 1, 0, 1, 0, 1, 1, 'Treant Protector - Elemental Lodestone: Treant Protector'),
(7206, 601679, 0, 1, 0, 1, 0, 1, 1, 'Ancient Stone Keeper - Elemental Lodestone: Ancient Stone Keeper'),
(7268, 79951, 0, 1, 0, 1, 0, 1, 1, 'Sandfury Guardian - Beastmaster''s Whistle: Sandfury Guardian'),
(7272, 87735, 0, 0.1, 0, 1, 0, 1, 1, 'Theka the Martyr - Blood Soaked Vellum: Theka the Martyr'),
(7276, 87736, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Farrak Dead Hero - Blood Soaked Vellum: Zul''Farrak Dead Hero(Male)'),
(7276, 89801, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Farrak Dead Hero - Blood Soaked Vellum: Zul''Farrak Dead Hero(Female)'),
(7286, 87737, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Farrak Zombie - Blood Soaked Vellum: Zul''Farrak Zombie'),
(7319, 79981, 0, 1, 0, 1, 0, 1, 1, 'Lady Sathrah - Beastmaster''s Whistle: Lady Sathrah'),
(7327, 87749, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Warrior - Blood Soaked Vellum: Withered Warrior'),
(7328, 87765, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Reaver - Blood Soaked Vellum: Withered Reaver'),
(7329, 87766, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Quilguard - Blood Soaked Vellum: Withered Quilguard'),
(7332, 87767, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Spearhide - Blood Soaked Vellum: Withered Spearhide'),
(7333, 87778, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Battle Boar - Blood Soaked Vellum: Withered Battle Boar'),
(7334, 87808, 0, 0.1, 0, 1, 0, 1, 1, 'Battle Boar Horror - Blood Soaked Vellum: Battle Boar Horror'),
(7340, 87809, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Shadowcaster - Blood Soaked Vellum: Skeletal Shadowcaster'),
(7341, 87810, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Frostweaver - Blood Soaked Vellum: Skeletal Frostweaver'),
(7342, 87818, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Summoner - Blood Soaked Vellum: Skeletal Summoner'),
(7344, 87819, 0, 0.1, 0, 1, 0, 1, 1, 'Splinterbone Warrior - Blood Soaked Vellum: Splinterbone Warrior'),
(7345, 87820, 0, 0.1, 0, 1, 0, 1, 1, 'Splinterbone Captain - Blood Soaked Vellum: Splinterbone Captain'),
(7346, 87840, 0, 0.1, 0, 1, 0, 1, 1, 'Splinterbone Centurion - Blood Soaked Vellum: Splinterbone Centurion'),
(7347, 87842, 0, 0.1, 0, 1, 0, 1, 1, 'Boneflayer Ghoul - Blood Soaked Vellum: Boneflayer Ghoul'),
(7348, 87845, 0, 0.1, 0, 1, 0, 1, 1, 'Thorn Eater Ghoul - Blood Soaked Vellum: Thorn Eater Ghoul'),
(7349, 87847, 0, 0.1, 0, 1, 0, 1, 1, 'Tomb Fiend - Blood Soaked Vellum: Tomb Fiend'),
(7351, 87851, 0, 0.1, 0, 1, 0, 1, 1, 'Tomb Reaver - Blood Soaked Vellum: Tomb Reaver'),
(7352, 87852, 0, 0.1, 0, 1, 0, 1, 1, 'Frozen Soul - Blood Soaked Vellum: Frozen Soul'),
(7353, 87857, 0, 0.1, 0, 1, 0, 1, 1, 'Freezing Spirit - Blood Soaked Vellum: Freezing Spirit'),
(7355, 87858, 0, 0.1, 0, 1, 0, 1, 1, 'Tuten''kash - Blood Soaked Vellum: Tuten''kash'),
(7357, 87859, 0, 0.1, 0, 1, 0, 1, 1, 'Mordresh Fire Eye - Blood Soaked Vellum: Mordresh Fire Eye'),
(7370, 87860, 0, 0.1, 0, 1, 0, 1, 1, 'Restless Shade - Blood Soaked Vellum: Restless Shade'),
(7376, 79982, 0, 1, 0, 1, 0, 1, 1, 'Sky Shadow - Beastmaster''s Whistle: Sky Shadow'),
(7405, 79991, 0, 1, 0, 1, 0, 1, 1, 'Deadly Cleft Scorpid - Beastmaster''s Whistle: Deadly Cleft Scorpid'),
(7430, 79992, 0, 1, 0, 1, 0, 1, 1, 'Frostsaber Cub - Beastmaster''s Whistle: Frostsaber Cub'),
(7431, 79993, 0, 1, 0, 1, 0, 1, 1, 'Frostsaber - Beastmaster''s Whistle: Frostsaber'),
(7432, 79994, 0, 1, 0, 1, 0, 1, 1, 'Frostsaber Stalker - Beastmaster''s Whistle: Frostsaber Stalker'),
(7433, 79995, 0, 1, 0, 1, 0, 1, 1, 'Frostsaber Huntress - Beastmaster''s Whistle: Frostsaber Huntress'),
(7434, 79996, 0, 1, 0, 1, 0, 1, 1, 'Frostsaber Pride Watcher - Beastmaster''s Whistle: Frostsaber Pride Watcher'),
(7435, 1180264, 0, 1, 0, 1, 0, 1, 1, 'Cobalt Wyrmkin - Draconic Warhorn: Cobalt Wyrmkin'),
(7436, 1180266, 0, 1, 0, 1, 0, 1, 1, 'Cobalt Scalebane - Draconic Warhorn: Cobalt Scalebane'),
(7437, 1180268, 0, 1, 0, 1, 0, 1, 1, 'Cobalt Mageweaver - Draconic Warhorn: Cobalt Mageweaver'),
(7443, 79997, 0, 1, 0, 1, 0, 1, 1, 'Shardtooth Mauler - Beastmaster''s Whistle: Shardtooth Mauler'),
(7444, 79998, 0, 1, 0, 1, 0, 1, 1, 'Shardtooth Bear - Beastmaster''s Whistle: Shardtooth Bear'),
(7445, 80030, 0, 1, 0, 1, 0, 1, 1, 'Elder Shardtooth - Beastmaster''s Whistle: Elder Shardtooth'),
(7446, 80031, 0, 1, 0, 1, 0, 1, 1, 'Rabid Shardtooth - Beastmaster''s Whistle: Rabid Shardtooth'),
(7447, 80032, 0, 1, 0, 1, 0, 1, 1, 'Fledgling Chillwind - Beastmaster''s Whistle: Fledgling Chillwind'),
(7448, 80033, 0, 1, 0, 1, 0, 1, 1, 'Chillwind Chimaera - Beastmaster''s Whistle: Chillwind Chimaera'),
(7449, 80034, 0, 1, 0, 1, 0, 1, 1, 'Chillwind Ravager - Beastmaster''s Whistle: Chillwind Ravager'),
(7455, 80035, 0, 1, 0, 1, 0, 1, 1, 'Winterspring Owl - Beastmaster''s Whistle: Winterspring Owl'),
(7456, 80036, 0, 1, 0, 1, 0, 1, 1, 'Winterspring Screecher - Beastmaster''s Whistle: Winterspring Screecher'),
(7523, 87861, 0, 0.1, 0, 1, 0, 1, 1, 'Suffering Highborne - Blood Soaked Vellum: Suffering Highborne'),
(7524, 87863, 0, 0.1, 0, 1, 0, 1, 1, 'Anguished Highborne - Blood Soaked Vellum: Anguished Highborne'),
(7584, 601835, 0, 1, 0, 1, 0, 1, 1, 'Wandering Forest Walker - Elemental Lodestone: Wandering Forest Walker'),
(7664, 82734, 0, 1, 0, 1, 0, 1, 1, 'Razelikh the Defiler - Summoner''s Stone: Razelikh the Defiler'),
(7796, 87865, 0, 0.1, 0, 1, 0, 1, 1, 'Nekrum Gutchewer - Blood Soaked Vellum: Nekrum Gutchewer'),
(7846, 1180270, 0, 1, 0, 1, 0, 1, 1, 'Teremus the Devourer - Draconic Warhorn: Teremus the Devourer'),
(7864, 87867, 0, 0.1, 0, 1, 0, 1, 1, 'Lingering Highborne - Blood Soaked Vellum: Lingering Highborne'),
(7977, 80037, 0, 1, 0, 1, 0, 1, 1, 'Gammerita - Beastmaster''s Whistle: Gammerita'),
(7997, 1180272, 0, 1, 0, 1, 0, 1, 1, 'Captured Sprite Darter - Draconic Warhorn: Captured Sprite Darter'),
(8196, 1180273, 0, 1, 0, 1, 0, 1, 1, 'Occulus - Draconic Warhorn: Occulus'),
(8197, 1180274, 0, 1, 0, 1, 0, 1, 1, 'Chronalis - Draconic Warhorn: Chronalis'),
(8198, 1180276, 0, 1, 0, 1, 0, 1, 1, 'Tick - Draconic Warhorn: Tick'),
(8204, 80038, 0, 1, 0, 1, 0, 1, 1, 'Soriid the Devourer - Beastmaster''s Whistle: Soriid the Devourer'),
(8205, 80039, 0, 1, 0, 1, 0, 1, 1, 'Haarka the Ravenous - Beastmaster''s Whistle: Haarka the Ravenous'),
(8207, 80041, 0, 1, 0, 1, 0, 1, 1, 'Greater Firebird - Beastmaster''s Whistle: Greater Firebird'),
(8208, 80042, 0, 1, 0, 1, 0, 1, 1, 'Murderous Blisterpaw - Beastmaster''s Whistle: Murderous Blisterpaw'),
(8211, 80043, 0, 1, 0, 1, 0, 1, 1, 'Old Cliff Jumper - Beastmaster''s Whistle: Old Cliff Jumper'),
(8213, 80044, 0, 1, 0, 1, 0, 1, 1, 'Ironback - Beastmaster''s Whistle: Ironback'),
(8277, 80045, 0, 1, 0, 1, 0, 1, 1, 'Rekk''tilac - Beastmaster''s Whistle: Rekk''tilac'),
(8278, 600396, 0, 1, 0, 1, 0, 1, 1, 'Smoldar - Elemental Lodestone: Smoldar'),
(8279, 601680, 0, 1, 0, 1, 0, 1, 1, 'Faulty War Golem - Elemental Lodestone: Faulty War Golem'),
(8280, 82744, 0, 1, 0, 1, 0, 1, 1, 'Shleipnarr - Summoner''s Stone: Shleipnarr'),
(8299, 80046, 0, 1, 0, 1, 0, 1, 1, 'Spiteflayer - Beastmaster''s Whistle: Spiteflayer'),
(8300, 80047, 0, 1, 0, 1, 0, 1, 1, 'Ravage - Beastmaster''s Whistle: Ravage'),
(8301, 80048, 0, 1, 0, 1, 0, 1, 1, 'Clack the Reaver - Beastmaster''s Whistle: Clack the Reaver'),
(8303, 80049, 0, 1, 0, 1, 0, 1, 1, 'Grunter - Beastmaster''s Whistle: Grunter'),
(8319, 1180278, 0, 1, 0, 1, 0, 1, 1, 'Nightmare Whelp - Draconic Warhorn: Nightmare Whelp'),
(8336, 80050, 0, 1, 0, 1, 0, 1, 1, 'Hakkari Sapper - Beastmaster''s Whistle: Hakkari Sapper'),
(8384, 601071, 0, 1, 0, 1, 0, 1, 1, 'Deep Lurker - Elemental Lodestone: Deep Lurker'),
(8497, 1180281, 0, 1, 0, 1, 0, 1, 1, 'Nightmare Suppressor - Draconic Warhorn: Nightmare Suppressor'),
(8519, 600397, 0, 1, 0, 1, 0, 1, 1, 'Blighted Surge - Elemental Lodestone: Blighted Surge'),
(8520, 600398, 0, 1, 0, 1, 0, 1, 1, 'Plague Ravager - Elemental Lodestone: Plague Ravager'),
(8521, 600399, 0, 1, 0, 1, 0, 1, 1, 'Blighted Horror - Elemental Lodestone: Blighted Horror'),
(8522, 600400, 0, 1, 0, 1, 0, 1, 1, 'Plague Monstrosity - Elemental Lodestone: Plague Monstrosity'),
(8523, 87868, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Soldier - Blood Soaked Vellum: Scourge Soldier'),
(8524, 87869, 0, 0.1, 0, 1, 0, 1, 1, 'Cursed Mage - Blood Soaked Vellum: Cursed Mage'),
(8525, 87870, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Warder - Blood Soaked Vellum: Scourge Warder'),
(8526, 87873, 0, 0.1, 0, 1, 0, 1, 1, 'Dark Caster - Blood Soaked Vellum: Dark Caster'),
(8527, 87876, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Guard - Blood Soaked Vellum: Scourge Guard'),
(8528, 87877, 0, 0.1, 0, 1, 0, 1, 1, 'Dread Weaver - Blood Soaked Vellum: Dread Weaver'),
(8529, 87879, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Champion - Blood Soaked Vellum: Scourge Champion'),
(8530, 87904, 0, 0.1, 0, 1, 0, 1, 1, 'Cannibal Ghoul - Blood Soaked Vellum: Cannibal Ghoul'),
(8531, 87905, 0, 0.1, 0, 1, 0, 1, 1, 'Gibbering Ghoul - Blood Soaked Vellum: Gibbering Ghoul'),
(8532, 87906, 0, 0.1, 0, 1, 0, 1, 1, 'Diseased Flayer - Blood Soaked Vellum: Diseased Flayer'),
(8534, 87907, 0, 0.1, 0, 1, 0, 1, 1, 'Putrid Gargoyle - Blood Soaked Vellum: Putrid Gargoyle'),
(8535, 87908, 0, 0.1, 0, 1, 0, 1, 1, 'Putrid Shrieker - Blood Soaked Vellum: Putrid Shrieker'),
(8538, 87909, 0, 0.1, 0, 1, 0, 1, 1, 'Unseen Servant - Blood Soaked Vellum: Unseen Servant'),
(8539, 87910, 0, 0.1, 0, 1, 0, 1, 1, 'Eyeless Watcher - Blood Soaked Vellum: Eyeless Watcher'),
(8540, 87997, 0, 0.1, 0, 1, 0, 1, 1, 'Torn Screamer - Blood Soaked Vellum: Torn Screamer'),
(8541, 88002, 0, 0.1, 0, 1, 0, 1, 1, 'Hate Shrieker - Blood Soaked Vellum: Hate Shrieker'),
(8542, 88003, 0, 0.1, 0, 1, 0, 1, 1, 'Death Singer - Blood Soaked Vellum: Death Singer'),
(8543, 88261, 0, 0.1, 0, 1, 0, 1, 1, 'Stitched Horror - Blood Soaked Vellum: Stitched Horror'),
(8544, 88262, 0, 0.1, 0, 1, 0, 1, 1, 'Gangled Golem - Blood Soaked Vellum: Gangled Golem'),
(8545, 88304, 0, 0.1, 0, 1, 0, 1, 1, 'Stitched Golem - Blood Soaked Vellum: Abomination'),
(8555, 88305, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Stalker - Blood Soaked Vellum: Crypt Fiend'),
(8556, 88306, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Walker - Blood Soaked Vellum: Crypt Walker'),
(8557, 88307, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Horror - Blood Soaked Vellum: Crypt Horror'),
(8558, 88308, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Slayer - Blood Soaked Vellum: Crypt Slayer'),
(8567, 88309, 0, 0.1, 0, 1, 0, 1, 1, 'Glutton - Blood Soaked Vellum: Glutton'),
(8600, 80051, 0, 1, 0, 1, 0, 1, 1, 'Plaguebat - Beastmaster''s Whistle: Plaguebat'),
(8601, 80052, 0, 1, 0, 1, 0, 1, 1, 'Noxious Plaguebat - Beastmaster''s Whistle: Noxious Plaguebat'),
(8602, 80053, 0, 1, 0, 1, 0, 1, 1, 'Monstrous Plaguebat - Beastmaster''s Whistle: Monstrous Plaguebat'),
(8660, 80054, 0, 1, 0, 1, 0, 1, 1, 'The Evalcharr - Beastmaster''s Whistle: The Evalcharr'),
(8716, 82763, 0, 1, 0, 1, 0, 1, 1, 'Dreadlord - Summoner''s Stone: Dreadlord'),
(8762, 80055, 0, 1, 0, 1, 0, 1, 1, 'Timberweb Recluse - Beastmaster''s Whistle: Timberweb Recluse'),
(8763, 80056, 0, 1, 0, 1, 0, 1, 1, 'Mistwing Rogue - Beastmaster''s Whistle: Mistwing Rogue'),
(8764, 80058, 0, 1, 0, 1, 0, 1, 1, 'Mistwing Ravager - Beastmaster''s Whistle: Mistwing Ravager'),
(8905, 601682, 0, 1, 0, 1, 0, 1, 1, 'Warbringer Construct - Elemental Lodestone: Warbringer Construct'),
(8906, 601683, 0, 1, 0, 1, 0, 1, 1, 'Ragereaver Golem - Elemental Lodestone: Ragereaver Golem'),
(8908, 601684, 0, 1, 0, 1, 0, 1, 1, 'Molten War Golem - Elemental Lodestone: Molten War Golem'),
(8923, 601685, 0, 1, 0, 1, 0, 1, 1, 'Panzor the Invincible - Elemental Lodestone: Panzor the Invincible'),
(8956, 80059, 0, 1, 0, 1, 0, 1, 1, 'Angerclaw Bear - Beastmaster''s Whistle: Angerclaw Bear'),
(8957, 80060, 0, 1, 0, 1, 0, 1, 1, 'Angerclaw Grizzly - Beastmaster''s Whistle: Angerclaw Grizzly'),
(8958, 80062, 0, 1, 0, 1, 0, 1, 1, 'Angerclaw Mauler - Beastmaster''s Whistle: Angerclaw Mauler'),
(8959, 80063, 0, 1, 0, 1, 0, 1, 1, 'Felpaw Wolf - Beastmaster''s Whistle: Felpaw Wolf'),
(8960, 80064, 0, 1, 0, 1, 0, 1, 1, 'Felpaw Scavenger - Beastmaster''s Whistle: Felpaw Scavenger'),
(8961, 80065, 0, 1, 0, 1, 0, 1, 1, 'Felpaw Ravager - Beastmaster''s Whistle: Felpaw Ravager'),
(8976, 1180285, 0, 1, 0, 1, 0, 1, 1, 'Hematos - Draconic Warhorn: Hematos'),
(8981, 601686, 0, 1, 0, 1, 0, 1, 1, 'Malfunctioning Reaver - Elemental Lodestone: Malfunctioning Reaver'),
(9025, 600408, 0, 1, 0, 1, 0, 1, 1, 'Lord Roccor - Elemental Lodestone: Lord Roccor'),
(9031, 88310, 0, 0.1, 0, 1, 0, 1, 1, 'Anub''shiah - Blood Soaked Vellum: Anub''shiah'),
(9096, 1180286, 0, 1, 0, 1, 0, 1, 1, 'Rage Talon Dragonspawn - Draconic Warhorn: Rage Talon Dragonspawn'),
(9416, 80066, 0, 1, 0, 1, 0, 1, 1, 'Scarshield Worg - Beastmaster''s Whistle: Scarshield Worg'),
(9454, 82766, 0, 1, 0, 1, 0, 1, 1, 'Xavathras - Summoner''s Stone: Xavathras'),
(9461, 1180290, 0, 1, 0, 1, 0, 1, 1, 'Frenzied Black Drake - Draconic Warhorn: Frenzied Black Drake'),
(9502, 601688, 0, 1, 0, 1, 0, 1, 1, 'Phalanx - Elemental Lodestone: Phalanx'),
(9516, 82768, 0, 1, 0, 1, 0, 1, 1, 'Lord Banehollow - Summoner''s Stone: Lord Banehollow'),
(9568, 1180292, 0, 1, 0, 1, 0, 1, 1, 'Overlord Wyrmthalak - Draconic Warhorn: Overlord Wyrmthalak'),
(9601, 601851, 0, 1, 0, 1, 0, 1, 1, 'Treant Spirit - Elemental Lodestone: Treant Spirit'),
(9622, 80075, 0, 1, 0, 1, 0, 1, 1, 'U''cha - Beastmaster''s Whistle: U''cha'),
(9690, 80076, 0, 1, 0, 1, 0, 1, 1, 'Ember Worg - Beastmaster''s Whistle: Ember Worg'),
(9691, 80077, 0, 1, 0, 1, 0, 1, 1, 'Venomtip Scorpid - Beastmaster''s Whistle: Venomtip Scorpid'),
(9694, 80078, 0, 1, 0, 1, 0, 1, 1, 'Slavering Ember Worg - Beastmaster''s Whistle: Slavering Ember Worg'),
(9695, 80079, 0, 1, 0, 1, 0, 1, 1, 'Deathlash Scorpid - Beastmaster''s Whistle: Deathlash Scorpid'),
(9696, 80080, 0, 1, 0, 1, 0, 1, 1, 'Bloodaxe Worg - Beastmaster''s Whistle: Bloodaxe Worg'),
(9697, 80081, 0, 1, 0, 1, 0, 1, 1, 'Giant Ember Worg - Beastmaster''s Whistle: Giant Ember Worg'),
(9698, 80082, 0, 1, 0, 1, 0, 1, 1, 'Firetail Scorpid - Beastmaster''s Whistle: Firetail Scorpid');
DELETE FROM `creature_loot_template` WHERE (`Entry`=9877 AND `Item`=82776) OR
  (`Entry`=9878 AND `Item`=600410) OR
  (`Entry`=9879 AND `Item`=600411) OR
  (`Entry`=9938 AND `Item`=601687) OR
  (`Entry`=10077 AND `Item`=80083) OR
  (`Entry`=10083 AND `Item`=1180294) OR
  (`Entry`=10161 AND `Item`=1180298) OR
  (`Entry`=10184 AND `Item`=1180299) OR
  (`Entry`=10196 AND `Item`=1180300) OR
  (`Entry`=10200 AND `Item`=80084) OR
  (`Entry`=10202 AND `Item`=1180301) OR
  (`Entry`=10221 AND `Item`=80085) OR
  (`Entry`=10264 AND `Item`=1180305) OR
  (`Entry`=10321 AND `Item`=1180307) OR
  (`Entry`=10357 AND `Item`=80086) OR
  (`Entry`=10358 AND `Item`=88311) OR
  (`Entry`=10359 AND `Item`=80087) OR
  (`Entry`=10363 AND `Item`=1180309) OR
  (`Entry`=10366 AND `Item`=1180310) OR
  (`Entry`=10371 AND `Item`=1180312) OR
  (`Entry`=10372 AND `Item`=1180314) OR
  (`Entry`=10373 AND `Item`=82777) OR
  (`Entry`=10375 AND `Item`=80088) OR
  (`Entry`=10381 AND `Item`=88312) OR
  (`Entry`=10382 AND `Item`=88313) OR
  (`Entry`=10387 AND `Item`=88314) OR
  (`Entry`=10388 AND `Item`=88315) OR
  (`Entry`=10389 AND `Item`=88316) OR
  (`Entry`=10390 AND `Item`=88317) OR
  (`Entry`=10391 AND `Item`=88318) OR
  (`Entry`=10393 AND `Item`=88319) OR
  (`Entry`=10394 AND `Item`=88320) OR
  (`Entry`=10404 AND `Item`=88321) OR
  (`Entry`=10405 AND `Item`=88322) OR
  (`Entry`=10406 AND `Item`=88323) OR
  (`Entry`=10407 AND `Item`=88324) OR
  (`Entry`=10408 AND `Item`=88325) OR
  (`Entry`=10409 AND `Item`=88326) OR
  (`Entry`=10411 AND `Item`=88327) OR
  (`Entry`=10412 AND `Item`=88328) OR
  (`Entry`=10413 AND `Item`=88329) OR
  (`Entry`=10414 AND `Item`=88330) OR
  (`Entry`=10416 AND `Item`=88331) OR
  (`Entry`=10417 AND `Item`=88332) OR
  (`Entry`=10429 AND `Item`=1180308) OR
  (`Entry`=10429 AND `Item`=1180316) OR
  (`Entry`=10429 AND `Item`=1180319) OR
  (`Entry`=10430 AND `Item`=80089) OR
  (`Entry`=10432 AND `Item`=88333) OR
  (`Entry`=10435 AND `Item`=88334) OR
  (`Entry`=10436 AND `Item`=88363) OR
  (`Entry`=10437 AND `Item`=88364) OR
  (`Entry`=10439 AND `Item`=88365) OR
  (`Entry`=10463 AND `Item`=88366) OR
  (`Entry`=10464 AND `Item`=88367) OR
  (`Entry`=10478 AND `Item`=88372) OR
  (`Entry`=10479 AND `Item`=88373) OR
  (`Entry`=10480 AND `Item`=88374) OR
  (`Entry`=10481 AND `Item`=88383) OR
  (`Entry`=10485 AND `Item`=88415) OR
  (`Entry`=10486 AND `Item`=88434) OR
  (`Entry`=10487 AND `Item`=88436) OR
  (`Entry`=10488 AND `Item`=88467) OR
  (`Entry`=10489 AND `Item`=88534) OR
  (`Entry`=10491 AND `Item`=88539) OR
  (`Entry`=10495 AND `Item`=88540) OR
  (`Entry`=10498 AND `Item`=88546) OR
  (`Entry`=10499 AND `Item`=88547) OR
  (`Entry`=10500 AND `Item`=88552) OR
  (`Entry`=10506 AND `Item`=88560) OR
  (`Entry`=10507 AND `Item`=88561) OR
  (`Entry`=10516 AND `Item`=88562) OR
  (`Entry`=10580 AND `Item`=88565) OR
  (`Entry`=10641 AND `Item`=601072) OR
  (`Entry`=10642 AND `Item`=600412) OR
  (`Entry`=10644 AND `Item`=80090) OR
  (`Entry`=10647 AND `Item`=82778) OR
  (`Entry`=10648 AND `Item`=82779) OR
  (`Entry`=10659 AND `Item`=1180322) OR
  (`Entry`=10660 AND `Item`=1180324) OR
  (`Entry`=10661 AND `Item`=1180326) OR
  (`Entry`=10662 AND `Item`=1180328) OR
  (`Entry`=10663 AND `Item`=1180330) OR
  (`Entry`=10664 AND `Item`=1180332) OR
  (`Entry`=10678 AND `Item`=1180333) OR
  (`Entry`=10756 AND `Item`=600413) OR
  (`Entry`=10757 AND `Item`=600414) OR
  (`Entry`=10801 AND `Item`=88670) OR
  (`Entry`=10806 AND `Item`=80091) OR
  (`Entry`=10807 AND `Item`=80092) OR
  (`Entry`=10808 AND `Item`=88671) OR
  (`Entry`=10809 AND `Item`=88672) OR
  (`Entry`=10813 AND `Item`=82780) OR
  (`Entry`=10816 AND `Item`=88673) OR
  (`Entry`=10825 AND `Item`=88674) OR
  (`Entry`=10826 AND `Item`=88675) OR
  (`Entry`=10836 AND `Item`=88676) OR
  (`Entry`=10901 AND `Item`=88677) OR
  (`Entry`=10992 AND `Item`=80093) OR
  (`Entry`=11075 AND `Item`=88679) OR
  (`Entry`=11076 AND `Item`=88680) OR
  (`Entry`=11077 AND `Item`=88681) OR
  (`Entry`=11078 AND `Item`=88689) OR
  (`Entry`=11121 AND `Item`=88713) OR
  (`Entry`=11290 AND `Item`=88716) OR
  (`Entry`=11291 AND `Item`=88717) OR
  (`Entry`=11320 AND `Item`=80094) OR
  (`Entry`=11321 AND `Item`=600417) OR
  (`Entry`=11451 AND `Item`=82781) OR
  (`Entry`=11452 AND `Item`=82782) OR
  (`Entry`=11453 AND `Item`=82786) OR
  (`Entry`=11454 AND `Item`=82801) OR
  (`Entry`=11455 AND `Item`=82804) OR
  (`Entry`=11456 AND `Item`=82805) OR
  (`Entry`=11457 AND `Item`=82806) OR
  (`Entry`=11458 AND `Item`=601818) OR
  (`Entry`=11461 AND `Item`=601819) OR
  (`Entry`=11462 AND `Item`=601820) OR
  (`Entry`=11464 AND `Item`=601821) OR
  (`Entry`=11465 AND `Item`=601822) OR
  (`Entry`=11471 AND `Item`=88718) OR
  (`Entry`=11472 AND `Item`=88719) OR
  (`Entry`=11473 AND `Item`=88720) OR
  (`Entry`=11475 AND `Item`=88721) OR
  (`Entry`=11476 AND `Item`=88722) OR
  (`Entry`=11477 AND `Item`=88753) OR
  (`Entry`=11480 AND `Item`=600418) OR
  (`Entry`=11483 AND `Item`=600419) OR
  (`Entry`=11484 AND `Item`=600420) OR
  (`Entry`=11490 AND `Item`=82863) OR
  (`Entry`=11492 AND `Item`=82865) OR
  (`Entry`=11496 AND `Item`=82871) OR
  (`Entry`=11497 AND `Item`=80105) OR
  (`Entry`=11551 AND `Item`=88754) OR
  (`Entry`=11561 AND `Item`=88755) OR
  (`Entry`=11622 AND `Item`=88757) OR
  (`Entry`=11723 AND `Item`=80107) OR
  (`Entry`=11728 AND `Item`=80108) OR
  (`Entry`=11730 AND `Item`=80109) OR
  (`Entry`=11734 AND `Item`=80110) OR
  (`Entry`=11735 AND `Item`=80111) OR
  (`Entry`=11736 AND `Item`=80112) OR
  (`Entry`=11737 AND `Item`=80113) OR
  (`Entry`=11738 AND `Item`=80114) OR
  (`Entry`=11739 AND `Item`=80115) OR
  (`Entry`=11740 AND `Item`=80117) OR
  (`Entry`=11741 AND `Item`=80118) OR
  (`Entry`=11783 AND `Item`=600422) OR
  (`Entry`=11784 AND `Item`=600423) OR
  (`Entry`=11787 AND `Item`=80119) OR
  (`Entry`=11788 AND `Item`=80121) OR
  (`Entry`=11789 AND `Item`=80128) OR
  (`Entry`=11790 AND `Item`=82872) OR
  (`Entry`=11791 AND `Item`=82873) OR
  (`Entry`=11792 AND `Item`=82874) OR
  (`Entry`=11873 AND `Item`=88758) OR
  (`Entry`=11876 AND `Item`=82875) OR
  (`Entry`=11921 AND `Item`=80135) OR
  (`Entry`=11983 AND `Item`=1180344) OR
  (`Entry`=12017 AND `Item`=1180345) OR
  (`Entry`=12037 AND `Item`=80160) OR
  (`Entry`=12129 AND `Item`=1180346) OR
  (`Entry`=12219 AND `Item`=601198) OR
  (`Entry`=12220 AND `Item`=601199) OR
  (`Entry`=12223 AND `Item`=601074) OR
  (`Entry`=12224 AND `Item`=601075) OR
  (`Entry`=12236 AND `Item`=82876) OR
  (`Entry`=12237 AND `Item`=601076) OR
  (`Entry`=12248 AND `Item`=88759) OR
  (`Entry`=12250 AND `Item`=88760) OR
  (`Entry`=12258 AND `Item`=601200) OR
  (`Entry`=12261 AND `Item`=88761) OR
  (`Entry`=12262 AND `Item`=88762) OR
  (`Entry`=12263 AND `Item`=88795) OR
  (`Entry`=12347 AND `Item`=80161) OR
  (`Entry`=12377 AND `Item`=88796) OR
  (`Entry`=12378 AND `Item`=88803) OR
  (`Entry`=12396 AND `Item`=82887) OR
  (`Entry`=12418 AND `Item`=80162) OR
  (`Entry`=12431 AND `Item`=80163) OR
  (`Entry`=12432 AND `Item`=80164) OR
  (`Entry`=12433 AND `Item`=80165) OR
  (`Entry`=12435 AND `Item`=1180352) OR
  (`Entry`=12460 AND `Item`=1180353) OR
  (`Entry`=12461 AND `Item`=1180355) OR
  (`Entry`=12463 AND `Item`=1180357) OR
  (`Entry`=12464 AND `Item`=1180359) OR
  (`Entry`=12465 AND `Item`=1180361) OR
  (`Entry`=12467 AND `Item`=1180364) OR
  (`Entry`=12468 AND `Item`=1180366) OR
  (`Entry`=12474 AND `Item`=1180369) OR
  (`Entry`=12475 AND `Item`=1180370) OR
  (`Entry`=12476 AND `Item`=1180371) OR
  (`Entry`=12477 AND `Item`=1180372) OR
  (`Entry`=12478 AND `Item`=1180373) OR
  (`Entry`=12479 AND `Item`=1180374) OR
  (`Entry`=12496 AND `Item`=1180376) OR
  (`Entry`=12497 AND `Item`=1180377) OR
  (`Entry`=12498 AND `Item`=1180379) OR
  (`Entry`=12759 AND `Item`=600430) OR
  (`Entry`=12800 AND `Item`=80166) OR
  (`Entry`=12801 AND `Item`=80168) OR
  (`Entry`=12802 AND `Item`=80169) OR
  (`Entry`=12803 AND `Item`=80170) OR
  (`Entry`=12876 AND `Item`=600432) OR
  (`Entry`=12899 AND `Item`=1180386) OR
  (`Entry`=12900 AND `Item`=1180387) OR
  (`Entry`=13020 AND `Item`=1180389) OR
  (`Entry`=13022 AND `Item`=601201) OR
  (`Entry`=13022 AND `Item`=601864) OR
  (`Entry`=13036 AND `Item`=80171) OR
  (`Entry`=13141 AND `Item`=1777421) OR
  (`Entry`=13196 AND `Item`=601202) OR
  (`Entry`=13197 AND `Item`=601203) OR
  (`Entry`=13279 AND `Item`=600435) OR
  (`Entry`=13280 AND `Item`=600436) OR
  (`Entry`=13282 AND `Item`=600437) OR
  (`Entry`=13285 AND `Item`=601204) OR
  (`Entry`=13599 AND `Item`=80172) OR
  (`Entry`=13743 AND `Item`=601824) OR
  (`Entry`=13896 AND `Item`=80173) OR
  (`Entry`=14020 AND `Item`=1180392) OR
  (`Entry`=14123 AND `Item`=80174) OR
  (`Entry`=14222 AND `Item`=80175) OR
  (`Entry`=14223 AND `Item`=80178) OR
  (`Entry`=14225 AND `Item`=82890) OR
  (`Entry`=14228 AND `Item`=80201) OR
  (`Entry`=14231 AND `Item`=601077) OR
  (`Entry`=14232 AND `Item`=80210) OR
  (`Entry`=14233 AND `Item`=80224) OR
  (`Entry`=14234 AND `Item`=80225) OR
  (`Entry`=14237 AND `Item`=80226) OR
  (`Entry`=14266 AND `Item`=80238) OR
  (`Entry`=14268 AND `Item`=80242) OR
  (`Entry`=14269 AND `Item`=600761) OR
  (`Entry`=14272 AND `Item`=1180410) OR
  (`Entry`=14279 AND `Item`=80243) OR
  (`Entry`=14280 AND `Item`=80244) OR
  (`Entry`=14303 AND `Item`=601825) OR
  (`Entry`=14339 AND `Item`=80247) OR
  (`Entry`=14340 AND `Item`=82981) OR
  (`Entry`=14343 AND `Item`=80248) OR
  (`Entry`=14344 AND `Item`=80249) OR
  (`Entry`=14398 AND `Item`=1180415) OR
  (`Entry`=14424 AND `Item`=601078) OR
  (`Entry`=14430 AND `Item`=80250) OR
  (`Entry`=14445 AND `Item`=1180417) OR
  (`Entry`=14448 AND `Item`=601079) OR
  (`Entry`=14467 AND `Item`=82982) OR
  (`Entry`=14472 AND `Item`=80251) OR
  (`Entry`=14473 AND `Item`=80252) OR
  (`Entry`=14476 AND `Item`=80253) OR
  (`Entry`=14477 AND `Item`=80254) OR
  (`Entry`=14491 AND `Item`=80255) OR
  (`Entry`=14502 AND `Item`=82983) OR
  (`Entry`=14506 AND `Item`=82985) OR
  (`Entry`=14519 AND `Item`=88852) OR
  (`Entry`=14530 AND `Item`=82996) OR
  (`Entry`=14535 AND `Item`=83017) OR
  (`Entry`=14564 AND `Item`=88858) OR
  (`Entry`=14682 AND `Item`=88859) OR
  (`Entry`=14686 AND `Item`=88860) OR
  (`Entry`=14825 AND `Item`=88870) OR
  (`Entry`=15211 AND `Item`=600766) OR
  (`Entry`=15271 AND `Item`=601853) OR
  (`Entry`=15294 AND `Item`=601854) OR
  (`Entry`=15298 AND `Item`=600767) OR
  (`Entry`=15366 AND `Item`=80293) OR
  (`Entry`=15372 AND `Item`=80296) OR
  (`Entry`=15409 AND `Item`=601855) OR
  (`Entry`=15547 AND `Item`=88891) OR
  (`Entry`=15548 AND `Item`=88899) OR
  (`Entry`=15625 AND `Item`=83033) OR
  (`Entry`=15636 AND `Item`=601857) OR
  (`Entry`=15637 AND `Item`=601858) OR
  (`Entry`=15648 AND `Item`=600769) OR
  (`Entry`=15649 AND `Item`=80297) OR
  (`Entry`=15650 AND `Item`=80298) OR
  (`Entry`=15651 AND `Item`=80299) OR
  (`Entry`=15652 AND `Item`=80300) OR
  (`Entry`=15654 AND `Item`=88900) OR
  (`Entry`=15655 AND `Item`=88901) OR
  (`Entry`=15656 AND `Item`=88902) OR
  (`Entry`=15657 AND `Item`=88903) OR
  (`Entry`=15658 AND `Item`=88904) OR
  (`Entry`=15690 AND `Item`=138255) OR
  (`Entry`=15958 AND `Item`=88906) OR
  (`Entry`=16042 AND `Item`=1180434) OR
  (`Entry`=16043 AND `Item`=600770) OR
  (`Entry`=16117 AND `Item`=80320) OR
  (`Entry`=16184 AND `Item`=88976) OR
  (`Entry`=16245 AND `Item`=88979) OR
  (`Entry`=16246 AND `Item`=88980) OR
  (`Entry`=16247 AND `Item`=88981) OR
  (`Entry`=16248 AND `Item`=88982) OR
  (`Entry`=16249 AND `Item`=88983) OR
  (`Entry`=16250 AND `Item`=88984) OR
  (`Entry`=16300 AND `Item`=88988) OR
  (`Entry`=16301 AND `Item`=88989) OR
  (`Entry`=16302 AND `Item`=88990);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(9877, 82776, 0, 1, 0, 1, 0, 1, 1, 'Prince Xavalis - Summoner''s Stone: Prince Xavalis'),
(9878, 600410, 0, 1, 0, 1, 0, 1, 1, 'Entropic Beast - Elemental Lodestone: Entropic Beast'),
(9879, 600411, 0, 1, 0, 1, 0, 1, 1, 'Entropic Horror - Elemental Lodestone: Entropic Horror'),
(9938, 601687, 0, 1, 0, 1, 0, 1, 1, 'Magmus - Elemental Lodestone: Ironhand Guardian'),
(10077, 80083, 0, 1, 0, 1, 0, 1, 1, 'Deathmaw - Beastmaster''s Whistle: Deathmaw'),
(10083, 1180294, 0, 1, 0, 1, 0, 1, 1, 'Rage Talon Flamescale - Draconic Warhorn: Rage Talon Flamescale'),
(10161, 1180298, 0, 1, 0, 1, 0, 1, 1, 'Rookery Whelp - Draconic Warhorn: Rookery Whelp'),
(10184, 1180299, 0, 1, 0, 1, 0, 1, 1, 'Onyxia - Draconic Warhorn: Onyxia'),
(10196, 1180300, 0, 1, 0, 1, 0, 1, 1, 'General Colbatann - Draconic Warhorn: General Colbatann'),
(10200, 80084, 0, 1, 0, 1, 0, 1, 1, 'Rak''shiri - Beastmaster''s Whistle: Rak''shiri'),
(10202, 1180301, 0, 1, 0, 1, 0, 1, 1, 'Azurous - Draconic Warhorn: Azurous'),
(10221, 80085, 0, 1, 0, 1, 0, 1, 1, 'Bloodaxe Worg Pup - Beastmaster''s Whistle: Bloodaxe Worg Pup'),
(10264, 1180305, 0, 1, 0, 1, 0, 1, 1, 'Solakar Flamewreath - Draconic Warhorn: Solakar Flamewreath'),
(10321, 1180307, 0, 1, 0, 1, 0, 1, 1, 'Emberstrife - Draconic Warhorn: Emberstrife'),
(10357, 80086, 0, 1, 0, 1, 0, 1, 1, 'Ressan the Needler - Beastmaster''s Whistle: Ressan the Needler'),
(10358, 88311, 0, 0.1, 0, 1, 0, 1, 1, 'Fellicent''s Shade - Blood Soaked Vellum: Fellicent''s Shade'),
(10359, 80087, 0, 1, 0, 1, 0, 1, 1, 'Sri''skulk - Beastmaster''s Whistle: Sri''skulk'),
(10363, 1180309, 0, 1, 0, 1, 0, 1, 1, 'General Drakkisath - Draconic Warhorn: General Drakkisath'),
(10366, 1180310, 0, 1, 0, 1, 0, 1, 1, 'Rage Talon Dragon Guard - Draconic Warhorn: Rage Talon Dragon Guard'),
(10371, 1180312, 0, 1, 0, 1, 0, 1, 1, 'Rage Talon Captain - Draconic Warhorn: Rage Talon Captain'),
(10372, 1180314, 0, 1, 0, 1, 0, 1, 1, 'Rage Talon Fire Tongue - Draconic Warhorn: Rage Talon Fire Tongue'),
(10373, 82777, 0, 1, 0, 1, 0, 1, 1, 'Xabraxxis - Summoner''s Stone: Xabraxxis'),
(10375, 80088, 0, 1, 0, 1, 0, 1, 1, 'Spire Spiderling - Beastmaster''s Whistle: Spire Spiderling'),
(10381, 88312, 0, 0.1, 0, 1, 0, 1, 1, 'Ravaged Cadaver - Blood Soaked Vellum: Ravaged Cadaver'),
(10382, 88313, 0, 0.1, 0, 1, 0, 1, 1, 'Mangled Cadaver - Blood Soaked Vellum: Mangled Cadaver'),
(10387, 88314, 0, 0.1, 0, 1, 0, 1, 1, 'Vengeful Phantom - Blood Soaked Vellum: Vengeful Phantom'),
(10388, 88315, 0, 0.1, 0, 1, 0, 1, 1, 'Spiteful Phantom - Blood Soaked Vellum: Spiteful Phantom'),
(10389, 88316, 0, 0.1, 0, 1, 0, 1, 1, 'Wrath Phantom - Blood Soaked Vellum: Wrath Phantom'),
(10390, 88317, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Guardian - Blood Soaked Vellum: Skeletal Guardian'),
(10391, 88318, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Berserker - Blood Soaked Vellum: Skeletal Berserker'),
(10393, 88319, 0, 0.1, 0, 1, 0, 1, 1, 'Skul - Blood Soaked Vellum: Skul'),
(10394, 88320, 0, 0.1, 0, 1, 0, 1, 1, 'Black Guard Sentry - Blood Soaked Vellum: Black Guard Sentry'),
(10404, 88321, 0, 0.1, 0, 1, 0, 1, 1, 'Pustulating Horror - Blood Soaked Vellum: Pustulating Horror'),
(10405, 88322, 0, 0.1, 0, 1, 0, 1, 1, 'Plague Ghoul - Blood Soaked Vellum: Plague Ghoul'),
(10406, 88323, 0, 0.1, 0, 1, 0, 1, 1, 'Ghoul Ravener - Blood Soaked Vellum: Ghoul Ravener'),
(10407, 88324, 0, 0.1, 0, 1, 0, 1, 1, 'Fleshflayer Ghoul - Blood Soaked Vellum: Fleshflayer Ghoul'),
(10408, 88325, 0, 0.1, 0, 1, 0, 1, 1, 'Rockwing Gargoyle - Blood Soaked Vellum: Rockwing Gargoyle'),
(10409, 88326, 0, 0.1, 0, 1, 0, 1, 1, 'Rockwing Screecher - Blood Soaked Vellum: Rockwing Screecher'),
(10411, 88327, 0, 0.1, 0, 1, 0, 1, 1, 'Eye of Naxxramas - Blood Soaked Vellum: Eye of Naxxramas'),
(10412, 88328, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Crawler - Blood Soaked Vellum: Crypt Crawler'),
(10413, 88329, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Beast - Blood Soaked Vellum: Crypt Beast'),
(10414, 88330, 0, 0.1, 0, 1, 0, 1, 1, 'Patchwork Horror - Blood Soaked Vellum: Patchwork Horror'),
(10416, 88331, 0, 0.1, 0, 1, 0, 1, 1, 'Bile Spewer - Blood Soaked Vellum: Bile Spewer'),
(10417, 88332, 0, 0.1, 0, 1, 0, 1, 1, 'Venom Belcher - Blood Soaked Vellum: Venom Belcher'),
(10429, 1180308, 0, 15, 0, 1, 0, 1, 1, 'Warchief Rend Blackhand - Draconic Warhorn: Gyth'),
(10429, 1180316, 0, 1, 0, 1, 0, 1, 1, 'Warchief Rend Blackhand - Draconic Warhorn: Chromatic Whelp'),
(10429, 1180319, 0, 1, 0, 1, 0, 1, 1, 'Warchief Rend Blackhand - Draconic Warhorn: Chromatic Dragonspawn'),
(10430, 80089, 0, 1, 0, 1, 0, 1, 1, 'The Beast - Beastmaster''s Whistle: The Beast'),
(10432, 88333, 0, 0.1, 0, 1, 0, 1, 1, 'Vectus - Blood Soaked Vellum: Vectus'),
(10435, 88334, 0, 0.1, 0, 1, 0, 1, 1, 'Magistrate Barthilas - Blood Soaked Vellum: Magistrate Barthilas'),
(10436, 88363, 0, 0.1, 0, 1, 0, 1, 1, 'Baroness Anastari - Blood Soaked Vellum: Baroness Anastari'),
(10437, 88364, 0, 0.1, 0, 1, 0, 1, 1, 'Nerub''enkan - Blood Soaked Vellum: Nerub''enkan'),
(10439, 88365, 0, 0.1, 0, 1, 0, 1, 1, 'Ramstein the Gorger - Blood Soaked Vellum: Ramstein the Gorger'),
(10463, 88366, 0, 0.1, 0, 1, 0, 1, 1, 'Shrieking Banshee - Blood Soaked Vellum: Shrieking Banshee'),
(10464, 88367, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Banshee - Blood Soaked Vellum: Wailing Banshee'),
(10478, 88372, 0, 0.1, 0, 1, 0, 1, 1, 'Splintered Skeleton - Blood Soaked Vellum: Splintered Skeleton'),
(10479, 88373, 0, 0.1, 0, 1, 0, 1, 1, 'Skulking Corpse - Blood Soaked Vellum: Skulking Corpse'),
(10480, 88374, 0, 0.1, 0, 1, 0, 1, 1, 'Unstable Corpse - Blood Soaked Vellum: Unstable Corpse'),
(10481, 88383, 0, 0.1, 0, 1, 0, 1, 1, 'Reanimated Corpse - Blood Soaked Vellum: Reanimated Corpse'),
(10485, 88415, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Aberration - Blood Soaked Vellum: Risen Aberration'),
(10486, 88434, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Warrior - Blood Soaked Vellum: Risen Warrior'),
(10487, 88436, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Protector - Blood Soaked Vellum: Risen Protector'),
(10488, 88467, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Construct - Blood Soaked Vellum: Risen Construct'),
(10489, 88534, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Guard - Blood Soaked Vellum: Risen Guard'),
(10491, 88539, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Bonewarder - Blood Soaked Vellum: Risen Bonewarder'),
(10495, 88540, 0, 0.1, 0, 1, 0, 1, 1, 'Diseased Ghoul - Blood Soaked Vellum: Diseased Ghoul'),
(10498, 88546, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Tutor - Blood Soaked Vellum: Spectral Tutor'),
(10499, 88547, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Researcher - Blood Soaked Vellum: Spectral Researcher'),
(10500, 88552, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Teacher - Blood Soaked Vellum: Spectral Teacher'),
(10506, 88560, 0, 0.1, 0, 1, 0, 1, 1, 'Kirtonos the Herald - Blood Soaked Vellum: Kirtonos the Herald'),
(10507, 88561, 0, 0.1, 0, 1, 0, 1, 1, 'The Ravenian - Blood Soaked Vellum: The Ravenian'),
(10516, 88562, 0, 0.1, 0, 1, 0, 1, 1, 'The Unforgiven - Blood Soaked Vellum: The Unforgiven'),
(10580, 88565, 0, 0.1, 0, 1, 0, 1, 1, 'Fetid Zombie - Blood Soaked Vellum: Fetid Zombie'),
(10641, 601072, 0, 1, 0, 1, 0, 1, 1, 'Branch Snapper - Elemental Lodestone: Branch Snapper'),
(10642, 600412, 0, 1, 0, 1, 0, 1, 1, 'Eck''alom - Elemental Lodestone: Eck''alom'),
(10644, 80090, 0, 1, 0, 1, 0, 1, 1, 'Mist Howler - Beastmaster''s Whistle: Mist Howler'),
(10647, 82778, 0, 1, 0, 1, 0, 1, 1, 'Prince Raze - Summoner''s Stone: Prince Raze'),
(10648, 82779, 0, 1, 0, 1, 0, 1, 1, 'Xavaric - Summoner''s Stone: Xavaric'),
(10659, 1180322, 0, 1, 0, 1, 0, 1, 1, 'Cobalt Whelp - Draconic Warhorn: Cobalt Whelp'),
(10660, 1180324, 0, 1, 0, 1, 0, 1, 1, 'Cobalt Broodling - Draconic Warhorn: Cobalt Broodling'),
(10661, 1180326, 0, 1, 0, 1, 0, 1, 1, 'Spell Eater - Draconic Warhorn: Spell Eater'),
(10662, 1180328, 0, 1, 0, 1, 0, 1, 1, 'Spellmaw - Draconic Warhorn: Spellmaw'),
(10663, 1180330, 0, 1, 0, 1, 0, 1, 1, 'Manaclaw - Draconic Warhorn: Manaclaw'),
(10664, 1180332, 0, 1, 0, 1, 0, 1, 1, 'Scryer - Draconic Warhorn: Scryer'),
(10678, 1180333, 0, 1, 0, 1, 0, 1, 1, 'Plagued Hatchling - Draconic Warhorn: Plagued Hatchling'),
(10756, 600413, 0, 1, 0, 1, 0, 1, 1, 'Scalding Elemental - Elemental Lodestone: Scalding Elemental'),
(10757, 600414, 0, 1, 0, 1, 0, 1, 1, 'Boiling Elemental - Elemental Lodestone: Boiling Elemental'),
(10801, 88670, 0, 0.1, 0, 1, 0, 1, 1, 'Jabbering Ghoul - Blood Soaked Vellum: Jabbering Ghoul'),
(10806, 80091, 0, 1, 0, 1, 0, 1, 1, 'Ursius - Beastmaster''s Whistle: Ursius'),
(10807, 80092, 0, 1, 0, 1, 0, 1, 1, 'Brumeran - Beastmaster''s Whistle: Brumeran'),
(10808, 88671, 0, 0.1, 0, 1, 0, 1, 1, 'Timmy the Cruel - Blood Soaked Vellum: Timmy the Cruel'),
(10809, 88672, 0, 0.1, 0, 1, 0, 1, 1, 'Stonespine - Blood Soaked Vellum: Stonespine'),
(10813, 82780, 0, 1, 0, 1, 0, 1, 1, 'Balnazzar - Summoner''s Stone: Balnazzar'),
(10816, 88673, 0, 0.1, 0, 1, 0, 1, 1, 'Wandering Skeleton - Blood Soaked Vellum: Wandering Skeleton'),
(10825, 88674, 0, 0.1, 0, 1, 0, 1, 1, 'Gish the Unmoving - Blood Soaked Vellum: Gish the Unmoving'),
(10826, 88675, 0, 0.1, 0, 1, 0, 1, 1, 'Lord Darkscythe - Blood Soaked Vellum: Lord Darkscythe'),
(10836, 88676, 0, 0.1, 0, 1, 0, 1, 1, 'Farmer Dalson - Blood Soaked Vellum: Farmer Dalson'),
(10901, 88677, 0, 0.1, 0, 1, 0, 1, 1, 'Lorekeeper Polkelt - Blood Soaked Vellum: Lorekeeper Polkelt'),
(10992, 80093, 0, 1, 0, 1, 0, 1, 1, 'Enraged Panther - Beastmaster''s Whistle: Enraged Panther'),
(11075, 88679, 0, 0.1, 0, 1, 0, 1, 1, 'Cauldron Lord Bilemaw - Blood Soaked Vellum: Cauldron Lord Bilemaw'),
(11076, 88680, 0, 0.1, 0, 1, 0, 1, 1, 'Cauldron Lord Razarch - Blood Soaked Vellum: Cauldron Lord Razarch'),
(11077, 88681, 0, 0.1, 0, 1, 0, 1, 1, 'Cauldron Lord Malvinious - Blood Soaked Vellum: Cauldron Lord Malvinious'),
(11078, 88689, 0, 0.1, 0, 1, 0, 1, 1, 'Cauldron Lord Soulwrath - Blood Soaked Vellum: Cauldron Lord Soulwrath'),
(11121, 88713, 0, 0.1, 0, 1, 0, 1, 1, 'Black Guard Swordsmith - Blood Soaked Vellum: Black Guard Swordsmith'),
(11290, 88716, 0, 0.1, 0, 1, 0, 1, 1, 'Mossflayer Zombie - Blood Soaked Vellum: Mossflayer Zombie'),
(11291, 88717, 0, 0.1, 0, 1, 0, 1, 1, 'Unliving Mossflayer - Blood Soaked Vellum: Unliving Mossflayer'),
(11320, 80094, 0, 1, 0, 1, 0, 1, 1, 'Earthborer - Beastmaster''s Whistle: Earthborer'),
(11321, 600417, 0, 1, 0, 1, 0, 1, 1, 'Molten Elemental - Elemental Lodestone: Molten Elemental'),
(11451, 82781, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Satyr - Summoner''s Stone: Wildspawn Satyr'),
(11452, 82782, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Rogue - Summoner''s Stone: Wildspawn Rogue'),
(11453, 82786, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Trickster - Summoner''s Stone: Wildspawn Trickster'),
(11454, 82801, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Betrayer - Summoner''s Stone: Wildspawn Betrayer'),
(11455, 82804, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Felsworn - Summoner''s Stone: Wildspawn Felsworn'),
(11456, 82805, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Shadowstalker - Summoner''s Stone: Wildspawn Shadowstalker'),
(11457, 82806, 0, 1, 0, 1, 0, 1, 1, 'Wildspawn Hellcaller - Summoner''s Stone: Wildspawn Hellcaller'),
(11458, 601818, 0, 1, 0, 1, 0, 1, 1, 'Petrified Treant - Elemental Lodestone: Petrified Treant'),
(11461, 601819, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Guardian - Elemental Lodestone: Warpwood Guardian'),
(11462, 601820, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Treant - Elemental Lodestone: Warpwood Treant'),
(11464, 601821, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Tangler - Elemental Lodestone: Warpwood Tangler'),
(11465, 601822, 0, 1, 0, 1, 0, 1, 1, 'Warpwood Stomper - Elemental Lodestone: Warpwood Stomper'),
(11471, 88718, 0, 0.1, 0, 1, 0, 1, 1, 'Eldreth Apparition - Blood Soaked Vellum: Eldreth Apparition'),
(11472, 88719, 0, 0.1, 0, 1, 0, 1, 1, 'Eldreth Spirit - Blood Soaked Vellum: Eldreth Spirit'),
(11473, 88720, 0, 0.1, 0, 1, 0, 1, 1, 'Eldreth Spectre - Blood Soaked Vellum: Eldreth Spectre'),
(11475, 88721, 0, 0.1, 0, 1, 0, 1, 1, 'Eldreth Phantasm - Blood Soaked Vellum: Eldreth Phantasm'),
(11476, 88722, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Highborne - Blood Soaked Vellum: Skeletal Highborne'),
(11477, 88753, 0, 0.1, 0, 1, 0, 1, 1, 'Rotting Highborne - Blood Soaked Vellum: Rotting Highborne'),
(11480, 600418, 0, 1, 0, 1, 0, 1, 1, 'Arcane Aberration - Elemental Lodestone: Arcane Aberration'),
(11483, 600419, 0, 1, 0, 1, 0, 1, 1, 'Mana Remnant - Elemental Lodestone: Mana Remnant'),
(11484, 600420, 0, 1, 0, 1, 0, 1, 1, 'Residual Monstrosity - Elemental Lodestone: Residual Monstrosity'),
(11490, 82863, 0, 1, 0, 1, 0, 1, 1, 'Zevrim Thornhoof - Summoner''s Stone: Zevrim Thornhoof'),
(11492, 82865, 0, 1, 0, 1, 0, 1, 1, 'Alzzin the Wildshaper - Summoner''s Stone: Alzzin the Wildshaper'),
(11496, 82871, 0, 1, 0, 1, 0, 1, 1, 'Immol''thar - Summoner''s Stone: Immol''thar'),
(11497, 80105, 0, 1, 0, 1, 0, 1, 1, 'The Razza - Beastmaster''s Whistle: The Razza'),
(11551, 88754, 0, 0.1, 0, 1, 0, 1, 1, 'Necrofiend - Blood Soaked Vellum: Necrofiend'),
(11561, 88755, 0, 0.1, 0, 1, 0, 1, 1, 'Undead Ravager - Blood Soaked Vellum: Undead Ravager'),
(11622, 88757, 0, 0.1, 0, 1, 0, 1, 1, 'Rattlegore - Blood Soaked Vellum: Rattlegore'),
(11723, 80107, 0, 1, 0, 1, 0, 1, 1, 'Hive''Ashi Sandstalker - Beastmaster''s Whistle: Hive''Ashi Sandstalker'),
(11728, 80108, 0, 1, 0, 1, 0, 1, 1, 'Hive''Zora Reaver - Beastmaster''s Whistle: Hive''Zora Reaver'),
(11730, 80109, 0, 1, 0, 1, 0, 1, 1, 'Hive''Regal Ambusher - Beastmaster''s Whistle: Hive''Regal Ambusher'),
(11734, 80110, 0, 1, 0, 1, 0, 1, 1, 'Hive''Regal Hive Lord - Beastmaster''s Whistle: Hive''Regal Hive Lord'),
(11735, 80111, 0, 1, 0, 1, 0, 1, 1, 'Stonelash Scorpid - Beastmaster''s Whistle: Stonelash Scorpid'),
(11736, 80112, 0, 1, 0, 1, 0, 1, 1, 'Stonelash Pincer - Beastmaster''s Whistle: Stonelash Pincer'),
(11737, 80113, 0, 1, 0, 1, 0, 1, 1, 'Stonelash Flayer - Beastmaster''s Whistle: Stonelash Flayer'),
(11738, 80114, 0, 1, 0, 1, 0, 1, 1, 'Sand Skitterer - Beastmaster''s Whistle: Sand Skitterer'),
(11739, 80115, 0, 1, 0, 1, 0, 1, 1, 'Rock Stalker - Beastmaster''s Whistle: Rock Stalker'),
(11740, 80117, 0, 1, 0, 1, 0, 1, 1, 'Dredge Striker - Beastmaster''s Whistle: Dredge Striker'),
(11741, 80118, 0, 1, 0, 1, 0, 1, 1, 'Dredge Crusher - Beastmaster''s Whistle: Dredge Crusher'),
(11783, 600422, 0, 1, 0, 1, 0, 1, 1, 'Theradrim Shardling - Elemental Lodestone: Theradrim Shardling'),
(11784, 600423, 0, 1, 0, 1, 0, 1, 1, 'Theradrim Guardian - Elemental Lodestone: Theradrim Guardian'),
(11787, 80119, 0, 1, 0, 1, 0, 1, 1, 'Rock Borer - Beastmaster''s Whistle: Rock Borer'),
(11788, 80121, 0, 1, 0, 1, 0, 1, 1, 'Rock Worm - Beastmaster''s Whistle: Rock Worm'),
(11789, 80128, 0, 1, 0, 1, 0, 1, 1, 'Deep Borer - Beastmaster''s Whistle: Deep Borer'),
(11790, 82872, 0, 1, 0, 1, 0, 1, 1, 'Putridus Satyr - Summoner''s Stone: Putridus Satyr'),
(11791, 82873, 0, 1, 0, 1, 0, 1, 1, 'Putridus Trickster - Summoner''s Stone: Putridus Trickster'),
(11792, 82874, 0, 1, 0, 1, 0, 1, 1, 'Putridus Shadowstalker - Summoner''s Stone: Putridus Shadowstalker'),
(11873, 88758, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Attendant - Blood Soaked Vellum: Spectral Attendant'),
(11876, 82875, 0, 1, 0, 1, 0, 1, 1, 'Demon Spirit - Summoner''s Stone: Demon Spirit'),
(11921, 80135, 0, 1, 0, 1, 0, 1, 1, 'Besseleth - Beastmaster''s Whistle: Besseleth'),
(11983, 1180344, 0, 1, 0, 1, 0, 1, 1, 'Firemaw - Draconic Warhorn: Firemaw'),
(12017, 1180345, 0, 1, 0, 1, 0, 1, 1, 'Broodlord Lashlayer - Draconic Warhorn: Broodlord Lashlayer'),
(12037, 80160, 0, 1, 0, 1, 0, 1, 1, 'Ursol''lok - Beastmaster''s Whistle: Ursol''lok'),
(12129, 1180346, 0, 1, 0, 1, 0, 1, 1, 'Onyxian Warder - Draconic Warhorn: Onyxian Warder'),
(12219, 601198, 0, 1, 0, 1, 0, 1, 1, 'Barbed Lasher - Elemental Lodestone: Barbed Lasher'),
(12220, 601199, 0, 1, 0, 1, 0, 1, 1, 'Constrictor Vine - Elemental Lodestone: Constrictor Vine'),
(12223, 601074, 0, 1, 0, 1, 0, 1, 1, 'Cavern Lurker - Elemental Lodestone: Cavern Lurker'),
(12224, 601075, 0, 1, 0, 1, 0, 1, 1, 'Cavern Shambler - Elemental Lodestone: Cavern Shambler'),
(12236, 82876, 0, 1, 0, 1, 0, 1, 1, 'Lord Vyletongue - Summoner''s Stone: Lord Vyletongue'),
(12237, 601076, 0, 1, 0, 1, 0, 1, 1, 'Meshlok the Harvester - Elemental Lodestone: Meshlok the Harvester'),
(12248, 88759, 0, 0.1, 0, 1, 0, 1, 1, 'Infiltrator Hameya - Blood Soaked Vellum: Infiltrator Hameya'),
(12250, 88760, 0, 0.1, 0, 1, 0, 1, 1, 'Zaeldarr the Outcast - Blood Soaked Vellum: Zaeldarr the Outcast'),
(12258, 601200, 0, 1, 0, 1, 0, 1, 1, 'Razorlash - Elemental Lodestone: Razorlash'),
(12261, 88761, 0, 0.1, 0, 1, 0, 1, 1, 'Infected Mossflayer - Blood Soaked Vellum: Infected Mossflayer'),
(12262, 88762, 0, 0.1, 0, 1, 0, 1, 1, 'Ziggurat Protector - Blood Soaked Vellum: Ziggurat Protector'),
(12263, 88795, 0, 0.1, 0, 1, 0, 1, 1, 'Slaughterhouse Protector - Blood Soaked Vellum: Slaughterhouse Protector'),
(12347, 80161, 0, 1, 0, 1, 0, 1, 1, 'Enraged Reef Crawler - Beastmaster''s Whistle: Enraged Reef Crawler'),
(12377, 88796, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Spectre - Blood Soaked Vellum: Wailing Spectre'),
(12378, 88803, 0, 0.1, 0, 1, 0, 1, 1, 'Damned Soul - Blood Soaked Vellum: Damned Soul'),
(12396, 82887, 0, 1, 0, 1, 0, 1, 1, 'Doomguard Commander - Summoner''s Stone: Doomguard Commander'),
(12418, 80162, 0, 1, 0, 1, 0, 1, 1, 'Gordok Hyena - Beastmaster''s Whistle: Gordok Hyena'),
(12431, 80163, 0, 1, 0, 1, 0, 1, 1, 'Gorefang - Beastmaster''s Whistle: Gorefang'),
(12432, 80164, 0, 1, 0, 1, 0, 1, 1, 'Old Vicejaw - Beastmaster''s Whistle: Old Vicejaw'),
(12433, 80165, 0, 1, 0, 1, 0, 1, 1, 'Krethis Shadowspinner - Beastmaster''s Whistle: Krethis Shadowspinner'),
(12435, 1180352, 0, 1, 0, 1, 0, 1, 1, 'Razorgore the Untamed - Draconic Warhorn: Razorgore the Untamed'),
(12460, 1180353, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Wyrmguard - Draconic Warhorn: Death Talon Wyrmguard'),
(12461, 1180355, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Overseer - Draconic Warhorn: Death Talon Overseer'),
(12463, 1180357, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Flamescale - Draconic Warhorn: Death Talon Flamescale'),
(12464, 1180359, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Seether - Draconic Warhorn: Death Talon Seether'),
(12465, 1180361, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Wyrmkin - Draconic Warhorn: Death Talon Wyrmkin'),
(12467, 1180364, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Captain - Draconic Warhorn: Death Talon Captain'),
(12468, 1180366, 0, 1, 0, 1, 0, 1, 1, 'Death Talon Hatcher - Draconic Warhorn: Death Talon Hatcher'),
(12474, 1180369, 0, 1, 0, 1, 0, 1, 1, 'Emeraldon Boughguard - Draconic Warhorn: Emeraldon Boughguard'),
(12475, 1180370, 0, 1, 0, 1, 0, 1, 1, 'Emeraldon Tree Warder - Draconic Warhorn: Emeraldon Tree Warder'),
(12476, 1180371, 0, 1, 0, 1, 0, 1, 1, 'Emeraldon Oracle - Draconic Warhorn: Emeraldon Oracle'),
(12477, 1180372, 0, 1, 0, 1, 0, 1, 1, 'Verdantine Boughguard - Draconic Warhorn: Verdantine Boughguard'),
(12478, 1180373, 0, 1, 0, 1, 0, 1, 1, 'Verdantine Oracle - Draconic Warhorn: Verdantine Oracle'),
(12479, 1180374, 0, 1, 0, 1, 0, 1, 1, 'Verdantine Tree Warder - Draconic Warhorn: Verdantine Tree Warder'),
(12496, 1180376, 0, 1, 0, 1, 0, 1, 1, 'Dreamtracker - Draconic Warhorn: Dreamtracker'),
(12497, 1180377, 0, 1, 0, 1, 0, 1, 1, 'Dreamroarer - Draconic Warhorn: Dreamroarer'),
(12498, 1180379, 0, 1, 0, 1, 0, 1, 1, 'Dreamstalker - Draconic Warhorn: Dreamstalker'),
(12759, 600430, 0, 1, 0, 1, 0, 1, 1, 'Tideress - Elemental Lodestone: Tideress'),
(12800, 80166, 0, 1, 0, 1, 0, 1, 1, 'Chimaerok - Beastmaster''s Whistle: Chimaerok'),
(12801, 80168, 0, 1, 0, 1, 0, 1, 1, 'Arcane Chimaerok - Beastmaster''s Whistle: Arcane Chimaerok'),
(12802, 80169, 0, 1, 0, 1, 0, 1, 1, 'Chimaerok Devourer - Beastmaster''s Whistle: Chimaerok Devourer'),
(12803, 80170, 0, 1, 0, 1, 0, 1, 1, 'Lord Lakmaeran - Beastmaster''s Whistle: Lord Lakmaeran'),
(12876, 600432, 0, 1, 0, 1, 0, 1, 1, 'Baron Aquanis - Elemental Lodestone: Baron Aquanis'),
(12899, 1180386, 0, 1, 0, 1, 0, 1, 1, 'Axtroz - Draconic Warhorn: Axtroz'),
(12900, 1180387, 0, 1, 0, 1, 0, 1, 1, 'Somnus - Draconic Warhorn: Somnus'),
(13020, 1180389, 0, 1, 0, 1, 0, 1, 1, 'Vaelastrasz the Corrupt - Draconic Warhorn: Vaelastrasz the Corrupt'),
(13022, 601201, 0, 1, 0, 1, 0, 1, 1, 'Whip Lasher - Elemental Lodestone: Whip Lasher(Purple)'),
(13022, 601864, 0, 1, 0, 1, 0, 1, 1, 'Whip Lasher - Elemental Lodestone: Whip Lasher (Fuchsia)'),
(13036, 80171, 0, 1, 0, 1, 0, 1, 1, 'Gordok Mastiff - Beastmaster''s Whistle: Gordok Mastiff'),
(13141, 1777421, 0, 1, 0, 1, 0, 1, 1, 'Deeprot Stomper - Elemental Lodestone: Deeprot Stomper'),
(13196, 601202, 0, 1, 0, 1, 0, 1, 1, 'Phase Lasher - Elemental Lodestone: Phase Lasher'),
(13197, 601203, 0, 1, 0, 1, 0, 1, 1, 'Fel Lash - Elemental Lodestone: Fel Lash'),
(13279, 600435, 0, 1, 0, 1, 0, 1, 1, 'Discordant Surge - Elemental Lodestone: Discordant Surge'),
(13280, 600436, 0, 1, 0, 1, 0, 1, 1, 'Hydrospawn - Elemental Lodestone: Hydrospawn'),
(13282, 600437, 0, 1, 0, 1, 0, 1, 1, 'Noxxion - Elemental Lodestone: Noxxion'),
(13285, 601204, 0, 1, 0, 1, 0, 1, 1, 'Death Lash - Elemental Lodestone: Death Lash'),
(13599, 80172, 0, 1, 0, 1, 0, 1, 1, 'Stolid Snapjaw - Beastmaster''s Whistle: Stolid Snapjaw'),
(13743, 601824, 0, 1, 0, 1, 0, 1, 1, 'Corrupt Force of Nature - Elemental Lodestone: Corrupt Force of Nature'),
(13896, 80173, 0, 1, 0, 1, 0, 1, 1, 'Scalebeard - Beastmaster''s Whistle: Scalebeard'),
(14020, 1180392, 0, 1, 0, 1, 0, 1, 1, 'Chromaggus - Draconic Warhorn: Chromaggus'),
(14123, 80174, 0, 1, 0, 1, 0, 1, 1, 'Steeljaw Snapper - Beastmaster''s Whistle: Steeljaw Snapper'),
(14222, 80175, 0, 1, 0, 1, 0, 1, 1, 'Araga - Beastmaster''s Whistle: Araga'),
(14223, 80178, 0, 1, 0, 1, 0, 1, 1, 'Cranky Benj - Beastmaster''s Whistle: Cranky Benj'),
(14225, 82890, 0, 1, 0, 1, 0, 1, 1, 'Prince Kellen - Summoner''s Stone: Prince Kellen'),
(14228, 80201, 0, 1, 0, 1, 0, 1, 1, 'Giggler - Beastmaster''s Whistle: Giggler'),
(14231, 601077, 0, 1, 0, 1, 0, 1, 1, 'Drogoth the Roamer - Elemental Lodestone: Drogoth the Roamer'),
(14232, 80210, 0, 1, 0, 1, 0, 1, 1, 'Dart - Beastmaster''s Whistle: Dart'),
(14233, 80224, 0, 1, 0, 1, 0, 1, 1, 'Ripscale - Beastmaster''s Whistle: Ripscale'),
(14234, 80225, 0, 1, 0, 1, 0, 1, 1, 'Hayoc - Beastmaster''s Whistle: Hayoc'),
(14237, 80226, 0, 1, 0, 1, 0, 1, 1, 'Oozeworm - Beastmaster''s Whistle: Oozeworm'),
(14266, 80238, 0, 1, 0, 1, 0, 1, 1, 'Shanda the Spinner - Beastmaster''s Whistle: Shanda the Spinner'),
(14268, 80242, 0, 1, 0, 1, 0, 1, 1, 'Lord Condar - Beastmaster''s Whistle: Lord Condar'),
(14269, 600761, 0, 1, 0, 1, 0, 1, 1, 'Seeker Aqualon - Elemental Lodestone: Seeker Aqualon'),
(14272, 1180410, 0, 1, 0, 1, 0, 1, 1, 'Snarlflare - Draconic Warhorn: Snarlflare'),
(14279, 80243, 0, 1, 0, 1, 0, 1, 1, 'Creepthess - Beastmaster''s Whistle: Creepthess'),
(14280, 80244, 0, 1, 0, 1, 0, 1, 1, 'Big Samras - Beastmaster''s Whistle: Big Samras'),
(14303, 601825, 0, 1, 0, 1, 0, 1, 1, 'Petrified Guardian - Elemental Lodestone: Petrified Guardian'),
(14339, 80247, 0, 1, 0, 1, 0, 1, 1, 'Death Howl - Beastmaster''s Whistle: Death Howl'),
(14340, 82981, 0, 1, 0, 1, 0, 1, 1, 'Alshirr Banebreath - Summoner''s Stone: Alshirr Banebreath'),
(14343, 80248, 0, 1, 0, 1, 0, 1, 1, 'Olm the Wise - Beastmaster''s Whistle: Olm the Wise'),
(14344, 80249, 0, 1, 0, 1, 0, 1, 1, 'Mongress - Beastmaster''s Whistle: Mongress'),
(14398, 1180415, 0, 1, 0, 1, 0, 1, 1, 'Eldreth Darter - Draconic Warhorn: Eldreth Darter'),
(14424, 601078, 0, 1, 0, 1, 0, 1, 1, 'Mirelow - Elemental Lodestone: Mirelow'),
(14430, 80250, 0, 1, 0, 1, 0, 1, 1, 'Duskstalker - Beastmaster''s Whistle: Duskstalker'),
(14445, 1180417, 0, 1, 0, 1, 0, 1, 1, 'Lord Captain Wyrmak - Draconic Warhorn: Lord Captain Wyrmak'),
(14448, 601079, 0, 1, 0, 1, 0, 1, 1, 'Molt Thorn - Elemental Lodestone: Molt Thorn'),
(14467, 82982, 0, 1, 0, 1, 0, 1, 1, 'Kroshius - Summoner''s Stone: Kroshius'),
(14472, 80251, 0, 1, 0, 1, 0, 1, 1, 'Gretheer - Beastmaster''s Whistle: Gretheer'),
(14473, 80252, 0, 1, 0, 1, 0, 1, 1, 'Lapress - Beastmaster''s Whistle: Lapress'),
(14476, 80253, 0, 1, 0, 1, 0, 1, 1, 'Krellack - Beastmaster''s Whistle: Krellack'),
(14477, 80254, 0, 1, 0, 1, 0, 1, 1, 'Grubthor - Beastmaster''s Whistle: Grubthor'),
(14491, 80255, 0, 1, 0, 1, 0, 1, 1, 'Kurmokk - Beastmaster''s Whistle: Kurmokk'),
(14502, 82983, 0, 1, 0, 1, 0, 1, 1, 'Xorothian Dreadsteed - Summoner''s Stone: Xorothian Dreadsteed'),
(14506, 82985, 0, 1, 0, 1, 0, 1, 1, 'Lord Hel''nurath - Summoner''s Stone: Lord Hel''nurath'),
(14519, 88852, 0, 0.1, 0, 1, 0, 1, 1, 'Aspect of Corruption - Blood Soaked Vellum: Aspect of Corruption'),
(14530, 82996, 0, 1, 0, 1, 0, 1, 1, 'Solenor the Slayer - Summoner''s Stone: Solenor the Slayer'),
(14535, 83017, 0, 1, 0, 1, 0, 1, 1, 'Artorius the Doombringer - Summoner''s Stone: Artorius the Doombringer'),
(14564, 88858, 0, 0.1, 0, 1, 0, 1, 1, 'Terrordale Spirit - Blood Soaked Vellum: Terrordale Spirit'),
(14682, 88859, 0, 0.1, 0, 1, 0, 1, 1, 'Sever - Blood Soaked Vellum: Sever'),
(14686, 88860, 0, 0.1, 0, 1, 0, 1, 1, 'Lady Falther''ess - Blood Soaked Vellum: Lady Falther''ess'),
(14825, 88870, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Mistress - Blood Soaked Vellum: Withered Mistress'),
(15211, 600766, 0, 1, 0, 1, 0, 1, 1, 'Azure Templar - Elemental Lodestone: Azure Templar'),
(15271, 601853, 0, 1, 0, 1, 0, 1, 1, 'Tender - Elemental Lodestone: Tender'),
(15294, 601854, 0, 1, 0, 1, 0, 1, 1, 'Feral Tender - Elemental Lodestone: Feral Tender'),
(15298, 600767, 0, 1, 0, 1, 0, 1, 1, 'Tainted Arcane Wraith - Elemental Lodestone: Tainted Arcane Wraith'),
(15366, 80293, 0, 1, 0, 1, 0, 1, 1, 'Springpaw Cub - Beastmaster''s Whistle: Springpaw Cub'),
(15372, 80296, 0, 1, 0, 1, 0, 1, 1, 'Springpaw Lynx - Beastmaster''s Whistle: Springpaw Lynx'),
(15409, 601855, 0, 1, 0, 1, 0, 1, 1, 'Old Whitebark - Elemental Lodestone: Old Whitebark'),
(15547, 88891, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Charger - Blood Soaked Vellum: Spectral Charger'),
(15548, 88899, 0, 0.1, 0, 1, 0, 1, 1, 'Spectral Stallion - Blood Soaked Vellum: Spectral Stallion'),
(15625, 83033, 0, 1, 0, 1, 0, 1, 1, 'Twilight Corrupter - Summoner''s Stone: Twilight Corrupter'),
(15636, 601857, 0, 1, 0, 1, 0, 1, 1, 'Eversong Green Keeper - Elemental Lodestone: Eversong Green Keeper'),
(15637, 601858, 0, 1, 0, 1, 0, 1, 1, 'Withered Green Keeper - Elemental Lodestone: Withered Green Keeper'),
(15648, 600769, 0, 1, 0, 1, 0, 1, 1, 'Manawraith - Elemental Lodestone: Manawraith'),
(15649, 80297, 0, 1, 0, 1, 0, 1, 1, 'Feral Dragonhawk Hatchling - Beastmaster''s Whistle: Feral Dragonhawk Hatchling'),
(15650, 80298, 0, 1, 0, 1, 0, 1, 1, 'Crazed Dragonhawk - Beastmaster''s Whistle: Crazed Dragonhawk'),
(15651, 80299, 0, 1, 0, 1, 0, 1, 1, 'Springpaw Stalker - Beastmaster''s Whistle: Springpaw Stalker'),
(15652, 80300, 0, 1, 0, 1, 0, 1, 1, 'Elder Springpaw - Beastmaster''s Whistle: Elder Springpaw'),
(15654, 88900, 0, 0.1, 0, 1, 0, 1, 1, 'Plaguebone Pillager - Blood Soaked Vellum: Plaguebone Pillager'),
(15655, 88901, 0, 0.1, 0, 1, 0, 1, 1, 'Rotlimb Cannibal - Blood Soaked Vellum: Rotlimb Cannibal'),
(15656, 88902, 0, 0.1, 0, 1, 0, 1, 1, 'Angershade - Blood Soaked Vellum: Angershade'),
(15657, 88903, 0, 0.1, 0, 1, 0, 1, 1, 'Darkwraith - Blood Soaked Vellum: Darkwraith'),
(15658, 88904, 0, 0.1, 0, 1, 0, 1, 1, 'Rotlimb Marauder - Blood Soaked Vellum: Rotlimb Marauder'),
(15690, 138255, 0, 1, 0, 1, 0, 1, 1, 'Prince Malchezaar - Summoner''s Stone: Prince Malchezaar'),
(15958, 88906, 0, 0.1, 0, 1, 0, 1, 1, 'Gharsul the Remorseless - Blood Soaked Vellum: Gharsul the Remorseless'),
(16042, 1180434, 0, 1, 0, 1, 0, 1, 1, 'Lord Valthalak - Draconic Warhorn: Lord Valthalak'),
(16043, 600770, 0, 1, 0, 1, 0, 1, 1, 'Magma Lord Bokk - Elemental Lodestone: Magma Lord Bokk'),
(16117, 80320, 0, 1, 0, 1, 0, 1, 1, 'Plagued Swine - Beastmaster''s Whistle: Plagued Swine'),
(16184, 88976, 0, 0.1, 0, 1, 0, 1, 1, 'Nerubian Overseer - Blood Soaked Vellum: Nerubian Overseer'),
(16245, 88979, 0, 0.1, 0, 1, 0, 1, 1, 'Luzran - Blood Soaked Vellum: Luzran'),
(16246, 88980, 0, 0.1, 0, 1, 0, 1, 1, 'Knucklerot - Blood Soaked Vellum: Knucklerot'),
(16247, 88981, 0, 0.1, 0, 1, 0, 1, 1, 'Borgoth the Bloodletter - Blood Soaked Vellum: Borgoth the Bloodletter'),
(16248, 88982, 0, 0.1, 0, 1, 0, 1, 1, 'Jurion the Deceiver - Blood Soaked Vellum: Jurion the Deceiver'),
(16249, 88983, 0, 0.1, 0, 1, 0, 1, 1, 'Masophet the Black - Blood Soaked Vellum: Masophet the Black'),
(16250, 88984, 0, 0.1, 0, 1, 0, 1, 1, 'Mirdoran the Fallen - Blood Soaked Vellum: Mirdoran the Fallen'),
(16300, 88988, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Creeper - Blood Soaked Vellum: Risen Creeper'),
(16301, 88989, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Hungerer - Blood Soaked Vellum: Risen Hungerer'),
(16302, 88990, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Stalker - Blood Soaked Vellum: Risen Stalker');
DELETE FROM `creature_loot_template` WHERE (`Entry`=16303 AND `Item`=88991) OR
  (`Entry`=16304 AND `Item`=600772) OR
  (`Entry`=16305 AND `Item`=88992) OR
  (`Entry`=16307 AND `Item`=88993) OR
  (`Entry`=16308 AND `Item`=88994) OR
  (`Entry`=16309 AND `Item`=88996) OR
  (`Entry`=16311 AND `Item`=88997) OR
  (`Entry`=16313 AND `Item`=88998) OR
  (`Entry`=16314 AND `Item`=89008) OR
  (`Entry`=16316 AND `Item`=89084) OR
  (`Entry`=16319 AND `Item`=89085) OR
  (`Entry`=16320 AND `Item`=89086) OR
  (`Entry`=16321 AND `Item`=89097) OR
  (`Entry`=16322 AND `Item`=89098) OR
  (`Entry`=16323 AND `Item`=89099) OR
  (`Entry`=16324 AND `Item`=89100) OR
  (`Entry`=16327 AND `Item`=89101) OR
  (`Entry`=16328 AND `Item`=89106) OR
  (`Entry`=16342 AND `Item`=89107) OR
  (`Entry`=16347 AND `Item`=80325) OR
  (`Entry`=16348 AND `Item`=80326) OR
  (`Entry`=16349 AND `Item`=80327) OR
  (`Entry`=16350 AND `Item`=80336) OR
  (`Entry`=16351 AND `Item`=80338) OR
  (`Entry`=16352 AND `Item`=80339) OR
  (`Entry`=16353 AND `Item`=80340) OR
  (`Entry`=16354 AND `Item`=80341) OR
  (`Entry`=16355 AND `Item`=80342) OR
  (`Entry`=16357 AND `Item`=89110) OR
  (`Entry`=16383 AND `Item`=89134) OR
  (`Entry`=16402 AND `Item`=89140) OR
  (`Entry`=16403 AND `Item`=89141) OR
  (`Entry`=16415 AND `Item`=89142) OR
  (`Entry`=16471 AND `Item`=89165) OR
  (`Entry`=16481 AND `Item`=89166) OR
  (`Entry`=16482 AND `Item`=89167) OR
  (`Entry`=16488 AND `Item`=600773) OR
  (`Entry`=16489 AND `Item`=600774) OR
  (`Entry`=16517 AND `Item`=601206) OR
  (`Entry`=16520 AND `Item`=80343) OR
  (`Entry`=16529 AND `Item`=600775) OR
  (`Entry`=16805 AND `Item`=89168) OR
  (`Entry`=16854 AND `Item`=600777) OR
  (`Entry`=16932 AND `Item`=80344) OR
  (`Entry`=16933 AND `Item`=80345) OR
  (`Entry`=16934 AND `Item`=80346) OR
  (`Entry`=16943 AND `Item`=83035) OR
  (`Entry`=16944 AND `Item`=83036) OR
  (`Entry`=16945 AND `Item`=83053) OR
  (`Entry`=16946 AND `Item`=83067) OR
  (`Entry`=16947 AND `Item`=83068) OR
  (`Entry`=16948 AND `Item`=83069) OR
  (`Entry`=16949 AND `Item`=83070) OR
  (`Entry`=16951 AND `Item`=83077) OR
  (`Entry`=16959 AND `Item`=83091) OR
  (`Entry`=16972 AND `Item`=80347) OR
  (`Entry`=16973 AND `Item`=80348) OR
  (`Entry`=17035 AND `Item`=80349) OR
  (`Entry`=17053 AND `Item`=80350) OR
  (`Entry`=17058 AND `Item`=83093) OR
  (`Entry`=17128 AND `Item`=80351) OR
  (`Entry`=17129 AND `Item`=80352) OR
  (`Entry`=17151 AND `Item`=83098) OR
  (`Entry`=17153 AND `Item`=600781) OR
  (`Entry`=17154 AND `Item`=600782) OR
  (`Entry`=17155 AND `Item`=600783) OR
  (`Entry`=17196 AND `Item`=601208) OR
  (`Entry`=17197 AND `Item`=601209) OR
  (`Entry`=17199 AND `Item`=80354) OR
  (`Entry`=17202 AND `Item`=80355) OR
  (`Entry`=17203 AND `Item`=80356) OR
  (`Entry`=17207 AND `Item`=600786) OR
  (`Entry`=17216 AND `Item`=80381) OR
  (`Entry`=17217 AND `Item`=80382) OR
  (`Entry`=17236 AND `Item`=80383) OR
  (`Entry`=17300 AND `Item`=83100) OR
  (`Entry`=17337 AND `Item`=83102) OR
  (`Entry`=17338 AND `Item`=83103) OR
  (`Entry`=17339 AND `Item`=83104) OR
  (`Entry`=17340 AND `Item`=83105) OR
  (`Entry`=17341 AND `Item`=83106) OR
  (`Entry`=17342 AND `Item`=83108) OR
  (`Entry`=17343 AND `Item`=601210) OR
  (`Entry`=17344 AND `Item`=601211) OR
  (`Entry`=17345 AND `Item`=80393) OR
  (`Entry`=17346 AND `Item`=601212) OR
  (`Entry`=17347 AND `Item`=80402) OR
  (`Entry`=17348 AND `Item`=80435) OR
  (`Entry`=17349 AND `Item`=80436) OR
  (`Entry`=17350 AND `Item`=80438) OR
  (`Entry`=17352 AND `Item`=601859) OR
  (`Entry`=17358 AND `Item`=600789) OR
  (`Entry`=17372 AND `Item`=80439) OR
  (`Entry`=17373 AND `Item`=80440) OR
  (`Entry`=17374 AND `Item`=80473) OR
  (`Entry`=17447 AND `Item`=80474) OR
  (`Entry`=17494 AND `Item`=83112) OR
  (`Entry`=17522 AND `Item`=80475) OR
  (`Entry`=17523 AND `Item`=80501) OR
  (`Entry`=17524 AND `Item`=83113) OR
  (`Entry`=17525 AND `Item`=80502) OR
  (`Entry`=17527 AND `Item`=80507) OR
  (`Entry`=17556 AND `Item`=80508) OR
  (`Entry`=17661 AND `Item`=80509) OR
  (`Entry`=17683 AND `Item`=80512) OR
  (`Entry`=17830 AND `Item`=83115) OR
  (`Entry`=17870 AND `Item`=600790) OR
  (`Entry`=17878 AND `Item`=89177) OR
  (`Entry`=17879 AND `Item`=1180443) OR
  (`Entry`=17880 AND `Item`=1180444) OR
  (`Entry`=17881 AND `Item`=1180445) OR
  (`Entry`=17895 AND `Item`=89186) OR
  (`Entry`=17897 AND `Item`=89187) OR
  (`Entry`=17906 AND `Item`=89198) OR
  (`Entry`=17980 AND `Item`=601213) OR
  (`Entry`=18033 AND `Item`=80517) OR
  (`Entry`=18096 AND `Item`=1180449) OR
  (`Entry`=18128 AND `Item`=80518) OR
  (`Entry`=18129 AND `Item`=80519) OR
  (`Entry`=18130 AND `Item`=80520) OR
  (`Entry`=18131 AND `Item`=80521) OR
  (`Entry`=18132 AND `Item`=80523) OR
  (`Entry`=18133 AND `Item`=80524) OR
  (`Entry`=18136 AND `Item`=601085) OR
  (`Entry`=18137 AND `Item`=601086) OR
  (`Entry`=18145 AND `Item`=600861) OR
  (`Entry`=18220 AND `Item`=80526) OR
  (`Entry`=18241 AND `Item`=80527) OR
  (`Entry`=18257 AND `Item`=80530) OR
  (`Entry`=18280 AND `Item`=80531) OR
  (`Entry`=18282 AND `Item`=601087) OR
  (`Entry`=18283 AND `Item`=80532) OR
  (`Entry`=18285 AND `Item`=80533) OR
  (`Entry`=18437 AND `Item`=80534) OR
  (`Entry`=18464 AND `Item`=80536) OR
  (`Entry`=18465 AND `Item`=80547) OR
  (`Entry`=18466 AND `Item`=80564) OR
  (`Entry`=18467 AND `Item`=80573) OR
  (`Entry`=18468 AND `Item`=80574) OR
  (`Entry`=18469 AND `Item`=80575) OR
  (`Entry`=18470 AND `Item`=80576) OR
  (`Entry`=18472 AND `Item`=600865) OR
  (`Entry`=18472 AND `Item`=600866) OR
  (`Entry`=18472 AND `Item`=1777426) OR
  (`Entry`=18472 AND `Item`=1777428) OR
  (`Entry`=18476 AND `Item`=80577) OR
  (`Entry`=18477 AND `Item`=80579) OR
  (`Entry`=18535 AND `Item`=138259) OR
  (`Entry`=18536 AND `Item`=83132) OR
  (`Entry`=18567 AND `Item`=83133) OR
  (`Entry`=18647 AND `Item`=80582) OR
  (`Entry`=18660 AND `Item`=83140) OR
  (`Entry`=18661 AND `Item`=83154) OR
  (`Entry`=18670 AND `Item`=80583) OR
  (`Entry`=18679 AND `Item`=83155) OR
  (`Entry`=18682 AND `Item`=601088) OR
  (`Entry`=18689 AND `Item`=89201) OR
  (`Entry`=18692 AND `Item`=1180456) OR
  (`Entry`=18694 AND `Item`=83240) OR
  (`Entry`=18695 AND `Item`=83241) OR
  (`Entry`=18696 AND `Item`=83242) OR
  (`Entry`=18827 AND `Item`=83244) OR
  (`Entry`=18858 AND `Item`=83251) OR
  (`Entry`=18859 AND `Item`=83252) OR
  (`Entry`=18860 AND `Item`=83253) OR
  (`Entry`=18867 AND `Item`=600864) OR
  (`Entry`=18877 AND `Item`=1180460) OR
  (`Entry`=18880 AND `Item`=80601) OR
  (`Entry`=18884 AND `Item`=80602) OR
  (`Entry`=18974 AND `Item`=83254) OR
  (`Entry`=18975 AND `Item`=83620) OR
  (`Entry`=18976 AND `Item`=83631) OR
  (`Entry`=18981 AND `Item`=83632) OR
  (`Entry`=19136 AND `Item`=83636) OR
  (`Entry`=19189 AND `Item`=80603) OR
  (`Entry`=19191 AND `Item`=138288) OR
  (`Entry`=19192 AND `Item`=83637) OR
  (`Entry`=19261 AND `Item`=83641) OR
  (`Entry`=19282 AND `Item`=83642) OR
  (`Entry`=19298 AND `Item`=83643) OR
  (`Entry`=19299 AND `Item`=83762) OR
  (`Entry`=19335 AND `Item`=83797) OR
  (`Entry`=19349 AND `Item`=80604) OR
  (`Entry`=19350 AND `Item`=80605) OR
  (`Entry`=19354 AND `Item`=84103) OR
  (`Entry`=19423 AND `Item`=80606) OR
  (`Entry`=19434 AND `Item`=84104) OR
  (`Entry`=19458 AND `Item`=80609) OR
  (`Entry`=19459 AND `Item`=80611) OR
  (`Entry`=19493 AND `Item`=84106) OR
  (`Entry`=19738 AND `Item`=84115) OR
  (`Entry`=19740 AND `Item`=84116) OR
  (`Entry`=19744 AND `Item`=84156) OR
  (`Entry`=19747 AND `Item`=138304) OR
  (`Entry`=19754 AND `Item`=84175) OR
  (`Entry`=19755 AND `Item`=84268) OR
  (`Entry`=19756 AND `Item`=84269) OR
  (`Entry`=19759 AND `Item`=84270) OR
  (`Entry`=19760 AND `Item`=84271) OR
  (`Entry`=19784 AND `Item`=80613) OR
  (`Entry`=19799 AND `Item`=84296) OR
  (`Entry`=19801 AND `Item`=84297) OR
  (`Entry`=19847 AND `Item`=138443) OR
  (`Entry`=19853 AND `Item`=84299) OR
  (`Entry`=19961 AND `Item`=84300) OR
  (`Entry`=19963 AND `Item`=84301) OR
  (`Entry`=19971 AND `Item`=84304) OR
  (`Entry`=19973 AND `Item`=84305) OR
  (`Entry`=19978 AND `Item`=84306) OR
  (`Entry`=19979 AND `Item`=84307) OR
  (`Entry`=19980 AND `Item`=84308) OR
  (`Entry`=20021 AND `Item`=1180470) OR
  (`Entry`=20052 AND `Item`=84309) OR
  (`Entry`=20058 AND `Item`=80616) OR
  (`Entry`=20079 AND `Item`=600870) OR
  (`Entry`=20090 AND `Item`=600871) OR
  (`Entry`=20132 AND `Item`=138465) OR
  (`Entry`=20138 AND `Item`=84310) OR
  (`Entry`=20141 AND `Item`=84311) OR
  (`Entry`=20196 AND `Item`=80617) OR
  (`Entry`=20197 AND `Item`=80619) OR
  (`Entry`=20198 AND `Item`=80620) OR
  (`Entry`=20215 AND `Item`=84312) OR
  (`Entry`=20285 AND `Item`=84313) OR
  (`Entry`=20326 AND `Item`=84314) OR
  (`Entry`=20330 AND `Item`=80621) OR
  (`Entry`=20332 AND `Item`=1180472) OR
  (`Entry`=20387 AND `Item`=80622) OR
  (`Entry`=20394 AND `Item`=84315) OR
  (`Entry`=20404 AND `Item`=84316) OR
  (`Entry`=20427 AND `Item`=84317) OR
  (`Entry`=20480 AND `Item`=89203) OR
  (`Entry`=20495 AND `Item`=89204) OR
  (`Entry`=20496 AND `Item`=89206) OR
  (`Entry`=20502 AND `Item`=80623) OR
  (`Entry`=20531 AND `Item`=1180449) OR
  (`Entry`=20557 AND `Item`=84318) OR
  (`Entry`=20611 AND `Item`=80624) OR
  (`Entry`=20634 AND `Item`=80625) OR
  (`Entry`=20671 AND `Item`=80626) OR
  (`Entry`=20673 AND `Item`=80627) OR
  (`Entry`=20680 AND `Item`=84319) OR
  (`Entry`=20683 AND `Item`=84350) OR
  (`Entry`=20685 AND `Item`=84368) OR
  (`Entry`=20713 AND `Item`=1180473) OR
  (`Entry`=20714 AND `Item`=80628) OR
  (`Entry`=20728 AND `Item`=80629) OR
  (`Entry`=20729 AND `Item`=80630) OR
  (`Entry`=20748 AND `Item`=80631) OR
  (`Entry`=20749 AND `Item`=80632) OR
  (`Entry`=20751 AND `Item`=80633) OR
  (`Entry`=20773 AND `Item`=80634) OR
  (`Entry`=20774 AND `Item`=601235) OR
  (`Entry`=20784 AND `Item`=84398) OR
  (`Entry`=20789 AND `Item`=84496) OR
  (`Entry`=20792 AND `Item`=600873) OR
  (`Entry`=20797 AND `Item`=80635) OR
  (`Entry`=20798 AND `Item`=84585) OR
  (`Entry`=20800 AND `Item`=84615) OR
  (`Entry`=20801 AND `Item`=84616) OR
  (`Entry`=20803 AND `Item`=84645) OR
  (`Entry`=20887 AND `Item`=84653) OR
  (`Entry`=20888 AND `Item`=139053) OR
  (`Entry`=20929 AND `Item`=84664) OR
  (`Entry`=20930 AND `Item`=84665) OR
  (`Entry`=20931 AND `Item`=80636) OR
  (`Entry`=20932 AND `Item`=80637) OR
  (`Entry`=20983 AND `Item`=601236) OR
  (`Entry`=20998 AND `Item`=80638) OR
  (`Entry`=21004 AND `Item`=1180479) OR
  (`Entry`=21021 AND `Item`=84666) OR
  (`Entry`=21022 AND `Item`=80639) OR
  (`Entry`=21032 AND `Item`=1180480) OR
  (`Entry`=21033 AND `Item`=80640) OR
  (`Entry`=21042 AND `Item`=80641) OR
  (`Entry`=21059 AND `Item`=600875) OR
  (`Entry`=21061 AND `Item`=600876) OR
  (`Entry`=21102 AND `Item`=80642) OR
  (`Entry`=21108 AND `Item`=80643) OR
  (`Entry`=21123 AND `Item`=80644) OR
  (`Entry`=21124 AND `Item`=80645) OR
  (`Entry`=21166 AND `Item`=84667) OR
  (`Entry`=21216 AND `Item`=600878) OR
  (`Entry`=21287 AND `Item`=139354) OR
  (`Entry`=21314 AND `Item`=84754) OR
  (`Entry`=21324 AND `Item`=80647) OR
  (`Entry`=21337 AND `Item`=84755) OR
  (`Entry`=21387 AND `Item`=1180502) OR
  (`Entry`=21389 AND `Item`=1180504) OR
  (`Entry`=21492 AND `Item`=1180508) OR
  (`Entry`=21499 AND `Item`=84756) OR
  (`Entry`=21500 AND `Item`=84760) OR
  (`Entry`=21501 AND `Item`=84761) OR
  (`Entry`=21506 AND `Item`=84768) OR
  (`Entry`=21515 AND `Item`=80648) OR
  (`Entry`=21516 AND `Item`=85152) OR
  (`Entry`=21520 AND `Item`=85154) OR
  (`Entry`=21648 AND `Item`=1180516) OR
  (`Entry`=21656 AND `Item`=85155) OR
  (`Entry`=21721 AND `Item`=1180520);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(16303, 88991, 0, 0.1, 0, 1, 0, 1, 1, 'Dreadbone Skeleton - Blood Soaked Vellum: Dreadbone Skeleton'),
(16304, 600772, 0, 1, 0, 1, 0, 1, 1, 'Arcane Devourer - Elemental Lodestone: Arcane Devourer'),
(16305, 88992, 0, 0.1, 0, 1, 0, 1, 1, 'Dreadbone Sentinel - Blood Soaked Vellum: Dreadbone Sentinel'),
(16307, 88993, 0, 0.1, 0, 1, 0, 1, 1, 'Deathcage Scryer - Blood Soaked Vellum: Deathcage Scryer'),
(16308, 88994, 0, 0.1, 0, 1, 0, 1, 1, 'Deathcage Sorcerer - Blood Soaked Vellum: Deathcage Sorcerer'),
(16309, 88996, 0, 0.1, 0, 1, 0, 1, 1, 'Gangled Cannibal - Blood Soaked Vellum: Gangled Cannibal'),
(16311, 88997, 0, 0.1, 0, 1, 0, 1, 1, 'Phantasmal Watcher - Blood Soaked Vellum: Phantasmal Watcher'),
(16313, 88998, 0, 0.1, 0, 1, 0, 1, 1, 'Nerubis Guard - Blood Soaked Vellum: Nerubis Guard'),
(16314, 89008, 0, 0.1, 0, 1, 0, 1, 1, 'Fallen Ranger - Blood Soaked Vellum: Fallen Ranger'),
(16316, 89084, 0, 0.1, 0, 1, 0, 1, 1, 'Stonewing Tracker - Blood Soaked Vellum: Stonewing Tracker'),
(16319, 89085, 0, 0.1, 0, 1, 0, 1, 1, 'Nerubis Centurion - Blood Soaked Vellum: Nerubis Centurion'),
(16320, 89086, 0, 0.1, 0, 1, 0, 1, 1, 'Eye of Dar''Khan - Blood Soaked Vellum: Eye of Dar''Khan'),
(16321, 89097, 0, 0.1, 0, 1, 0, 1, 1, 'Wailer - Blood Soaked Vellum: Wailer'),
(16322, 89098, 0, 0.1, 0, 1, 0, 1, 1, 'Gangled Flesheater - Blood Soaked Vellum: Gangled Flesheater'),
(16323, 89099, 0, 0.1, 0, 1, 0, 1, 1, 'Phantasmal Seeker - Blood Soaked Vellum: Phantasmal Seeker'),
(16324, 89100, 0, 0.1, 0, 1, 0, 1, 1, 'Stonewing Slayer - Blood Soaked Vellum: Stonewing Slayer'),
(16327, 89101, 0, 0.1, 0, 1, 0, 1, 1, 'Ravening Apparition - Blood Soaked Vellum: Ravening Apparition'),
(16328, 89106, 0, 0.1, 0, 1, 0, 1, 1, 'Vengeful Apparition - Blood Soaked Vellum: Vengeful Apparition'),
(16342, 89107, 0, 0.1, 0, 1, 0, 1, 1, 'Mummified Headhunter - Blood Soaked Vellum: Mummified Headhunter'),
(16347, 80325, 0, 1, 0, 1, 0, 1, 1, 'Starving Ghostclaw - Beastmaster''s Whistle: Starving Ghostclaw'),
(16348, 80326, 0, 1, 0, 1, 0, 1, 1, 'Ghostclaw Lynx - Beastmaster''s Whistle: Ghostclaw Lynx'),
(16349, 80327, 0, 1, 0, 1, 0, 1, 1, 'Ghostclaw Ravager - Beastmaster''s Whistle: Ghostclaw Ravager'),
(16350, 80336, 0, 1, 0, 1, 0, 1, 1, 'Spindleweb Spider - Beastmaster''s Whistle: Spindleweb Spider'),
(16351, 80338, 0, 1, 0, 1, 0, 1, 1, 'Spindleweb Lurker - Beastmaster''s Whistle: Spindleweb Lurker'),
(16352, 80339, 0, 1, 0, 1, 0, 1, 1, 'Greater Spindleweb - Beastmaster''s Whistle: Greater Spindleweb'),
(16353, 80340, 0, 1, 0, 1, 0, 1, 1, 'Mistbat - Beastmaster''s Whistle: Mistbat'),
(16354, 80341, 0, 1, 0, 1, 0, 1, 1, 'Vampiric Mistbat - Beastmaster''s Whistle: Vampiric Mistbat'),
(16355, 80342, 0, 1, 0, 1, 0, 1, 1, 'Lesser Scourgebat - Beastmaster''s Whistle: Lesser Scourgebat'),
(16357, 89110, 0, 0.1, 0, 1, 0, 1, 1, 'Anok''suten - Blood Soaked Vellum: Anok''suten'),
(16383, 89134, 0, 0.1, 0, 1, 0, 1, 1, 'Flameshocker - Blood Soaked Vellum: Flameshocker'),
(16402, 89140, 0, 0.1, 0, 1, 0, 1, 1, 'Zombified Grimscale - Blood Soaked Vellum: Zombified Grimscale'),
(16403, 89141, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Grimscale - Blood Soaked Vellum: Withered Grimscale'),
(16415, 89142, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Waiter - Blood Soaked Vellum: Skeletal Waiter'),
(16471, 89165, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Usher - Blood Soaked Vellum: Skeletal Usher'),
(16481, 89166, 0, 0.1, 0, 1, 0, 1, 1, 'Ghastly Haunt - Blood Soaked Vellum: Ghastly Haunt'),
(16482, 89167, 0, 0.1, 0, 1, 0, 1, 1, 'Trapped Soul - Blood Soaked Vellum: Trapped Soul'),
(16488, 600773, 0, 1, 0, 1, 0, 1, 1, 'Arcane Anomaly - Elemental Lodestone: Arcane Anomaly'),
(16489, 600774, 0, 1, 0, 1, 0, 1, 1, 'Chaotic Sentience - Elemental Lodestone: Chaotic Sentience'),
(16517, 601206, 0, 1, 0, 1, 0, 1, 1, 'Mutated Root Lasher - Elemental Lodestone: Mutated Root Lasher'),
(16520, 80343, 0, 1, 0, 1, 0, 1, 1, 'Vale Moth - Beastmaster''s Whistle: Vale Moth'),
(16529, 600775, 0, 1, 0, 1, 0, 1, 1, 'Magical Horror - Elemental Lodestone: Magical Horror'),
(16805, 89168, 0, 0.1, 0, 1, 0, 1, 1, 'Broken Skeleton - Blood Soaked Vellum: Broken Skeleton'),
(16854, 600777, 0, 1, 0, 1, 0, 1, 1, 'Eldinarcus - Elemental Lodestone: Eldinarcus'),
(16932, 80344, 0, 1, 0, 1, 0, 1, 1, 'Razorfang Hatchling - Beastmaster''s Whistle: Razorfang Hatchling'),
(16933, 80345, 0, 1, 0, 1, 0, 1, 1, 'Razorfang Ravager - Beastmaster''s Whistle: Razorfang Ravager'),
(16934, 80346, 0, 1, 0, 1, 0, 1, 1, 'Quillfang Ravager - Beastmaster''s Whistle: Quillfang Ravager'),
(16943, 83035, 0, 1, 0, 1, 0, 1, 1, 'Cyber-Rage Forgelord - Summoner''s Stone: Cyber-Rage Forgelord'),
(16944, 83036, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Doomsmith - Summoner''s Stone: Mo''arg Doomsmith'),
(16945, 83053, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Engineer - Summoner''s Stone: Mo''arg Engineer'),
(16946, 83067, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Forgefiend - Summoner''s Stone: Mo''arg Forgefiend'),
(16947, 83068, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Servant - Summoner''s Stone: Gan''arg Servant'),
(16948, 83069, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Engineer - Summoner''s Stone: Gan''arg Engineer'),
(16949, 83070, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Mekgineer - Summoner''s Stone: Gan''arg Mekgineer'),
(16951, 83077, 0, 1, 0, 1, 0, 1, 1, 'Terrorfiend - Summoner''s Stone: Terrorfiend'),
(16959, 83091, 0, 1, 0, 1, 0, 1, 1, 'Dread Tactician - Summoner''s Stone: Dread Tactician'),
(16972, 80347, 0, 1, 0, 1, 0, 1, 1, 'Bonestripper Buzzard - Beastmaster''s Whistle: Bonestripper Buzzard'),
(16973, 80348, 0, 1, 0, 1, 0, 1, 1, 'Bonestripper Vulture - Beastmaster''s Whistle: Bonestripper Vulture'),
(17035, 80349, 0, 1, 0, 1, 0, 1, 1, 'Kaliri Matriarch - Beastmaster''s Whistle: Kaliri Matriarch'),
(17053, 80350, 0, 1, 0, 1, 0, 1, 1, 'Kaliri Swooper - Beastmaster''s Whistle: Kaliri Swooper'),
(17058, 83093, 0, 1, 0, 1, 0, 1, 1, 'Illidari Taskmaster - Summoner''s Stone: Illidari Taskmaster'),
(17128, 80351, 0, 1, 0, 1, 0, 1, 1, 'Windroc - Beastmaster''s Whistle: Windroc'),
(17129, 80352, 0, 1, 0, 1, 0, 1, 1, 'Greater Windroc - Beastmaster''s Whistle: Greater Windroc'),
(17151, 83098, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Tinkerer - Summoner''s Stone: Gan''arg Tinkerer'),
(17153, 600781, 0, 1, 0, 1, 0, 1, 1, 'Lake Spirit - Elemental Lodestone: Lake Spirit'),
(17154, 600782, 0, 1, 0, 1, 0, 1, 1, 'Muck Spawn - Elemental Lodestone: Muck Spawn'),
(17155, 600783, 0, 1, 0, 1, 0, 1, 1, 'Lake Surger - Elemental Lodestone: Lake Surger'),
(17196, 601208, 0, 1, 0, 1, 0, 1, 1, 'Root Trapper - Elemental Lodestone: Root Trapper'),
(17197, 601209, 0, 1, 0, 1, 0, 1, 1, 'Root Thresher - Elemental Lodestone: Root Thresher'),
(17199, 80354, 0, 1, 0, 1, 0, 1, 1, 'Ravager Specimen - Beastmaster''s Whistle: Ravager Specimen'),
(17202, 80355, 0, 1, 0, 1, 0, 1, 1, 'Infected Nightstalker Runt - Beastmaster''s Whistle: Infected Nightstalker Runt'),
(17203, 80356, 0, 1, 0, 1, 0, 1, 1, 'Nightstalker - Beastmaster''s Whistle: Nightstalker'),
(17207, 600786, 0, 1, 0, 1, 0, 1, 1, 'Naias - Elemental Lodestone: Naias'),
(17216, 80381, 0, 1, 0, 1, 0, 1, 1, 'Skittering Crawler - Beastmaster''s Whistle: Skittering Crawler'),
(17217, 80382, 0, 1, 0, 1, 0, 1, 1, 'Barbed Crawler - Beastmaster''s Whistle: Barbed Crawler'),
(17236, 80383, 0, 1, 0, 1, 0, 1, 1, 'Tcha''kaz - Beastmaster''s Whistle: Tcha''kaz'),
(17300, 83100, 0, 1, 0, 1, 0, 1, 1, 'Gorgannon - Summoner''s Stone: Gorgannon'),
(17337, 83102, 0, 1, 0, 1, 0, 1, 1, 'Nazzivus Satyr - Summoner''s Stone: Nazzivus Satyr'),
(17338, 83103, 0, 1, 0, 1, 0, 1, 1, 'Nazzivus Rogue - Summoner''s Stone: Nazzivus Rogue'),
(17339, 83104, 0, 1, 0, 1, 0, 1, 1, 'Nazzivus Felsworn - Summoner''s Stone: Nazzivus Felsworn'),
(17340, 83105, 0, 1, 0, 1, 0, 1, 1, 'Axxarien Shadowstalker - Summoner''s Stone: Axxarien Shadowstalker'),
(17341, 83106, 0, 1, 0, 1, 0, 1, 1, 'Axxarien Trickster - Summoner''s Stone: Axxarien Trickster'),
(17342, 83108, 0, 1, 0, 1, 0, 1, 1, 'Axxarien Hellcaller - Summoner''s Stone: Axxarien Hellcaller'),
(17343, 601210, 0, 1, 0, 1, 0, 1, 1, 'Thistle Lasher - Elemental Lodestone: Thistle Lasher'),
(17344, 601211, 0, 1, 0, 1, 0, 1, 1, 'Mutated Constrictor - Elemental Lodestone: Mutated Constrictor'),
(17345, 80393, 0, 1, 0, 1, 0, 1, 1, 'Brown Bear - Beastmaster''s Whistle: Brown Bear'),
(17346, 601212, 0, 1, 0, 1, 0, 1, 1, 'Mutated Tangler - Elemental Lodestone: Mutated Tangler'),
(17347, 80402, 0, 1, 0, 1, 0, 1, 1, 'Grizzled Brown Bear - Beastmaster''s Whistle: Grizzled Brown Bear'),
(17348, 80435, 0, 1, 0, 1, 0, 1, 1, 'Elder Brown Bear - Beastmaster''s Whistle: Elder Brown Bear'),
(17349, 80436, 0, 1, 0, 1, 0, 1, 1, 'Blue Flutterer - Beastmaster''s Whistle: Blue Flutterer'),
(17350, 80438, 0, 1, 0, 1, 0, 1, 1, 'Royal Blue Flutterer - Beastmaster''s Whistle: Royal Blue Flutterer'),
(17352, 601859, 0, 1, 0, 1, 0, 1, 1, 'Corrupted Treant - Elemental Lodestone: Corrupted Treant'),
(17358, 600789, 0, 1, 0, 1, 0, 1, 1, 'Fouled Water Spirit - Elemental Lodestone: Fouled Water Spirit'),
(17372, 80439, 0, 1, 0, 1, 0, 1, 1, 'Timberstrider Fledgling - Beastmaster''s Whistle: Timberstrider Fledgling'),
(17373, 80440, 0, 1, 0, 1, 0, 1, 1, 'Timberstrider - Beastmaster''s Whistle: Timberstrider'),
(17374, 80473, 0, 1, 0, 1, 0, 1, 1, 'Greater Timberstrider - Beastmaster''s Whistle: Greater Timberstrider'),
(17447, 80474, 0, 1, 0, 1, 0, 1, 1, 'The Kurken - Beastmaster''s Whistle: The Kurken'),
(17494, 83112, 0, 1, 0, 1, 0, 1, 1, 'Zevrax - Summoner''s Stone: Zevrax'),
(17522, 80475, 0, 1, 0, 1, 0, 1, 1, 'Myst Spinner - Beastmaster''s Whistle: Myst Spinner'),
(17523, 80501, 0, 1, 0, 1, 0, 1, 1, 'Myst Leecher - Beastmaster''s Whistle: Myst Leecher'),
(17524, 83113, 0, 1, 0, 1, 0, 1, 1, 'Nazzivus Summoner - Summoner''s Stone: Nazzivus Summoner'),
(17525, 80502, 0, 1, 0, 1, 0, 1, 1, 'Bloodmyst Hatchling - Beastmaster''s Whistle: Bloodmyst Hatchling'),
(17527, 80507, 0, 1, 0, 1, 0, 1, 1, 'Enraged Ravager - Beastmaster''s Whistle: Enraged Ravager'),
(17556, 80508, 0, 1, 0, 1, 0, 1, 1, 'Death Ravager - Beastmaster''s Whistle: Death Ravager'),
(17661, 80509, 0, 1, 0, 1, 0, 1, 1, 'Deathclaw - Beastmaster''s Whistle: Deathclaw'),
(17683, 80512, 0, 1, 0, 1, 0, 1, 1, 'Zarakh - Beastmaster''s Whistle: Zarakh'),
(17830, 83115, 0, 1, 0, 1, 0, 1, 1, 'Zelemar the Wrathful - Summoner''s Stone: Zelemar the Wrathful'),
(17870, 600790, 0, 1, 0, 1, 0, 1, 1, 'Angered Nether-wraith - Elemental Lodestone: Angered Nether-wraith'),
(17878, 89177, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Siege Engineer - Blood Soaked Vellum: Scourge Siege Engineer'),
(17879, 1180443, 0, 1, 0, 1, 0, 1, 1, 'Chrono Lord Deja - Draconic Warhorn: Chrono Lord Deja'),
(17880, 1180444, 0, 1, 0, 1, 0, 1, 1, 'Temporus - Draconic Warhorn: Temporus'),
(17881, 1180445, 0, 1, 0, 1, 0, 1, 1, 'Aeonus - Draconic Warhorn: Aeonus'),
(17895, 89186, 0, 0.1, 0, 1, 0, 1, 1, 'Ghoul - Blood Soaked Vellum: Ghoul'),
(17897, 89187, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Fiend - Blood Soaked Vellum: Crypt Fiend'),
(17906, 89198, 0, 0.1, 0, 1, 0, 1, 1, 'Gargoyle - Blood Soaked Vellum: Gargoyle'),
(17980, 601213, 0, 1, 0, 1, 0, 1, 1, 'Laj - Elemental Lodestone: Laj'),
(18033, 80517, 0, 1, 0, 1, 0, 1, 1, 'Dark Worg - Beastmaster''s Whistle: Dark Worg'),
(18096, 1180449, 0, 1, 0, 1, 0, 1, 1, 'Epoch Hunter - Draconic Warhorn: Epoch Hunter'),
(18128, 80518, 0, 1, 0, 1, 0, 1, 1, 'Sporebat - Beastmaster''s Whistle: Sporebat'),
(18129, 80519, 0, 1, 0, 1, 0, 1, 1, 'Greater Sporebat - Beastmaster''s Whistle: Greater Sporebat'),
(18130, 80520, 0, 1, 0, 1, 0, 1, 1, 'Marshfang Ripper - Beastmaster''s Whistle: Marshfang Ripper'),
(18131, 80521, 0, 1, 0, 1, 0, 1, 1, 'Marshfang Slicer - Beastmaster''s Whistle: Marshfang Slicer'),
(18132, 80523, 0, 1, 0, 1, 0, 1, 1, 'Umbraglow Stinger - Beastmaster''s Whistle: Umbraglow Stinger'),
(18133, 80524, 0, 1, 0, 1, 0, 1, 1, 'Marshlight Bleeder - Beastmaster''s Whistle: Marshlight Bleeder'),
(18136, 601085, 0, 1, 0, 1, 0, 1, 1, 'Marsh Lurker - Elemental Lodestone: Marsh Lurker'),
(18137, 601086, 0, 1, 0, 1, 0, 1, 1, 'Marsh Dredger - Elemental Lodestone: Marsh Dredger'),
(18145, 600861, 0, 1, 0, 1, 0, 1, 1, 'Watoosun''s Polluted Essence - Elemental Lodestone: Watoosun''s Polluted Essence'),
(18220, 80526, 0, 1, 0, 1, 0, 1, 1, 'Ravenous Windroc - Beastmaster''s Whistle: Ravenous Windroc'),
(18241, 80527, 0, 1, 0, 1, 0, 1, 1, 'Crusty - Beastmaster''s Whistle: Crusty'),
(18257, 80530, 0, 1, 0, 1, 0, 1, 1, 'Gutripper - Beastmaster''s Whistle: Gutripper'),
(18280, 80531, 0, 1, 0, 1, 0, 1, 1, 'Sporewing - Beastmaster''s Whistle: Sporewing'),
(18282, 601087, 0, 1, 0, 1, 0, 1, 1, 'Lord Klaq - Elemental Lodestone: Lord Klaq'),
(18283, 80532, 0, 1, 0, 1, 0, 1, 1, 'Blacksting - Beastmaster''s Whistle: Blacksting'),
(18285, 80533, 0, 1, 0, 1, 0, 1, 1, '"Count" Ungula - Beastmaster''s Whistle: "Count" Ungula'),
(18437, 80534, 0, 1, 0, 1, 0, 1, 1, 'Vicious Teromoth - Beastmaster''s Whistle: Vicious Teromoth'),
(18464, 80536, 0, 1, 0, 1, 0, 1, 1, 'Warp Stalker - Beastmaster''s Whistle: Warp Stalker'),
(18465, 80547, 0, 1, 0, 1, 0, 1, 1, 'Warp Hunter - Beastmaster''s Whistle: Warp Hunter'),
(18466, 80564, 0, 1, 0, 1, 0, 1, 1, 'Dreadfang Lurker - Beastmaster''s Whistle: Dreadfang Lurker'),
(18467, 80573, 0, 1, 0, 1, 0, 1, 1, 'Dreadfang Widow - Beastmaster''s Whistle: Dreadfang Widow'),
(18468, 80574, 0, 1, 0, 1, 0, 1, 1, 'Teromoth - Beastmaster''s Whistle: Teromoth'),
(18469, 80575, 0, 1, 0, 1, 0, 1, 1, 'Royal Teromoth - Beastmaster''s Whistle: Royal Teromoth'),
(18470, 80576, 0, 1, 0, 1, 0, 1, 1, 'Bonelasher - Beastmaster''s Whistle: Bonelasher'),
(18472, 600865, 0, 1, 0, 1, 0, 1, 1, 'Darkweaver Syth - Elemental Lodestone: Syth Frost Elemental'),
(18472, 600866, 0, 1, 0, 1, 0, 1, 1, 'Darkweaver Syth - Elemental Lodestone: Syth Shadow Elemental'),
(18472, 1777426, 0, 1, 0, 1, 0, 1, 1, 'Darkweaver Syth - Elemental Lodestone: Syth Fire Elemental'),
(18472, 1777428, 0, 1, 0, 1, 0, 1, 1, 'Darkweaver Syth - Elemental Lodestone: Syth Arcane Elemental'),
(18476, 80577, 0, 1, 0, 1, 0, 1, 1, 'Timber Worg - Beastmaster''s Whistle: Timber Worg'),
(18477, 80579, 0, 1, 0, 1, 0, 1, 1, 'Timber Worg Alpha - Beastmaster''s Whistle: Timber Worg Alpha'),
(18535, 138259, 0, 1, 0, 1, 0, 1, 1, 'Demos, Overseer of Hate - Summoner''s Stone: Demos, Overseer of Hate'),
(18536, 83132, 0, 1, 0, 1, 0, 1, 1, 'Xirkos, Overseer of Fear - Summoner''s Stone: Xirkos, Overseer of Fear'),
(18567, 83133, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Master Planner - Summoner''s Stone: Mo''arg Master Planner'),
(18647, 80582, 0, 1, 0, 1, 0, 1, 1, 'Deathskitter - Beastmaster''s Whistle: Deathskitter'),
(18660, 83140, 0, 1, 0, 1, 0, 1, 1, 'Subjugator Vaz''shir - Summoner''s Stone: Subjugator Vaz''shir'),
(18661, 83154, 0, 1, 0, 1, 0, 1, 1, 'Terrorguard - Summoner''s Stone: Terrorguard'),
(18670, 80583, 0, 1, 0, 1, 0, 1, 1, 'Ironjaw - Beastmaster''s Whistle: Ironjaw'),
(18679, 83155, 0, 1, 0, 1, 0, 1, 1, 'Vorakem Doomspeaker - Summoner''s Stone: Vorakem Doomspeaker'),
(18682, 601088, 0, 1, 0, 1, 0, 1, 1, 'Bog Lurker - Elemental Lodestone: Bog Lurker'),
(18689, 89201, 0, 0.1, 0, 1, 0, 1, 1, 'Crippler - Blood Soaked Vellum: Crippler'),
(18692, 1180456, 0, 1, 0, 1, 0, 1, 1, 'Hemathion - Draconic Warhorn: Hemathion'),
(18694, 83240, 0, 1, 0, 1, 0, 1, 1, 'Collidus the Warp-Watcher - Summoner''s Stone: Collidus the Warp-Watcher'),
(18695, 83241, 0, 1, 0, 1, 0, 1, 1, 'Ambassador Jerrikar - Summoner''s Stone: Ambassador Jerrikar'),
(18696, 83242, 0, 1, 0, 1, 0, 1, 1, 'Kraator - Summoner''s Stone: Kraator'),
(18827, 83244, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Sapper - Summoner''s Stone: Gan''arg Sapper'),
(18858, 83251, 0, 1, 0, 1, 0, 1, 1, 'Wrathbringer - Summoner''s Stone: Wrathbringer'),
(18859, 83252, 0, 1, 0, 1, 0, 1, 1, 'Wrath Priestess - Summoner''s Stone: Wrath Priestess'),
(18860, 83253, 0, 1, 0, 1, 0, 1, 1, 'Daughter of Destiny - Summoner''s Stone: Daughter of Destiny'),
(18867, 600864, 0, 1, 0, 1, 0, 1, 1, 'Mana Seeker - Elemental Lodestone: Mana Seeker'),
(18877, 1180460, 0, 1, 0, 1, 0, 1, 1, 'Nether Drake - Draconic Warhorn: Nether Drake'),
(18880, 80601, 0, 1, 0, 1, 0, 1, 1, 'Nether Ray - Beastmaster''s Whistle: Nether Ray'),
(18884, 80602, 0, 1, 0, 1, 0, 1, 1, 'Warp Chaser - Beastmaster''s Whistle: Warp Chaser'),
(18974, 83254, 0, 1, 0, 1, 0, 1, 1, 'Z''kral - Summoner''s Stone: Z''kral'),
(18975, 83620, 0, 1, 0, 1, 0, 1, 1, 'Wrathguard - Summoner''s Stone: Wrathguard'),
(18976, 83631, 0, 1, 0, 1, 0, 1, 1, 'Urga''zz - Summoner''s Stone: Urga''zz'),
(18981, 83632, 0, 1, 0, 1, 0, 1, 1, 'Doomwhisperer - Summoner''s Stone: Doomwhisperer'),
(19136, 83636, 0, 1, 0, 1, 0, 1, 1, 'Flamewaker Imp - Summoner''s Stone: Flamewaker Imp'),
(19189, 80603, 0, 1, 0, 1, 0, 1, 1, 'Quillfang Skitterer - Beastmaster''s Whistle: Quillfang Skitterer'),
(19191, 138288, 0, 1, 0, 1, 0, 1, 1, 'Arazzius the Cruel - Summoner''s Stone: Arazzius the Cruel'),
(19192, 83637, 0, 1, 0, 1, 0, 1, 1, 'Mistress of Doom - Summoner''s Stone: Mistress of Doom'),
(19261, 83641, 0, 1, 0, 1, 0, 1, 1, 'Infernal Warbringer - Summoner''s Stone: Infernal Warbringer'),
(19282, 83642, 0, 1, 0, 1, 0, 1, 1, 'Subjugator Shi''aziv - Summoner''s Stone: Subjugator Shi''aziv'),
(19298, 83643, 0, 1, 0, 1, 0, 1, 1, 'Warbringer Arix''Amal - Summoner''s Stone: Warbringer Arix''Amal'),
(19299, 83762, 0, 1, 0, 1, 0, 1, 1, 'Deathwhisperer - Summoner''s Stone: Deathwhisperer'),
(19335, 83797, 0, 1, 0, 1, 0, 1, 1, 'Subjugator Yalqiz - Summoner''s Stone: Subjugator Yalqiz'),
(19349, 80604, 0, 1, 0, 1, 0, 1, 1, 'Thornfang Ravager - Beastmaster''s Whistle: Thornfang Ravager'),
(19350, 80605, 0, 1, 0, 1, 0, 1, 1, 'Thornfang Venomspitter - Beastmaster''s Whistle: Thornfang Venomspitter'),
(19354, 84103, 0, 1, 0, 1, 0, 1, 1, 'Arzeth the Merciless - Summoner''s Stone: Arzeth the Merciless'),
(19423, 80606, 0, 1, 0, 1, 0, 1, 1, 'Bleeding Hollow Worg - Beastmaster''s Whistle: Bleeding Hollow Worg'),
(19434, 84104, 0, 1, 0, 1, 0, 1, 1, 'Dreadcaller - Summoner''s Stone: Dreadcaller'),
(19458, 80609, 0, 1, 0, 1, 0, 1, 1, 'Ripp - Beastmaster''s Whistle: Ripp'),
(19459, 80611, 0, 1, 0, 1, 0, 1, 1, 'Feng - Beastmaster''s Whistle: Feng'),
(19493, 84106, 0, 1, 0, 1, 0, 1, 1, 'Ekkorash the Inquisitor - Summoner''s Stone: Ekkorash the Inquisitor'),
(19738, 84115, 0, 1, 0, 1, 0, 1, 1, 'Doomclaw - Summoner''s Stone: Doomclaw'),
(19740, 84116, 0, 1, 0, 1, 0, 1, 1, 'Wrathwalker - Summoner''s Stone: Wrathwalker'),
(19744, 84156, 0, 1, 0, 1, 0, 1, 1, 'Dreadwarden - Summoner''s Stone: Dreadwarden'),
(19747, 138304, 0, 1, 0, 1, 0, 1, 1, 'Baelmon the Hound-Master - Summoner''s Stone: Baelmon the Hound-Master'),
(19754, 84175, 0, 1, 0, 1, 0, 1, 1, 'Deathforge Tinkerer - Summoner''s Stone: Deathforge Tinkerer'),
(19755, 84268, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Weaponsmith - Summoner''s Stone: Mo''arg Weaponsmith'),
(19756, 84269, 0, 1, 0, 1, 0, 1, 1, 'Deathforge Smith - Summoner''s Stone: Deathforge Smith'),
(19759, 84270, 0, 1, 0, 1, 0, 1, 1, 'Newly Crafted Infernal - Summoner''s Stone: Newly Crafted Infernal'),
(19760, 84271, 0, 1, 0, 1, 0, 1, 1, 'Cooling Infernal - Summoner''s Stone: Cooling Infernal'),
(19784, 80613, 0, 1, 0, 1, 0, 1, 1, 'Coilskar Cobra - Beastmaster''s Whistle: Coilskar Cobra'),
(19799, 84296, 0, 1, 0, 1, 0, 1, 1, 'Illidari Dreadbringer - Summoner''s Stone: Illidari Dreadbringer'),
(19801, 84297, 0, 1, 0, 1, 0, 1, 1, 'Illidari Agonizer - Summoner''s Stone: Illidari Agonizer'),
(19847, 138443, 0, 1, 0, 1, 0, 1, 1, 'Levixus - Summoner''s Stone: Levixus'),
(19853, 84299, 0, 1, 0, 1, 0, 1, 1, 'Felblade Doomguard - Summoner''s Stone: Felblade Doomguard'),
(19961, 84300, 0, 1, 0, 1, 0, 1, 1, 'Doomforge Attendant - Summoner''s Stone: Doomforge Attendant'),
(19963, 84301, 0, 1, 0, 1, 0, 1, 1, 'Doomcryer - Summoner''s Stone: Doomcryer'),
(19971, 84304, 0, 1, 0, 1, 0, 1, 1, 'Dreadforge Servant - Summoner''s Stone: Dreadforge Servant'),
(19973, 84305, 0, 1, 0, 1, 0, 1, 1, 'Abyssal Flamebringer - Summoner''s Stone: Abyssal Flamebringer'),
(19978, 84306, 0, 1, 0, 1, 0, 1, 1, 'Deathforge Over-Smith - Summoner''s Stone: Deathforge Over-Smith'),
(19979, 84307, 0, 1, 0, 1, 0, 1, 1, 'Deathforge Technician - Summoner''s Stone: Deathforge Technician'),
(19980, 84308, 0, 1, 0, 1, 0, 1, 1, 'Void Terror - Summoner''s Stone: Void Terror'),
(20021, 1180470, 0, 1, 0, 1, 0, 1, 1, 'Nether Whelp - Draconic Warhorn: Nether Whelp'),
(20052, 84309, 0, 1, 0, 1, 0, 1, 1, 'Crystalcore Mechanic - Summoner''s Stone: Crystalcore Mechanic'),
(20058, 80616, 0, 1, 0, 1, 0, 1, 1, 'Bloodmaul Dire Wolf - Beastmaster''s Whistle: Bloodmaul Dire Wolf'),
(20079, 600870, 0, 1, 0, 1, 0, 1, 1, 'Darkcrest Sentry - Elemental Lodestone: Darkcrest Sentry'),
(20090, 600871, 0, 1, 0, 1, 0, 1, 1, 'Bloodscale Sentry - Elemental Lodestone: Bloodscale Sentry'),
(20132, 138465, 0, 1, 0, 1, 0, 1, 1, 'Socrethar - Summoner''s Stone: Socrethar'),
(20138, 84310, 0, 1, 0, 1, 0, 1, 1, 'Culuthas - Summoner''s Stone: Culuthas'),
(20141, 84311, 0, 1, 0, 1, 0, 1, 1, 'Hound of Culuthas - Summoner''s Stone: Hound of Culuthas'),
(20196, 80617, 0, 1, 0, 1, 0, 1, 1, 'Bloodthirsty Marshfang - Beastmaster''s Whistle: Bloodthirsty Marshfang'),
(20197, 80619, 0, 1, 0, 1, 0, 1, 1, 'Bogflare Needler - Beastmaster''s Whistle: Bogflare Needler'),
(20198, 80620, 0, 1, 0, 1, 0, 1, 1, 'Fenglow Stinger - Beastmaster''s Whistle: Fenglow Stinger'),
(20215, 84312, 0, 1, 0, 1, 0, 1, 1, 'Pentatharon - Summoner''s Stone: Pentatharon'),
(20285, 84313, 0, 1, 0, 1, 0, 1, 1, 'Gan''arg Warp-Tinker - Summoner''s Stone: Gan''arg Warp-Tinker'),
(20326, 84314, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Warp-Master - Summoner''s Stone: Mo''arg Warp-Master'),
(20330, 80621, 0, 1, 0, 1, 0, 1, 1, 'Bloodmaul Battle Worg - Beastmaster''s Whistle: Bloodmaul Battle Worg'),
(20332, 1180472, 0, 1, 0, 1, 0, 1, 1, 'Nether Dragon - Draconic Warhorn: Nether Dragon'),
(20387, 80622, 0, 1, 0, 1, 0, 1, 1, 'Young Sporebat - Beastmaster''s Whistle: Young Sporebat'),
(20394, 84315, 0, 1, 0, 1, 0, 1, 1, 'Eye of Culuthas - Summoner''s Stone: Eye of Culuthas'),
(20404, 84316, 0, 1, 0, 1, 0, 1, 1, 'Warp-Gate Engineer - Summoner''s Stone: Warp-Gate Engineer'),
(20427, 84317, 0, 1, 0, 1, 0, 1, 1, 'Veneratus the Many - Summoner''s Stone: Veneratus the Many'),
(20480, 89203, 0, 0.1, 0, 1, 0, 1, 1, 'Kirin''Var Ghost - Blood Soaked Vellum: Kirin''Var Ghost'),
(20495, 89204, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Stallion - Blood Soaked Vellum: Skeletal Stallion'),
(20496, 89206, 0, 0.1, 0, 1, 0, 1, 1, 'Kirin''Var Spectre - Blood Soaked Vellum: Kirin''Var Spectre'),
(20502, 80623, 0, 1, 0, 1, 0, 1, 1, 'Eclipsion Dragonhawk - Beastmaster''s Whistle: Eclipsion Dragonhawk'),
(20531, 1180449, 0, 1, 0, 1, 0, 1, 1, 'Epoch Hunter (1) - Draconic Warhorn: Epoch Hunter'),
(20557, 84318, 0, 1, 0, 1, 0, 1, 1, 'Wrath Hound - Summoner''s Stone: Wrath Hound'),
(20611, 80624, 0, 1, 0, 1, 0, 1, 1, 'Shimmerwing Moth - Beastmaster''s Whistle: Shimmerwing Moth'),
(20634, 80625, 0, 1, 0, 1, 0, 1, 1, 'Scythetooth Raptor - Beastmaster''s Whistle: Scythetooth Raptor'),
(20671, 80626, 0, 1, 0, 1, 0, 1, 1, 'Ripfang Lynx - Beastmaster''s Whistle: Ripfang Lynx'),
(20673, 80627, 0, 1, 0, 1, 0, 1, 1, 'Swiftwing Shredder - Beastmaster''s Whistle: Swiftwing Shredder'),
(20680, 84319, 0, 1, 0, 1, 0, 1, 1, 'Arzeth the Powerless - Summoner''s Stone: Arzeth the Powerless'),
(20683, 84350, 0, 1, 0, 1, 0, 1, 1, 'Prophetess Cavrylin - Summoner''s Stone: Prophetess Cavrylin'),
(20685, 84368, 0, 1, 0, 1, 0, 1, 1, 'Overseer Azarad - Summoner''s Stone: Overseer Azarad'),
(20713, 1180473, 0, 1, 0, 1, 0, 1, 1, 'Fey Drake - Draconic Warhorn: Fey Drake'),
(20714, 80628, 0, 1, 0, 1, 0, 1, 1, 'Ridgespine Stalker - Beastmaster''s Whistle: Ridgespine Stalker'),
(20728, 80629, 0, 1, 0, 1, 0, 1, 1, 'Bladespire Raptor - Beastmaster''s Whistle: Bladespire Raptor'),
(20729, 80630, 0, 1, 0, 1, 0, 1, 1, 'Bladespire Ravager - Beastmaster''s Whistle: Bladespire Ravager'),
(20748, 80631, 0, 1, 0, 1, 0, 1, 1, 'Thunderlord Dire Wolf - Beastmaster''s Whistle: Thunderlord Dire Wolf'),
(20749, 80632, 0, 1, 0, 1, 0, 1, 1, 'Scalewing Serpent - Beastmaster''s Whistle: Scalewing Serpent'),
(20751, 80633, 0, 1, 0, 1, 0, 1, 1, 'Daggermaw Lashtail - Beastmaster''s Whistle: Daggermaw Lashtail'),
(20773, 80634, 0, 1, 0, 1, 0, 1, 1, 'Barbscale Crocolisk - Beastmaster''s Whistle: Barbscale Crocolisk'),
(20774, 601235, 0, 1, 0, 1, 0, 1, 1, 'Farahlon Lasher - Elemental Lodestone: Farahlon Lasher'),
(20784, 84398, 0, 1, 0, 1, 0, 1, 1, 'Armbreaker Huffaz - Summoner''s Stone: Armbreaker Huffaz'),
(20789, 84496, 0, 1, 0, 1, 0, 1, 1, 'Wrathbringer Laz-tarash - Summoner''s Stone: Wrathbringer Laz-tarash'),
(20792, 600873, 0, 1, 0, 1, 0, 1, 1, 'Bloodscale Elemental - Elemental Lodestone: Bloodscale Elemental'),
(20797, 80635, 0, 1, 0, 1, 0, 1, 1, 'Deviate Coiler Hatchling - Beastmaster''s Whistle: Deviate Coiler Hatchling'),
(20798, 84585, 0, 1, 0, 1, 0, 1, 1, 'Razorsaw - Summoner''s Stone: Razorsaw'),
(20800, 84615, 0, 1, 0, 1, 0, 1, 1, 'Forgemaster Morug - Summoner''s Stone: Forgemaster Morug'),
(20801, 84616, 0, 1, 0, 1, 0, 1, 1, 'Silroth - Summoner''s Stone: Silroth'),
(20803, 84645, 0, 1, 0, 1, 0, 1, 1, 'Overmaster Grindgarr - Summoner''s Stone: Overmaster Grindgarr'),
(20887, 84653, 0, 1, 0, 1, 0, 1, 1, 'Deathforge Imp - Summoner''s Stone: Deathforge Imp'),
(20888, 139053, 0, 1, 0, 1, 0, 1, 1, 'Solus the Eternal - Summoner''s Stone: Solus the Eternal'),
(20929, 84664, 0, 1, 0, 1, 0, 1, 1, 'Wrath Lord - Summoner''s Stone: Wrath Lord'),
(20930, 84665, 0, 1, 0, 1, 0, 1, 1, 'Hatecryer - Summoner''s Stone: Hatecryer'),
(20931, 80636, 0, 1, 0, 1, 0, 1, 1, 'Tyrantus - Beastmaster''s Whistle: Tyrantus'),
(20932, 80637, 0, 1, 0, 1, 0, 1, 1, 'Nuramoc - Beastmaster''s Whistle: Nuramoc'),
(20983, 601236, 0, 1, 0, 1, 0, 1, 1, 'Mutated Farahlon Lasher - Elemental Lodestone: Mutated Farahlon Lasher'),
(20998, 80638, 0, 1, 0, 1, 0, 1, 1, 'Ridgespine Horror - Beastmaster''s Whistle: Ridgespine Horror'),
(21004, 1180479, 0, 1, 0, 1, 0, 1, 1, 'Lesser Nether Drake - Draconic Warhorn: Lesser Nether Drake'),
(21021, 84666, 0, 1, 0, 1, 0, 1, 1, 'Scorch Imp - Summoner''s Stone: Scorch Imp'),
(21022, 80639, 0, 1, 0, 1, 0, 1, 1, 'Grovestalker Lynx - Beastmaster''s Whistle: Grovestalker Lynx'),
(21032, 1180480, 0, 1, 0, 1, 0, 1, 1, 'Dreadwing - Draconic Warhorn: Dreadwing'),
(21033, 80640, 0, 1, 0, 1, 0, 1, 1, 'Bladewing Bloodletter - Beastmaster''s Whistle: Bladewing Bloodletter'),
(21042, 80641, 0, 1, 0, 1, 0, 1, 1, 'Dire Raven - Beastmaster''s Whistle: Dire Raven'),
(21059, 600875, 0, 1, 0, 1, 0, 1, 1, 'Enraged Water Spirit - Elemental Lodestone: Enraged Water Spirit'),
(21061, 600876, 0, 1, 0, 1, 0, 1, 1, 'Enraged Fire Spirit - Elemental Lodestone: Enraged Fire Spirit'),
(21102, 80642, 0, 1, 0, 1, 0, 1, 1, 'Uvuros - Beastmaster''s Whistle: Uvuros'),
(21108, 80643, 0, 1, 0, 1, 0, 1, 1, 'Spawn of Uvuros - Beastmaster''s Whistle: Spawn of Uvuros'),
(21123, 80644, 0, 1, 0, 1, 0, 1, 1, 'Felsworn Scalewing - Beastmaster''s Whistle: Felsworn Scalewing'),
(21124, 80645, 0, 1, 0, 1, 0, 1, 1, 'Felsworn Daggermaw - Beastmaster''s Whistle: Felsworn Daggermaw'),
(21166, 84667, 0, 1, 0, 1, 0, 1, 1, 'Illidari Dreadlord - Summoner''s Stone: Illidari Dreadlord'),
(21216, 600878, 0, 1, 0, 1, 0, 1, 1, 'Hydross the Unstable - Elemental Lodestone: Hydross the Unstable'),
(21287, 139354, 0, 1, 0, 1, 0, 1, 1, 'Warbringer Razuun - Summoner''s Stone: Warbringer Razuun'),
(21314, 84754, 0, 1, 0, 1, 0, 1, 1, 'Terrormaster - Summoner''s Stone: Terrormaster'),
(21324, 80647, 0, 1, 0, 1, 0, 1, 1, 'Spirit Raven - Beastmaster''s Whistle: Spirit Raven'),
(21337, 84755, 0, 1, 0, 1, 0, 1, 1, 'Illidari Shadowstalker - Summoner''s Stone: Illidari Shadowstalker'),
(21387, 1180502, 0, 1, 0, 1, 0, 1, 1, 'Wyrmcult Blackwhelp - Draconic Warhorn: Wyrmcult Blackwhelp'),
(21389, 1180504, 0, 1, 0, 1, 0, 1, 1, 'Maxnar the Ashmaw - Draconic Warhorn: Maxnar the Ashmaw'),
(21492, 1180508, 0, 1, 0, 1, 0, 1, 1, 'Wyrmcult Blessed - Draconic Warhorn: Wyrmcult Blessed'),
(21499, 84756, 0, 1, 0, 1, 0, 1, 1, 'Overseer Ripsaw - Summoner''s Stone: Overseer Ripsaw'),
(21500, 84760, 0, 1, 0, 1, 0, 1, 1, 'Morgroron - Summoner''s Stone: Morgroron'),
(21501, 84761, 0, 1, 0, 1, 0, 1, 1, 'Makazradon - Summoner''s Stone: Makazradon'),
(21506, 84768, 0, 1, 0, 1, 0, 1, 1, 'Azaloth - Summoner''s Stone: Azaloth'),
(21515, 80648, 0, 1, 0, 1, 0, 1, 1, 'Trachela - Beastmaster''s Whistle: Trachela'),
(21516, 85152, 0, 1, 0, 1, 0, 1, 1, 'Death''s Watch - Summoner''s Stone: Death''s Watch'),
(21520, 85154, 0, 1, 0, 1, 0, 1, 1, 'Illidari Jailor - Summoner''s Stone: Illidari Jailor'),
(21648, 1180516, 0, 1, 0, 1, 0, 1, 1, 'Mature Netherwing Drake - Draconic Warhorn: Mature Netherwing Drake'),
(21656, 85155, 0, 1, 0, 1, 0, 1, 1, 'Illidari Satyr - Summoner''s Stone: Illidari Satyr'),
(21721, 1180520, 0, 1, 0, 1, 0, 1, 1, 'Enslaved Netherwing Whelp - Draconic Warhorn: Enslaved Netherwing Whelp');
DELETE FROM `creature_loot_template` WHERE (`Entry`=21722 AND `Item`=1180521) OR
  (`Entry`=21723 AND `Item`=80649) OR
  (`Entry`=21728 AND `Item`=600888) OR
  (`Entry`=21730 AND `Item`=600889) OR
  (`Entry`=21808 AND `Item`=85156) OR
  (`Entry`=21817 AND `Item`=1180525) OR
  (`Entry`=21820 AND `Item`=1180527) OR
  (`Entry`=21827 AND `Item`=85157) OR
  (`Entry`=21839 AND `Item`=80650) OR
  (`Entry`=21863 AND `Item`=601091) OR
  (`Entry`=21864 AND `Item`=80651) OR
  (`Entry`=21879 AND `Item`=80652) OR
  (`Entry`=21901 AND `Item`=80654) OR
  (`Entry`=21923 AND `Item`=85195) OR
  (`Entry`=21928 AND `Item`=85197) OR
  (`Entry`=21941 AND `Item`=89207) OR
  (`Entry`=21956 AND `Item`=80656) OR
  (`Entry`=21963 AND `Item`=85201) OR
  (`Entry`=22044 AND `Item`=80657) OR
  (`Entry`=22045 AND `Item`=89208) OR
  (`Entry`=22052 AND `Item`=80658) OR
  (`Entry`=22072 AND `Item`=1180540) OR
  (`Entry`=22095 AND `Item`=601866) OR
  (`Entry`=22100 AND `Item`=80659) OR
  (`Entry`=22123 AND `Item`=80660) OR
  (`Entry`=22132 AND `Item`=80661) OR
  (`Entry`=22181 AND `Item`=80662) OR
  (`Entry`=22195 AND `Item`=85202) OR
  (`Entry`=22204 AND `Item`=85207) OR
  (`Entry`=22253 AND `Item`=1180549) OR
  (`Entry`=22255 AND `Item`=80663) OR
  (`Entry`=22265 AND `Item`=80664) OR
  (`Entry`=22281 AND `Item`=85209) OR
  (`Entry`=22304 AND `Item`=85243) OR
  (`Entry`=22309 AND `Item`=600899) OR
  (`Entry`=22313 AND `Item`=1777001) OR
  (`Entry`=22323 AND `Item`=600900) OR
  (`Entry`=22357 AND `Item`=139429) OR
  (`Entry`=22807 AND `Item`=80665) OR
  (`Entry`=22825 AND `Item`=85246) OR
  (`Entry`=22827 AND `Item`=85247) OR
  (`Entry`=22828 AND `Item`=85257) OR
  (`Entry`=22853 AND `Item`=85258) OR
  (`Entry`=22855 AND `Item`=85259) OR
  (`Entry`=22869 AND `Item`=85260) OR
  (`Entry`=22878 AND `Item`=600908) OR
  (`Entry`=22953 AND `Item`=89210) OR
  (`Entry`=22954 AND `Item`=85503) OR
  (`Entry`=22957 AND `Item`=85511) OR
  (`Entry`=22962 AND `Item`=85564) OR
  (`Entry`=23051 AND `Item`=80667) OR
  (`Entry`=23061 AND `Item`=1180560) OR
  (`Entry`=23163 AND `Item`=80668) OR
  (`Entry`=23219 AND `Item`=80669) OR
  (`Entry`=23281 AND `Item`=1180569) OR
  (`Entry`=23282 AND `Item`=1180570) OR
  (`Entry`=23326 AND `Item`=80671) OR
  (`Entry`=23339 AND `Item`=85579) OR
  (`Entry`=23353 AND `Item`=85586) OR
  (`Entry`=23355 AND `Item`=85637) OR
  (`Entry`=23427 AND `Item`=139454) OR
  (`Entry`=23501 AND `Item`=80672) OR
  (`Entry`=23554 AND `Item`=89211) OR
  (`Entry`=23555 AND `Item`=89212) OR
  (`Entry`=23584 AND `Item`=80673) OR
  (`Entry`=23643 AND `Item`=89213) OR
  (`Entry`=23644 AND `Item`=89214) OR
  (`Entry`=23645 AND `Item`=89215) OR
  (`Entry`=23687 AND `Item`=1180596) OR
  (`Entry`=23693 AND `Item`=80674) OR
  (`Entry`=23873 AND `Item`=80675) OR
  (`Entry`=23929 AND `Item`=80676) OR
  (`Entry`=23945 AND `Item`=80680) OR
  (`Entry`=23958 AND `Item`=80681) OR
  (`Entry`=23959 AND `Item`=80682) OR
  (`Entry`=23992 AND `Item`=89217) OR
  (`Entry`=24013 AND `Item`=89218) OR
  (`Entry`=24026 AND `Item`=80683) OR
  (`Entry`=24043 AND `Item`=80684) OR
  (`Entry`=24047 AND `Item`=80805) OR
  (`Entry`=24064 AND `Item`=80813) OR
  (`Entry`=24073 AND `Item`=89219) OR
  (`Entry`=24076 AND `Item`=80814) OR
  (`Entry`=24084 AND `Item`=89220) OR
  (`Entry`=24128 AND `Item`=80815) OR
  (`Entry`=24138 AND `Item`=80805) OR
  (`Entry`=24217 AND `Item`=80673) OR
  (`Entry`=24262 AND `Item`=89231) OR
  (`Entry`=24440 AND `Item`=89281) OR
  (`Entry`=24475 AND `Item`=80819) OR
  (`Entry`=24478 AND `Item`=80820) OR
  (`Entry`=24485 AND `Item`=89283) OR
  (`Entry`=24516 AND `Item`=80821) OR
  (`Entry`=24517 AND `Item`=80823) OR
  (`Entry`=24530 AND `Item`=80825) OR
  (`Entry`=24546 AND `Item`=89284) OR
  (`Entry`=24547 AND `Item`=80826) OR
  (`Entry`=24633 AND `Item`=80833) OR
  (`Entry`=24673 AND `Item`=80834) OR
  (`Entry`=24677 AND `Item`=80835) OR
  (`Entry`=24744 AND `Item`=600921) OR
  (`Entry`=24747 AND `Item`=80836) OR
  (`Entry`=24787 AND `Item`=80837) OR
  (`Entry`=24789 AND `Item`=89354) OR
  (`Entry`=24871 AND `Item`=89355) OR
  (`Entry`=24872 AND `Item`=89356) OR
  (`Entry`=24882 AND `Item`=612859) OR
  (`Entry`=24919 AND `Item`=85702) OR
  (`Entry`=24922 AND `Item`=80838) OR
  (`Entry`=25227 AND `Item`=89357) OR
  (`Entry`=25228 AND `Item`=89358) OR
  (`Entry`=25294 AND `Item`=89359) OR
  (`Entry`=25315 AND `Item`=139581) OR
  (`Entry`=25383 AND `Item`=89361) OR
  (`Entry`=25386 AND `Item`=89369) OR
  (`Entry`=25387 AND `Item`=89370) OR
  (`Entry`=25393 AND `Item`=89371) OR
  (`Entry`=25396 AND `Item`=89372) OR
  (`Entry`=25448 AND `Item`=1180641) OR
  (`Entry`=25454 AND `Item`=80843) OR
  (`Entry`=25464 AND `Item`=80844) OR
  (`Entry`=25481 AND `Item`=80845) OR
  (`Entry`=25482 AND `Item`=80846) OR
  (`Entry`=25487 AND `Item`=80847) OR
  (`Entry`=25488 AND `Item`=80848) OR
  (`Entry`=25489 AND `Item`=80849) OR
  (`Entry`=25498 AND `Item`=80850) OR
  (`Entry`=25585 AND `Item`=1180642) OR
  (`Entry`=25599 AND `Item`=85714) OR
  (`Entry`=25600 AND `Item`=89436) OR
  (`Entry`=25611 AND `Item`=89547) OR
  (`Entry`=25650 AND `Item`=89604) OR
  (`Entry`=25655 AND `Item`=89615) OR
  (`Entry`=25660 AND `Item`=89616) OR
  (`Entry`=25675 AND `Item`=80851) OR
  (`Entry`=25684 AND `Item`=89617) OR
  (`Entry`=25711 AND `Item`=1180645) OR
  (`Entry`=25712 AND `Item`=1180646) OR
  (`Entry`=25713 AND `Item`=1180647) OR
  (`Entry`=25716 AND `Item`=1180648) OR
  (`Entry`=25717 AND `Item`=1180649) OR
  (`Entry`=25721 AND `Item`=1180650) OR
  (`Entry`=25722 AND `Item`=1180651) OR
  (`Entry`=25728 AND `Item`=1180653) OR
  (`Entry`=25748 AND `Item`=80904) OR
  (`Entry`=25774 AND `Item`=80905) OR
  (`Entry`=25791 AND `Item`=80940) OR
  (`Entry`=25817 AND `Item`=80941) OR
  (`Entry`=26073 AND `Item`=89618) OR
  (`Entry`=26076 AND `Item`=89619) OR
  (`Entry`=26126 AND `Item`=89620) OR
  (`Entry`=26174 AND `Item`=80942) OR
  (`Entry`=26202 AND `Item`=89621) OR
  (`Entry`=26276 AND `Item`=1180663) OR
  (`Entry`=26293 AND `Item`=80943) OR
  (`Entry`=26322 AND `Item`=1180669) OR
  (`Entry`=26349 AND `Item`=1180670) OR
  (`Entry`=26358 AND `Item`=81056) OR
  (`Entry`=26359 AND `Item`=81057) OR
  (`Entry`=26360 AND `Item`=81117) OR
  (`Entry`=26369 AND `Item`=81118) OR
  (`Entry`=26446 AND `Item`=81119) OR
  (`Entry`=26455 AND `Item`=89625) OR
  (`Entry`=26458 AND `Item`=89626) OR
  (`Entry`=26461 AND `Item`=89627) OR
  (`Entry`=26482 AND `Item`=81120) OR
  (`Entry`=26483 AND `Item`=81121) OR
  (`Entry`=26492 AND `Item`=89629) OR
  (`Entry`=26521 AND `Item`=81144) OR
  (`Entry`=26529 AND `Item`=89637) OR
  (`Entry`=26536 AND `Item`=89638) OR
  (`Entry`=26555 AND `Item`=89771) OR
  (`Entry`=26592 AND `Item`=81173) OR
  (`Entry`=26605 AND `Item`=89772) OR
  (`Entry`=26621 AND `Item`=89773) OR
  (`Entry`=26622 AND `Item`=81226) OR
  (`Entry`=26623 AND `Item`=89782) OR
  (`Entry`=26624 AND `Item`=89838) OR
  (`Entry`=26625 AND `Item`=81227) OR
  (`Entry`=26628 AND `Item`=81228) OR
  (`Entry`=26630 AND `Item`=89840) OR
  (`Entry`=26641 AND `Item`=81278) OR
  (`Entry`=26643 AND `Item`=81322) OR
  (`Entry`=26644 AND `Item`=81323) OR
  (`Entry`=26672 AND `Item`=81363) OR
  (`Entry`=26706 AND `Item`=81374) OR
  (`Entry`=26723 AND `Item`=1180659) OR
  (`Entry`=26806 AND `Item`=81377) OR
  (`Entry`=26838 AND `Item`=81378) OR
  (`Entry`=26948 AND `Item`=89845) OR
  (`Entry`=26966 AND `Item`=89846) OR
  (`Entry`=27131 AND `Item`=81379) OR
  (`Entry`=27244 AND `Item`=81380) OR
  (`Entry`=27249 AND `Item`=81381) OR
  (`Entry`=27272 AND `Item`=89850) OR
  (`Entry`=27283 AND `Item`=89851) OR
  (`Entry`=27284 AND `Item`=89852) OR
  (`Entry`=27286 AND `Item`=89853) OR
  (`Entry`=27287 AND `Item`=89854) OR
  (`Entry`=27294 AND `Item`=81382) OR
  (`Entry`=27329 AND `Item`=81383) OR
  (`Entry`=27360 AND `Item`=89855) OR
  (`Entry`=27362 AND `Item`=89859) OR
  (`Entry`=27408 AND `Item`=81386) OR
  (`Entry`=27410 AND `Item`=89860) OR
  (`Entry`=27421 AND `Item`=81387) OR
  (`Entry`=27447 AND `Item`=1180690) OR
  (`Entry`=27483 AND `Item`=81392) OR
  (`Entry`=27551 AND `Item`=89866) OR
  (`Entry`=27552 AND `Item`=89867) OR
  (`Entry`=27578 AND `Item`=81395) OR
  (`Entry`=27633 AND `Item`=1180695) OR
  (`Entry`=27635 AND `Item`=1180696) OR
  (`Entry`=27636 AND `Item`=1180697) OR
  (`Entry`=27654 AND `Item`=1180700) OR
  (`Entry`=27680 AND `Item`=89878) OR
  (`Entry`=27729 AND `Item`=89879) OR
  (`Entry`=27736 AND `Item`=89890) OR
  (`Entry`=27797 AND `Item`=89891) OR
  (`Entry`=27808 AND `Item`=89892) OR
  (`Entry`=27823 AND `Item`=89904) OR
  (`Entry`=27824 AND `Item`=89905) OR
  (`Entry`=27835 AND `Item`=89913) OR
  (`Entry`=27836 AND `Item`=89914) OR
  (`Entry`=27941 AND `Item`=89995) OR
  (`Entry`=28001 AND `Item`=81398) OR
  (`Entry`=28002 AND `Item`=81399) OR
  (`Entry`=28004 AND `Item`=81416) OR
  (`Entry`=28009 AND `Item`=81419) OR
  (`Entry`=28011 AND `Item`=81420) OR
  (`Entry`=28022 AND `Item`=89998) OR
  (`Entry`=28069 AND `Item`=601700) OR
  (`Entry`=28085 AND `Item`=81421) OR
  (`Entry`=28086 AND `Item`=81422) OR
  (`Entry`=28087 AND `Item`=81423) OR
  (`Entry`=28096 AND `Item`=81424) OR
  (`Entry`=28097 AND `Item`=81425) OR
  (`Entry`=28098 AND `Item`=81426) OR
  (`Entry`=28101 AND `Item`=101049) OR
  (`Entry`=28108 AND `Item`=101050) OR
  (`Entry`=28158 AND `Item`=101051) OR
  (`Entry`=28199 AND `Item`=101053) OR
  (`Entry`=28201 AND `Item`=101054) OR
  (`Entry`=28220 AND `Item`=101055) OR
  (`Entry`=28221 AND `Item`=81428) OR
  (`Entry`=28233 AND `Item`=81429) OR
  (`Entry`=28246 AND `Item`=101056) OR
  (`Entry`=28249 AND `Item`=101057) OR
  (`Entry`=28268 AND `Item`=101058) OR
  (`Entry`=28297 AND `Item`=81431) OR
  (`Entry`=28358 AND `Item`=81432) OR
  (`Entry`=28404 AND `Item`=81433) OR
  (`Entry`=28477 AND `Item`=81434) OR
  (`Entry`=28564 AND `Item`=101059) OR
  (`Entry`=28565 AND `Item`=101060) OR
  (`Entry`=28603 AND `Item`=101061) OR
  (`Entry`=28747 AND `Item`=101064) OR
  (`Entry`=28748 AND `Item`=101065) OR
  (`Entry`=28766 AND `Item`=81435) OR
  (`Entry`=28793 AND `Item`=101068) OR
  (`Entry`=28840 AND `Item`=601705) OR
  (`Entry`=28843 AND `Item`=101069) OR
  (`Entry`=28860 AND `Item`=1180732) OR
  (`Entry`=28931 AND `Item`=101073) OR
  (`Entry`=29044 AND `Item`=81436) OR
  (`Entry`=29120 AND `Item`=101075) OR
  (`Entry`=29123 AND `Item`=101076) OR
  (`Entry`=29133 AND `Item`=101077) OR
  (`Entry`=29316 AND `Item`=85715) OR
  (`Entry`=29319 AND `Item`=81437) OR
  (`Entry`=29327 AND `Item`=81438) OR
  (`Entry`=29334 AND `Item`=81439) OR
  (`Entry`=29358 AND `Item`=81558) OR
  (`Entry`=29390 AND `Item`=81893) OR
  (`Entry`=29411 AND `Item`=81894) OR
  (`Entry`=29412 AND `Item`=81895) OR
  (`Entry`=29452 AND `Item`=81896) OR
  (`Entry`=29461 AND `Item`=81897) OR
  (`Entry`=29469 AND `Item`=81898) OR
  (`Entry`=29562 AND `Item`=81899) OR
  (`Entry`=29605 AND `Item`=81900) OR
  (`Entry`=29646 AND `Item`=101078) OR
  (`Entry`=29656 AND `Item`=101079) OR
  (`Entry`=29693 AND `Item`=81902) OR
  (`Entry`=29698 AND `Item`=81903) OR
  (`Entry`=29719 AND `Item`=101080) OR
  (`Entry`=29722 AND `Item`=101081) OR
  (`Entry`=29735 AND `Item`=81904) OR
  (`Entry`=29854 AND `Item`=81905) OR
  (`Entry`=29994 AND `Item`=81907) OR
  (`Entry`=30148 AND `Item`=81908) OR
  (`Entry`=30164 AND `Item`=81909) OR
  (`Entry`=30202 AND `Item`=101083) OR
  (`Entry`=30206 AND `Item`=81910) OR
  (`Entry`=30283 AND `Item`=101084) OR
  (`Entry`=30285 AND `Item`=101085) OR
  (`Entry`=30286 AND `Item`=101086) OR
  (`Entry`=30294 AND `Item`=81912) OR
  (`Entry`=30422 AND `Item`=81913) OR
  (`Entry`=30430 AND `Item`=81914);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(21722, 1180521, 0, 1, 0, 1, 0, 1, 1, 'Enslaved Netherwing Drake - Draconic Warhorn: Enslaved Netherwing Drake'),
(21723, 80649, 0, 1, 0, 1, 0, 1, 1, 'Blackwind Sabercat - Beastmaster''s Whistle: Blackwind Sabercat'),
(21728, 600888, 0, 1, 0, 1, 0, 1, 1, 'Skettis Surger - Elemental Lodestone: Skettis Surger'),
(21730, 600889, 0, 1, 0, 1, 0, 1, 1, 'Alluvion - Elemental Lodestone: Alluvion'),
(21808, 85156, 0, 1, 0, 1, 0, 1, 1, 'Illidari Overseer - Summoner''s Stone: Illidari Overseer'),
(21817, 1180525, 0, 1, 0, 1, 0, 1, 1, 'Adolescent Nether Drake - Draconic Warhorn: Adolescent Nether Drake'),
(21820, 1180527, 0, 1, 0, 1, 0, 1, 1, 'Mature Nether Drake - Draconic Warhorn: Mature Nether Drake'),
(21827, 85157, 0, 1, 0, 1, 0, 1, 1, 'Zandras - Summoner''s Stone: Zandras'),
(21839, 80650, 0, 1, 0, 1, 0, 1, 1, 'Mature Silkwing - Beastmaster''s Whistle: Mature Silkwing'),
(21863, 601091, 0, 1, 0, 1, 0, 1, 1, 'Serpentshrine Lurker - Elemental Lodestone: Serpentshrine Lurker'),
(21864, 80651, 0, 1, 0, 1, 0, 1, 1, 'Scorchshell Pincer - Beastmaster''s Whistle: Scorchshell Pincer'),
(21879, 80652, 0, 1, 0, 1, 0, 1, 1, 'Vilewing Chimaera - Beastmaster''s Whistle: Vilewing Chimaera'),
(21901, 80654, 0, 1, 0, 1, 0, 1, 1, 'Netherskate - Beastmaster''s Whistle: Netherskate'),
(21923, 85195, 0, 1, 0, 1, 0, 1, 1, 'Terrorguard Protector - Summoner''s Stone: Terrorguard Protector'),
(21928, 85197, 0, 1, 0, 1, 0, 1, 1, 'Lothros - Summoner''s Stone: Lothros'),
(21941, 89207, 0, 0.1, 0, 1, 0, 1, 1, 'Accursed Apparition - Blood Soaked Vellum: Accursed Apparition'),
(21956, 80656, 0, 1, 0, 1, 0, 1, 1, 'Rema - Beastmaster''s Whistle: Rema'),
(21963, 85201, 0, 1, 0, 1, 0, 1, 1, 'Enslaved Doomguard - Summoner''s Stone: Enslaved Doomguard'),
(22044, 80657, 0, 1, 0, 1, 0, 1, 1, 'Cavern Crawler - Beastmaster''s Whistle: Cavern Crawler'),
(22045, 89208, 0, 0.1, 0, 1, 0, 1, 1, 'Vengeful Husk - Blood Soaked Vellum: Vengeful Husk'),
(22052, 80658, 0, 1, 0, 1, 0, 1, 1, 'Daggermaw Blackhide - Beastmaster''s Whistle: Daggermaw Blackhide'),
(22072, 1180540, 0, 1, 0, 1, 0, 1, 1, 'Shadowsworn Drakonid - Draconic Warhorn: Shadowsworn Drakonid'),
(22095, 601866, 0, 1, 0, 1, 0, 1, 1, 'Infested Root-Walker - Elemental Lodestone: Infested Root-Walker'),
(22100, 80659, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Bonecrawler - Beastmaster''s Whistle: Scorpid Bonecrawler'),
(22123, 80660, 0, 1, 0, 1, 0, 1, 1, 'Rip-Blade Ravager - Beastmaster''s Whistle: Rip-Blade Ravager'),
(22132, 80661, 0, 1, 0, 1, 0, 1, 1, 'Mature Cavern Crawler - Beastmaster''s Whistle: Mature Cavern Crawler'),
(22181, 80662, 0, 1, 0, 1, 0, 1, 1, 'Aether Ray - Beastmaster''s Whistle: Aether Ray'),
(22195, 85202, 0, 1, 0, 1, 0, 1, 1, 'Wrath Speaker - Summoner''s Stone: Wrath Speaker'),
(22204, 85207, 0, 1, 0, 1, 0, 1, 1, 'Fear Fiend - Summoner''s Stone: Fear Fiend'),
(22253, 1180549, 0, 1, 0, 1, 0, 1, 1, 'Dragonmaw Ascendant - Draconic Warhorn: Dragonmaw Ascendant'),
(22255, 80663, 0, 1, 0, 1, 0, 1, 1, 'Daggertail Lizard - Beastmaster''s Whistle: Daggertail Lizard'),
(22265, 80664, 0, 1, 0, 1, 0, 1, 1, 'Shadowwing Owl - Beastmaster''s Whistle: Shadowwing Owl'),
(22281, 85209, 0, 1, 0, 1, 0, 1, 1, 'Galvanoth - Summoner''s Stone: Galvanoth'),
(22304, 85243, 0, 1, 0, 1, 0, 1, 1, 'Mo''arg Extractor - Summoner''s Stone: Mo''arg Extractor'),
(22309, 600899, 0, 1, 0, 1, 0, 1, 1, 'Crashing Wave-Spirit - Elemental Lodestone: Crashing Wave-Spirit'),
(22313, 1777001, 0, 1, 0, 1, 0, 1, 1, 'Rumbling Earth-Heart - Elemental Lodestone: Rumbling Earth-Heart'),
(22323, 600900, 0, 1, 0, 1, 0, 1, 1, 'Incandescent Fel Spark - Elemental Lodestone: Incandescent Fel Spark'),
(22357, 139429, 0, 1, 0, 1, 0, 1, 1, 'Reth''hedron the Subduer - Summoner''s Stone: Reth''hedron the Subduer'),
(22807, 80665, 0, 1, 0, 1, 0, 1, 1, 'Lost Torranche - Beastmaster''s Whistle: Lost Torranche'),
(22825, 85246, 0, 1, 0, 1, 0, 1, 1, 'Matron Li-sahar - Summoner''s Stone: Matron Li-sahar'),
(22827, 85247, 0, 1, 0, 1, 0, 1, 1, 'Gorgolon the All-seeing - Summoner''s Stone: Gorgolon the All-seeing'),
(22828, 85257, 0, 1, 0, 1, 0, 1, 1, 'Trelopades - Summoner''s Stone: Trelopades'),
(22853, 85258, 0, 1, 0, 1, 0, 1, 1, 'Illidari Defiler - Summoner''s Stone: Illidari Defiler'),
(22855, 85259, 0, 1, 0, 1, 0, 1, 1, 'Illidari Nightlord - Summoner''s Stone: Illidari Nightlord'),
(22869, 85260, 0, 1, 0, 1, 0, 1, 1, 'Illidari Boneslicer - Summoner''s Stone: Illidari Boneslicer'),
(22878, 600908, 0, 1, 0, 1, 0, 1, 1, 'Aqueous Lord - Elemental Lodestone: Aqueous Lord'),
(22953, 89210, 0, 0.1, 0, 1, 0, 1, 1, 'Wrathbone Flayer - Blood Soaked Vellum: Wrathbone Flayer'),
(22954, 85503, 0, 1, 0, 1, 0, 1, 1, 'Illidari Fearbringer - Summoner''s Stone: Illidari Fearbringer'),
(22957, 85511, 0, 1, 0, 1, 0, 1, 1, 'Priestess of Dementia - Summoner''s Stone: Priestess of Dementia'),
(22962, 85564, 0, 1, 0, 1, 0, 1, 1, 'Priestess of Delight - Summoner''s Stone: Priestess of Delight'),
(23051, 80667, 0, 1, 0, 1, 0, 1, 1, 'Monstrous Kaliri - Beastmaster''s Whistle: Monstrous Kaliri'),
(23061, 1180560, 0, 1, 0, 1, 0, 1, 1, 'Rivendark - Draconic Warhorn: Rivendark'),
(23163, 80668, 0, 1, 0, 1, 0, 1, 1, 'Gezzarak the Huntress - Beastmaster''s Whistle: Gezzarak the Huntress'),
(23219, 80669, 0, 1, 0, 1, 0, 1, 1, 'Blackwind Warp Chaser - Beastmaster''s Whistle: Blackwind Warp Chaser'),
(23281, 1180569, 0, 1, 0, 1, 0, 1, 1, 'Insidion - Draconic Warhorn: Insidion'),
(23282, 1180570, 0, 1, 0, 1, 0, 1, 1, 'Obsidia - Draconic Warhorn: Obsidia'),
(23326, 80671, 0, 1, 0, 1, 0, 1, 1, 'Nethermine Ravager - Beastmaster''s Whistle: Nethermine Ravager'),
(23339, 85579, 0, 1, 0, 1, 0, 1, 1, 'Illidari Heartseeker - Summoner''s Stone: Illidari Heartseeker'),
(23353, 85586, 0, 1, 0, 1, 0, 1, 1, 'Braxxus - Summoner''s Stone: Braxxus'),
(23355, 85637, 0, 1, 0, 1, 0, 1, 1, 'Zarcsin - Summoner''s Stone: Zarcsin'),
(23427, 139454, 0, 1, 0, 1, 0, 1, 1, 'Illidari Lord Balthas - Summoner''s Stone: Illidari Lord Balthas'),
(23501, 80672, 0, 1, 0, 1, 0, 1, 1, 'Netherwing Ray - Beastmaster''s Whistle: Netherwing Ray'),
(23554, 89211, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Spirit - Blood Soaked Vellum: Risen Spirit'),
(23555, 89212, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Husk - Blood Soaked Vellum: Risen Husk'),
(23584, 80673, 0, 1, 0, 1, 0, 1, 1, 'Amani Bear - Beastmaster''s Whistle: Amani Bear'),
(23643, 89213, 0, 0.1, 0, 1, 0, 1, 1, 'Unstable Mur''ghoul - Blood Soaked Vellum: Unstable Mur''ghoul'),
(23644, 89214, 0, 0.1, 0, 1, 0, 1, 1, 'Mur''ghoul Flesheater - Blood Soaked Vellum: Mur''ghoul Flesheater'),
(23645, 89215, 0, 0.1, 0, 1, 0, 1, 1, 'Mur''ghoul Corrupter - Blood Soaked Vellum: Mur''ghoul Corrupter'),
(23687, 1180596, 0, 1, 0, 1, 0, 1, 1, 'Scorchscale Drake - Draconic Warhorn: Scorchscale Drake'),
(23693, 80674, 0, 1, 0, 1, 0, 1, 1, 'Duskwing Eagle - Beastmaster''s Whistle: Duskwing Eagle'),
(23873, 80675, 0, 1, 0, 1, 0, 1, 1, 'Goreclaw the Ravenous - Beastmaster''s Whistle: Goreclaw the Ravenous'),
(23929, 80676, 0, 1, 0, 1, 0, 1, 1, 'Giant Tidecrawler - Beastmaster''s Whistle: Giant Tidecrawler'),
(23945, 80680, 0, 1, 0, 1, 0, 1, 1, 'Fjord Crow - Beastmaster''s Whistle: Fjord Crow'),
(23958, 80681, 0, 1, 0, 1, 0, 1, 1, 'Riven Widow - Beastmaster''s Whistle: Riven Widow'),
(23959, 80682, 0, 1, 0, 1, 0, 1, 1, 'Darkclaw Bat - Beastmaster''s Whistle: Darkclaw Bat'),
(23992, 89217, 0, 0.1, 0, 1, 0, 1, 1, 'Putrid Wight - Blood Soaked Vellum: Putrid Wight'),
(24013, 89218, 0, 0.1, 0, 1, 0, 1, 1, 'Deathless Watcher - Blood Soaked Vellum: Deathless Watcher'),
(24026, 80683, 0, 1, 0, 1, 0, 1, 1, 'Fanggore Worg - Beastmaster''s Whistle: Fanggore Worg'),
(24043, 80684, 0, 1, 0, 1, 0, 1, 1, 'Amani Lynx - Beastmaster''s Whistle: Amani Lynx'),
(24047, 80805, 0, 1, 0, 1, 0, 1, 1, 'Amani Crocolisk - Beastmaster''s Whistle: Amani Crocolisk'),
(24064, 80813, 0, 1, 0, 1, 0, 1, 1, 'Amani Lynx Cub - Beastmaster''s Whistle: Amani Lynx Cub'),
(24073, 89219, 0, 0.1, 0, 1, 0, 1, 1, 'Fearsome Horror - Blood Soaked Vellum: Fearsome Horror'),
(24076, 80814, 0, 1, 0, 1, 0, 1, 1, 'Winterskorn Worg - Beastmaster''s Whistle: Winterskorn Worg'),
(24084, 89220, 0, 0.1, 0, 1, 0, 1, 1, 'Tunneling Ghoul - Blood Soaked Vellum: Tunneling Ghoul'),
(24128, 80815, 0, 1, 0, 1, 0, 1, 1, 'Wild Worg - Beastmaster''s Whistle: Wild Worg'),
(24138, 80805, 0, 1, 0, 1, 0, 1, 1, 'Tamed Amani Crocolisk - Beastmaster''s Whistle: Amani Crocolisk'),
(24217, 80673, 0, 1, 0, 1, 0, 1, 1, 'Amani Bear Mount - Beastmaster''s Whistle: Amani Bear'),
(24262, 89231, 0, 0.1, 0, 1, 0, 1, 1, 'Vrykul Soul - Blood Soaked Vellum: Vrykul Soul'),
(24440, 89281, 0, 0.1, 0, 1, 0, 1, 1, 'Gjalerbron Gargoyle - Blood Soaked Vellum: Gjalerbron Gargoyle'),
(24475, 80819, 0, 1, 0, 1, 0, 1, 1, 'Bloodthirsty Worg - Beastmaster''s Whistle: Bloodthirsty Worg'),
(24478, 80820, 0, 1, 0, 1, 0, 1, 1, 'Fjord Crawler - Beastmaster''s Whistle: Fjord Crawler'),
(24485, 89283, 0, 0.1, 0, 1, 0, 1, 1, 'Servitor Shade - Blood Soaked Vellum: Servitor Shade'),
(24516, 80821, 0, 1, 0, 1, 0, 1, 1, 'Bjomolf - Beastmaster''s Whistle: Bjomolf'),
(24517, 80823, 0, 1, 0, 1, 0, 1, 1, 'Varg - Beastmaster''s Whistle: Varg'),
(24530, 80825, 0, 1, 0, 1, 0, 1, 1, 'Amani Elder Lynx - Beastmaster''s Whistle: Amani Elder Lynx'),
(24546, 89284, 0, 0.1, 0, 1, 0, 1, 1, 'Rotgill - Blood Soaked Vellum: Rotgill'),
(24547, 80826, 0, 1, 0, 1, 0, 1, 1, 'Hozzer - Beastmaster''s Whistle: Hozzer'),
(24633, 80833, 0, 1, 0, 1, 0, 1, 1, 'Rabid Brown Bear - Beastmaster''s Whistle: Rabid Brown Bear'),
(24673, 80834, 0, 1, 0, 1, 0, 1, 1, 'Frostwing Chimaera - Beastmaster''s Whistle: Frostwing Chimaera'),
(24677, 80835, 0, 1, 0, 1, 0, 1, 1, 'Spearfang Worg - Beastmaster''s Whistle: Spearfang Worg'),
(24744, 600921, 0, 1, 0, 1, 0, 1, 1, 'Vexallus - Elemental Lodestone: Vexallus'),
(24747, 80836, 0, 1, 0, 1, 0, 1, 1, 'Fjord Hawk - Beastmaster''s Whistle: Fjord Hawk'),
(24787, 80837, 0, 1, 0, 1, 0, 1, 1, 'Fjord Hawk Matriarch - Beastmaster''s Whistle: Fjord Hawk Matriarch'),
(24789, 89354, 0, 0.1, 0, 1, 0, 1, 1, 'Forlorn Soul - Blood Soaked Vellum: Forlorn Soul'),
(24871, 89355, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Vrykul Ancestor - Blood Soaked Vellum: Risen Vrykul Ancestor'),
(24872, 89356, 0, 0.1, 0, 1, 0, 1, 1, 'Blood Shade - Blood Soaked Vellum: Blood Shade'),
(24882, 612859, 0, 1, 0, 1, 0, 1, 1, 'Brutallus - Summoner''s Stone: Brutallus'),
(24919, 85702, 0, 1, 0, 1, 0, 1, 1, 'Wrath Herald - Summoner''s Stone: Wrath Herald'),
(24922, 80838, 0, 1, 0, 1, 0, 1, 1, 'Razorthorn Ravager - Beastmaster''s Whistle: Razorthorn Ravager'),
(25227, 89357, 0, 0.1, 0, 1, 0, 1, 1, 'Crypt Crawler - Blood Soaked Vellum: Crypt Crawler'),
(25228, 89358, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Crypt Lord - Blood Soaked Vellum: Risen Crypt Lord'),
(25294, 89359, 0, 0.1, 0, 1, 0, 1, 1, 'Nerub''ar Web Lord - Blood Soaked Vellum: Nerub''ar Web Lord'),
(25315, 139581, 0, 1, 0, 1, 0, 1, 1, 'Kil''jaeden - Summoner''s Stone: Apolyon (Hand of the Deceiver)'),
(25383, 89361, 0, 0.1, 0, 1, 0, 1, 1, 'En''kilah Abomination - Blood Soaked Vellum: En''kilah Abomination'),
(25386, 89369, 0, 0.1, 0, 1, 0, 1, 1, 'En''kilah Crypt Fiend - Blood Soaked Vellum: En''kilah Crypt Fiend'),
(25387, 89370, 0, 0.1, 0, 1, 0, 1, 1, 'En''kilah Gargoyle - Blood Soaked Vellum: En''kilah Gargoyle'),
(25393, 89371, 0, 0.1, 0, 1, 0, 1, 1, 'En''kilah Ghoul - Blood Soaked Vellum: En''kilah Ghoul'),
(25396, 89372, 0, 0.1, 0, 1, 0, 1, 1, 'Naxxanar Skeletal Mage - Blood Soaked Vellum: Naxxanar Skeletal Mage'),
(25448, 1180641, 0, 1, 0, 1, 0, 1, 1, 'Curator Insivius - Draconic Warhorn: Curator Insivius'),
(25454, 80843, 0, 1, 0, 1, 0, 1, 1, 'Tundra Crawler - Beastmaster''s Whistle: Tundra Crawler'),
(25464, 80844, 0, 1, 0, 1, 0, 1, 1, 'Bloodspore Moth - Beastmaster''s Whistle: Bloodspore Moth'),
(25481, 80845, 0, 1, 0, 1, 0, 1, 1, 'Landing Crawler - Beastmaster''s Whistle: Landing Crawler'),
(25482, 80846, 0, 1, 0, 1, 0, 1, 1, 'Sand Turtle - Beastmaster''s Whistle: Sand Turtle'),
(25487, 80847, 0, 1, 0, 1, 0, 1, 1, 'Wooly Rhino Matriarch - Beastmaster''s Whistle: Wooly Rhino Matriarch'),
(25488, 80848, 0, 1, 0, 1, 0, 1, 1, 'Wooly Rhino Calf - Beastmaster''s Whistle: Wooly Rhino Calf'),
(25489, 80849, 0, 1, 0, 1, 0, 1, 1, 'Wooly Rhino Bull - Beastmaster''s Whistle: Wooly Rhino Bull'),
(25498, 80850, 0, 1, 0, 1, 0, 1, 1, 'Aspatha the Broodmother - Beastmaster''s Whistle: Aspatha the Broodmother'),
(25585, 1180642, 0, 1, 0, 1, 0, 1, 1, 'Beryl Mage Hunter - Draconic Warhorn: Beryl Mage Hunter'),
(25599, 85714, 0, 1, 0, 1, 0, 1, 1, 'Cataclysm Hound - Summoner''s Stone: Cataclysm Hound'),
(25600, 89436, 0, 0.1, 0, 1, 0, 1, 1, 'Unliving Swine - Blood Soaked Vellum: Unliving Swine'),
(25611, 89547, 0, 0.1, 0, 1, 0, 1, 1, 'Warsong Aberration - Blood Soaked Vellum: Warsong Aberration'),
(25650, 89604, 0, 0.1, 0, 1, 0, 1, 1, 'Plagued Scavenger - Blood Soaked Vellum: Plagued Scavenger'),
(25655, 89615, 0, 0.1, 0, 1, 0, 1, 1, 'Bane - Blood Soaked Vellum: Bane'),
(25660, 89616, 0, 0.1, 0, 1, 0, 1, 1, 'Festering Ghoul - Blood Soaked Vellum: Festering Ghoul'),
(25675, 80851, 0, 1, 0, 1, 0, 1, 1, 'Tundra Wolf - Beastmaster''s Whistle: Tundra Wolf'),
(25684, 89617, 0, 0.1, 0, 1, 0, 1, 1, 'Talramas Abomination - Blood Soaked Vellum: Talramas Abomination'),
(25711, 1180645, 0, 1, 0, 1, 0, 1, 1, 'Spirit of the North - Draconic Warhorn: Spirit of the North'),
(25712, 1180646, 0, 1, 0, 1, 0, 1, 1, 'Warbringer Goredrak - Draconic Warhorn: Warbringer Goredrak'),
(25713, 1180647, 0, 1, 0, 1, 0, 1, 1, 'Blue Drakonid Supplicant - Draconic Warhorn: Blue Drakonid Supplicant'),
(25716, 1180648, 0, 1, 0, 1, 0, 1, 1, 'General Cerulean - Draconic Warhorn: General Cerulean'),
(25717, 1180649, 0, 1, 0, 1, 0, 1, 1, 'Coldarra Scalesworn - Draconic Warhorn: Coldarra Scalesworn'),
(25721, 1180650, 0, 1, 0, 1, 0, 1, 1, 'Arcane Serpent - Draconic Warhorn: Arcane Serpent'),
(25722, 1180651, 0, 1, 0, 1, 0, 1, 1, 'Coldarra Spellweaver - Draconic Warhorn: Coldarra Spellweaver'),
(25728, 1180653, 0, 1, 0, 1, 0, 1, 1, 'Coldarra Wyrmkin - Draconic Warhorn: Coldarra Wyrmkin'),
(25748, 80904, 0, 1, 0, 1, 0, 1, 1, 'Oil-covered Hawk - Beastmaster''s Whistle: Oil-covered Hawk'),
(25774, 80905, 0, 1, 0, 1, 0, 1, 1, 'Rockfang - Beastmaster''s Whistle: Rockfang'),
(25791, 80940, 0, 1, 0, 1, 0, 1, 1, 'Oil-stained Wolf - Beastmaster''s Whistle: Oil-stained Wolf'),
(25817, 80941, 0, 1, 0, 1, 0, 1, 1, 'Oiled Fledgeling - Beastmaster''s Whistle: Oiled Fledgeling'),
(26073, 89618, 0, 0.1, 0, 1, 0, 1, 1, 'High Priest Talet-Kha - Blood Soaked Vellum: High Priest Talet-Kha'),
(26076, 89619, 0, 0.1, 0, 1, 0, 1, 1, 'High Priest Naferset - Blood Soaked Vellum: High Priest Naferset'),
(26126, 89620, 0, 0.1, 0, 1, 0, 1, 1, 'Bone Warrior - Blood Soaked Vellum: Bone Warrior'),
(26174, 80942, 0, 1, 0, 1, 0, 1, 1, 'Carrion Condor - Beastmaster''s Whistle: Carrion Condor'),
(26202, 89621, 0, 0.1, 0, 1, 0, 1, 1, 'Ziggurat Defender - Blood Soaked Vellum: Ziggurat Defender'),
(26276, 1180663, 0, 1, 0, 1, 0, 1, 1, 'Nexus Guardian - Draconic Warhorn: Nexus Guardian'),
(26293, 80943, 0, 1, 0, 1, 0, 1, 1, 'Hulking Jormungar - Beastmaster''s Whistle: Hulking Jormungar'),
(26322, 1180669, 0, 1, 0, 1, 0, 1, 1, 'Arcane Wyrm - Draconic Warhorn: Arcane Wyrm'),
(26349, 1180670, 0, 1, 0, 1, 0, 1, 1, 'Goramosh - Draconic Warhorn: Goramosh'),
(26358, 81056, 0, 1, 0, 1, 0, 1, 1, 'Ice Heart Jormungar Feeder - Beastmaster''s Whistle: Ice Heart Jormungar Feeder'),
(26359, 81057, 0, 1, 0, 1, 0, 1, 1, 'Ice Heart Jormungar Spawn - Beastmaster''s Whistle: Ice Heart Jormungar Spawn'),
(26360, 81117, 0, 1, 0, 1, 0, 1, 1, 'Rattlebore - Beastmaster''s Whistle: Rattlebore'),
(26369, 81118, 0, 1, 0, 1, 0, 1, 1, 'Imperial Eagle - Beastmaster''s Whistle: Imperial Eagle'),
(26446, 81119, 0, 1, 0, 1, 0, 1, 1, 'Ice Serpent - Beastmaster''s Whistle: Ice Serpent'),
(26455, 89625, 0, 0.1, 0, 1, 0, 1, 1, 'Moonrest Highborne - Blood Soaked Vellum: Moonrest Highborne'),
(26458, 89626, 0, 0.1, 0, 1, 0, 1, 1, 'Drakkari Plaguebringer - Blood Soaked Vellum: Drakkari Plaguebringer'),
(26461, 89627, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Corpserender - Blood Soaked Vellum: Scourge Corpserender'),
(26482, 81120, 0, 1, 0, 1, 0, 1, 1, 'Arctic Grizzly - Beastmaster''s Whistle: Arctic Grizzly'),
(26483, 81121, 0, 1, 0, 1, 0, 1, 1, 'Dragonbone Condor - Beastmaster''s Whistle: Dragonbone Condor'),
(26492, 89629, 0, 0.1, 0, 1, 0, 1, 1, 'Wastes Digger - Blood Soaked Vellum: Wastes Digger'),
(26521, 81144, 0, 1, 0, 1, 0, 1, 1, 'Kili''ua - Beastmaster''s Whistle: Kili''ua'),
(26529, 89637, 0, 0.1, 0, 1, 0, 1, 1, 'Meathook - Blood Soaked Vellum: Meathook'),
(26536, 89638, 0, 0.1, 0, 1, 0, 1, 1, 'Mindless Servant - Blood Soaked Vellum: Mindless Servant'),
(26555, 89771, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Hulk - Blood Soaked Vellum: Scourge Hulk'),
(26592, 81173, 0, 1, 0, 1, 0, 1, 1, 'Graymist Hunter - Beastmaster''s Whistle: Graymist Hunter'),
(26605, 89772, 0, 0.1, 0, 1, 0, 1, 1, 'Anub''ar Underlord - Blood Soaked Vellum: Anub''ar Underlord'),
(26621, 89773, 0, 0.1, 0, 1, 0, 1, 1, 'Ghoul Tormentor - Blood Soaked Vellum: Ghoul Tormentor'),
(26622, 81226, 0, 1, 0, 1, 0, 1, 1, 'Drakkari Bat - Beastmaster''s Whistle: Drakkari Bat'),
(26623, 89782, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Brute - Blood Soaked Vellum: Scourge Brute'),
(26624, 89838, 0, 0.1, 0, 1, 0, 1, 1, 'Wretched Belcher - Blood Soaked Vellum: Wretched Belcher'),
(26625, 81227, 0, 1, 0, 1, 0, 1, 1, 'Darkweb Recluse - Beastmaster''s Whistle: Darkweb Recluse'),
(26628, 81228, 0, 1, 0, 1, 0, 1, 1, 'Drakkari Scytheclaw - Beastmaster''s Whistle: Drakkari Scytheclaw'),
(26630, 89840, 0, 0.1, 0, 1, 0, 1, 1, 'Trollgore - Blood Soaked Vellum: Trollgore'),
(26641, 81278, 0, 1, 0, 1, 0, 1, 1, 'Drakkari Gutripper - Beastmaster''s Whistle: Drakkari Gutripper'),
(26643, 81322, 0, 1, 0, 1, 0, 1, 1, 'Rabid Grizzly - Beastmaster''s Whistle: Rabid Grizzly'),
(26644, 81323, 0, 1, 0, 1, 0, 1, 1, 'Ursus Mauler - Beastmaster''s Whistle: Ursus Mauler'),
(26672, 81363, 0, 1, 0, 1, 0, 1, 1, 'Bloodthirsty Tundra Wolf - Beastmaster''s Whistle: Bloodthirsty Tundra Wolf'),
(26706, 81374, 0, 1, 0, 1, 0, 1, 1, 'Infected Grizzly Bear - Beastmaster''s Whistle: Infected Grizzly Bear'),
(26723, 1180659, 0, 1, 0, 1, 0, 1, 1, 'Keristrasza - Draconic Warhorn: Keristrasza'),
(26806, 81377, 0, 1, 0, 1, 0, 1, 1, 'Guardian Serpent - Beastmaster''s Whistle: Guardian Serpent'),
(26838, 81378, 0, 1, 0, 1, 0, 1, 1, 'Dreadtalon - Beastmaster''s Whistle: Dreadtalon'),
(26948, 89845, 0, 0.1, 0, 1, 0, 1, 1, 'Hulking Atrocity - Blood Soaked Vellum: Hulking Atrocity'),
(26966, 89846, 0, 0.1, 0, 1, 0, 1, 1, 'Shadowy Tormentor - Blood Soaked Vellum: Shadowy Tormentor'),
(27131, 81379, 0, 1, 0, 1, 0, 1, 1, 'Grizzly Bear - Beastmaster''s Whistle: Grizzly Bear'),
(27244, 81380, 0, 1, 0, 1, 0, 1, 1, 'Emerald Skytalon - Beastmaster''s Whistle: Emerald Skytalon'),
(27249, 81381, 0, 1, 0, 1, 0, 1, 1, 'Alystros the Verdant Keeper - Beastmaster''s Whistle: Alystros the Verdant Keeper'),
(27272, 89850, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Villager - Blood Soaked Vellum: Risen Villager'),
(27283, 89851, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Wintergarde Mage - Blood Soaked Vellum: Risen Wintergarde Mage'),
(27284, 89852, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Wintergarde Defender - Blood Soaked Vellum: Risen Wintergarde Defender'),
(27286, 89853, 0, 0.1, 0, 1, 0, 1, 1, 'Dreadbone Invader - Blood Soaked Vellum: Dreadbone Invader'),
(27287, 89854, 0, 0.1, 0, 1, 0, 1, 1, 'Mindless Wight - Blood Soaked Vellum: Mindless Wight'),
(27294, 81382, 0, 1, 0, 1, 0, 1, 1, 'Tundra Scavenger - Beastmaster''s Whistle: Tundra Scavenger'),
(27329, 81383, 0, 1, 0, 1, 0, 1, 1, 'Onslaught Bloodhound - Beastmaster''s Whistle: Onslaught Bloodhound'),
(27360, 89855, 0, 0.1, 0, 1, 0, 1, 1, 'Smoldering Skeleton - Blood Soaked Vellum: Smoldering Skeleton'),
(27362, 89859, 0, 0.1, 0, 1, 0, 1, 1, 'Smoldering Construct - Blood Soaked Vellum: Smoldering Construct'),
(27408, 81386, 0, 1, 0, 1, 0, 1, 1, 'Duskhowl Prowler - Beastmaster''s Whistle: Duskhowl Prowler'),
(27410, 89860, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Siegesmith - Blood Soaked Vellum: Scourge Siegesmith'),
(27421, 81387, 0, 1, 0, 1, 0, 1, 1, 'Fern Feeder Moth - Beastmaster''s Whistle: Fern Feeder Moth'),
(27447, 1180690, 0, 1, 0, 1, 0, 1, 1, 'Varos Cloudstrider - Draconic Warhorn: Varos Cloudstrider'),
(27483, 81392, 0, 1, 0, 1, 0, 1, 1, 'King Dred - Beastmaster''s Whistle: King Dred'),
(27551, 89866, 0, 0.1, 0, 1, 0, 1, 1, 'Enraged Apparition - Blood Soaked Vellum: Enraged Apparition'),
(27552, 89867, 0, 0.1, 0, 1, 0, 1, 1, 'Reanimated Noble - Blood Soaked Vellum: Reanimated Noble'),
(27578, 81395, 0, 1, 0, 1, 0, 1, 1, 'Goremaw - Beastmaster''s Whistle: Goremaw'),
(27633, 1180695, 0, 1, 0, 1, 0, 1, 1, 'Azure Inquisitor - Draconic Warhorn: Azure Inquisitor'),
(27635, 1180696, 0, 1, 0, 1, 0, 1, 1, 'Azure Spellbinder - Draconic Warhorn: Azure Spellbinder'),
(27636, 1180697, 0, 1, 0, 1, 0, 1, 1, 'Azure Ley-Whelp - Draconic Warhorn: Azure Ley-Whelp'),
(27654, 1180700, 0, 1, 0, 1, 0, 1, 1, 'Drakos the Interrogator - Draconic Warhorn: Drakos the Interrogator'),
(27680, 89878, 0, 0.1, 0, 1, 0, 1, 1, 'Dahlia Suntouch - Blood Soaked Vellum: Dahlia Suntouch'),
(27729, 89879, 0, 0.1, 0, 1, 0, 1, 1, 'Enraging Ghoul - Blood Soaked Vellum: Enraging Ghoul'),
(27736, 89890, 0, 0.1, 0, 1, 0, 1, 1, 'Patchwork Construct - Blood Soaked Vellum: Patchwork Construct'),
(27797, 89891, 0, 0.1, 0, 1, 0, 1, 1, 'Tattered Abomination - Blood Soaked Vellum: Tattered Abomination'),
(27808, 89892, 0, 0.1, 0, 1, 0, 1, 1, 'Turgid the Vile - Blood Soaked Vellum: Turgid the Vile'),
(27823, 89904, 0, 0.1, 0, 1, 0, 1, 1, 'Naxxramas Dreadguard - Blood Soaked Vellum: Naxxramas Dreadguard'),
(27824, 89905, 0, 0.1, 0, 1, 0, 1, 1, 'Naxxramas Shade - Blood Soaked Vellum: Naxxramas Shade'),
(27835, 89913, 0, 0.1, 0, 1, 0, 1, 1, 'Dreadbone Construct - Blood Soaked Vellum: Dreadbone Construct'),
(27836, 89914, 0, 0.1, 0, 1, 0, 1, 1, 'Wailing Soul - Blood Soaked Vellum: Wailing Soul'),
(27941, 89995, 0, 0.1, 0, 1, 0, 1, 1, 'Drakkari Plague Spreader - Blood Soaked Vellum: Drakkari Plague Spreader'),
(28001, 81398, 0, 1, 0, 1, 0, 1, 1, 'Dreadsaber - Beastmaster''s Whistle: Dreadsaber'),
(28002, 81399, 0, 1, 0, 1, 0, 1, 1, 'Mangal Crocolisk - Beastmaster''s Whistle: Mangal Crocolisk'),
(28004, 81416, 0, 1, 0, 1, 0, 1, 1, 'Goretalon Roc - Beastmaster''s Whistle: Goretalon Roc'),
(28009, 81419, 0, 1, 0, 1, 0, 1, 1, 'Shardhorn Rhino - Beastmaster''s Whistle: Shardhorn Rhino'),
(28011, 81420, 0, 1, 0, 1, 0, 1, 1, 'Emperor Cobra - Beastmaster''s Whistle: Emperor Cobra'),
(28022, 89998, 0, 0.1, 0, 1, 0, 1, 1, 'Carrion Eater - Blood Soaked Vellum: Carrion Eater'),
(28069, 601700, 0, 1, 0, 1, 0, 1, 1, 'Sholazar Guardian - Elemental Lodestone: Sholazar Guardian'),
(28085, 81421, 0, 1, 0, 1, 0, 1, 1, 'Sapphire Hive Drone - Beastmaster''s Whistle: Sapphire Hive Drone'),
(28086, 81422, 0, 1, 0, 1, 0, 1, 1, 'Sapphire Hive Wasp - Beastmaster''s Whistle: Sapphire Hive Wasp'),
(28087, 81423, 0, 1, 0, 1, 0, 1, 1, 'Sapphire Hive Queen - Beastmaster''s Whistle: Sapphire Hive Queen'),
(28096, 81424, 0, 1, 0, 1, 0, 1, 1, 'Hardknuckle Charger - Beastmaster''s Whistle: Hardknuckle Charger'),
(28097, 81425, 0, 1, 0, 1, 0, 1, 1, 'Pitch - Beastmaster''s Whistle: Pitch'),
(28098, 81426, 0, 1, 0, 1, 0, 1, 1, 'Hardknuckle Forager - Beastmaster''s Whistle: Hardknuckle Forager'),
(28101, 101049, 0, 0.1, 0, 1, 0, 1, 1, 'Blighted Corpse - Blood Soaked Vellum: Blighted Corpse'),
(28108, 101050, 0, 0.1, 0, 1, 0, 1, 1, 'Bonescythe Ravager - Blood Soaked Vellum: Bonescythe Ravager'),
(28158, 101051, 0, 0.1, 0, 1, 0, 1, 1, 'Withered Argent Footman - Blood Soaked Vellum: Withered Argent Footman'),
(28199, 101053, 0, 0.1, 0, 1, 0, 1, 1, 'Tomb Stalker - Blood Soaked Vellum: Tomb Stalker'),
(28201, 101054, 0, 0.1, 0, 1, 0, 1, 1, 'Bile Golem - Blood Soaked Vellum: Bile Golem'),
(28220, 101055, 0, 0.1, 0, 1, 0, 1, 1, 'Frostbitten Corpse - Blood Soaked Vellum: Frostbitten Corpse'),
(28221, 81428, 0, 1, 0, 1, 0, 1, 1, 'Trapdoor Crawler - Beastmaster''s Whistle: Trapdoor Crawler'),
(28233, 81429, 0, 1, 0, 1, 0, 1, 1, 'Zul''Drak Bat - Beastmaster''s Whistle: Zul''Drak Bat'),
(28246, 101056, 0, 0.1, 0, 1, 0, 1, 1, 'Sky Terror - Blood Soaked Vellum: Sky Terror'),
(28249, 101057, 0, 0.1, 0, 1, 0, 1, 1, 'Devouring Ghoul - Blood Soaked Vellum: Devouring Ghoul'),
(28268, 101058, 0, 0.1, 0, 1, 0, 1, 1, 'Scourged Argent Footman - Blood Soaked Vellum: Scourged Argent Footman'),
(28297, 81431, 0, 1, 0, 1, 0, 1, 1, 'Shango - Beastmaster''s Whistle: Shango'),
(28358, 81432, 0, 1, 0, 1, 0, 1, 1, 'Venomtip - Beastmaster''s Whistle: Venomtip'),
(28404, 81433, 0, 1, 0, 1, 0, 1, 1, 'Cursed Offspring of Har''koa - Beastmaster''s Whistle: Cursed Offspring of Har''koa'),
(28477, 81434, 0, 1, 0, 1, 0, 1, 1, 'Scion of Quetz''lun - Beastmaster''s Whistle: Scion of Quetz''lun'),
(28564, 101059, 0, 0.1, 0, 1, 0, 1, 1, 'Putrid Abomination - Blood Soaked Vellum: Putrid Abomination'),
(28565, 101060, 0, 0.1, 0, 1, 0, 1, 1, 'Decaying Ghoul - Blood Soaked Vellum: Decaying Ghoul'),
(28603, 101061, 0, 0.1, 0, 1, 0, 1, 1, 'Blightguard - Blood Soaked Vellum: Blightguard'),
(28747, 101064, 0, 0.1, 0, 1, 0, 1, 1, 'Quetz''lun Worshipper - Blood Soaked Vellum: Quetz''lun Worshipper'),
(28748, 101065, 0, 0.1, 0, 1, 0, 1, 1, 'Serpent-Touched Berserker - Blood Soaked Vellum: Serpent-Touched Berserker'),
(28766, 81435, 0, 1, 0, 1, 0, 1, 1, 'Scarlet Farm Hound - Beastmaster''s Whistle: Scarlet Farm Hound'),
(28793, 101068, 0, 0.1, 0, 1, 0, 1, 1, 'Darmuk - Blood Soaked Vellum: Darmuk'),
(28840, 601705, 0, 1, 0, 1, 0, 1, 1, 'Overlook Sentry - Elemental Lodestone: Overlook Sentry'),
(28843, 101069, 0, 0.1, 0, 1, 0, 1, 1, 'Bloated Abomination - Blood Soaked Vellum: Bloated Abomination'),
(28860, 1180732, 0, 1, 0, 1, 0, 1, 1, 'Sartharion - Draconic Warhorn: Sartharion'),
(28931, 101073, 0, 0.1, 0, 1, 0, 1, 1, 'Blightblood Troll - Blood Soaked Vellum: Blightblood Troll'),
(29044, 81436, 0, 1, 0, 1, 0, 1, 1, 'Goretalon Matriarch - Beastmaster''s Whistle: Goretalon Matriarch'),
(29120, 101075, 0, 0.1, 0, 1, 0, 1, 1, 'Anub''arak - Blood Soaked Vellum: Anub''arak'),
(29123, 101076, 0, 0.1, 0, 1, 0, 1, 1, 'Monstrous Wight - Blood Soaked Vellum: Monstrous Wight'),
(29133, 101077, 0, 0.1, 0, 1, 0, 1, 1, 'Disturbed Soul - Blood Soaked Vellum: Disturbed Soul'),
(29316, 85715, 0, 1, 0, 1, 0, 1, 1, 'Moragg - Summoner''s Stone: Moragg'),
(29319, 81437, 0, 1, 0, 1, 0, 1, 1, 'Icepaw Bear - Beastmaster''s Whistle: Icepaw Bear'),
(29327, 81438, 0, 1, 0, 1, 0, 1, 1, 'Frost Leopard - Beastmaster''s Whistle: Frost Leopard'),
(29334, 81439, 0, 1, 0, 1, 0, 1, 1, 'Gundrak Raptor - Beastmaster''s Whistle: Gundrak Raptor'),
(29358, 81558, 0, 1, 0, 1, 0, 1, 1, 'Frostworg - Beastmaster''s Whistle: Frostworg'),
(29390, 81893, 0, 1, 0, 1, 0, 1, 1, 'Snowdrift Jormungar - Beastmaster''s Whistle: Snowdrift Jormungar'),
(29411, 81894, 0, 1, 0, 1, 0, 1, 1, 'Crystalweb Weaver - Beastmaster''s Whistle: Crystalweb Weaver'),
(29412, 81895, 0, 1, 0, 1, 0, 1, 1, 'Crystalweb Spitter - Beastmaster''s Whistle: Crystalweb Spitter'),
(29452, 81896, 0, 1, 0, 1, 0, 1, 1, 'Vargul Blighthound - Beastmaster''s Whistle: Vargul Blighthound'),
(29461, 81897, 0, 1, 0, 1, 0, 1, 1, 'Icetip Crawler - Beastmaster''s Whistle: Icetip Crawler'),
(29469, 81898, 0, 1, 0, 1, 0, 1, 1, 'Ice Steppe Rhino - Beastmaster''s Whistle: Ice Steppe Rhino'),
(29562, 81899, 0, 1, 0, 1, 0, 1, 1, 'Icemaw Bear - Beastmaster''s Whistle: Icemaw Bear'),
(29605, 81900, 0, 1, 0, 1, 0, 1, 1, 'Ravenous Jormungar - Beastmaster''s Whistle: Ravenous Jormungar'),
(29646, 101078, 0, 0.1, 0, 1, 0, 1, 1, 'Banshee Soulclaimer - Blood Soaked Vellum: Banshee Soulclaimer'),
(29656, 101079, 0, 0.1, 0, 1, 0, 1, 1, 'Drakuru Berserker - Blood Soaked Vellum: Drakuru Berserker'),
(29693, 81902, 0, 1, 0, 1, 0, 1, 1, 'Serpent Defender - Beastmaster''s Whistle: Serpent Defender'),
(29698, 81903, 0, 1, 0, 1, 0, 1, 1, 'Drakuru Raptor - Beastmaster''s Whistle: Drakuru Raptor'),
(29719, 101080, 0, 0.1, 0, 1, 0, 1, 1, 'Morbid Carcass - Blood Soaked Vellum: Morbid Carcass'),
(29722, 101081, 0, 0.1, 0, 1, 0, 1, 1, 'Rabid Cannibal - Blood Soaked Vellum: Rabid Cannibal'),
(29735, 81904, 0, 1, 0, 1, 0, 1, 1, 'Savage Worg - Beastmaster''s Whistle: Savage Worg'),
(29854, 81905, 0, 1, 0, 1, 0, 1, 1, 'Stormcrest Eagle - Beastmaster''s Whistle: Stormcrest Eagle'),
(29994, 81907, 0, 1, 0, 1, 0, 1, 1, 'Shardtooth - Beastmaster''s Whistle: Shardtooth'),
(30148, 81908, 0, 1, 0, 1, 0, 1, 1, 'Infesting Jormungar - Beastmaster''s Whistle: Infesting Jormungar'),
(30164, 81909, 0, 1, 0, 1, 0, 1, 1, 'Cavedweller Worg - Beastmaster''s Whistle: Cavedweller Worg'),
(30202, 101083, 0, 0.1, 0, 1, 0, 1, 1, 'Reanimated Crusader - Blood Soaked Vellum: Reanimated Crusader'),
(30206, 81910, 0, 1, 0, 1, 0, 1, 1, 'Carrion Fleshstripper - Beastmaster''s Whistle: Carrion Fleshstripper'),
(30283, 101084, 0, 0.1, 0, 1, 0, 1, 1, 'Plague Walker - Blood Soaked Vellum: Plague Walker'),
(30285, 101085, 0, 0.1, 0, 1, 0, 1, 1, 'Eye of Taldaram - Blood Soaked Vellum: Eye of Taldaram'),
(30286, 101086, 0, 0.1, 0, 1, 0, 1, 1, 'Frostbringer - Blood Soaked Vellum: Frostbringer'),
(30294, 81912, 0, 1, 0, 1, 0, 1, 1, 'Frostworg Denmother - Beastmaster''s Whistle: Frostworg Denmother'),
(30422, 81913, 0, 1, 0, 1, 0, 1, 1, 'Roaming Jormungar - Beastmaster''s Whistle: Roaming Jormungar'),
(30430, 81914, 0, 1, 0, 1, 0, 1, 1, 'Sentry Worg - Beastmaster''s Whistle: Sentry Worg');
DELETE FROM `creature_loot_template` WHERE (`Entry`=30445 AND `Item`=81915) OR
  (`Entry`=30447 AND `Item`=81929) OR
  (`Entry`=30449 AND `Item`=1180732) OR
  (`Entry`=30449 AND `Item`=1180767) OR
  (`Entry`=30451 AND `Item`=1180732) OR
  (`Entry`=30451 AND `Item`=1180768) OR
  (`Entry`=30452 AND `Item`=1180732) OR
  (`Entry`=30452 AND `Item`=1180769) OR
  (`Entry`=30453 AND `Item`=1180770) OR
  (`Entry`=30456 AND `Item`=81930) OR
  (`Entry`=30482 AND `Item`=101087) OR
  (`Entry`=30541 AND `Item`=101088) OR
  (`Entry`=30597 AND `Item`=101089) OR
  (`Entry`=30680 AND `Item`=1180789) OR
  (`Entry`=30681 AND `Item`=1180790) OR
  (`Entry`=30682 AND `Item`=1180791) OR
  (`Entry`=30687 AND `Item`=101090) OR
  (`Entry`=30689 AND `Item`=101091) OR
  (`Entry`=30696 AND `Item`=101092) OR
  (`Entry`=30830 AND `Item`=101093) OR
  (`Entry`=30920 AND `Item`=101095) OR
  (`Entry`=30921 AND `Item`=101096) OR
  (`Entry`=30949 AND `Item`=101097) OR
  (`Entry`=30951 AND `Item`=101098) OR
  (`Entry`=30958 AND `Item`=101099) OR
  (`Entry`=30960 AND `Item`=101100) OR
  (`Entry`=31015 AND `Item`=101102) OR
  (`Entry`=31140 AND `Item`=101106) OR
  (`Entry`=31141 AND `Item`=101107) OR
  (`Entry`=31142 AND `Item`=101108) OR
  (`Entry`=31150 AND `Item`=101109) OR
  (`Entry`=31152 AND `Item`=101110) OR
  (`Entry`=31155 AND `Item`=101111) OR
  (`Entry`=31198 AND `Item`=101112) OR
  (`Entry`=31233 AND `Item`=81931) OR
  (`Entry`=31393 AND `Item`=1180829) OR
  (`Entry`=31402 AND `Item`=1180830) OR
  (`Entry`=31403 AND `Item`=1180831) OR
  (`Entry`=31411 AND `Item`=101117) OR
  (`Entry`=31747 AND `Item`=81932) OR
  (`Entry`=31754 AND `Item`=101122) OR
  (`Entry`=31779 AND `Item`=101123) OR
  (`Entry`=31780 AND `Item`=101124) OR
  (`Entry`=31787 AND `Item`=101125) OR
  (`Entry`=31812 AND `Item`=101126) OR
  (`Entry`=31813 AND `Item`=101127) OR
  (`Entry`=31843 AND `Item`=101128) OR
  (`Entry`=31900 AND `Item`=101129) OR
  (`Entry`=32161 AND `Item`=101130) OR
  (`Entry`=32164 AND `Item`=101131) OR
  (`Entry`=32257 AND `Item`=101132) OR
  (`Entry`=32267 AND `Item`=101133) OR
  (`Entry`=32284 AND `Item`=101134) OR
  (`Entry`=32323 AND `Item`=101135) OR
  (`Entry`=32361 AND `Item`=81933) OR
  (`Entry`=32467 AND `Item`=101136) OR
  (`Entry`=32471 AND `Item`=101137) OR
  (`Entry`=32475 AND `Item`=81934) OR
  (`Entry`=32481 AND `Item`=81935) OR
  (`Entry`=32485 AND `Item`=81936) OR
  (`Entry`=32502 AND `Item`=101138) OR
  (`Entry`=32517 AND `Item`=81937) OR
  (`Entry`=32572 AND `Item`=1180855) OR
  (`Entry`=32630 AND `Item`=1180856) OR
  (`Entry`=32769 AND `Item`=101139) OR
  (`Entry`=32770 AND `Item`=101140) OR
  (`Entry`=32771 AND `Item`=101141) OR
  (`Entry`=32772 AND `Item`=101142) OR
  (`Entry`=33499 AND `Item`=101143) OR
  (`Entry`=33733 AND `Item`=1180859) OR
  (`Entry`=33772 AND `Item`=1180859) OR
  (`Entry`=33776 AND `Item`=82296) OR
  (`Entry`=35189 AND `Item`=82297) OR
  (`Entry`=36070 AND `Item`=601832) OR
  (`Entry`=36473 AND `Item`=601832) OR
  (`Entry`=36474 AND `Item`=601832) OR
  (`Entry`=36475 AND `Item`=601832) OR
  (`Entry`=36476 AND `Item`=101144) OR
  (`Entry`=36724 AND `Item`=101149) OR
  (`Entry`=36807 AND `Item`=101150) OR
  (`Entry`=37007 AND `Item`=101155) OR
  (`Entry`=37011 AND `Item`=101156) OR
  (`Entry`=37012 AND `Item`=101157) OR
  (`Entry`=37022 AND `Item`=101158) OR
  (`Entry`=37544 AND `Item`=101159) OR
  (`Entry`=37545 AND `Item`=101160) OR
  (`Entry`=37546 AND `Item`=101161) OR
  (`Entry`=38453 AND `Item`=82303) OR
  (`Entry`=103653 AND `Item`=79638) OR
  (`Entry`=104425 AND `Item`=79701) OR
  (`Entry`=105709 AND `Item`=1180226) OR
  (`Entry`=105711 AND `Item`=87697) OR
  (`Entry`=105712 AND `Item`=87698) OR
  (`Entry`=105716 AND `Item`=87717) OR
  (`Entry`=105717 AND `Item`=87718) OR
  (`Entry`=105719 AND `Item`=1180229) OR
  (`Entry`=105722 AND `Item`=1180232) OR
  (`Entry`=105775 AND `Item`=601062) OR
  (`Entry`=106489 AND `Item`=87734) OR
  (`Entry`=107206 AND `Item`=601679) OR
  (`Entry`=109568 AND `Item`=1180292) OR
  (`Entry`=109938 AND `Item`=601687) OR
  (`Entry`=110264 AND `Item`=1180305) OR
  (`Entry`=110363 AND `Item`=1180309) OR
  (`Entry`=110430 AND `Item`=80089) OR
  (`Entry`=112237 AND `Item`=601076) OR
  (`Entry`=13142 AND `Item`=601823) OR
  (`Entry`=13142 AND `Item`=1777422) OR
  (`Entry`=113743 AND `Item`=601824) OR
  (`Entry`=116042 AND `Item`=1180434) OR
  (`Entry`=203653 AND `Item`=79638) OR
  (`Entry`=204425 AND `Item`=79701) OR
  (`Entry`=205709 AND `Item`=1180226) OR
  (`Entry`=205711 AND `Item`=87697) OR
  (`Entry`=205712 AND `Item`=87698) OR
  (`Entry`=205716 AND `Item`=87717) OR
  (`Entry`=205717 AND `Item`=87718) OR
  (`Entry`=205719 AND `Item`=1180229) OR
  (`Entry`=205722 AND `Item`=1180232) OR
  (`Entry`=205775 AND `Item`=601062) OR
  (`Entry`=206489 AND `Item`=87734) OR
  (`Entry`=207079 AND `Item`=600392) OR
  (`Entry`=207206 AND `Item`=601679) OR
  (`Entry`=209568 AND `Item`=1180292) OR
  (`Entry`=209938 AND `Item`=601687) OR
  (`Entry`=210264 AND `Item`=1180305) OR
  (`Entry`=210363 AND `Item`=1180309) OR
  (`Entry`=210430 AND `Item`=80089) OR
  (`Entry`=212237 AND `Item`=601076) OR
  (`Entry`=213743 AND `Item`=601824) OR
  (`Entry`=216042 AND `Item`=1180434) OR
  (`Entry`=254939 AND `Item`=79468) OR
  (`Entry`=299222 AND `Item`=79353) OR
  (`Entry`=299224 AND `Item`=79353);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(30445, 81915, 0, 1, 0, 1, 0, 1, 1, 'Ice Steppe Bull - Beastmaster''s Whistle: Ice Steppe Bull'),
(30447, 81929, 0, 1, 0, 1, 0, 1, 1, 'Romping Rhino - Beastmaster''s Whistle: Romping Rhino'),
(30449, 1180732, 0, 1, 0, 1, 0, 1, 1, 'Vesperon - Draconic Warhorn: Sartharion'),
(30449, 1180767, 0, 1, 0, 1, 0, 1, 1, 'Vesperon - Draconic Warhorn: Vesperon'),
(30451, 1180732, 0, 1, 0, 1, 0, 1, 1, 'Shadron - Draconic Warhorn: Sartharion'),
(30451, 1180768, 0, 1, 0, 1, 0, 1, 1, 'Shadron - Draconic Warhorn: Shadron'),
(30452, 1180732, 0, 1, 0, 1, 0, 1, 1, 'Tenebron - Draconic Warhorn: Sartharion'),
(30452, 1180769, 0, 1, 0, 1, 0, 1, 1, 'Tenebron - Draconic Warhorn: Tenebron'),
(30453, 1180770, 0, 1, 0, 1, 0, 1, 1, 'Onyx Sanctum Guardian - Draconic Warhorn: Onyx Sanctum Guardian'),
(30456, 81930, 0, 1, 0, 1, 0, 1, 1, 'Oloh - Beastmaster''s Whistle: Oloh'),
(30482, 101087, 0, 0.1, 0, 1, 0, 1, 1, 'Wrathstrike Gargoyle - Blood Soaked Vellum: Wrathstrike Gargoyle'),
(30541, 101088, 0, 0.1, 0, 1, 0, 1, 1, 'Forgotten Depths Underking - Blood Soaked Vellum: Forgotten Depths Underking'),
(30597, 101089, 0, 0.1, 0, 1, 0, 1, 1, 'Spiked Ghoul - Blood Soaked Vellum: Spiked Ghoul'),
(30680, 1180789, 0, 1, 0, 1, 0, 1, 1, 'Onyx Brood General - Draconic Warhorn: Onyx Brood General'),
(30681, 1180790, 0, 1, 0, 1, 0, 1, 1, 'Onyx Blaze Mistress - Draconic Warhorn: Onyx Blaze Mistress'),
(30682, 1180791, 0, 1, 0, 1, 0, 1, 1, 'Onyx Flight Captain - Draconic Warhorn: Onyx Flight Captain'),
(30687, 101090, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Constructor - Blood Soaked Vellum: Skeletal Constructor'),
(30689, 101091, 0, 0.1, 0, 1, 0, 1, 1, 'Chained Abomination - Blood Soaked Vellum: Chained Abomination'),
(30696, 101092, 0, 0.1, 0, 1, 0, 1, 1, 'Corpulent Horror - Blood Soaked Vellum: Corpulent Horror'),
(30830, 101093, 0, 0.1, 0, 1, 0, 1, 1, 'Underking Talonox - Blood Soaked Vellum: Underking Talonox'),
(30920, 101095, 0, 0.1, 0, 1, 0, 1, 1, 'Lumbering Atrocity - Blood Soaked Vellum: Lumbering Atrocity'),
(30921, 101096, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Runesmith - Blood Soaked Vellum: Skeletal Runesmith'),
(30949, 101097, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Laborer - Blood Soaked Vellum: Risen Laborer'),
(30951, 101098, 0, 0.1, 0, 1, 0, 1, 1, 'Restless Lookout - Blood Soaked Vellum: Restless Lookout'),
(30958, 101099, 0, 0.1, 0, 1, 0, 1, 1, 'Death Knight Initiate - Blood Soaked Vellum: Death Knight Initiate'),
(30960, 101100, 0, 0.1, 0, 1, 0, 1, 1, 'Risen Soldier - Blood Soaked Vellum: Risen Soldier'),
(31015, 101102, 0, 0.1, 0, 1, 0, 1, 1, 'Intrepid Ghoul - Blood Soaked Vellum: Intrepid Ghoul'),
(31140, 101106, 0, 0.1, 0, 1, 0, 1, 1, 'Hulking Abomination - Blood Soaked Vellum: Hulking Abomination'),
(31141, 101107, 0, 0.1, 0, 1, 0, 1, 1, 'Decaying Wight - Blood Soaked Vellum: Decaying Wight'),
(31142, 101108, 0, 0.1, 0, 1, 0, 1, 1, 'Icy Ghoul - Blood Soaked Vellum: Icy Ghoul'),
(31150, 101109, 0, 0.1, 0, 1, 0, 1, 1, 'Plagued Fiend - Blood Soaked Vellum: Plagued Fiend'),
(31152, 101110, 0, 0.1, 0, 1, 0, 1, 1, 'Undying Minion - Blood Soaked Vellum: Undying Minion'),
(31155, 101111, 0, 0.1, 0, 1, 0, 1, 1, 'Malefic Necromancer - Blood Soaked Vellum: Malefic Necromancer'),
(31198, 101112, 0, 0.1, 0, 1, 0, 1, 1, 'Coprous the Defiled - Blood Soaked Vellum: Coprous the Defiled'),
(31233, 81931, 0, 1, 0, 1, 0, 1, 1, 'Sinewy Wolf - Beastmaster''s Whistle: Sinewy Wolf'),
(31393, 1180829, 0, 1, 0, 1, 0, 1, 1, 'Crystal Wyrm - Draconic Warhorn: Crystal Wyrm'),
(31402, 1180830, 0, 1, 0, 1, 0, 1, 1, 'Azure Scalebane - Draconic Warhorn: Azure Scalebane'),
(31403, 1180831, 0, 1, 0, 1, 0, 1, 1, 'Azure Spellweaver - Draconic Warhorn: Azure Spellweaver'),
(31411, 101117, 0, 0.1, 0, 1, 0, 1, 1, 'Hulking Horror - Blood Soaked Vellum: Hulking Horror'),
(31747, 81932, 0, 1, 0, 1, 0, 1, 1, 'Necrotic Webspinner - Beastmaster''s Whistle: Necrotic Webspinner'),
(31754, 101122, 0, 0.1, 0, 1, 0, 1, 1, 'Glacial Bonelord - Blood Soaked Vellum: Glacial Bonelord'),
(31779, 101123, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Archmage - Blood Soaked Vellum: Skeletal Archmage'),
(31780, 101124, 0, 0.1, 0, 1, 0, 1, 1, 'Fallen Spiderlord - Blood Soaked Vellum: Fallen Spiderlord'),
(31787, 101125, 0, 0.1, 0, 1, 0, 1, 1, 'Citadel Watcher - Blood Soaked Vellum: Citadel Watcher'),
(31812, 101126, 0, 0.1, 0, 1, 0, 1, 1, 'Decomposed Ghoul - Blood Soaked Vellum: Decomposed Ghoul'),
(31813, 101127, 0, 0.1, 0, 1, 0, 1, 1, 'Frostskull Magus - Blood Soaked Vellum: Frostskull Magus'),
(31843, 101128, 0, 0.1, 0, 1, 0, 1, 1, 'Reanimated Miner - Blood Soaked Vellum: Reanimated Miner'),
(31900, 101129, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Banner-Bearer - Blood Soaked Vellum: Scourge Banner-Bearer'),
(32161, 101130, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge War Engineer - Blood Soaked Vellum: Scourge War Engineer'),
(32164, 101131, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Craftsman - Blood Soaked Vellum: Skeletal Craftsman'),
(32257, 101132, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Converter - Blood Soaked Vellum: Scourge Converter'),
(32267, 101133, 0, 0.1, 0, 1, 0, 1, 1, 'Animated Laborer - Blood Soaked Vellum: Animated Laborer'),
(32284, 101134, 0, 0.1, 0, 1, 0, 1, 1, 'Scourge Soulbinder - Blood Soaked Vellum: Scourge Soulbinder'),
(32323, 101135, 0, 0.1, 0, 1, 0, 1, 1, 'Aldur''thar Sentry - Blood Soaked Vellum: Aldur''thar Sentry'),
(32361, 81933, 0, 1, 0, 1, 0, 1, 1, 'Icehorn - Beastmaster''s Whistle: Icehorn'),
(32467, 101136, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Reaver - Blood Soaked Vellum: Skeletal Reaver'),
(32471, 101137, 0, 0.1, 0, 1, 0, 1, 1, 'Griegen - Blood Soaked Vellum: Griegen'),
(32475, 81934, 0, 1, 0, 1, 0, 1, 1, 'Terror Spinner - Beastmaster''s Whistle: Terror Spinner'),
(32481, 81935, 0, 1, 0, 1, 0, 1, 1, 'Aotona - Beastmaster''s Whistle: Aotona'),
(32485, 81936, 0, 1, 0, 1, 0, 1, 1, 'King Krush - Beastmaster''s Whistle: King Krush'),
(32502, 101138, 0, 0.1, 0, 1, 0, 1, 1, 'Ravaged Ghoul - Blood Soaked Vellum: Ravaged Ghoul'),
(32517, 81937, 0, 1, 0, 1, 0, 1, 1, 'Loque''nahak - Beastmaster''s Whistle: Loque''nahak'),
(32572, 1180855, 0, 1, 0, 1, 0, 1, 1, 'Dragonblight Mage Hunter - Draconic Warhorn: Dragonblight Mage Hunter'),
(32630, 1180856, 0, 1, 0, 1, 0, 1, 1, 'Vyragosa - Draconic Warhorn: Vyragosa'),
(32769, 101139, 0, 0.1, 0, 1, 0, 1, 1, 'Gargoyle Ambusher - Blood Soaked Vellum: Gargoyle Ambusher'),
(32770, 101140, 0, 0.1, 0, 1, 0, 1, 1, 'Enraged Fleshrender - Blood Soaked Vellum: Enraged Fleshrender'),
(32771, 101141, 0, 0.1, 0, 1, 0, 1, 1, 'Stitched Brute - Blood Soaked Vellum: Stitched Brute'),
(32772, 101142, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Footsoldier - Blood Soaked Vellum: Skeletal Footsoldier'),
(33499, 101143, 0, 0.1, 0, 1, 0, 1, 1, 'Skeletal Woodcutter - Blood Soaked Vellum: Skeletal Woodcutter'),
(33733, 1180859, 0, 1, 0, 1, 0, 1, 1, 'Guardian of Life (1) - Draconic Warhorn: Guardian of Life'),
(33772, 1180859, 0, 1, 0, 1, 0, 1, 1, 'Faceless Horror - Draconic Warhorn: Guardian of Life'),
(33776, 82296, 0, 1, 0, 1, 0, 1, 1, 'Gondria - Beastmaster''s Whistle: Gondria'),
(35189, 82297, 0, 1, 0, 1, 0, 1, 1, 'Skoll - Beastmaster''s Whistle: Skoll'),
(36070, 601832, 0, 1, 0, 1, 0, 1, 1, 'Treant - Elemental Lodestone: Treant'),
(36473, 601832, 0, 1, 0, 1, 0, 1, 1, 'Treant (1) - Elemental Lodestone: Treant'),
(36474, 601832, 0, 1, 0, 1, 0, 1, 1, 'Treant (2) - Elemental Lodestone: Treant'),
(36475, 601832, 0, 1, 0, 1, 0, 1, 1, 'Treant (3) - Elemental Lodestone: Treant'),
(36476, 101144, 0, 0.1, 0, 1, 0, 1, 1, 'Ick - Blood Soaked Vellum: Ick'),
(36724, 101149, 0, 0.1, 0, 1, 0, 1, 1, 'Servant of the Throne - Blood Soaked Vellum: Servant of the Throne'),
(36807, 101150, 0, 0.1, 0, 1, 0, 1, 1, 'Deathspeaker Disciple - Blood Soaked Vellum: Deathspeaker Disciple'),
(37007, 101155, 0, 0.1, 0, 1, 0, 1, 1, 'Deathbound Ward - Blood Soaked Vellum: Deathbound Ward'),
(37011, 101156, 0, 0.1, 0, 1, 0, 1, 1, 'The Damned - Blood Soaked Vellum: The Damned'),
(37012, 101157, 0, 0.1, 0, 1, 0, 1, 1, 'Ancient Skeletal Soldier - Blood Soaked Vellum: Ancient Skeletal Soldier'),
(37022, 101158, 0, 0.1, 0, 1, 0, 1, 1, 'Blighted Abomination - Blood Soaked Vellum: Blighted Abomination'),
(37544, 101159, 0, 0.1, 0, 1, 0, 1, 1, 'Spire Gargoyle - Blood Soaked Vellum: Spire Gargoyle'),
(37545, 101160, 0, 0.1, 0, 1, 0, 1, 1, 'Spire Minion - Blood Soaked Vellum: Spire Minion'),
(37546, 101161, 0, 0.1, 0, 1, 0, 1, 1, 'Frenzied Abomination - Blood Soaked Vellum: Frenzied Abomination'),
(38453, 82303, 0, 1, 0, 1, 0, 1, 1, 'Arcturis - Beastmaster''s Whistle: Arcturis'),
(103653, 79638, 0, 1, 0, 1, 0, 1, 1, 'Kresh - Beastmaster''s Whistle: Kresh'),
(104425, 79701, 0, 1, 0, 1, 0, 1, 1, 'Blind Hunter - Beastmaster''s Whistle: Blind Hunter'),
(105709, 1180226, 0, 1, 0, 1, 0, 1, 1, 'Shade of Eranikus - Draconic Warhorn: Shade of Eranikus'),
(105711, 87697, 0, 0.1, 0, 1, 0, 1, 1, 'Ogom the Wretched - Blood Soaked Vellum: Ogom the Wretched'),
(105712, 87698, 0, 0.1, 0, 1, 0, 1, 1, 'Zolo - Blood Soaked Vellum: Zolo'),
(105716, 87717, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Lor - Blood Soaked Vellum: Zul''Lor'),
(105717, 87718, 0, 0.1, 0, 1, 0, 1, 1, 'Mijan - Blood Soaked Vellum: Mijan'),
(105719, 1180229, 0, 1, 0, 1, 0, 1, 1, 'Morphaz - Draconic Warhorn: Morphaz'),
(105722, 1180232, 0, 1, 0, 1, 0, 1, 1, 'Hazzas - Draconic Warhorn: Hazzas'),
(105775, 601062, 0, 1, 0, 1, 0, 1, 1, 'Verdan the Everliving - Elemental Lodestone: Verdan the Everliving'),
(106489, 87734, 0, 0.1, 0, 1, 0, 1, 1, 'Ironspine - Blood Soaked Vellum: Ironspine'),
(107206, 601679, 0, 1, 0, 1, 0, 1, 1, 'Ancient Stone Keeper - Elemental Lodestone: Ancient Stone Keeper'),
(109568, 1180292, 0, 1, 0, 1, 0, 1, 1, 'Overlord Wyrmthalak - Draconic Warhorn: Overlord Wyrmthalak'),
(109938, 601687, 0, 1, 0, 1, 0, 1, 1, 'Magmus - Elemental Lodestone: Ironhand Guardian'),
(110264, 1180305, 0, 1, 0, 1, 0, 1, 1, 'Solakar Flamewreath - Draconic Warhorn: Solakar Flamewreath'),
(110363, 1180309, 0, 1, 0, 1, 0, 1, 1, 'General Drakkisath - Draconic Warhorn: General Drakkisath'),
(110430, 80089, 0, 1, 0, 1, 0, 1, 1, 'The Beast - Beastmaster''s Whistle: The Beast'),
(112237, 601076, 0, 1, 0, 1, 0, 1, 1, 'Meshlok the Harvester - Elemental Lodestone: Meshlok the Harvester'),
(13142, 601823, 0, 1, 0, 1, 0, 1, 1, 'Deeprot Tangler - Elemental Lodestone: Deeprot Tangler'),
(13142, 1777422, 0, 1, 0, 1, 0, 1, 1, 'Deeprot Tangler - Elemental Lodestone: Deeprot Tangler'),
(113743, 601824, 0, 1, 0, 1, 0, 1, 1, 'Corrupt Force of Nature - Elemental Lodestone: Corrupt Force of Nature'),
(116042, 1180434, 0, 1, 0, 1, 0, 1, 1, 'Lord Valthalak - Draconic Warhorn: Lord Valthalak'),
(203653, 79638, 0, 1, 0, 1, 0, 1, 1, 'Kresh - Beastmaster''s Whistle: Kresh'),
(204425, 79701, 0, 1, 0, 1, 0, 1, 1, 'Blind Hunter - Beastmaster''s Whistle: Blind Hunter'),
(205709, 1180226, 0, 1, 0, 1, 0, 1, 1, 'Shade of Eranikus - Draconic Warhorn: Shade of Eranikus'),
(205711, 87697, 0, 0.1, 0, 1, 0, 1, 1, 'Ogom the Wretched - Blood Soaked Vellum: Ogom the Wretched'),
(205712, 87698, 0, 0.1, 0, 1, 0, 1, 1, 'Zolo - Blood Soaked Vellum: Zolo'),
(205716, 87717, 0, 0.1, 0, 1, 0, 1, 1, 'Zul''Lor - Blood Soaked Vellum: Zul''Lor'),
(205717, 87718, 0, 0.1, 0, 1, 0, 1, 1, 'Mijan - Blood Soaked Vellum: Mijan'),
(205719, 1180229, 0, 1, 0, 1, 0, 1, 1, 'Morphaz - Draconic Warhorn: Morphaz'),
(205722, 1180232, 0, 1, 0, 1, 0, 1, 1, 'Hazzas - Draconic Warhorn: Hazzas'),
(205775, 601062, 0, 1, 0, 1, 0, 1, 1, 'Verdan the Everliving - Elemental Lodestone: Verdan the Everliving'),
(206489, 87734, 0, 0.1, 0, 1, 0, 1, 1, 'Ironspine - Blood Soaked Vellum: Ironspine'),
(207079, 600392, 0, 1, 0, 1, 0, 1, 1, 'Viscous Fallout - Elemental Lodestone: Viscous Fallout'),
(207206, 601679, 0, 1, 0, 1, 0, 1, 1, 'Ancient Stone Keeper - Elemental Lodestone: Ancient Stone Keeper'),
(209568, 1180292, 0, 1, 0, 1, 0, 1, 1, 'Overlord Wyrmthalak - Draconic Warhorn: Overlord Wyrmthalak'),
(209938, 601687, 0, 1, 0, 1, 0, 1, 1, 'Magmus - Elemental Lodestone: Ironhand Guardian'),
(210264, 1180305, 0, 1, 0, 1, 0, 1, 1, 'Solakar Flamewreath - Draconic Warhorn: Solakar Flamewreath'),
(210363, 1180309, 0, 1, 0, 1, 0, 1, 1, 'General Drakkisath - Draconic Warhorn: General Drakkisath'),
(210430, 80089, 0, 1, 0, 1, 0, 1, 1, 'The Beast - Beastmaster''s Whistle: The Beast'),
(212237, 601076, 0, 1, 0, 1, 0, 1, 1, 'Meshlok the Harvester - Elemental Lodestone: Meshlok the Harvester'),
(213743, 601824, 0, 1, 0, 1, 0, 1, 1, 'Corrupt Force of Nature - Elemental Lodestone: Corrupt Force of Nature'),
(216042, 1180434, 0, 1, 0, 1, 0, 1, 1, 'Lord Valthalak - Draconic Warhorn: Lord Valthalak'),
(254939, 79468, 0, 1, 0, 1, 0, 1, 1, 'Duskdrinker - Beastmaster''s Whistle: Vampiric Duskbat'),
(299222, 79353, 0, 1, 0, 1, 0, 1, 1, 'Suspicious Creature - Beastmaster''s Whistle: Young Wolf'),
(299224, 79353, 0, 1, 0, 1, 0, 1, 1, 'Scorpid Stalker - Beastmaster''s Whistle: Young Wolf');
