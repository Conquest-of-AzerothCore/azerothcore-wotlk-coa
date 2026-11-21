-- Nightmare - Lost in Horror (challenge 186) applies only its visible aura 93178, whose three effects are timers
-- with no damage-taken modifier. The client's hidden twin aura 93179 carries the +300% physical / +500% magic damage
-- taken that the trial text describes. A spell_linked_spell aura link (type 2) applies 93179 with 93178 and removes
-- it with 93178, so challenge 186 keeps the aura list of the client export and a regenerated challenge definitions
-- file cannot drop 93179. The UPDATE undoes an earlier revision of this file that listed 93179 on the challenge.
UPDATE `coa_challenge_spell` SET `pve` = '93178', `pvp` = '93178'
WHERE `challengeId` = 186 AND `pve` = '93178;93179' AND `pvp` = '93178;93179';

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 93178 AND `spell_effect` = 93179 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(93178, 93179, 2, 'Nightmare - Lost in Horror - hidden damage taken aura');
