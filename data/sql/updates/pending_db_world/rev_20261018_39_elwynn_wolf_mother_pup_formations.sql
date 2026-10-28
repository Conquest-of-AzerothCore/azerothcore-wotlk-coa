-- Elwynn mother/pup wolf pairs (#8116): six Mangy Wolf (525) / Young Wolf
-- (299) pairs spawn side by side in Elwynn but wander independently and
-- assist nothing, while the established behaviour (warcraft.wiki.gg
-- Young Wolf / Mangy Wolf) is pups trailing mothers with linked aggro.
-- creature_formations carries both natively with no radius limit:
-- FOLLOW_LEADER (0x200) trails the pup behind, MEMBER_ASSIST_LEADER
-- (0x001, read off the leader row when she engages) and
-- LEADER_ASSIST_MEMBER (0x002, read off the member row when the pup
-- engages) pull the other half in. No SmartAI or AIName change is
-- needed: formations work under the existing random-wander movement and
-- NullAI. Pairs below are the six nearest one-to-one pup/mother matches
-- under 22 yd; the seventh pup (79920) stays solo. Confirm in game: fly
-- Elwynn, watch a pup trail its mother, pull one and confirm both come.
DELETE FROM `creature_formations` WHERE `memberGUID` IN (79650, 79651, 79894, 79895, 80270, 79899, 80341, 80342, 79900, 79921, 80343, 80351);
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(79650, 79650, 0, 0, 1, 0, 0),
(79650, 79651, 4, 3, 514, 0, 0),
(79895, 79895, 0, 0, 1, 0, 0),
(79895, 79894, 4, 3, 514, 0, 0),
(79899, 79899, 0, 0, 1, 0, 0),
(79899, 80270, 4, 3, 514, 0, 0),
(80342, 80342, 0, 0, 1, 0, 0),
(80342, 80341, 4, 3, 514, 0, 0),
(79921, 79921, 0, 0, 1, 0, 0),
(79921, 79900, 4, 3, 514, 0, 0),
(80351, 80351, 0, 0, 1, 0, 0),
(80351, 80343, 4, 3, 514, 0, 0);
