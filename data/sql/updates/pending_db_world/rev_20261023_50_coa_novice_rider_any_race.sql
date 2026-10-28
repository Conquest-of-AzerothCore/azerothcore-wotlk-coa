-- CoA lets every race start in any starting zone, and the client's Novice Rider SuperTrack points
-- (QuestSuperTrack.dbc 10029-10064) send every Alliance race to Garion Hunter, Binjy Featherwhistle and Aalun,
-- and every Horde race to Gorn Axefist, Kar Stormsinger and Velma Warnam. The racial riding trainers therefore
-- teach every race of their faction instead of asking for Exalted reputation.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` IN (14, 15)
    AND `SourceGroup` IN (4014, 4015, 4016, 4018, 4019, 4020, 4021, 4022, 8275, 8553);
DELETE FROM `gossip_menu` WHERE (`MenuID`, `TextID`) IN ((4014, 5858), (4015, 5859), (4016, 5860), (4018, 5861),
    (4019, 5862), (4020, 5863), (4021, 5864), (4022, 5865), (8275, 10310), (8553, 10705));

-- Garion Hunter (Goldshire), Hank Dullahan (Sentinel Hill) and Gorn Axefist (Durotar) teach Novice Riding as well,
-- so they also offer and take back their faction's Path to Ascension: Novice Rider quests
DELETE FROM `creature_queststarter` WHERE `id` IN (97921, 776785, 75133)
    AND `quest` IN (4420430, 4420431, 4420432, 4420433, 4420434, 4420435, 4420436, 4420437, 4420438, 4420439);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(97921, 4420430),
(97921, 4420432),
(97921, 4420433),
(97921, 4420436),
(97921, 4420439),
(776785, 4420430),
(776785, 4420432),
(776785, 4420433),
(776785, 4420436),
(776785, 4420439),
(75133, 4420431),
(75133, 4420434),
(75133, 4420435),
(75133, 4420437),
(75133, 4420438);
DELETE FROM `creature_questender` WHERE `id` IN (97921, 776785, 75133)
    AND `quest` IN (4420430, 4420431, 4420432, 4420433, 4420434, 4420435, 4420436, 4420437, 4420438, 4420439);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(97921, 4420430),
(97921, 4420432),
(97921, 4420433),
(97921, 4420436),
(97921, 4420439),
(776785, 4420430),
(776785, 4420432),
(776785, 4420433),
(776785, 4420436),
(776785, 4420439),
(75133, 4420431),
(75133, 4420434),
(75133, 4420435),
(75133, 4420437),
(75133, 4420438);
