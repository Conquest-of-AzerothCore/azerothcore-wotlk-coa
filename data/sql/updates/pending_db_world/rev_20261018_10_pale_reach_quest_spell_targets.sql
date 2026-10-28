-- Three Pale Reach quest items whose spell could never land on its target (same fault as Cinders of Tragedy):
-- Soothing the Inner Gnoll (175026) and Anger Not Easily Appeased (175096): Throw Potion (365011) and Golden Tranquility
-- (365042) are used on hostile Hexed Bloodpaw Gnolls and Furious Gilded Treants, but count as helpful spells, and a player's
-- helpful spell is refused on a hostile target. Mark their effect harmful (SPELL_ATTR0_CU_NEGATIVE_EFF0) so they use the
-- attack rules instead.
DELETE FROM `spell_custom_attr` WHERE `spell_id` IN (365011, 365042);
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(365011, 4096),
(365042, 4096);
-- Amphora From The Spring (175084): the Injured Andraste Soldiers healed with the Filled Amphora (Heal Injured 257543) were
-- immune to players, so the heal was refused. They stay friendly and are no longer immune to players.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` & ~256 WHERE `entry` IN (164153, 164263);
