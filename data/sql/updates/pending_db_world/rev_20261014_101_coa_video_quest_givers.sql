-- Quest givers and takers read off the NPC talk windows in Pale Reach gameplay videos:
-- * Rothfuss takes "That Monster, My Husband" and offers "Arathel's Camp" (youtu.be/SGUWwezq2Z0?t=4688). Players talk to
--   him there, so he is friendly rather than a mob to fight.
-- * The Rockrend Citizen at the Fading Shore takes "Those Who Fled to the Sea" and offers "The Last Captives" and
--   "Quillscale Murlocs" (youtu.be/JG98sWrvX4U?t=650).
UPDATE `creature_template` SET `faction` = 35, `npcflag` = `npcflag` | 3 WHERE `entry` = 164238;
UPDATE `creature_template` SET `npcflag` = `npcflag` | 3 WHERE `entry` = 164359;
DELETE FROM `creature_questender` WHERE (`id`, `quest`) IN ((164238, 175072), (164359, 175127));
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164238, 175072),
(164359, 175127);
DELETE FROM `creature_queststarter` WHERE (`id`, `quest`) IN ((164238, 175078), (164359, 175128), (164359, 175129));
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164238, 175078),
(164359, 175128),
(164359, 175129);
