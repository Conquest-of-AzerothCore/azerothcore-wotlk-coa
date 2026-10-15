-- The Weapon Crate in the Cavern of Eldigh (Darengar well) takes "Notes of a Conspiracy" and offers "To Believe In An Ideal
-- Is To Be Willing To Betray It", as a gameplay video shows (youtu.be/c3a0y5pCKpE?t=386).
DELETE FROM `gameobject_questender` WHERE `id` = 2300631 AND `quest` = 175004;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(2300631, 175004);
DELETE FROM `gameobject_queststarter` WHERE `id` = 2300631 AND `quest` = 175005;
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES
(2300631, 175005);
