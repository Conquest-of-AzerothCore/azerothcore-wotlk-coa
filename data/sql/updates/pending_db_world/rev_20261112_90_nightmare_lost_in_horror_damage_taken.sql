-- Nightmare - Lost in Horror (challenge 186) applied only its visible aura 93178, whose three effects are timers
-- with no damage-taken modifier, so the trial never raised damage taken. The client's hidden twin aura 93179
-- ("Nightmare - Lost in Horror", hidden client-side) carries the +300% physical / +500% magic damage taken that the
-- trial text describes, the same values as Nightmare III (93134).
UPDATE `coa_challenge_spell` SET `pve` = '93178;93179', `pvp` = '93178;93179'
WHERE `challengeId` = 186 AND `pve` = '93178' AND `pvp` = '93178';
